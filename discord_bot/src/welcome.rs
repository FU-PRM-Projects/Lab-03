//! Discord event webhook: DMs a welcome + connect guide when someone authorizes the app
//! (`APPLICATION_AUTHORIZED`, fired for both user installs and server installs).
//!
//! Setup: Developer Portal → Webhooks → Events URL = `https://<domain>/discord/events`,
//! subscribe to `APPLICATION_AUTHORIZED`. Needs `DISCORD_PUBLIC_KEY` (General Information).

use std::{
    collections::HashSet,
    sync::{Arc, Mutex},
};

use axum::{
    Router,
    body::Bytes,
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::{get, post},
};
use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use poise::serenity_prelude as serenity;

const WELCOME: &str = "👋 **Chào mừng bạn đến với Nốt!**\n\
    Mình là bot giúp bạn ghi chú nhanh ngay trong Discord — cứ nhắn tin cho mình, mình sẽ lưu lại thành ghi chú trong ứng dụng **Nốt**. 📝\n\n\
    **Kết nối với ứng dụng Nốt (chỉ mất 1 phút):**\n\
    1. Gõ `/connect` tại đây để nhận mã 6 ký tự.\n\
    2. Mở ứng dụng **Nốt** → **Cài đặt → Liên kết Discord**.\n\
    3. Nhập mã để hoàn tất liên kết.\n\n\
    Sau khi liên kết, bạn có thể gửi ghi chú (kèm ảnh nếu muốn) cho mình bất cứ lúc nào. Gõ `/clear` nếu muốn bắt đầu cuộc trò chuyện mới. ✨";

struct AppState {
    public_key: VerifyingKey,
    http: Arc<serenity::Http>,
    /// Users already welcomed since the bot started (re-authorizing fires the event again).
    welcomed: Mutex<HashSet<u64>>,
}

/// Starts the webhook server if `DISCORD_PUBLIC_KEY` is set; otherwise welcome DMs stay off.
pub fn spawn(http: Arc<serenity::Http>) {
    let Some(key_hex) = std::env::var("DISCORD_PUBLIC_KEY")
        .ok()
        .map(|k| k.trim().to_string())
        .filter(|k| !k.is_empty())
    else {
        println!("Welcome webhook disabled (DISCORD_PUBLIC_KEY not set)");
        return;
    };
    let public_key = match parse_key(&key_hex) {
        Some(k) => k,
        None => {
            eprintln!("Welcome webhook disabled: DISCORD_PUBLIC_KEY is not a valid ed25519 key");
            return;
        }
    };
    let port = std::env::var("PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(8080u16);

    let state = Arc::new(AppState {
        public_key,
        http,
        welcomed: Mutex::new(HashSet::new()),
    });
    let app = Router::new()
        .route("/", get(|| async { "ok" }))
        .route("/discord/events", post(events))
        .with_state(state);

    tokio::spawn(async move {
        match tokio::net::TcpListener::bind(("0.0.0.0", port)).await {
            Ok(listener) => {
                println!("Welcome webhook listening on :{port}/discord/events");
                if let Err(e) = axum::serve(listener, app).await {
                    eprintln!("Welcome webhook server error: {e}");
                }
            }
            Err(e) => eprintln!("Welcome webhook cannot bind :{port}: {e}"),
        }
    });
}

fn parse_key(hex_str: &str) -> Option<VerifyingKey> {
    let bytes: [u8; 32] = hex::decode(hex_str).ok()?.try_into().ok()?;
    VerifyingKey::from_bytes(&bytes).ok()
}

fn verified(state: &AppState, headers: &HeaderMap, body: &[u8]) -> bool {
    let (Some(sig), Some(ts)) = (
        headers.get("x-signature-ed25519").and_then(|v| v.to_str().ok()),
        headers.get("x-signature-timestamp").and_then(|v| v.to_str().ok()),
    ) else {
        return false;
    };
    let Some(sig) = hex::decode(sig)
        .ok()
        .and_then(|b| <[u8; 64]>::try_from(b).ok())
        .map(|b| Signature::from_bytes(&b))
    else {
        return false;
    };
    let mut msg = ts.as_bytes().to_vec();
    msg.extend_from_slice(body);
    state.public_key.verify(&msg, &sig).is_ok()
}

async fn events(State(state): State<Arc<AppState>>, headers: HeaderMap, body: Bytes) -> StatusCode {
    if !verified(&state, &headers, &body) {
        return StatusCode::UNAUTHORIZED;
    }
    let Ok(json) = serde_json::from_slice::<serde_json::Value>(&body) else {
        return StatusCode::BAD_REQUEST;
    };
    // Webhook type 0 = PING (portal URL check), 1 = EVENT. Both are acknowledged with 204.
    let event = &json["event"];
    if json["type"] == 1 && event["type"] == "APPLICATION_AUTHORIZED" {
        let user_id = event["data"]["user"]["id"]
            .as_str()
            .and_then(|s| s.parse::<u64>().ok());
        if let Some(id) = user_id {
            let first_time = state.welcomed.lock().map(|mut s| s.insert(id)).unwrap_or(true);
            if first_time {
                let http = state.http.clone();
                // Reply right away; Discord expects a quick ack.
                tokio::spawn(async move {
                    let msg = serenity::CreateMessage::new().content(WELCOME);
                    if let Err(e) = serenity::UserId::new(id).direct_message(&http, msg).await {
                        eprintln!("Failed to DM welcome to {id}: {e}");
                    }
                });
            }
        }
    }
    StatusCode::NO_CONTENT
}
