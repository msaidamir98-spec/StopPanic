#!/bin/zsh
# ============================================================
# Stillō Supreme Commander — Automated Pipeline
# Build → Deploy → Commit → Notify
#
# Modes:
#   ./pipeline.sh "Phase XX: description"                 # dev mode (default)
#   ./pipeline.sh --mode=archive "v1.0.0 App Store"       # App Store archive
#   ./pipeline.sh --mode=release "v1.0.0 release build"   # release .ipa without upload
#   ./pipeline.sh --mode=test                             # unit tests on iOS Simulator
#
# dev mode: strips entitlements, builds Debug, installs to device, commits+pushes.
# archive mode: applies FULL entitlements (.full → .entitlements в /tmp/StilloBuild),
#               builds archive for App Store Connect upload.
# release mode: keeps entitlements, builds Release without sideload.
# test mode: runs StilloTests (xcodebuild test) on the iPhone 17 simulator.
# ============================================================

set -euo pipefail

PROJECT="/Users/msk/Desktop/Stillo"
BUILD_DIR="/tmp/StilloBuild"
DERIVED="/tmp/StilloDerived"
ARCHIVE_PATH="/tmp/Stillo.xcarchive"
EXPORT_DIR="/tmp/StilloExport"
# Default = iPhone 12 (исторически main test device).
# Можно переопределить через env: STILLO_DEVICE="UDID-другого-iPhone" ./pipeline.sh
# Или auto-detect: STILLO_DEVICE=auto подхватит первое paired device.
if [[ "${STILLO_DEVICE:-}" == "auto" ]]; then
    DEVICE=$(xcrun devicectl list devices --json-output /tmp/_dev.json >/dev/null 2>&1 && \
             python3 -c "import json; d=json.load(open('/tmp/_dev.json')); print(next((x['hardwareProperties']['udid'] for x in d['result']['devices'] if x.get('connectionProperties',{}).get('pairingState')=='paired' and 'iPhone' in x.get('hardwareProperties',{}).get('deviceType','')), ''))")
    if [[ -z "$DEVICE" ]]; then
        echo "❌ STILLO_DEVICE=auto: не нашёл подключённый iPhone. Подключи по USB."
        exit 1
    fi
    echo "🔌 Auto-detected device: $DEVICE"
elif [[ -n "${STILLO_DEVICE:-}" ]]; then
    DEVICE="$STILLO_DEVICE"
else
    DEVICE="00008101-001028290C50801E"
fi
APP_NAME="Stillō"
NOTIFY="python3 $PROJECT/Scripts/notify.py"

MODE="dev"
COMMIT_MSG="auto-commit"
for arg in "$@"; do
  case "$arg" in
    --mode=*) MODE="${arg#--mode=}";;
    *) COMMIT_MSG="$arg";;
  esac
done

echo "══════════════════════════════════════"
echo "  🤖 Supreme Commander Pipeline ($MODE)"
echo "══════════════════════════════════════"

# --- Step 1: rsync ---
echo "\n[1/5] 📁 Syncing to build directory..."
rsync -a --delete "$PROJECT/" "$BUILD_DIR/" --exclude .git
echo "     ✅ Synced"

# --- Step 2: Entitlements handling ---
echo "[2/5] 🔐 Preparing entitlements..."
if [[ "$MODE" == "dev" ]]; then
  # Dev sideload without Apple Developer team — strip entitlements
  cat > "$BUILD_DIR/Stillo/Stillo.entitlements" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST
  echo "     ✅ Stripped (dev sideload)"
elif [[ "$MODE" == "archive" ]]; then
  # archive — apply FULL entitlements (HealthKit etc.) on top of Stillo.entitlements.
  # ВАЖНО: копируем ВНУТРИ $BUILD_DIR (/tmp/StilloBuild), НЕ в рабочей директории —
  # иначе dev-копия Stillo.entitlements в репо будет затёрта (документированная грабля).
  if [[ ! -f "$BUILD_DIR/Stillo/Stillo.entitlements.full" ]]; then
    echo "     ❌ $BUILD_DIR/Stillo/Stillo.entitlements.full не найден."
    echo "        Архив без полных entitlements (HealthKit) загружать нельзя."
    echo "        Проверь, что Stillo/Stillo.entitlements.full существует в $PROJECT и не игнорируется rsync/.gitignore."
    exit 1
  fi
  cp "$BUILD_DIR/Stillo/Stillo.entitlements.full" "$BUILD_DIR/Stillo/Stillo.entitlements"
  echo "     ✅ Applied full entitlements (.full → .entitlements in $BUILD_DIR)"
else
  # release/test — KEEP original entitlements (HealthKit etc.)
  echo "     ✅ Preserved (HealthKit entitlements intact)"
fi

# --- Step 3: Build ---
echo "[3/5] 🔨 Building ($MODE)..."

