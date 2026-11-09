//! AI agent (rig + OpenRouter) that lets a linked user manage their Nốt notes by chatting.
//!
//! The agent is built per request: its tools are bound to the caller's Firebase `uid`
//! (resolved from the Discord link), so the model can never pick or see another user's data.

use std::{
    convert::Infallible,
    sync::{Arc, Mutex},
};

use chrono::{FixedOffset, Utc};
use rig_agent::{AgentBuilder, tool::{Tool, ToolContext}};
use rig_core::{message::Message, providers::openrouter};
use serde::Deserialize;
use serde_json::{Value, json};

use crate::{Error, cloudinary::Photo, firebase::FirebaseClient};

/// The user's photo waiting to be attached to the next note; `create_note` takes it.
pub type PhotoSlot = Arc<Mutex<Option<Photo>>>;

pub const DEFAULT_MODEL: &str = "deepseek/deepseek-v4.1-flash-1017";
const MAX_TURNS: usize = 5;
const MAX_REQUEST_CHARS: usize = 1000;
const TITLE_MAX: usize = 120;
const BODY_MAX: usize = 2000;
const SEARCH_WINDOW: i64 = 100;

const PREAMBLE: &str = "Bạn là trợ lý của ứng dụng **Nốt**, một hũ ghi chú những khoảnh khắc nhỏ của người dùng. \
Trả lời bằng tiếng Việt, ngắn gọn, ấm áp. Bạn có các công cụ để tạo nốt, xem nốt gần đây và tìm nốt. \
Bạn nhớ các tin nhắn gần đây trong cuộc trò chuyện. Chỉ tạo nốt khi người dùng muốn lưu; \
khi họ đã muốn lưu và nội dung đã rõ (kể cả từ các tin trước) thì tự đặt tiêu đề, chọn loại nốt hợp lý \
rồi tạo, đừng hỏi lại về nội dung. Không tự ý tạo nốt khi họ chỉ hỏi han. \
Mỗi nốt có thể kèm MỘT ảnh khoảnh khắc (không bắt buộc). Trước khi tạo nốt, nếu chưa có ảnh đang chờ và bạn chưa \
hỏi về ảnh trong cuộc trò chuyện này, hãy hỏi đúng một lần: họ có ảnh muốn đính kèm không (gửi ảnh ngay trong \
cuộc trò chuyện, hoặc nói không/bỏ qua). Họ từ chối hoặc đã trả lời thì tạo nốt luôn, không hỏi lại. \
Khi có ảnh đang chờ, gọi create_note với attach_photo=true; ảnh chỉ đính kèm được lúc tạo nốt mới. \
Loại nốt: chien_thang (chiến thắng nhỏ), tu_chu (tự chủ), nhat_ky (nhật ký). \
Nếu yêu cầu mơ hồ về nội dung thì hỏi lại thay vì bịa. Không bao giờ nhắc đến uid hay chi tiết kỹ thuật.";

/// Runs one agent turn for `uid` and returns the final text to send back on Discord.
pub async fn run(
    history: Vec<Message>,
    firebase: &FirebaseClient,
    uid: &str,
    model_id: &str,
    request: &str,
    photo: PhotoSlot,
) -> Result<String, Error> {
    let request: String = request.chars().take(MAX_REQUEST_CHARS).collect();
    let model = openrouter::from_env()?.chat(model_id);

    let now = Utc::now().with_timezone(&FixedOffset::east_opt(7 * 3600).expect("valid offset"));
    let photo_status = if photo.lock().expect("photo slot poisoned").is_some() {
        "Trạng thái ảnh: CÓ 1 ảnh đang chờ đính kèm."
    } else {
        "Trạng thái ảnh: chưa có ảnh nào đang chờ."
    };
    let preamble = format!(
        "{PREAMBLE}\nBây giờ là {} (giờ Việt Nam).\n{photo_status}",
        now.format("%H:%M ngày %d/%m/%Y")
    );

    let ctx = NoteAccess {
        firebase: firebase.clone(),
        uid: uid.to_string(),
    };
    let agent = AgentBuilder::new(model)
        .preamble(preamble)
        .temperature(0.3)
        .max_tokens(800)
        .tool(CreateNote(ctx.clone(), photo))
        .tool(ListRecentNotes(ctx.clone()))
        .tool(SearchNotes(ctx))
        .build();

    let answer = agent.prompt(request).history(history).max_turns(MAX_TURNS).await?;
    Ok(answer.to_string())
}

