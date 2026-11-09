use std::sync::Arc;

use base64::Engine;
use chrono::{Duration, Utc};
use gcp_auth::{CustomServiceAccount, TokenProvider};
use serde_json::{Value, json};

use crate::Error;

const FIRESTORE_SCOPES: &[&str] = &["https://www.googleapis.com/auth/datastore"];

/// Thin client wrapper around the Cloud Firestore REST API.
#[derive(Clone)]
pub struct FirebaseClient {
    http: reqwest::Client,
    base_url: String,
    api_key: Option<String>,
    /// Service account used for admin access (bypasses Firestore rules).
    /// `None` → unauthenticated REST, limited by the security rules.
    auth: Option<Arc<CustomServiceAccount>>,
}

/// Reads `FIREBASE_SERVICE_ACCOUNT_JSON`: either the raw JSON or its base64 encoding.
fn load_service_account() -> Option<CustomServiceAccount> {
    let raw = std::env::var("FIREBASE_SERVICE_ACCOUNT_JSON").ok()?;
    let raw = raw.trim();
    if raw.is_empty() {
        return None;
    }
    let json = if raw.starts_with('{') {
        raw.to_string()
    } else {
        let bytes = base64::engine::general_purpose::STANDARD
            .decode(raw)
            .expect("FIREBASE_SERVICE_ACCOUNT_JSON is neither JSON nor valid base64");
        String::from_utf8(bytes).expect("FIREBASE_SERVICE_ACCOUNT_JSON base64 is not UTF-8")
    };
    Some(
        CustomServiceAccount::from_json(&json)
            .expect("FIREBASE_SERVICE_ACCOUNT_JSON is not a valid service account key"),
    )
}

impl FirebaseClient {
    /// Initializes the Firestore REST client from environment variables:
    /// - `FIREBASE_PROJECT_ID` (defaults to `prm393-not-lab3`)
    /// - `FIREBASE_API_KEY` (optional)
    /// - `FIREBASE_SERVICE_ACCOUNT_JSON` (optional; raw or base64 service account key,
    ///   required for the AI agent to read/write users' notes)
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

        let auth = load_service_account().map(Arc::new);
        if auth.is_some() {
            println!("Firestore admin access enabled (service account)");
        }

        Self {
            http: reqwest::Client::new(),
            base_url,
            api_key,
            auth,
        }
    }

    /// Whether admin (service account) access is configured.
    pub fn has_admin(&self) -> bool {
        self.auth.is_some()
    }

    /// Starts a request, attaching a service-account bearer token when configured.
    async fn request(
        &self,
        method: reqwest::Method,
        url: &str,
    ) -> Result<reqwest::RequestBuilder, Error> {
        let builder = self.http.request(method, url);
        match &self.auth {
            Some(auth) => {
                let token = auth.token(FIRESTORE_SCOPES).await?;
                Ok(builder.bearer_auth(token.as_str()))
            }
            None => Ok(builder),
        }
    }

    /// Appends the API key only when not using a service account.
    fn with_key(&self, url: String) -> String {
        match (&self.api_key, &self.auth) {
            (Some(key), None) => format!("{url}?key={key}"),
            _ => url,
        }
    }

    fn doc_url(&self, collection: &str, doc_id: &str) -> String {
        self.with_key(format!("{}/{}/{}", self.base_url, collection, doc_id))
    }

    /// Fetches a Firestore document as raw JSON, returning `Ok(None)` if not found (404).
    pub async fn get_document(&self, collection: &str, doc_id: &str) -> Result<Option<Value>, Error> {
        let url = self.doc_url(collection, doc_id);
        let resp = self.request(reqwest::Method::GET, &url).await?.send().await?;
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
        let resp = self
            .request(reqwest::Method::PATCH, &url)
            .await?
            .json(&payload)
            .send()
            .await?;
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

    /// Creates a document with an auto-generated id under `collection_path`
    /// (e.g. `users/{uid}/notes`). Returns the new document id.
    pub async fn create_document(
        &self,
        collection_path: &str,
        fields: Value,
    ) -> Result<String, Error> {
        let url = self.with_key(format!("{}/{}", self.base_url, collection_path));
        let resp = self
            .request(reqwest::Method::POST, &url)
            .await?
            .json(&json!({ "fields": fields }))
            .send()
            .await?;
        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(format!("Firestore POST {collection_path} failed ({status}): {text}").into());
        }
        let body: Value = resp.json().await?;
        let id = body
            .get("name")
            .and_then(Value::as_str)
            .and_then(|n| n.rsplit('/').next())
            .ok_or("Firestore create response has no document name")?;
        Ok(id.to_string())
    }

    /// Runs a structured query under `parent_path` (e.g. `users/{uid}`) and
    /// returns the matched documents.
    pub async fn run_query(
        &self,
        parent_path: &str,
        structured_query: Value,
    ) -> Result<Vec<Value>, Error> {
        let url = self.with_key(format!("{}/{}:runQuery", self.base_url, parent_path));
        let resp = self
            .request(reqwest::Method::POST, &url)
            .await?
            .json(&json!({ "structuredQuery": structured_query }))
            .send()
            .await?;
        if !resp.status().is_success() {
            let status = resp.status();
            let text = resp.text().await.unwrap_or_default();
            return Err(format!("Firestore runQuery {parent_path} failed ({status}): {text}").into());
        }
        let rows: Vec<Value> = resp.json().await?;
        Ok(rows
            .into_iter()
            .filter_map(|mut row| row.get_mut("document").map(Value::take))
            .collect())
    }
}