if [[ "$MODE" == "archive" ]]; then
  # Archive for App Store Connect
  xcodebuild \
    -project "$BUILD_DIR/Stillo.xcodeproj" \
    -scheme Stillo \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$DERIVED" \
    archive 2>&1 | tee /tmp/stillo_archive.log | grep -E "(error:|warning:|ARCHIVE SUCCEEDED)" || true

  if grep -q "ARCHIVE SUCCEEDED" /tmp/stillo_archive.log; then
    echo "     ✅ ARCHIVE SUCCEEDED → $ARCHIVE_PATH"
    $NOTIFY --message "✅ Archive built: $ARCHIVE_PATH" 2>/dev/null || true
  else
    echo "     ❌ ARCHIVE FAILED (see /tmp/stillo_archive.log)"
    exit 1
  fi

  echo "\n  ℹ️  Next: upload via Xcode Organizer or:"
  echo "      xcodebuild -exportArchive -archivePath $ARCHIVE_PATH \\"
  echo "                 -exportPath $EXPORT_DIR \\"
  echo "                 -exportOptionsPlist $PROJECT/ExportOptions.plist"
  echo "      xcrun altool --upload-app -f $EXPORT_DIR/*.ipa --apiKey ... --apiIssuer ..."
  exit 0

elif [[ "$MODE" == "test" ]]; then
  # Unit tests (StilloTests) on iOS Simulator
  xcodebuild test \
    -project "$BUILD_DIR/Stillo.xcodeproj" \
    -scheme Stillo \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    2>&1 | tee /tmp/stillo_test.log | grep -E "error:|failed|passed|Test Suite|BUILD|TEST" | tail -40 || true

  if grep -q "TEST SUCCEEDED" /tmp/stillo_test.log; then
    echo "     ✅ TEST SUCCEEDED"
    $NOTIFY --message "✅ Tests passed (StilloTests)" 2>/dev/null || true
    exit 0
  else
    echo "     ❌ TEST FAILED (see /tmp/stillo_test.log)"
    $NOTIFY --message "❌ Tests failed (see /tmp/stillo_test.log)" 2>/dev/null || true
    exit 1
  fi

elif [[ "$MODE" == "release" ]]; then
  # Release build without archive upload
  BUILD_OUTPUT=$(xcodebuild \
    -project "$BUILD_DIR/Stillo.xcodeproj" \
    -scheme Stillo \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED" \
    build 2>&1)
else
  # Dev build (default)
  BUILD_OUTPUT=$(xcodebuild \
    -project "$BUILD_DIR/Stillo.xcodeproj" \
    -scheme Stillo \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$DERIVED" \
    build 2>&1)
fi

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
  echo "     ✅ BUILD SUCCEEDED"
  $NOTIFY --build-ok --phase "$COMMIT_MSG" 2>/dev/null || true
else
  echo "     ❌ BUILD FAILED"
  ERRORS=$(echo "$BUILD_OUTPUT" | grep "error:" | tail -10)
  echo "$ERRORS"
  $NOTIFY --build-fail --errors "$ERRORS" 2>/dev/null || true
  exit 1
fi

# --- Step 4: Deploy (dev mode only) ---
if [[ "$MODE" == "dev" ]]; then
  echo "[4/5] 🚀 Deploying to device..."
  CONFIG_DIR="Debug-iphoneos"
  DEPLOY_OUTPUT=$(xcrun devicectl device install app \
    --device "$DEVICE" \
    "$DERIVED/Build/Products/$CONFIG_DIR/$APP_NAME.app" 2>&1)

  if echo "$DEPLOY_OUTPUT" | grep -q "installationURL"; then
    echo "     ✅ Deployed to $DEVICE"
    $NOTIFY --deployed 2>/dev/null || true
  else
    echo "     ❌ Deploy failed"
    echo "$DEPLOY_OUTPUT"
    $NOTIFY --message "❌ Deploy failed" 2>/dev/null || true
    exit 1
  fi
else
  echo "[4/5] ⏭  Deploy skipped (mode=$MODE)"
fi

# --- Step 5: Commit & Push (dev mode only) ---
if [[ "$MODE" == "dev" ]]; then
  echo "[5/5] 📝 Committing..."
  cd "$PROJECT"
  git add -A
  HASH=$(git commit -m "$COMMIT_MSG" 2>&1 | grep -oE '[a-f0-9]{7}' | head -1)
  git push 2>&1 | tail -3

  echo "     ✅ Pushed ($HASH)"
  $NOTIFY --commit "$COMMIT_MSG" --hash "$HASH" 2>/dev/null || true
else
  echo "[5/5] ⏭  Commit skipped (mode=$MODE — commit manually after QA)"
fi

# --- Done ---
echo "\n══════════════════════════════════════"
echo "  ✅ PIPELINE COMPLETE ($MODE)"
echo "  Message: $COMMIT_MSG"
echo "══════════════════════════════════════"

$NOTIFY --phase "$COMMIT_MSG" --message "All systems nominal ($MODE)." 2>/dev/null || true