/// Firestore handle bound to a single user.
#[derive(Clone)]
struct NoteAccess {
    firebase: FirebaseClient,
    uid: String,
}

impl NoteAccess {
    fn notes_path(&self) -> String {
        format!("users/{}/notes", self.uid)
    }

    fn user_path(&self) -> String {
        format!("users/{}", self.uid)
    }

    /// Latest `limit` notes, newest first, as compact JSON for the model.
    async fn recent(&self, limit: i64) -> Result<Vec<Value>, Error> {
        let docs = self
            .firebase
            .run_query(
                &self.user_path(),
                json!({
                    "from": [{ "collectionId": "notes" }],
                    "orderBy": [{ "field": { "fieldPath": "createdAt" }, "direction": "DESCENDING" }],
                    "limit": limit,
                }),
            )
            .await?;
        Ok(docs.iter().filter_map(summarize_note).collect())
    }
}

fn str_field<'a>(fields: &'a Value, key: &str) -> Option<&'a str> {
    fields.get(key)?.get("stringValue")?.as_str()
}

fn summarize_note(doc: &Value) -> Option<Value> {
    let fields = doc.get("fields")?;
    let created = fields.get("createdAt")?.get("timestampValue")?.as_str()?;
    Some(json!({
        "type": str_field(fields, "type")?,
        "title": str_field(fields, "title").unwrap_or(""),
        "body": str_field(fields, "body").unwrap_or(""),
        "createdAt": created,
    }))
}

// ---------------------------------------------------------------- create_note

#[derive(Clone)]
struct CreateNote(NoteAccess, PhotoSlot);

#[derive(Deserialize)]
struct CreateNoteArgs {
    r#type: String,
    title: String,
    body: Option<String>,
    attach_photo: Option<bool>,
}

impl Tool for CreateNote {
    const NAME: &'static str = "create_note";
    type Args = CreateNoteArgs;
    type Output = String;
    type Error = Infallible;

    fn description(&self) -> String {
        "Tạo một nốt mới trong hũ của người dùng, thời điểm là bây giờ.".into()
    }

    fn parameters(&self) -> Value {
        json!({
            "type": "object",
            "properties": {
                "type": {
                    "type": "string",
                    "enum": ["chien_thang", "tu_chu", "nhat_ky"],
                    "description": "chien_thang: chiến thắng nhỏ; tu_chu: tự chủ; nhat_ky: nhật ký"
                },
                "title": { "type": "string", "description": "Tiêu đề ngắn, tối đa 120 ký tự" },
                "body": { "type": "string", "description": "Nội dung kể thêm (không bắt buộc), tối đa 2000 ký tự" },
                "attach_photo": { "type": "boolean", "description": "true để đính kèm ảnh người dùng vừa gửi (chỉ khi trạng thái ảnh là có ảnh đang chờ)" }
            },
            "required": ["type", "title"]
        })
    }

