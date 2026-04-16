#!/bin/zsh
# ============================================================
# Stillō Supreme Commander — Automated Pipeline
# Build → Deploy → Commit → Notify
# Usage: ./pipeline.sh "Phase XX: description"
# ============================================================

set -euo pipefail

PROJECT="/Users/msk/Desktop/Stillo"
BUILD_DIR="/tmp/StilloBuild"
DERIVED="/tmp/StilloDerived"
DEVICE="00008101-001028290C50801E"
APP_NAME="Stillō"
NOTIFY="python3 $PROJECT/Scripts/notify.py"

COMMIT_MSG="${1:-auto-commit}"

echo "══════════════════════════════════════"
echo "  🤖 Supreme Commander Pipeline"
echo "══════════════════════════════════════"

# --- Step 1: rsync ---
echo "\n[1/5] 📁 Syncing to build directory..."
rsync -a --delete "$PROJECT/" "$BUILD_DIR/" --exclude .git
echo "     ✅ Synced"

# --- Step 2: Strip entitlements ---
echo "[2/5] 🔐 Stripping entitlements..."
cat > "$BUILD_DIR/Stillo/Stillo.entitlements" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
PLIST
echo "     ✅ Stripped"

# --- Step 3: Build ---
echo "[3/5] 🔨 Building..."
BUILD_OUTPUT=$(xcodebuild \
  -project "$BUILD_DIR/Stillo.xcodeproj" \
  -scheme Stillo \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$DERIVED" \
  build 2>&1)

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

# --- Step 4: Deploy ---
echo "[4/5] 🚀 Deploying to device..."
DEPLOY_OUTPUT=$(xcrun devicectl device install app \
  --device "$DEVICE" \
  "$DERIVED/Build/Products/Debug-iphoneos/$APP_NAME.app" 2>&1)

if echo "$DEPLOY_OUTPUT" | grep -q "installationURL"; then
  echo "     ✅ Deployed to $DEVICE"
  $NOTIFY --deployed 2>/dev/null || true
else
  echo "     ❌ Deploy failed"
  echo "$DEPLOY_OUTPUT"
  $NOTIFY --message "❌ Deploy failed" 2>/dev/null || true
  exit 1
fi

# --- Step 5: Commit & Push ---
echo "[5/5] 📝 Committing..."
cd "$PROJECT"
git add -A
HASH=$(git commit -m "$COMMIT_MSG" 2>&1 | grep -oE '[a-f0-9]{7}' | head -1)
git push 2>&1 | tail -3

echo "     ✅ Pushed ($HASH)"
$NOTIFY --commit "$COMMIT_MSG" --hash "$HASH" 2>/dev/null || true

# --- Done ---
echo "\n══════════════════════════════════════"
echo "  ✅ PIPELINE COMPLETE"
echo "  Commit: $HASH"
echo "  Message: $COMMIT_MSG"
echo "══════════════════════════════════════"

$NOTIFY --phase "$COMMIT_MSG" --message "All systems nominal." 2>/dev/null || true
