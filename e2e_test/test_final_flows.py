"""Các ca Android bổ sung cho bản Final, chạy trên tài khoản test riêng."""

from __future__ import annotations

import os
import re
from uuid import uuid4

import pytest


REVIEW_BATCH = os.environ.get("E2E_REVIEW_BATCH", "")
REVIEW_OUTCOME = os.environ.get("E2E_REVIEW_OUTCOME", "approved")
REJECTION_REASON = "Trung voi the da co"
AI_MODE = os.environ.get("E2E_AI_MODE", "")
EDIT_BATCH = os.environ.get("E2E_EDIT_BATCH", "")
AI_INPUT = "Hom nay minh don ban hoc, di bo va dat dien thoai xuong de ngu som."
STOP = (
    " Nếu không thấy đúng kết quả, trả lời FAILED rồi dừng. "
    "Không lặp lại luồng, không đăng xuất, không xoá dữ liệu."
)
TEST_ACCOUNT = pytest.mark.skipif(
    os.environ.get("E2E_FINAL_TEST_ACCOUNT") != "1",
    reason="chỉ chạy trên tài khoản và dữ liệu test riêng (E2E_FINAL_TEST_ACCOUNT=1)",
)
REVIEW_FIXTURE = pytest.mark.skipif(
    not re.fullmatch(r"[a-zA-Z0-9-]{1,32}", REVIEW_BATCH),
    reason="đặt E2E_REVIEW_BATCH là mã đợt duy nhất, 1–32 ký tự chữ/số/gạch ngang",
)
OPEN_AI = "Từ tab 'Hôm nay', bấm 'Ghi nốt' rồi chọn 'Kể tự do · Nốt AI'. "


@TEST_ACCOUNT
@REVIEW_FIXTURE
async def test_t17_android_submit_challenge(ask, attempt: int) -> None:
    title = f"E2E-{REVIEW_BATCH}-{attempt}"
    answer, result = await ask(
        "Mở tab 'Thử thách', cuộn xuống và bấm 'Thêm điều tốt của bạn'. "
        f"Nhập đúng '{title}' vào ô 'Hôm nay mình sẽ…', chọn chủ đề Dũng cảm "
        "và 2 phút. Nếu ô chưa hiện đúng tiêu đề, dừng. Bấm 'Thêm vào thẻ của mình'. "
        f"Tìm đúng thẻ '{title}' ở đầu chồng thẻ, bấm 'Gửi cho mọi người', "
        "rồi xác nhận 'Gửi'. Chỉ trả lời PENDING nếu đúng thẻ hiện 'Đang chờ duyệt'."
        + STOP,
        "PENDING hoặc FAILED",
        timeout=180,
    )
    assert answer == "PENDING", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
@REVIEW_FIXTURE
@pytest.mark.skipif(
    REVIEW_OUTCOME not in {"approved", "rejected"},
    reason="E2E_REVIEW_OUTCOME phải là approved hoặc rejected",
)
async def test_t18_android_receive_review_result(ask, attempt: int) -> None:
    title = f"E2E-{REVIEW_BATCH}-{attempt}"
    approved = REVIEW_OUTCOME == "approved"
    status = (
        "Đã vào kho chung"
        if approved
        else f"Chưa được duyệt, có lý do '{REJECTION_REASON}'"
    )
    message = (
        "Thẻ của bạn đã vào kho chung"
        if approved
        else "Thẻ của bạn chưa được duyệt"
    )
    expected = "APPROVED_WITH_INBOX" if approved else "REJECTED_WITH_INBOX"
    answer, result = await ask(
        f"Vào tab 'Thử thách' và tìm thẻ tự thêm có tiêu đề chính xác '{title}'. "
        f"Xác nhận trạng thái trên chính thẻ đó là '{status}'. "
        f"Bấm chuông để mở 'Hộp thư' và tìm tin '{message}' có nội dung nhắc "
        f"chính xác tên thẻ '{title}'. Chỉ khi thấy cả trạng thái lẫn tin, trả lời {expected}. "
        "Đây là bước xác minh, không gửi thêm thẻ hay đổi trạng thái."
        + STOP,
        f"{expected} hoặc FAILED",
        timeout=150,
    )
    assert answer == expected, f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
