#!/bin/bash
# Chụp màn hình emulator định kỳ khi bộ E2E ARTEMIS đang chạy (bằng chứng).
ADB="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
OUT="$(dirname "$0")/emulator"
until [ -s /e/PRM-Lab03/Lab-03-e2e/e2e_test/results.xml ]; do
  "$ADB" exec-out screencap -p > "$OUT/$(date +%H%M%S).png" 2>/dev/null
  sleep 40
done
