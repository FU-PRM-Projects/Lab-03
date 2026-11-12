"""Các luồng chính của Nốt (F1 ghi nốt, F2 tự chủ, F3 thử thách, tab, cài đặt).

Mỗi ca nói bằng ngôn ngữ tự nhiên và khẳng định trên giá trị ARTEMIS báo về.
T02 lưu từ gợi ý nhanh trên tài khoản test. T03 chỉ dọn nốt có nội dung
`E2E test note` do những ca dùng chuỗi này tạo ra.
Kế hoạch và bảng kết quả: docs/test-plan.md.
"""

from __future__ import annotations

import os
import shutil
import subprocess

import pytest

NOTE_TEXT = "E2E test note"
ADB = shutil.which("adb") or os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk", "platform-tools", "adb.exe"
)
SERIAL = os.environ.get("ARTEMIS_DEVICE_SERIAL")


def adb(*args: str) -> str:
    """Chạy một lệnh adb trên đúng thiết bị ARTEMIS đang dùng, trả về stdout."""
    cmd = [ADB, *(["-s", SERIAL] if SERIAL else []), *args]
    done = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    return done.stdout

# Chỉ dẫn chung: không đăng xuất, không đổi cài đặt, trả lời đúng định dạng.
RULES = (
    " Không đăng xuất và không đổi cài đặt nào. Cuối cùng trả lời đúng định dạng "
    "được yêu cầu, không thêm chữ nào khác."
)


# --- F1: ghi nốt buổi tối ---------------------------------------------------


async def test_t02_f1_save_a_note(ask) -> None:
    """F1 nhánh chính: Today → Ghi nốt → viết → lưu → màn xác nhận."""
    answer, result = await ask(
        "Nếu đang ở màn xác nhận nốt đã lưu, bấm 'Về Hôm nay' (hoặc 'Để sau' ở màn mốc). "
        "Về tab 'Hôm nay', cuộn xuống nếu cần rồi bấm 'Ghi nốt' và chọn 'Chiến thắng nhỏ'. "
        "Ở bước ảnh 1/3, bấm 'Bỏ qua'. Ở bước nội dung 2/3, chạm gợi ý 'Dọn phòng' "
        "và kiểm tra ô nội dung hiện đúng 'Dọn phòng'. Không mở bàn phím hoặc tìm mục tâm trạng. "
        "Bấm 'Bỏ qua phần kể thêm' một lần để lưu ngay. "
        "Trả lời SAVED nếu màn xác nhận đã lưu hiện ra cùng nốt 'Dọn phòng'. "
        "Nếu thiếu một bước hoặc không thấy đúng kết quả, trả lời FAILED và dừng, "
        "không tạo lại hay xoá nốt." + RULES,
        "SAVED hoặc FAILED",
        timeout=240,
    )
    assert answer == "SAVED", f"{answer!r} (trace {result.trace_id})"


async def test_t04_f1_empty_note_cannot_be_saved(ask) -> None:
    """F1 nhánh lỗi: không có nội dung thì không lưu được."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Chiến thắng nhỏ' và bấm 'Bỏ qua' ở bước ảnh. "
        "Ở bước nội dung 2/3, KHÔNG nhập hay chọn gợi ý. Kiểm tra nút 'Tiếp' và "
        "'Bỏ qua phần kể thêm': trả lời DISABLED nếu cả hai bị vô hiệu hóa, hoặc ENABLED nếu "
        "nút bị mờ hoặc bấm vào không đi tiếp, ENABLED nếu bấm được và đi tiếp. Sau đó "
        "thoát về màn Hôm nay, chọn bỏ nháp nếu app hỏi." + RULES,
        "DISABLED hoặc ENABLED",
    )
    assert "DISABLED" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t05_f1_leaving_asks_to_keep_draft(ask) -> None:
    """F1 nhánh lỗi: thoát giữa chừng phải hỏi có giữ nháp không."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Chiến thắng nhỏ', bỏ qua ảnh ở bước 1/3, "
        "chạm gợi ý 'Dọn phòng' ở bước 2/3 rồi bấm nút Back của Android. "
        "Nếu hiện hộp thoại hỏi giữ nháp thì trả lời "
        "DIALOG (và chọn bỏ nháp), nếu thoát luôn không hỏi thì trả lời NO_DIALOG." + RULES,
        "DIALOG hoặc NO_DIALOG",
    )
    assert "DIALOG" in answer and "NO_DIALOG" not in answer, (
        f"{answer!r} (trace {result.trace_id})"
    )


