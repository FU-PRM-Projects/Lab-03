//! Plain-DM handler: any message that is not a `!command` is answered by the AI agent.

use std::time::{Duration, Instant};

use poise::serenity_prelude as serenity;
use rig_core::message::Message;

use crate::{Data, Error, agent};

const DISCORD_LIMIT: usize = 1900;
const COOLDOWN: Duration = Duration::from_secs(3);

/// How many of the latest DM messages (before the new one) the agent remembers.
const HISTORY_MESSAGES: u8 = 20;
const HISTORY_CHARS_PER_MESSAGE: usize = 1500;

/// The last [`HISTORY_MESSAGES`] messages of this DM, oldest first, as chat history.
async fn load_history(
    ctx: &serenity::Context,
    msg: &serenity::Message,
) -> Result<Vec<Message>, Error> {
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
        .filter_map(|m| {
            let text: String = m.content.trim().chars().take(HISTORY_CHARS_PER_MESSAGE).collect();
            if text.is_empty() {
                return None;
            }
            if m.author.bot {
                Some(Message::assistant(text))
            } else if text.starts_with('!') {
                None // prefix commands are not conversation
            } else {
                Some(Message::user(text))
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
    if text.is_empty() || text.starts_with('!') {
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

    let history = load_history(ctx, msg).await.unwrap_or_else(|e| {
        eprintln!("history load failed: {e}");
        Vec::new()
    });
    let _typing = msg.channel_id.start_typing(&ctx.http);
    let reply = match agent::run(history, &data.firebase, &uid, model, text).await {
        Ok(t) if !t.trim().is_empty() => t,
        Ok(_) => "Mình chưa hiểu ý bạn, bạn nói lại giúp mình nhé.".to_string(),
        Err(e) => {
            eprintln!("agent error: {e}");
            "😵 Trợ lý đang gặp sự cố, bạn thử lại sau nhé.".to_string()
        }
    };
    let reply: String = reply.chars().take(DISCORD_LIMIT).collect();
    msg.channel_id.say(&ctx.http, reply).await?;
    Ok(())
}
