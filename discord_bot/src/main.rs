mod commands;
mod firebase;

use std::{
    collections::HashMap,
    sync::{Arc, Mutex},
};

use poise::serenity_prelude as serenity;

use crate::firebase::FirebaseClient;

/// Shared bot state accessible across all commands
pub struct Data {
    pub firebase: FirebaseClient,
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

    // Only subscribe to DM messages (non-privileged; does not require enabling Privileged Intents in Discord Portal)
    let intents = serenity::GatewayIntents::DIRECT_MESSAGES;

    let framework = poise::Framework::builder()
        .options(poise::FrameworkOptions {
            commands: commands::all(),
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
