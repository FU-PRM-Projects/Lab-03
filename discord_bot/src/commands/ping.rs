use crate::{Context, Error};

/// Kiểm tra trạng thái hoạt động của bot (chỉ dùng trong DM)
#[poise::command(
    slash_command,
    prefix_command,
    dm_only,
    interaction_context = "BotDm|PrivateChannel",
    install_context = "Guild|User"
)]
pub async fn ping(ctx: Context<'_>) -> Result<(), Error> {
    ctx.say("Pong! 🏓 (Remote Agent đang hoạt động trong DM)").await?;
    Ok(())
}
