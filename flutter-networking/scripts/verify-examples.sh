#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/flutter_networking_verify_$$"
APP_DIR="$TMP_ROOT/app"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

flutter create --empty --platforms=android,ios,web "$APP_DIR"

cd "$APP_DIR"
flutter pub add http web_socket_channel shared_preferences flutter_secure_storage

cp "$ROOT_DIR"/assets/code-templates/*.dart lib/
cp "$ROOT_DIR"/assets/examples/*.dart lib/

dart format lib
dart format --output=none --set-exit-if-changed lib
flutter analyze