async def test_t06_f1_offline_note_is_kept_on_device(ask) -> None:
    """F1 nhánh lỗi mạng: mất mạng thì lưu trên máy và báo cho người dùng biết."""
    subprocess.run([ADB, "shell", "cmd", "connectivity", "airplane-mode", "enable"], check=False)
    try:
        answer, result = await ask(
            "Máy đang mất mạng. Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Chiến thắng nhỏ' "
            f"và bỏ qua ảnh. Ở bước 2/3, nhập đúng '{NOTE_TEXT}' rồi bấm 'Bỏ qua phần kể thêm' "
            "để lưu ngay. Trả lời OFFLINE_BANNER nếu app "
            "báo nốt được lưu trên máy / đang chờ mạng (banner hoặc thông báo), SAVED nếu "
            "lưu như bình thường không nhắc gì đến mạng, FAILED nếu không lưu được." + RULES,
            "OFFLINE_BANNER, SAVED hoặc FAILED",
        )
    finally:
        subprocess.run(
            [ADB, "shell", "cmd", "connectivity", "airplane-mode", "disable"], check=False
        )
    assert "OFFLINE_BANNER" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t13_analytics_note_saved_is_logged(ask) -> None:
    """Analytics: lưu nốt xong thì sự kiện `note_saved` được ghi (đọc từ logcat).

    Agent chỉ thấy màn hình, nên test bật log chi tiết của Firebase Analytics
    (tag FA, FA-SVC) rồi tự đọc logcat. Bản chạy Emulator in `[analytics]` với tag
    flutter. Chạy trước T03 vì T03 xoá nốt `E2E test note`.
    """
    for tag in ("FA", "FA-SVC"):
        adb("shell", "setprop", f"log.tag.{tag}", "VERBOSE")
    adb("logcat", "-c")
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Chiến thắng nhỏ' và bỏ qua ảnh. "
        f"Ở bước 2/3, nhập đúng '{NOTE_TEXT}' rồi bấm 'Bỏ qua phần kể thêm' để lưu ngay. "
        "Trả lời SAVED nếu màn xác nhận đã lưu hiện ra, ngược "
        "lại FAILED." + RULES,
        "SAVED hoặc FAILED",
    )
    assert "SAVED" in answer, f"{answer!r} (trace {result.trace_id})"
    log = adb("logcat", "-d", "-s", "FA", "FA-SVC", "flutter")
    events = [line for line in log.splitlines() if "note_saved" in line]
    assert events, f"không thấy note_saved trong logcat (trace {result.trace_id})"
    # Tham số theo docs/analytics-plan.md §4; không có nội dung nốt.
    assert any("mood" in line and "note_type" in line for line in events), events[-1]
    assert not any(NOTE_TEXT in line for line in events), "nội dung nốt bị gửi lên Analytics"


async def test_t03_jar_open_and_delete_note(ask) -> None:
    """P4/P5: tìm nốt vừa ghi trong hũ, mở ra, xoá, rồi chắc chắn nó biến mất."""
    answer, result = await ask(
        "Mở tab 'Hũ'. Mở nốt có nội dung 'E2E test note'. Nếu thấy đúng nội dung đó thì "
        "xoá nó (xác nhận xoá nếu có hộp thoại), rồi lặp lại cho tới khi trong hũ không "
        "còn nốt nào có nội dung đó. Trả lời DELETED nếu mọi nốt như vậy đã mất khỏi danh sách, NOT_FOUND nếu ngay từ "
        "đầu không có nốt nào như vậy, hoặc STILL_THERE nếu xoá xong vẫn còn." + RULES,
        "DELETED, NOT_FOUND hoặc STILL_THERE",
    )
    # Không có nốt cần xoá cũng hợp lệ khi một ca trước đã bị lỗi giữa chừng.
    assert "DELETED" in answer or "NOT_FOUND" in answer, f"{answer!r} (trace {result.trace_id})"


# --- F2: tự chủ -------------------------------------------------------------


