//! Plain-DM handler: any message that is not a `!command` is answered by the AI agent.
//! Photos sent in the DM are uploaded to Cloudinary and can be attached to the next note.

use std::{
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

use poise::serenity_prelude as serenity;
use rig_core::message::Message;

use crate::{Data, Error, agent, cloudinary::Photo};

/// Shown instead of an AI reply when the guardrail flags the conversation; `/clear` resets it.
const GUARD_REJECTION: &str = "Có lỗi xảy ra, hãy /clear để tiếp tục chat với bot của chúng tôi";

/// One message of the DM conversation (`bot` = sent by the bot).
pub struct Turn {
    bot: bool,
    text: String,
}

const DISCORD_LIMIT: usize = 1900;
const COOLDOWN: Duration = Duration::from_secs(3);

/// How many of the latest DM messages (before the new one) the agent remembers.
const HISTORY_MESSAGES: u8 = 20;
const HISTORY_CHARS_PER_MESSAGE: usize = 1500;

/// A photo is attached to a note only if sent within this time before it.
const PHOTO_TTL: Duration = Duration::from_secs(30 * 60);
const MAX_IMAGE_BYTES: u32 = 10 * 1024 * 1024;

/// A photo the user sent, already uploaded, waiting to be attached to a note.
pub struct PendingPhoto {
    photo: Photo,
    at: Instant,
}

fn is_image(a: &serenity::Attachment) -> bool {
    a.content_type
        .as_deref()
        .is_some_and(|c| c.starts_with("image/"))
        && a.size <= MAX_IMAGE_BYTES
}

/// The last [`HISTORY_MESSAGES`] messages of this DM (newer than `cutoff`), oldest first.
async fn load_history(
    ctx: &serenity::Context,
    msg: &serenity::Message,
    cutoff: Option<serenity::Timestamp>,
) -> Result<Vec<Turn>, Error> {
    let mut recent = msg
        .channel_id
        .messages(
            &ctx.http,
            serenity::GetMessages::new()
                .before(msg.id)
                .limit(HISTORY_MESSAGES),
        )
        .await?;
    recent.reverse(); // Discord returns newest first.

    Ok(recent
        .iter()
        .filter(|m| cutoff.is_none_or(|c| m.timestamp > c))
        .filter_map(|m| {
            let mut text: String = m
                .content
                .trim()
                .chars()
                .take(HISTORY_CHARS_PER_MESSAGE)
                .collect();
            if m.attachments.iter().any(is_image) {
                text.push_str(" [đã gửi ảnh]");
            }
            let text = text.trim().to_string();
            if text.is_empty() {
                return None;
            }
            if m.author.bot {
                Some(Turn { bot: true, text })
            } else if text.starts_with('!') {
                None // prefix commands are not conversation
            } else {
                Some(Turn { bot: false, text })
            }
        })
        .collect())
}

pub async fn event_handler(
    ctx: &serenity::Context,
    event: &serenity::FullEvent,
    data: &Data,
) -> Result<(), Error> {
    let serenity::FullEvent::Message { new_message: msg } = event else {
        return Ok(());
    };
    // Only human DMs; `!connect` / `!ping` stay with the prefix-command framework.
    if msg.author.bot || msg.guild_id.is_some() {
        return Ok(());
    }
    let text = msg.content.trim();
    let image = msg.attachments.iter().find(|a| is_image(a));
    if text.starts_with('!') || (text.is_empty() && image.is_none()) {
        return Ok(());
    }
    let Some(model) = data.ai_model.as_deref() else {
        return Ok(());
    };
    if !data.firebase.has_admin() {
        return Ok(());
    }

    // Per-user cooldown so a burst of messages can't run up the OpenRouter bill.
    {
        let mut last = data.last_ai_call.lock().expect("cooldown lock poisoned");
        let now = Instant::now();
        if last
            .get(&msg.author.id)
            .is_some_and(|t| now.duration_since(*t) < COOLDOWN)
        {
            return Ok(());
        }
        last.insert(msg.author.id, now);
    }

    let Some(uid) = data
        .firebase
        .get_linked_uid(&msg.author.id.to_string())
        .await?
    else {
        // Not linked yet: fixed reply, no AI call.
        msg.channel_id
            .say(
                &ctx.http,
                "🔗 Bạn cần liên kết tài khoản Nốt trước khi trò chuyện với mình. \
                Gõ `/connect` để lấy mã kết nối nhé!",
            )
            .await?;
        return Ok(());
    };

    let _typing = msg.channel_id.start_typing(&ctx.http);

    let cutoff = data
        .cleared_at
        .lock()
        .expect("cleared_at lock poisoned")
        .get(&msg.author.id)
        .copied();
    let turns = load_history(ctx, msg, cutoff).await.unwrap_or_else(|e| {
        eprintln!("history load failed: {e}");
        Vec::new()
    });

    let prompt = match (text.is_empty(), image.is_some()) {
        (true, true) => "(Mình vừa gửi một ảnh)".to_string(),
        (false, true) => format!("{text}\n(Kèm theo một ảnh)"),
        _ => text.to_string(),
    };

    // Guardrail: if anything in the context sent to the AI is abusive, refuse until the user runs /clear.
    // Fails open (logged) so an outage of the decision model does not lock everyone out.
    if let Some(guard) = &data.guard {
        let mut conversation: String = turns
            .iter()
            .map(|t| format!("{}: {}\n", if t.bot { "Assistant" } else { "User" }, t.text))
            .collect();
        conversation.push_str(&format!("User: {prompt}"));
        match guard.is_abusive(&conversation).await {
            Ok(true) => {
                eprintln!("guard: blocked conversation of user {}", msg.author.id);
                msg.channel_id.say(&ctx.http, GUARD_REJECTION).await?;
                return Ok(());
            }
            Ok(false) => {}
            Err(e) => eprintln!("guard error (allowing message): {e}"),
        }
    }

    // A photo in this message: upload it now so a later "create note" can attach it.
    if let Some(attachment) = image {
        match data.cloudinary.upload_from_url(&attachment.url).await {
            Ok(photo) => {
                data.pending_photos
                    .lock()
                    .expect("pending_photos lock poisoned")
                    .insert(
                        msg.author.id,
                        PendingPhoto {
                            photo,
                            at: Instant::now(),
                        },
                    );
            }
            Err(e) => {
                eprintln!("photo upload failed: {e}");
                msg.channel_id
                    .say(
                        &ctx.http,
                        "😵 Mình chưa tải được ảnh này lên, bạn thử gửi lại giúp mình nhé.",
                    )
                    .await?;
                return Ok(());
            }
        }
    }

    // Hand the (fresh enough) pending photo to this run; drop it from the map once a note used it.
    let pending = {
        let mut map = data
            .pending_photos
            .lock()
            .expect("pending_photos lock poisoned");
        if map
            .get(&msg.author.id)
            .is_some_and(|p| p.at.elapsed() >= PHOTO_TTL)
        {
            map.remove(&msg.author.id);
        }
        map.get(&msg.author.id).map(|p| p.photo.clone())
    };
    let had_photo = pending.is_some();
    let slot: agent::PhotoSlot = Arc::new(Mutex::new(pending));

    let history: Vec<Message> = turns
        .into_iter()
        .map(|t| {
            if t.bot {
                Message::assistant(t.text)
            } else {
                Message::user(t.text)
            }
        })
        .collect();

    let reply = match agent::run(history, &data.firebase, &uid, model, &prompt, slot.clone()).await
    {
        Ok(t) if !t.trim().is_empty() => t,
        Ok(_) => "Mình chưa hiểu ý bạn, bạn nói lại giúp mình nhé.".to_string(),
        Err(e) => {
            eprintln!("agent error: {e}");
            "😵 Trợ lý đang gặp sự cố, bạn thử lại sau nhé.".to_string()
        }
    };

    // The note took the photo: it is no longer waiting.
    if had_photo && slot.lock().expect("photo slot poisoned").is_none() {
        data.pending_photos
            .lock()
            .expect("pending_photos lock poisoned")
            .remove(&msg.author.id);
    }

    let reply: String = reply.chars().take(DISCORD_LIMIT).collect();
    msg.channel_id.say(&ctx.http, reply).await?;
    Ok(())
}
