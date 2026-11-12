"""Smoke test: kiểm tra cả chuỗi ARTEMIS → ADB → app Nốt hoạt động.

Chạy test này trước khi viết các ca trong docs/test-plan.md. Nó khẳng định
trên giá trị ARTEMIS báo về (output), không chỉ trạng thái thành công.
"""

from __future__ import annotations

from artemis_client import ArtemisClient

GOAL = (
    "Mở app Nốt (com.quanphungg.lab03). Nhìn màn hình đầu tiên và trả lời đúng "
    "một từ: WELCOME nếu là màn hình đăng nhập có nút 'Tiếp tục với Google', "
    "TODAY nếu là màn hình có tiêu đề 'Hôm nay bạn làm được gì?', "
    "hoặc ONBOARDING nếu thấy tiêu đề 'Làm quen' và số bước (ví dụ 1/4). "
    "Không bấm nút nào."
)


async def test_app_opens_to_a_known_screen(
    client: ArtemisClient, app_id: str, attempt: int, reported
) -> None:
    result = await client.run(
        GOAL,
        locked_app_package=app_id,
        expected_output="WELCOME, TODAY hoặc ONBOARDING",
        timeout=300,
    )

    assert result.succeeded, f"[run{attempt}] {result.error or result.status}"
    answer = (await reported(result)).upper()
    assert any(screen in answer for screen in ("WELCOME", "TODAY", "ONBOARDING")), (
        f"[run{attempt}] ARTEMIS báo về giá trị lạ: {answer!r} "
        f"(trace {result.trace_id})"
    )
