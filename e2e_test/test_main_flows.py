"""Các luồng chính của Nốt (F1 ghi nốt, F2 tự chủ, F3 thử thách, tab, cài đặt).

Mỗi ca nói bằng ngôn ngữ tự nhiên và khẳng định trên giá trị ARTEMIS báo về.
Ca ghi dữ liệu dùng nốt có chữ `E2E test note` và được dọn ở T03 (chạy sau các ca ghi).
Kế hoạch và bảng kết quả: docs/test-plan.md.
"""

from __future__ import annotations

import os
import shutil
import subprocess

NOTE_TEXT = "E2E test note"
ADB = shutil.which("adb") or os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Android", "Sdk", "platform-tools", "adb.exe"
)

# Chỉ dẫn chung: không đăng xuất, không đổi cài đặt, trả lời đúng định dạng.
RULES = (
    " Không đăng xuất và không đổi cài đặt nào. Cuối cùng trả lời đúng định dạng "
    "được yêu cầu, không thêm chữ nào khác."
)


# --- F1: ghi nốt buổi tối ---------------------------------------------------


async def test_t02_f1_save_a_note(ask) -> None:
    """F1 nhánh chính: Today → Ghi nốt → viết → lưu → màn xác nhận."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt'. Chọn ghi một điều làm được (không phải nhật ký), "
        f"chọn một tâm trạng bất kỳ, gõ đúng chữ '{NOTE_TEXT}' vào ô nội dung, bỏ qua "
        "phần kể thêm ('Bỏ qua phần kể thêm') rồi bấm lưu. Khi màn hình xác nhận đã lưu "
        "hiện ra, trả lời SAVED nếu thấy, ngược lại FAILED." + RULES,
        "SAVED hoặc FAILED",
    )
    assert "SAVED" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t04_f1_empty_note_cannot_be_saved(ask) -> None:
    """F1 nhánh lỗi: không có nội dung thì không lưu được."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn ghi một điều làm được và chọn một tâm trạng "
        "nhưng KHÔNG gõ gì vào ô nội dung. Nhìn nút lưu/tiếp tục: trả lời DISABLED nếu "
        "nút bị mờ hoặc bấm vào không đi tiếp, ENABLED nếu bấm được và đi tiếp. Sau đó "
        "thoát về màn Hôm nay, chọn bỏ nháp nếu app hỏi." + RULES,
        "DISABLED hoặc ENABLED",
    )
    assert "DISABLED" in answer, f"{answer!r} (trace {result.trace_id})"


async def test_t05_f1_leaving_asks_to_keep_draft(ask) -> None:
    """F1 nhánh lỗi: thoát giữa chừng phải hỏi có giữ nháp không."""
    answer, result = await ask(
        "Ở màn Hôm nay, bấm 'Ghi nốt', chọn ghi một điều làm được, gõ vài chữ vào ô nội "
        "dung rồi bấm nút Back của Android. Nếu hiện hộp thoại hỏi giữ nháp thì trả lời "
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
            "Máy đang mất mạng. Ở màn Hôm nay, bấm 'Ghi nốt', chọn ghi một điều làm được, "
            f"tâm trạng bất kỳ, gõ '{NOTE_TEXT}' rồi lưu. Trả lời OFFLINE_BANNER nếu app "
            "báo nốt được lưu trên máy / đang chờ mạng (banner hoặc thông báo), SAVED nếu "
            "lưu như bình thường không nhắc gì đến mạng, FAILED nếu không lưu được." + RULES,
            "OFFLINE_BANNER, SAVED hoặc FAILED",
        )
    finally:
        subprocess.run(
            [ADB, "shell", "cmd", "connectivity", "airplane-mode", "disable"], check=False
        )
    assert "OFFLINE_BANNER" in answer, f"{answer!r} (trace {result.trace_id})"


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
