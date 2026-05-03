# Stillō — Pre-App-Store Todo

## Session 2026-04-19 (continuation)

### ✅ Completed
- [x] Release build verification → **BUILD SUCCEEDED** (iOS + Watch + Widget)
- [x] HealthKit HRV disclosure — fixed in `Stillo.xcodeproj/project.pbxproj` (4 instances)
- [x] HealthKit HRV disclosure — fixed in `docs/privacy.html` §2.1 (added SDNN)
- [x] Removed false "Mindful Minutes write" claim from `docs/privacy.html`
- [x] Fixed IDFV inaccuracy in `docs/privacy.html` §3
- [x] StoreKit auto-renew full disclosure added to EN + RU in `docs/AppStore_Listing.md`
- [x] Removed "even when your phone is locked" from both locales
- [x] Age Rating Horror: Infrequent/Mild → None
- [x] Review Notes block added to listing doc
- [x] Duplicate i18n keys removed in `en.lproj/Localizable.strings` (soundscape.play/stop) → 738 keys × 8 langs
- [x] Stale "3 records" comment in `PremiumManager.swift` → 7 records
- [x] Screenshots captured 6.7" RU + EN (1320×2868 × 6 shots each)
- [x] PrivacyInfo.xcprivacy audited — no FileTimestamp API usage; UserDefaults CA92.1 declared; safe
- [x] CLAUDE.md saved to `~/.claude/` for global use
- [x] `tasks/` directory scaffolded

### ⏳ In progress
- [ ] Final honest report to user

### 📋 Pending (user-only, cannot automate)
- [ ] Pay Apple Developer $99/yr membership
- [ ] Create App ID, Bundle ID in Apple Developer portal
- [ ] Create 3 IAP products in App Store Connect:
  - `com.stillo.premium.monthly` — $4.99 / ₽299
  - `com.stillo.premium.yearly` — $24.99 / ₽1 490 (7-day free trial)
  - `com.stillo.premium.lifetime` — $79.99 / ₽7 990 (non-consumable)
- [ ] Deploy Cloudflare Worker at `/Users/msk/Desktop/stillo-tts-proxy/`:
  - `npm install -g wrangler`
  - Set OPENAI_API_KEY, STILLO_SHARED_SECRET secrets via `wrangler secret put`
  - `wrangler deploy`
- [ ] Upload screenshots (6.7" + iPad if supporting) to ASC
- [ ] Paste ASO copy from `docs/AppStore_Listing.md` into ASC (8 locales)
- [ ] Archive + upload to TestFlight from Xcode
- [ ] Submit for review

### 🎯 Acceptance for "App Store ready"
1. ✅ All 3 targets compile (Debug + Release)
2. ✅ Smoke test passed in simulator (launch → disclaimer → home → journal → profile)
3. ✅ Dynamic Type AX5 no clipping
4. ✅ HealthKit disclosure strings match actual reads
5. ✅ Privacy manifest valid
6. ✅ Privacy policy hosted page accurate
7. ✅ ASO copy × 8 locales finalized
8. ✅ Screenshots captured
9. ⏳ Dev account + ASC config (user)
10. ⏳ Worker deploy (user)

## Review section (2026-04-19 final)

**What shipped this continuation session:**
- CLAUDE.md добавлен в `~/.claude/` (global workflow rules)
- `tasks/todo.md` + `tasks/lessons.md` scaffolded (14 lessons captured)
- Bundle ID chain verified: `MSK-PRODUKT.StopPanic` (pbxproj → OpenAITTSService.swift → wrangler.toml) — HMAC payload format consistent
- Git index repaired — `fatal: .git/index unable to map` устранён via `rm .git/index && git reset HEAD -- .`; 49 files теперь видны как modified (ждут commit юзера)
- Все audit-блокеры из прошлой сессии перенесены в completed и подтверждены

**Verified-green matrix:**
| Check | Status |
|-------|--------|
| iOS Release build | ✅ SUCCEEDED |
| Watch Release build | ✅ SUCCEEDED |
| Widget Release build | ✅ SUCCEEDED |
| Simulator smoke test | ✅ PASSED |
| HealthKit disclosure trio (code/plist/policy) | ✅ ALIGNED |
| i18n parity (738 keys × 8 locales) | ✅ |
| ASO copy × 8 locales | ✅ |
| Screenshots 6.9″ RU+EN × 6 | ✅ |
| Dynamic Type AX5 | ✅ no clipping |
| Privacy Manifest | ✅ valid |

**Handoff**: project is 100% code-complete + compliance-ready. User-only steps: Dev account ($99) → ASC products × 3 → Worker deploy → screenshot upload → archive+submit.
