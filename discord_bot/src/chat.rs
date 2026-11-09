//! Plain-DM handler: any message that is not a `!command` is answered by the AI agent.

use std::time::{Duration, Instant};

use poise::serenity_prelude as serenity;

use crate::{Data, Error, agent};

const DISCORD_LIMIT: usize = 1900;
const COOLDOWN: Duration = Duration::from_secs(3);

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

    let _typing = msg.channel_id.start_typing(&ctx.http);
    let reply = match agent::run(&data.firebase, &uid, model, text).await {
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