async def test_t07_f2_self_control_screen_opens(ask) -> None:
    """F2: lối tắt 'Dừng lại, ghi 1 lần tự chủ' mở màn tự chủ."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Dừng lại, ghi 1 lần tự chủ'. Đọc tiêu đề màn hình mới: trả "
        "lời SELF_CONTROL nếu nó nói về tự chủ / ghi một lần tự chủ, ngược lại OTHER. "
        "Không ghi gì cả, bấm Back về màn Hôm nay." + RULES,
        "SELF_CONTROL hoặc OTHER",
    )
    assert "SELF_CONTROL" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t08_f2_breathing_starts(ask) -> None:
    """F2 khó dừng: thẻ Stress? mở màn thở 90 giây."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm thẻ 'Stress?'. Nếu một màn hình thở có đếm giờ hoặc hình "
        "động hít thở xuất hiện thì trả lời BREATHING, ngược lại OTHER. Rồi bấm Back về "
        "màn Hôm nay." + RULES,
        "BREATHING hoặc OTHER",
    )
    assert "BREATHING" in answer, f"{answer!r} (trace {result.trace_id})"


# --- F3: thử thách ----------------------------------------------------------


async def test_t09_f3_open_a_challenge_and_postpone(ask) -> None:
    """F3: mở một thẻ thử thách rồi để mai, không bị trừ gì."""
    answer, result = await ask(
        "Mở tab 'Thử thách'. Mở thẻ đầu tiên chưa làm. Nếu một màn chi tiết thẻ hiện ra "
        "thì chưa hoàn thành nó: dùng lựa chọn để mai hoặc bấm Back để quay lại danh sách. "
        "Trả lời DETAIL_THEN_BACK nếu mở được chi tiết và quay lại danh sách thành công, "
        "ngược lại FAILED." + RULES,
        "DETAIL_THEN_BACK hoặc FAILED",
    )
    assert "DETAIL_THEN_BACK" in answer, f"{answer!r} (trace {result.trace_id})"


# --- Tab và cài đặt ---------------------------------------------------------