@pytest.mark.skipif(AI_MODE != "on", reason="bật ai_enabled rồi đặt E2E_AI_MODE=on")
async def test_t19_ai_sort_confirm_and_save(ask) -> None:
    title = f"Final AI {uuid4().hex[:6]}"
    answer, result = await ask(
        OPEN_AI
        + f"Nhập đúng đoạn mẫu không có dữ liệu cá nhân '{AI_INPUT}'. "
        "Bấm 'Nhờ Tụi Nốt sắp xếp', và nếu hiện hộp đồng ý lần đầu thì bấm "
        "'Đồng ý và sắp xếp'. Chờ nhãn 'Gợi ý từ Nốt AI · kiểm tra trước khi lưu'. "
        f"Giữ ít nhất một gợi ý, sửa tiêu đề của gợi ý giữ lại thành '{title}', "
        "bấm 'Lưu … nốt', rồi kiểm tra trong tab 'Hũ' có nốt đúng tiêu đề vừa sửa. "
        "Chỉ trả lời AI_SAVED nếu đã thấy nhãn gợi ý và nốt trong Hũ."
        + STOP,
        "AI_SAVED hoặc FAILED",
        timeout=240,
    )
    assert answer == "AI_SAVED", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
@pytest.mark.skipif(AI_MODE != "off", reason="tắt ai_enabled rồi đặt E2E_AI_MODE=off")
async def test_t20_ai_disabled_manual_fallback(ask) -> None:
    answer, result = await ask(
        OPEN_AI
        + "Kiểm tra có câu 'Nốt AI đang nghỉ' và không có nút 'Nhờ Tụi Nốt sắp xếp'. "
        "Bấm 'Ghi tay', bỏ qua ảnh nếu có, chọn gợi ý 'Dọn phòng' ở bước nội dung "
        "và bấm 'Bỏ qua phần kể thêm'. Chỉ trả lời MANUAL_SAVED nếu đã thấy thông báo "
        "AI nghỉ và màn xác nhận lưu nốt 'Dọn phòng'."
        + STOP,
        "MANUAL_SAVED hoặc FAILED",
        timeout=180,
    )
    assert answer == "MANUAL_SAVED", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
@pytest.mark.skipif(AI_MODE != "error", reason="chuẩn bị lỗi AI ở môi trường test rồi đặt E2E_AI_MODE=error")
async def test_t21_ai_error_keeps_draft_and_allows_manual(ask) -> None:
    answer, result = await ask(
        OPEN_AI
        + f"Nhập đoạn mẫu '{AI_INPUT}', bấm 'Nhờ Tụi Nốt sắp xếp' rồi đồng ý nếu "
        "có hộp đồng ý lần đầu. Kiểm tra có thông báo lỗi, còn nguyên đoạn đã nhập, "
        "và có cả hai nút 'Thử lại' và 'Ghi tay'. Bấm 'Ghi tay' và xác nhận có thể "
        "mở màn soạn nốt tay. Chỉ trả lời ERROR_FALLBACK nếu đủ các dấu hiệu này."
        + STOP,
        "ERROR_FALLBACK hoặc FAILED",
        timeout=180,
    )
    assert answer == "ERROR_FALLBACK", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
async def test_t22_journey_stats_and_calendar(ask) -> None:
    answer, result = await ask(
        "Mở tab 'Hành trình'. Bấm 'Thống kê' và kiểm tra thấy 'Mục tiêu tuần' "
        "(cuộn nếu cần). Sau đó bấm 'Lịch' và kiểm tra thấy 'Lịch năng lượng'. "
        "Chỉ trả lời STATS_AND_CALENDAR nếu đã thấy cả hai màn."
        + STOP,
        "STATS_AND_CALENDAR hoặc FAILED",
        timeout=140,
    )
    assert answer == "STATS_AND_CALENDAR", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