    async fn call(&self, _: &mut ToolContext, args: Self::Args) -> Result<String, Infallible> {
        if !matches!(args.r#type.as_str(), "chien_thang" | "tu_chu" | "nhat_ky") {
            return Ok("Lỗi: loại nốt không hợp lệ.".into());
        }
        let title = args.title.trim();
        if title.is_empty() || title.chars().count() > TITLE_MAX {
            return Ok(format!("Lỗi: tiêu đề phải từ 1 đến {TITLE_MAX} ký tự."));
        }
        let body = args.body.as_deref().map(str::trim).filter(|b| !b.is_empty());
        if body.is_some_and(|b| b.chars().count() > BODY_MAX) {
            return Ok(format!("Lỗi: nội dung tối đa {BODY_MAX} ký tự."));
        }

        let mut fields = json!({
            "type": { "stringValue": args.r#type },
            "title": { "stringValue": title },
            "createdAt": { "timestampValue": Utc::now().to_rfc3339() },
        });
        if let Some(body) = body {
            fields["body"] = json!({ "stringValue": body });
        }

        // Take the waiting photo (put back below if saving fails so the user can retry).
        let photo = if args.attach_photo == Some(true) {
            match self.1.lock().expect("photo slot poisoned").take() {
                Some(p) => Some(p),
                None => return Ok("Lỗi: chưa có ảnh nào đang chờ. Hãy nhờ người dùng gửi ảnh.".into()),
            }
        } else {
            None
        };
        if let Some(p) = &photo {
            fields["image"] = json!({ "mapValue": { "fields": {
                "url": { "stringValue": p.url },
                "publicId": { "stringValue": p.public_id },
            }}});
        }

        Ok(match self.0.firebase.create_document(&self.0.notes_path(), fields).await {
            Ok(_) if photo.is_some() => format!("Đã tạo nốt \"{title}\" kèm ảnh."),
            Ok(_) => format!("Đã tạo nốt \"{title}\"."),
            Err(e) => {
                eprintln!("create_note failed: {e}");
                *self.1.lock().expect("photo slot poisoned") = photo;
                "Lỗi: không lưu được nốt, hãy thử lại sau.".into()
            }
        })
    }
}

// --------------------------------------------------------- list_recent_notes

#[derive(Clone)]
struct ListRecentNotes(NoteAccess);

#[derive(Deserialize)]
struct ListArgs {
    count: Option<i64>,
}

impl Tool for ListRecentNotes {
    const NAME: &'static str = "list_recent_notes";
    type Args = ListArgs;
    type Output = String;
    type Error = Infallible;

    fn description(&self) -> String {
        "Liệt kê các nốt gần đây nhất của người dùng (mới nhất trước).".into()
    }

    fn parameters(&self) -> Value {
        json!({
            "type": "object",
            "properties": {
                "count": { "type": "integer", "minimum": 1, "maximum": 20, "description": "Số nốt, mặc định 5" }
            }
        })
    }

    async fn call(&self, _: &mut ToolContext, args: Self::Args) -> Result<String, Infallible> {
        let limit = args.count.unwrap_or(5).clamp(1, 20);
        Ok(match self.0.recent(limit).await {
            Ok(notes) if notes.is_empty() => "Hũ chưa có nốt nào.".into(),
            Ok(notes) => Value::Array(notes).to_string(),
            Err(e) => {
                eprintln!("list_recent_notes failed: {e}");
                "Lỗi: không đọc được nốt.".into()
            }
        })
    }
}

// --------------------------------------------------------------- search_notes

#[derive(Clone)]
struct SearchNotes(NoteAccess);

#[derive(Deserialize)]
struct SearchArgs {
    query: String,
}

impl Tool for SearchNotes {
    const NAME: &'static str = "search_notes";
    type Args = SearchArgs;
    type Output = String;
    type Error = Infallible;

    fn description(&self) -> String {
        format!("Tìm nốt có tiêu đề hoặc nội dung chứa từ khóa, trong {SEARCH_WINDOW} nốt gần nhất.")
    }

    fn parameters(&self) -> Value {
        json!({
            "type": "object",
            "properties": { "query": { "type": "string", "description": "Từ khóa cần tìm" } },
            "required": ["query"]
        })
    }

    async fn call(&self, _: &mut ToolContext, args: Self::Args) -> Result<String, Infallible> {
        let needle = args.query.trim().to_lowercase();
        if needle.is_empty() {
            return Ok("Lỗi: từ khóa trống.".into());
        }
        Ok(match self.0.recent(SEARCH_WINDOW).await {
            Ok(notes) => {
                let hits: Vec<Value> = notes
                    .into_iter()
                    .filter(|n| {
                        ["title", "body"].iter().any(|k| {
                            n[k].as_str().is_some_and(|s| s.to_lowercase().contains(&needle))
                        })
                    })
                    .take(10)
                    .collect();
                if hits.is_empty() {
                    "Không tìm thấy nốt nào khớp.".into()
                } else {
                    Value::Array(hits).to_string()
                }
            }
            Err(e) => {
                eprintln!("search_notes failed: {e}");
                "Lỗi: không đọc được nốt.".into()
            }
        })
    }
}
