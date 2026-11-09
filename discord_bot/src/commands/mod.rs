pub mod clear;
pub mod connect;
pub mod ping;

use crate::{Context, Data, Error};

/// Returns all registered bot commands.
pub fn all() -> Vec<poise::Command<Data, Error>> {
    vec![clear::clear(), connect::connect(), ping::ping()]
}

/// Global pre-command check: remote agent only responds in Direct Messages (DMs).
pub async fn dm_only_check(ctx: Context<'_>) -> Result<bool, Error> {
    if ctx.guild_id().is_some() {
        let _ = ctx
            .send(
                poise::CreateReply::default()
                    .content(
                        "🔒 Bot chỉ hoạt động qua tin nhắn riêng (DM). Hãy nhắn trực tiếp cho bot nhé!",
                    )
                    .ephemeral(true),
            )
            .await;
        return Ok(false);
    }
    Ok(true)
}