async def test_t23_journal_prompt_and_save(ask) -> None:
    answer, result = await ask(
        "Ở tab 'Hôm nay', bấm 'Ghi nốt' rồi 'Viết nhật ký'. "
        "Bấm 'Gợi ý', chạm một câu gợi ý để thêm vào trang và bấm 'Xong'. "
        "Ở màn 'Điều rõ ràng nhất là gì?', chọn một câu làm tiêu đề, "
        "bấm 'Lưu vào hũ' và chờ màn xác nhận lưu nốt. "
        "Chỉ trả lời JOURNAL_SAVED nếu đã đi qua màn chọn câu và lưu thành công."
        + STOP,
        "JOURNAL_SAVED hoặc FAILED",
        timeout=180,
    )
    assert answer == "JOURNAL_SAVED", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
async def test_t24_onboarding_and_starter_plan(ask) -> None:
    answer, result = await ask(
        "Từ tab 'Hôm nay', chạm avatar vào 'Cài đặt', tìm 'Làm lại khảo sát làm quen'. "
        "Nếu app hỏi xác nhận làm lại, đồng ý. Ở bốn bước 'Làm quen', "
        "bấm 'Bỏ qua câu này' ở từng bước. Chờ màn hồ sơ khởi đầu, chấp nhận cả "
        "hồ sơ do AI tạo và hồ sơ dự phòng. Bấm 'Bắt đầu' để về tab 'Hôm nay'. "
        "Chỉ trả lời ONBOARDING_DONE nếu đã thấy hồ sơ khởi đầu và quay về Hôm nay."
        + STOP,
        "ONBOARDING_DONE hoặc FAILED",
        timeout=220,
    )
    assert answer == "ONBOARDING_DONE", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
async def test_t25_movement_stops_early_and_saves(ask) -> None:
    answer, result = await ask(
        "Ở tab 'Thử thách', tìm một thẻ chủ đề 'Vận động'. Bấm 'Nhận thử thách', "
        "rồi 'Xong rồi' để mở kết quả. Chọn 'Dừng sớm', bấm 'Lưu', "
        "và xác nhận nốt kết quả đã vào Hũ. "
        "Chỉ trả lời MOVEMENT_SAVED nếu đã chọn 'Dừng sớm' và thấy xác nhận lưu."
        + STOP,
        "MOVEMENT_SAVED hoặc FAILED",
        timeout=180,
    )
    assert answer == "MOVEMENT_SAVED", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
@pytest.mark.skipif(
    not re.fullmatch(r"[a-zA-Z0-9-]{1,24}", EDIT_BATCH),
    reason="chuẩn bị ba nốt test và đặt E2E_EDIT_BATCH theo README",
)
async def test_t26_edit_and_reopen_note(ask, attempt: int) -> None:
    original = f"E2E edit {EDIT_BATCH} {attempt}"
    revised = f"{original} updated"
    answer, result = await ask(
        f"Mở tab 'Hũ', tìm và mở đúng nốt '{original}'. Bấm icon 'Sửa', "
        f"đổi ô 'Tiêu đề' thành '{revised}' và kiểm tra đã nhập đúng rồi mới bấm 'Lưu'. "
        f"Về Hũ, mở lại nốt '{revised}' và kiểm tra tiêu đề trong chi tiết. "
        "Chỉ trả lời EDIT_PERSISTED khi đã mở lại và thấy đúng tiêu đề mới."
        + STOP,
        "EDIT_PERSISTED hoặc FAILED",
        timeout=180,
    )
    assert answer == "EDIT_PERSISTED", f"{answer!r} (trace {result.trace_id})"


@TEST_ACCOUNT
async def test_t27_self_control_records_a_win(ask) -> None:
    answer, result = await ask(
        "Ở tab 'Hôm nay', bấm 'Dừng lại' để vào 'Tự chủ'. Bấm 'Ghi lại vừa rồi', "
        "chọn 'Mình đã dừng được', rồi chờ màn xác nhận đã lưu. "
        "Chỉ trả lời SELF_CONTROL_SAVED nếu thấy màn xác nhận một nốt tự chủ."
        + STOP,
        "SELF_CONTROL_SAVED hoặc FAILED",
        timeout=150,
    )
    assert answer == "SELF_CONTROL_SAVED", f"{answer!r} (trace {result.trace_id})"
