use poise::serenity_prelude as serenity;

use crate::{Context, Error};

/// Xóa ngữ cảnh: trợ lý AI sẽ quên các tin nhắn trước đó (chỉ dùng trong DM)
#[poise::command(
    slash_command,
    prefix_command,
    dm_only,
    interaction_context = "BotDm|PrivateChannel",
    install_context = "Guild|User"
)]
pub async fn clear(ctx: Context<'_>) -> Result<(), Error> {
    ctx.say("🧹 Đã xóa ngữ cảnh. Mình sẽ bắt đầu cuộc trò chuyện mới từ đây nhé!")
        .await?;

    // Bots cannot delete the user's DM messages, so "clearing" moves a cutoff:
    // anything older is no longer given to the AI. Set after the reply so it isn't kept as history.
    let user = ctx.author().id;
    let data = ctx.data();
    data.cleared_at
        .lock()
        .expect("cleared_at lock poisoned")
        .insert(user, serenity::Timestamp::now());
    data.pending_photos
        .lock()
        .expect("pending_photos lock poisoned")
        .remove(&user);
    Ok(())
}