async def test_t10_four_tabs_switch(ask) -> None:
    """Điều hướng: bốn tab đều mở được và đưa về đúng màn."""
    answer, result = await ask(
        "Lần lượt bấm bốn tab ở thanh dưới: 'Hũ', 'Thử thách', 'Hành trình', 'Hôm nay'. "
        "Sau mỗi tab, nhìn xem màn hình có đổi và hiện nội dung của tab đó không. Trả lời "
        "ALL_TABS nếu cả bốn đều mở đúng, ngược lại BROKEN." + RULES,
        "ALL_TABS hoặc BROKEN",
    )
    assert "ALL_TABS" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t11_settings_show_feature_flags(ask) -> None:
    """Cài đặt: dòng Remote Config hiển thị trạng thái các cờ tính năng."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Cài đặt'. Tìm dòng 'Remote Config' (trong khu demo Firebase, "
        "có thể phải cuộn xuống) và đọc nguyên văn dòng phụ bên dưới nó. Trả lời đúng "
        "dòng phụ đó, hoặc MISSING nếu không có dòng Remote Config." + RULES,
        "nội dung dòng phụ hoặc MISSING",
    )
    assert "CỜ TÍNH NĂNG" in answer, f"{answer!r} (trace {result.trace_id})"


# --- Tương tác Android gốc --------------------------------------------------


async def test_t12_native_home_and_return(ask) -> None:
    """Android gốc: Home rồi mở lại app từ launcher, vẫn đăng nhập (giữ màn cũ)."""
    answer, result = await ask(
        "Bấm nút Home của Android để ra màn hình chính, kéo thanh thông báo xuống rồi "
        "đóng lại, sau đó mở lại app Nốt (com.quanphungg.lab03). Trả lời LOGGED_IN nếu "
        "app mở lại ở một màn bên trong app (Hôm nay, Hũ, Cài đặt... đều được, vì app "
        "giữ màn đang xem), hoặc WELCOME nếu bị đưa về màn đăng nhập có nút 'Tiếp tục với "
        "Google'." + RULES,
        "LOGGED_IN hoặc WELCOME",
        locked=False,
    )
    assert "LOGGED_IN" in answer, f"{answer!r} (trace {result.trace_id})"


# --- Thẻ tuần ----------------------------------------------------------------


async def test_t14_weekly_card_pdf(ask) -> None:
    """S11b: lưu Thẻ tuần PDF vào máy và mở hộp chia sẻ (Final: không dùng
    Cloud Storage; metadata ghi vào Firestore)."""
    answer, result = await ask(
        "Mở tab 'Hành trình', chọn 'Thống kê' và chạm 'Mục tiêu tuần' (có thể phải "
        "cuộn xuống) để mở màn 'Thẻ tuần'. Bấm 'Lưu thẻ tuần (PDF)'. Khi hộp chia sẻ "
        "của Android hiện lên, nhấn Back để đóng nó, không chọn ứng dụng nào. Trả lời "
        "SAVED_SHARED nếu hộp chia sẻ đã hiện và màn Thẻ tuần ghi 'Đã lưu thẻ tuần vào "
        "máy.' kèm tên file bắt đầu bằng 'weekly-', ERROR_MESSAGE nếu hiện câu báo lỗi "
        "kèm nút 'Thử lại', CRASHED nếu app bị đóng. Rồi đóng màn Thẻ tuần." + RULES,
        "SAVED_SHARED, ERROR_MESSAGE hoặc CRASHED",
    )
    assert "SAVED_SHARED" in answer, f"{answer!r} (trace {result.trace_id})"


# --- Final: làm quen, Nốt AI, liên vai trò -----------------------------------
#
# Các ca dưới đây chạy trên tài khoản demo nên KHÔNG để lại dữ liệu: làm quen
# không bấm "Bắt đầu" (sẽ ghi đè cấp thử thách và giờ nhắc), Kể tự do không lưu
# nốt AI, thẻ gửi duyệt được rút lại ngay.

CARD_NAME = "E2E thẻ thử"


def restart_app(app_id: str) -> None:
    """Tắt hẳn app rồi mở lại: thoát làm quen mà không lưu gì."""
    adb("shell", "am", "force-stop", app_id)
    adb("shell", "monkey", "-p", app_id, "-c", "android.intent.category.LAUNCHER", "1")


async def test_t17_onboarding_starter_plan(ask, app_id: str) -> None:
    """A2 / S13: trả lời 4 câu làm quen → màn "Hồ sơ khởi đầu" có 3 thẻ đầu tiên."""
    try:
        answer, result = await ask(
            "Ở màn Hôm nay, bấm 'Cài đặt', bấm 'Làm lại khảo sát làm quen'. Trả lời lần "
            "lượt 4 câu hỏi (chọn đáp án bất kỳ, câu nào cần chọn nhiều thì chọn 1–2 mục) "
            "và bấm nút đi tiếp sau mỗi câu, KHÔNG bấm 'Bỏ qua câu này'. Khi màn 'Hồ sơ "
            "khởi đầu' hiện ra thì DỪNG, KHÔNG bấm 'Bắt đầu' và không bấm Back. Trả lời "
            "PLAN_SHOWN nếu màn đó có mục '3 thẻ để bắt đầu' và nút 'Bắt đầu', "
            "NO_PLAN nếu không tới được màn đó." + RULES,
            "PLAN_SHOWN hoặc NO_PLAN",
        )
    finally:
        restart_app(app_id)
    assert "PLAN_SHOWN" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t18_free_tell_ai_suggestions(ask) -> None:
    """A1 / S03b: Kể tự do → Gemini tách thành nốt gợi ý có nhãn, sửa được.

    Nội dung Gemini trả về đổi giữa các lần, nên chỉ khẳng định trên nhãn cố
    định "Gợi ý từ Nốt AI". Không lưu để khỏi để lại nốt trong hũ.
    """
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Kể tự do · Nốt AI'. Gõ vào ô: 'Sang nay "
        "minh day som chay bo 2km, chieu hoi thay mot cau, toi met nen ngu som'. Bấm "
        "'Nhờ Tụi Nốt sắp xếp' (nếu hiện bảng hỏi đồng ý gửi cho Gemini thì đồng ý). Chờ "
        "tối đa 30 giây. Trả lời SUGGESTIONS nếu hiện danh sách nốt gợi ý có dòng 'Gợi ý "
        "từ Nốt AI', FALLBACK nếu hiện câu báo Nốt AI đang nghỉ hoặc lỗi, kèm lối ghi "
        "tay. KHÔNG bấm lưu: sau khi xem xong, bấm Back / Đóng cho tới khi về màn Hôm "
        "nay, chọn bỏ nếu app hỏi." + RULES,
        "SUGGESTIONS hoặc FALLBACK",
        timeout=480,
    )
    assert "SUGGESTIONS" in answer, f"{answer!r} (trace {result.trace_id})"


@pytest.mark.skipif(
    os.environ.get("E2E_AI_DISABLED") != "1",
    reason="đặt ai_enabled = false trên Remote Config, Publish, rồi chạy với E2E_AI_DISABLED=1",
)
async def test_t19_ai_disabled_by_remote_config(ask) -> None:
    """Remote Config `ai_enabled = false`: Kể tự do báo Nốt AI nghỉ, vẫn ghi tay được.

    Cần bản debug (bản release chỉ tải Remote Config mỗi giờ một lần).
    """
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn 'Kể tự do · Nốt AI'. Đọc dòng dưới tiêu "
        "đề và các nút ở cuối màn. Trả lời AI_OFF_MANUAL nếu có câu 'Nốt AI đang nghỉ' "
        "và chỉ còn nút 'Ghi tay' (không có nút 'Nhờ Tụi Nốt sắp xếp'), AI_ON nếu vẫn có "
        "nút 'Nhờ Tụi Nốt sắp xếp'. Bấm 'Ghi tay': trả lời thêm MANUAL_OPENS nếu mở ra "
        "màn ghi nốt tay. Không lưu gì; bấm Back / Đóng về màn Hôm nay, chọn bỏ nếu app "
        "hỏi. Trả lời các từ khoá cách nhau dấu cách, ví dụ 'AI_OFF_MANUAL "
        "MANUAL_OPENS'." + RULES,
        "AI_OFF_MANUAL|AI_ON và MANUAL_OPENS",
    )
    assert "AI_OFF_MANUAL" in answer, f"{answer!r} (trace {result.trace_id})"
    assert "MANUAL_OPENS" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t20_cross_role_mobile_part(ask) -> None:
    """Liên vai trò, phần mobile: gửi thẻ → "Đang chờ duyệt"; thẻ đã duyệt hiện
    "Đã vào kho chung"; hộp thư có tin duyệt. Bước duyệt trên web xem
    docs/cross-role-flow.md (D-1…D-3). Thẻ thử được rút lại và xoá để hàng chờ
    của staff vẫn trống."""
    answer, result = await ask(
        "Mở tab 'Thử thách', bấm 'Thêm điều tốt của bạn', tạo thẻ tên "
        f"'{CARD_NAME}' (điền các ô bắt buộc tối thiểu) rồi lưu. Mở thẻ đó, bấm 'Gửi "
        "cho mọi người' rồi 'Gửi'. Ghi PENDING nếu thẻ hiện 'Đang chờ duyệt'. Sau đó "
        "bấm 'Rút lại', rồi 'Xoá thẻ này' và xác nhận xoá. Tiếp theo tìm trong tab Thử "
        "thách một thẻ có dòng 'Đã vào kho chung' (thẻ đã gửi trước đây, có thể phải "
        "vuốt): ghi APPROVED nếu thấy. Cuối cùng về màn Hôm nay, bấm 'Hộp thư': ghi "
        "INBOX nếu có tin 'Thẻ của bạn đã vào kho chung', rồi đóng hộp thư. Trả lời các "
        "từ khoá đã ghi, cách nhau dấu cách, ví dụ 'PENDING APPROVED INBOX'." + RULES,
        "PENDING, APPROVED, INBOX (những từ thấy được)",
        timeout=600,
    )
    for keyword in ("PENDING", "APPROVED", "INBOX"):
        assert keyword in answer, f"thiếu {keyword}: {answer!r} (trace {result.trace_id})"


# --- Đăng xuất và đăng nhập (chạy cuối vì đổi phiên đăng nhập) --------------

#: Tài khoản email chỉ dùng cho test. Mật khẩu đi qua model của agent, nên
#: không dùng tài khoản thật.
TEST_EMAIL = os.environ.get("E2E_EMAIL", "")
TEST_PASSWORD = os.environ.get("E2E_PASSWORD", "")
needs_account = pytest.mark.skipif(
    not (TEST_EMAIL and TEST_PASSWORD),
    reason="đặt E2E_EMAIL và E2E_PASSWORD (tài khoản email chỉ dùng cho test)",
)


@needs_account
async def test_t15_sign_out_then_sign_in(ask) -> None:
    """Đăng xuất về màn chào, rồi đăng nhập lại bằng email về màn Hôm nay."""
    answer, result = await ask(
        "Mở 'Cài đặt' (ở màn Hôm nay), cuộn xuống bấm 'Đăng xuất' và xác nhận "
        "'Đăng xuất'. Ghi lại màn hiện ra: OUT_WELCOME nếu là màn chào có nút 'Tiếp tục "
        "với Google', OUT_OTHER nếu khác. Sau đó bấm 'Đăng nhập bằng email', gõ email "
        f"'{TEST_EMAIL}' vào ô 'Email' và '{TEST_PASSWORD}' vào ô 'Mật khẩu', bấm "
        "'Đăng nhập'. Ghi lại: IN_TODAY nếu vào màn Hôm nay, IN_FAILED nếu không. Trả "
        "lời hai từ khoá cách nhau dấu cách, ví dụ 'OUT_WELCOME IN_TODAY'. Không đổi "
        "cài đặt nào khác, không thêm chữ nào khác.",
        "OUT_WELCOME|OUT_OTHER và IN_TODAY|IN_FAILED",
    )
    assert "OUT_WELCOME" in answer, f"đăng xuất: {answer!r} (trace {result.trace_id})"
    assert "IN_TODAY" in answer, f"đăng nhập: {answer!r} (trace {result.trace_id})"


@needs_account
async def test_t16_sign_in_wrong_password_shows_error(ask) -> None:
    """Nhánh lỗi đăng nhập: sai mật khẩu thì báo lỗi dưới ô, rồi đăng nhập đúng."""
    answer, result = await ask(
        "Mở 'Cài đặt', cuộn xuống bấm 'Đăng xuất' và xác nhận. Ở màn chào bấm 'Đăng "
        f"nhập bằng email', gõ '{TEST_EMAIL}' và mật khẩu 'sai-mat-khau-e2e', bấm "
        "'Đăng nhập'. Ghi lại: ERROR_SHOWN nếu hiện câu 'Email hoặc mật khẩu chưa "
        "đúng.' (hoặc câu báo lỗi khác), NO_ERROR nếu vào được app. Sau đó xoá ô mật "
        f"khẩu, gõ '{TEST_PASSWORD}' và bấm 'Đăng nhập'. Ghi lại: IN_TODAY nếu vào màn "
        "Hôm nay, IN_FAILED nếu không. Trả lời hai từ khoá cách nhau dấu cách, ví dụ "
        "'ERROR_SHOWN IN_TODAY'. Không thêm chữ nào khác.",
        "ERROR_SHOWN|NO_ERROR và IN_TODAY|IN_FAILED",
    )
    assert "ERROR_SHOWN" in answer, f"lỗi đăng nhập: {answer!r} (trace {result.trace_id})"
    assert "IN_TODAY" in answer, f"đăng nhập lại: {answer!r} (trace {result.trace_id})"


# --- Phiên khám phá (chỉ chạy với `-m exploratory`) -------------------------


@pytest.mark.exploratory
async def test_x01_exploratory_session(client, app_id: str, attempt: int, reported) -> None:
    """Phiên khám phá 15–30 phút, profile Pro: agent tự đi khắp app và liệt kê lỗi.

    Chạy một lần: `uv run pytest -m exploratory --runs 1 -s`. Danh sách lỗi in ra
    được chép vào docs/test-plan.md mục 6.
    """
    result = await client.run(
        "Khám phá app Nốt khoảng 20 phút như một người dùng mới tò mò: đi qua mọi tab "
        "(Hôm nay, Hũ, Thử thách, Hành trình), mở Cài đặt, thử ghi nốt, mở nốt, thử "
        "thách, nhóm, màn thở, nhập dữ liệu lạ (rất dài, emoji, để trống), xoay màn "
        "hình, bấm Back nhiều lần. Không đăng xuất, không xoá tài khoản, không gửi gì ra "
        "ngoài app. Ghi lại mọi lỗi thấy được: app đóng, màn trắng, chữ bị cắt, nút "
        "không phản hồi, câu báo lỗi khó hiểu. Cuối cùng trả lời danh sách, mỗi lỗi một "
        "dòng dạng 'BUG: <màn> | <bước> | <thấy gì>', hoặc đúng một dòng 'NO_BUGS'.",
        profile="pro",
        locked_app_package=app_id,
        expected_output="các dòng BUG: ... hoặc NO_BUGS",
        timeout=40 * 60,
    )
    assert result.succeeded, f"[run{attempt}] {result.error or result.status}"
    answer = (await reported(result)).strip()
    print(f"\n--- exploratory (trace {result.trace_id}) ---\n{answer}")
    assert "BUG:" in answer.upper() or "NO_BUGS" in answer.upper(), answer
