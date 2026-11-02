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

import os
from typing import Literal, cast

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
