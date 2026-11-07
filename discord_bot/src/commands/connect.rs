use rand::RngExt;

use crate::{Context, Error};

const CODE_CHARS: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_LEN: usize = 6;
const CODE_TTL_MINUTES: i64 = 10;

fn generate_code() -> String {
    let mut rng = rand::rng();
    (0..CODE_LEN)
        .map(|_| {
            let idx = rng.random_range(0..CODE_CHARS.len());
            CODE_CHARS[idx] as char
        })
        .collect()
}

/// Tạo mã kết nối tài khoản Discord với ứng dụng Nốt (chỉ dùng trong DM)
#[poise::command(
    slash_command,
    prefix_command,
    dm_only,
    interaction_context = "BotDm|PrivateChannel",
    install_context = "Guild|User"
)]
pub async fn connect(ctx: Context<'_>) -> Result<(), Error> {
    ctx.defer_ephemeral().await?;

    let author = ctx.author();
    let discord_id = author.id.to_string();
    let discord_username = match &author.global_name {
        Some(global) if !global.is_empty() => format!("{global} (@{})", author.name),
        _ => author.name.clone(),
    };

    // 1. Enforce 1-to-1: check if this Discord account is already associated with an app account
    if let Some(_uid) = ctx.data().firebase.get_linked_uid(&discord_id).await? {
        ctx.say(
            "✅ Tài khoản Discord của bạn đã được liên kết với một tài khoản **Nốt**.\n\
            *(Mỗi tài khoản Discord chỉ được liên kết với 1 tài khoản Nốt. Nếu muốn đổi, hãy ngắt kết nối trong ứng dụng Nốt trước.)*",
        )
        .await?;
        return Ok(());
    }

    // 2. Generate a fresh 6-character code and save it to Firestore
    let code = generate_code();
    ctx.data()
        .firebase
        .save_connect_code(&code, &discord_id, &discord_username, CODE_TTL_MINUTES)
        .await?;

    let response = format!(
        "🔗 **Mã kết nối Nốt của bạn là:** `{code}`\n\n\
        **Cách sử dụng:**\n\
        1. Mở ứng dụng **Nốt** trên điện thoại hoặc trình duyệt.\n\
        2. Vào **Cài đặt → Liên kết Discord**.\n\
        3. Nhập mã `{code}` để hoàn tất liên kết.\n\n\
        ⏳ *Mã có hiệu lực trong {CODE_TTL_MINUTES} phút. Mỗi tài khoản Nốt chỉ liên kết với 1 tài khoản Discord duy nhất.*"
    );

    ctx.say(response).await?;
    Ok(())
}
