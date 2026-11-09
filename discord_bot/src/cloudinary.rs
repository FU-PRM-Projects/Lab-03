//! Cloudinary unsigned upload, the same cloud/preset the Nốt app uses, so photos sent
//! to the bot show up in the app like photos taken there.

use rand::RngExt;
use serde_json::Value;

use crate::Error;

const ID_CHARS: &[u8] = b"abcdefghijklmnopqrstuvwxyz0123456789";

/// A photo stored on Cloudinary (`{url, publicId}` in the app's note documents).
#[derive(Clone, Debug)]
pub struct Photo {
    pub url: String,
    pub public_id: String,
}

#[derive(Clone)]
pub struct Cloudinary {
    http: reqwest::Client,
    cloud_name: String,
    upload_preset: String,
}

impl Cloudinary {
    /// `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_UPLOAD_PRESET` (public values, same defaults as the app).
    pub fn from_env() -> Self {
        let get = |key: &str, default: &str| {
            std::env::var(key)
                .ok()
                .filter(|v| !v.trim().is_empty())
                .unwrap_or_else(|| default.to_string())
        };
        Self {
            http: reqwest::Client::new(),
            cloud_name: get("CLOUDINARY_CLOUD_NAME", "t7crbqj0"),
            upload_preset: get("CLOUDINARY_UPLOAD_PRESET", "PRM_Lab3"),
        }
    }

    /// Has Cloudinary fetch the image at `source_url` (e.g. a Discord attachment) and store it.
    pub async fn upload_from_url(&self, source_url: &str) -> Result<Photo, Error> {
        let id: String = {
            let mut rng = rand::rng();
            (0..20)
                .map(|_| ID_CHARS[rng.random_range(0..ID_CHARS.len())] as char)
                .collect()
        };
        let resp = self
            .http
            .post(format!(
                "https://api.cloudinary.com/v1_1/{}/image/upload",
                self.cloud_name
            ))
            .form(&[
                ("file", source_url),
                ("upload_preset", self.upload_preset.as_str()),
                // Random public id: not guessable, never overwrites (same scheme as the app).
                ("public_id", format!("not/notes/{id}").as_str()),
            ])
            .send()
            .await?;
        let status = resp.status();
        let body: Value = resp.json().await?;
        if !status.is_success() {
            let message = body["error"]["message"].as_str().unwrap_or("unknown error");
            return Err(format!("Cloudinary upload failed ({status}): {message}").into());
        }
        let url = body["secure_url"].as_str().ok_or("Cloudinary: no secure_url")?;
        let public_id = body["public_id"].as_str().ok_or("Cloudinary: no public_id")?;
        if !url.starts_with("https://res.cloudinary.com/") {
            return Err("Cloudinary returned an unexpected URL".into());
        }
        Ok(Photo {
            url: url.to_string(),
            public_id: public_id.to_string(),
        })
    }
}
