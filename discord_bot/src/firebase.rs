use chrono::{Duration, Utc};
use serde_json::{Value, json};

use crate::Error;

/// Thin client wrapper around the Cloud Firestore REST API.
#[derive(Clone)]
pub struct FirebaseClient {
    http: reqwest::Client,
    base_url: String,
    api_key: Option<String>,
}

impl FirebaseClient {
    /// Initializes the Firestore REST client from environment variables:
    /// - `FIREBASE_PROJECT_ID` (defaults to `prm393-not-lab3`)
    /// - `FIREBASE_API_KEY` (optional)
    /// - `FIRESTORE_EMULATOR_HOST` (optional, e.g. `localhost:8080`)
    pub fn from_env() -> Self {
        let project_id = std::env::var("FIREBASE_PROJECT_ID")
            .unwrap_or_else(|_| "prm393-not-lab3".to_string());
        let api_key = std::env::var("FIREBASE_API_KEY")
            .ok()
            .filter(|k| !k.is_empty());

        let base_url = match std::env::var("FIRESTORE_EMULATOR_HOST") {
            Ok(host) if !host.is_empty() => {
                println!("Using Firestore Emulator at {host} (project: {project_id})");
                format!("http://{host}/v1/projects/{project_id}/databases/(default)/documents")
            }
            _ => {
                println!("Using Cloud Firestore (project: {project_id})");
                format!(
                    "https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents"
                )
            }
        };

        Self {
            http: reqwest::Client::new(),
            base_url,
            api_key,
        }
    }

    fn doc_url(&self, collection: &str, doc_id: &str) -> String {
        let url = format!("{}/{}/{}", self.base_url, collection, doc_id);
        match &self.api_key {
            Some(key) => format!("{url}?key={key}"),
            None => url,
        }
    }

    /// Fetches a Firestore document as raw JSON, returning `Ok(None)` if not found (404).
    pub async fn get_document(&self, collection: &str, doc_id: &str) -> Result<Option<Value>, Error> {
        let url = self.doc_url(collection, doc_id);
        let resp = self.http.get(&url).send().await?;
        if resp.status() == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }
        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(format!("Firestore GET {collection}/{doc_id} failed ({status}): {text}").into());
        }
        let body: Value = resp.json().await?;
        Ok(Some(body))
    }

    /// Creates or overwrites fields in a Firestore document (`PATCH`).
    pub async fn set_document(
        &self,
        collection: &str,
        doc_id: &str,
        fields: Value,
    ) -> Result<Value, Error> {
        let url = self.doc_url(collection, doc_id);
        let payload = json!({ "fields": fields });
        let resp = self.http.patch(&url).json(&payload).send().await?;
        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(
                format!("Firestore PATCH {collection}/{doc_id} failed ({status}): {text}").into(),
            );
        }
        let body: Value = resp.json().await?;
        Ok(body)
    }

    /// Checks `discordLinks/{discordId}` and returns the associated Nốt user `uid` if already linked.
    pub async fn get_linked_uid(&self, discord_id: &str) -> Result<Option<String>, Error> {
        let Some(doc) = self.get_document("discordLinks", discord_id).await? else {
            return Ok(None);
        };
        let uid = doc
            .get("fields")
            .and_then(|f| f.get("uid"))
            .and_then(|u| u.get("stringValue"))
            .and_then(|v| v.as_str())
            .map(String::from);
        Ok(uid)
    }

    /// Saves a one-time connection code in `discordConnectCodes/{code}` with an expiration timestamp.
    pub async fn save_connect_code(
        &self,
        code: &str,
        discord_id: &str,
        discord_username: &str,
        ttl_minutes: i64,
    ) -> Result<(), Error> {
        let now = Utc::now();
        let expires_at = now + Duration::minutes(ttl_minutes);

        let fields = json!({
            "discordId": { "stringValue": discord_id },
            "discordUsername": { "stringValue": discord_username },
            "createdAt": { "timestampValue": now.to_rfc3339() },
            "expiresAt": { "timestampValue": expires_at.to_rfc3339() }
        });

        self.set_document("discordConnectCodes", code, fields).await?;
        Ok(())
    }
}
