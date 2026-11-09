mod agent;
mod chat;
mod cloudinary;
mod commands;
mod firebase;
mod guard;

use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use poise::serenity_prelude as serenity;

use crate::firebase::FirebaseClient;

/// Shared bot state accessible across all commands
pub struct Data {
    pub firebase: FirebaseClient,
    /// OpenRouter model id for the AI agent; `None` when `OPENROUTER_API_KEY` is not set.
    pub ai_model: Option<String>,
    /// Abuse guardrail (decision model); `None` when the AI is off or `GUARD_MODEL=off`.
    pub guard: Option<guard::Guard>,
    /// Last AI call per Discord user (cooldown).
    pub last_ai_call: Mutex<HashMap<serenity::UserId, std::time::Instant>>,
    /// `/clear` cutoff per user: older DM messages are not given to the AI.
    pub cleared_at: Mutex<HashMap<serenity::UserId, serenity::Timestamp>>,
    /// Latest photo each user sent, uploaded and waiting to be attached to a note.
    pub pending_photos: Mutex<HashMap<serenity::UserId, chat::PendingPhoto>>,
    pub cloudinary: cloudinary::Cloudinary,
    /// Background tasks (keyed by Discord user id) waiting for a connect code to be redeemed in the app.
    pub link_watchers: Arc<Mutex<HashMap<String, tokio::task::JoinHandle<()>>>>,
}

pub type Error = Box<dyn std::error::Error + Send + Sync>;
pub type Context<'a> = poise::Context<'a, Data, Error>;

#[tokio::main]
async fn main() {
    let _ = dotenvy::dotenv();

    let token = std::env::var("DISCORD_TOKEN")
        .expect("Missing DISCORD_TOKEN environment variable")
        .trim()
        .to_string();
    let firebase = FirebaseClient::from_env();
    let ai_model = std::env::var("OPENROUTER_API_KEY")
        .ok()
        .filter(|k| !k.trim().is_empty())
        .map(|_| {
            std::env::var("OPENROUTER_MODEL")
                .ok()
                .filter(|m| !m.trim().is_empty())
                .unwrap_or_else(|| agent::DEFAULT_MODEL.to_string())
        });
    match &ai_model {
        Some(m) => println!("AI agent enabled (OpenRouter model: {m})"),
        None => println!("AI agent disabled (OPENROUTER_API_KEY not set)"),
    }

    let guard = std::env::var("OPENROUTER_API_KEY")
        .ok()
        .filter(|k| !k.trim().is_empty())
        .and_then(|key| guard::Guard::from_env(key.trim()));
    match &guard {
        Some(g) => println!("Guardrail enabled (model: {})", g.model()),
        None => println!("Guardrail disabled"),
    }

    // Only subscribe to DM messages (non-privileged; does not require enabling Privileged Intents in Discord Portal)
    let intents = serenity::GatewayIntents::DIRECT_MESSAGES;

    let framework = poise::Framework::builder()
        .options(poise::FrameworkOptions {
            commands: commands::all(),
            event_handler: |framework, event| {
                Box::pin(chat::event_handler(
                    framework.serenity_context,
                    event,
                    framework.user_data,
                ))
            },
            command_check: Some(|ctx| Box::pin(commands::dm_only_check(ctx))),
            prefix_options: poise::PrefixFrameworkOptions {
                prefix: Some("!".into()),
                case_insensitive_commands: true,
                ..Default::default()
            },
            ..Default::default()
        })
        .setup(move |ctx, ready, framework| {
            Box::pin(async move {
                println!("Logged in as {} (DM-only Remote Agent)", ready.user.name);
                poise::builtins::register_globally(ctx, &framework.options().commands).await?;
                Ok(Data {
                    firebase,
                    ai_model,
                    guard,
                    last_ai_call: Mutex::new(HashMap::new()),
                    cleared_at: Mutex::new(HashMap::new()),
                    pending_photos: Mutex::new(HashMap::new()),
                    cloudinary: cloudinary::Cloudinary::from_env(),
                    link_watchers: Arc::new(Mutex::new(HashMap::new())),
                })
            })
        })
        .build();

    let mut client = serenity::ClientBuilder::new(token, intents)
        .framework(framework)
        .await
        .expect("Error creating Discord client");

    if let Err(why) = client.start().await {
        eprintln!("Client error: {why:?}");
    }
}
