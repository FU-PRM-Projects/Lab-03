#!/usr/bin/env bash
# Runs `flutter build <args>` and retries only when the failure is a network
# error while Gradle downloads its distribution or dependencies (GitHub
# Releases often answers 502/503/504). Real build errors fail at once.
#
#   .github/scripts/flutter-build-retry.sh apk --debug
set -uo pipefail

attempts=3
log="$(mktemp)"

for attempt in $(seq 1 "$attempts"); do
  flutter build "$@" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  if [ "$status" -eq 0 ]; then
    exit 0
  fi
  if ! grep -Eq 'Server returned HTTP response code: 5[0-9]{2}|Could not (GET|HEAD|download)|Read timed out|Connection reset|Connect timed out|UnknownHostException' "$log"; then
    echo "::error::flutter build failed (not a download error); not retrying."
    exit "$status"
  fi
  if [ "$attempt" -lt "$attempts" ]; then
    wait=$((attempt * 30))
    echo "::warning::Download error on attempt $attempt/$attempts; retrying in ${wait}s."
    sleep "$wait"
  fi
done

echo "::error::flutter build still failed after $attempts download attempts."
exit 1
