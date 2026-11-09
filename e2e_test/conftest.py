"""Cấu hình chung cho bộ test E2E ARTEMIS.

ARTEMIS gồm một server chạy trên máy có ADB (mặc định http://127.0.0.1:8000)
và client Python gửi mục tiêu bằng ngôn ngữ tự nhiên. Test ở đây chỉ nói
chuyện với server; thiết bị/emulator do server điều khiển.

Biến môi trường:
  ARTEMIS_BASE_URL       địa chỉ server (mặc định http://127.0.0.1:8000)
  ARTEMIS_DEVICE_SERIAL  serial thiết bị, ví dụ emulator-5554 (mặc định: tự chọn)
  ARTEMIS_PROFILE        flash (mặc định) hoặc pro
"""

from __future__ import annotations

import asyncio
import os
from collections.abc import Awaitable, Callable
from typing import Any, Literal, cast

import pytest
from artemis_client import ArtemisClient

#: Package của app Nốt; ARTEMIS bị khoá vào app này để không thao tác ngoài app.
APP_ID = "com.quanphungg.lab03"

#: Handout yêu cầu mỗi test chạy 3 lần và báo tỉ lệ đạt.
DEFAULT_RUNS = 3


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--runs",
        type=int,
        default=DEFAULT_RUNS,
        help="số lần chạy mỗi test (mặc định 3)",
    )


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    # Test nào nhận tham số `attempt` sẽ được chạy lặp `--runs` lần.
    if "attempt" in metafunc.fixturenames:
        runs = int(metafunc.config.getoption("--runs"))
        metafunc.parametrize("attempt", range(1, runs + 1), ids=lambda n: f"run{n}")


def pytest_collection_modifyitems(
    config: pytest.Config, items: list[pytest.Item]
) -> None:
    # Phiên khám phá rất dài: chỉ chạy khi gọi rõ `-m exploratory`.
    if "exploratory" in (config.getoption("-m") or ""):
        return
    skip = pytest.mark.skip(reason="phiên khám phá: chạy bằng `-m exploratory`")
    for item in items:
        if "exploratory" in item.keywords:
            item.add_marker(skip)


@pytest.fixture(scope="session")
def client() -> ArtemisClient:
    profile = os.environ.get("ARTEMIS_PROFILE", "flash")
    return ArtemisClient(
        os.environ.get("ARTEMIS_BASE_URL", "http://127.0.0.1:8000"),
        device_serial=os.environ.get("ARTEMIS_DEVICE_SERIAL") or None,
        default_profile=cast(Literal["flash", "pro"], profile),
        request_timeout=60.0,
    )


@pytest.fixture(scope="session", autouse=True)
async def server_ready(client: ArtemisClient) -> None:
    """Dừng sớm, rõ ràng nếu server hoặc thiết bị chưa sẵn sàng."""
    try:
        await client.health()
        devices = await client.list_devices()
    except Exception as error:  # noqa: BLE001 - báo nguyên nhân gốc cho người chạy
        pytest.exit(
            f"Không kết nối được server ARTEMIS tại {client.base_url}: {error}\n"
            "Khởi động server trước (xem e2e_test/README.md).",
            returncode=2,
        )
    if not any(device.state == "device" for device in devices):
        pytest.exit(
            "Server ARTEMIS chạy nhưng không thấy thiết bị nào ở trạng thái "
            "'device'. Bật emulator hoặc cắm điện thoại (USB debugging).",
            returncode=2,
        )


@pytest.fixture
def app_id() -> str:
    return APP_ID


@pytest.fixture
def reported(client: ArtemisClient) -> Callable[[Any], Awaitable[str]]:
    """Giá trị ARTEMIS báo về qua `report_task_status` (bước cuối của phiên).

    Server hiện không điền `TaskResult.output`; câu trả lời nằm ở trường
    `explanation` của bước cuối trong `/api/sessions/{id}/steps`.
    """

    async def read(result: Any) -> str:
        # Bước cuối có thể chưa được lưu ngay khi phiên vừa xong (T13 lần 1
        # đọc ra chuỗi rỗng dù agent đã báo SAVED), nên thử đọc lại vài lần.
        for _ in range(5):
            steps = await client._request(  # noqa: SLF001 - client chưa có API công khai cho bước
                "GET", f"/api/sessions/{result.task_id}/steps"
            )
            steps = steps if isinstance(steps, list) else []
            for step in reversed(steps):
                # Profile Flash ghi một hành động (dict); profile Pro ghi một
                # danh sách hành động mỗi bước.
                taken = step.get("action_taken") or []
                for action in taken if isinstance(taken, list) else [taken]:
                    if isinstance(action, dict) and action.get("action") == "report_task_status":
                        return str((action.get("args") or {}).get("explanation") or "")
            # Profile Pro không gọi report_task_status: câu trả lời cuối nằm sau
            # "Final answer:" trong phần suy nghĩ của bước cuối (X01).
            if steps:
                thinking = str(steps[-1].get("operator_raw_thinking") or "")
                marker = thinking.rfind("Final answer:")
                if marker >= 0:
                    return thinking[marker + len("Final answer:") :].strip()
            await asyncio.sleep(2)
        return str(result.output or "")

    return read


@pytest.fixture
def ask(client: ArtemisClient, app_id: str, attempt: int, reported):
    """Gửi một mục tiêu cho ARTEMIS và trả về (câu trả lời viết hoa, kết quả).

    Test khẳng định trên câu trả lời (giá trị ARTEMIS báo), không chỉ trạng thái.
    `locked=False` cho ca cần thao tác ngoài app (nút Home, thanh thông báo).
    """

    async def run(goal: str, expected: str, *, locked: bool = True, timeout: int = 420):
        result = await client.run(
            goal,
            locked_app_package=app_id if locked else None,
            expected_output=expected,
            timeout=timeout,
        )
        assert result.succeeded, f"[run{attempt}] {result.error or result.status}"
        answer = (await reported(result)).strip().upper()
        return answer, result

    return run
