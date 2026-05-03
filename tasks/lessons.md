# Stillō — Lessons Learned

Каждый урок = правило, чтобы не повторять ошибку. Формат: **Rule** → *Why* → *How to apply*.

---

## 1. NSHealth*UsageDescription parity
**Rule**: Строки `INFOPLIST_KEY_NSHealthShareUsageDescription` и `NSHealthUpdateUsageDescription` должны отражать КАЖДЫЙ `HKQuantityType` в `HealthKitManager.typesToRead` / `toShare`.
**Why**: Apple reviewer по гайду 5.1.1 сравнивает Info.plist с реальными HealthKit-reads через static analysis. Несовпадение = rejection. В этой сессии я писал «heart rate» хотя код читал HRV SDNN — blocker.
**How to apply**: При каждом добавлении `HKQuantityType` в код — синхронно править все 4 instance `NSHealthShareUsageDescription` в `project.pbxproj` (iOS + Watch, Debug + Release).

## 2. HealthKit в Privacy Manifest
**Rule**: Декларировать `NSPrivacyCollectedDataTypeHealthData` с `Linked=false, Tracking=false, Purpose=AppFunctionality` даже если данные не покидают устройство.
**Why**: Apple's "Collect" terminology размыта; консервативная декларация не вредит, отсутствие декларации = rejection.
**How to apply**: Для любого HealthKit-read — запись в `PrivacyInfo.xcprivacy` с `AppFunctionality` и флагами false.

## 3. Privacy trio consistency
**Rule**: Privacy policy HTML + `Info.plist` UsageDescription + `PrivacyInfo.xcprivacy` должны взаимно согласованы.
**Why**: Apple reviewer сверяет все три. Одно несовпадение (например, policy говорит «reads HR», Info.plist говорит «reads HR and HRV») = blocker. В этой сессии privacy.html врал про «Mindful Minutes write» которого не было в коде.
**How to apply**: При правке одного из трёх — grep двух других по ключевым словам (HealthKit, HRV, heart rate, Mindful Minutes) и выровнять.

## 4. Release guard для DEBUG-only флагов
**Rule**: `init()` должен удалять UserDefaults-ключи DEBUG-only флагов под `#if !DEBUG`.
**Why**: TestFlight/Release билд может унаследовать `stillo_debug_god_mode=true` с предыдущей DEBUG-установки на том же девайсе — и выкатиться юзеру с bypass.
**How to apply**: Паттерн из `PremiumManager.swift:27-29`: `#if !DEBUG { UserDefaults.standard.removeObject(forKey: Self.godModeKey) }`. Применять КО ВСЕМ DEBUG-флагам.

## 5. Localization parity
**Rule**: `grep -c '^"' *.strings` у всех 8 локалей должен давать одно число.
**Why**: Дубли ключей в одном языке → первое значение берётся iOS, второе молча отбрасывается. Дрейф числа ключей → runtime-fallback на ключ вместо перевода = reviewer-visible bug.
**How to apply**: Перед submission запускать `for lang in en ru de es fr pt-BR ja zh-Hans; do echo -n "$lang: "; grep -c '^"' Stillo/Resources/$lang.lproj/Localizable.strings; done` — проверить 738 × 8.

## 6. Grep-filtered xcodebuild
**Rule**: `xcodebuild ... 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)" | head -40`.
**Why**: Полный лог xcodebuild = 50–200KB. Grep-filtered = 1–3KB. Экономия токенов 50×, точность сигнала 100%.
**How to apply**: Никогда не читать xcodebuild-лог целиком. Если нужен контекст — второй grep с `-B 2 -A 2` вокруг первого error.

## 7. Screenshots — native simctl
**Rule**: `xcrun simctl io booted screenshot /path/file.png` + `osascript System Events` для навигации.
**Why**: Нативные скрины симулятора — это Apple-canonical путь. Figma / Sketch / Screely — опциональный polish. Для MVP и fast-publish достаточно native.
**How to apply**: `xcrun simctl boot "iPhone 17 Pro Max" && xcrun simctl install booted $APP_PATH && xcrun simctl launch booted $BUNDLE_ID && xcrun simctl io booted screenshot ~/Desktop/shot.png`. Разрешение iPhone 17 Pro Max = 1320×2868 (6.9″).

## 8. StoreKit auto-renew disclosure
**Rule**: В App Store description блок Terms обязателен: длина подписки, цена, auto-renew условие, cancel instructions, privacy/terms ссылки.
**Why**: Гайд 3.1.2 mandates это — иначе rejection, даже если всё остальное безупречно. Юзер не может его опустить даже в «минималистичном» листинге.
**How to apply**: Копировать Apple's рекомендованный текст дословно — не переформулировать. Для RU локали — те же пункты, те же цены (₽), но по-русски. См. `docs/AppStore_Listing.md` Description sections.

## 9. API key never in binary
**Rule**: OpenAI / любой serverside-API — через прокси (Cloudflare Worker / Lambda), attestation через HMAC-SHA256 c shared secret.
**Why**: `strings <binary>.ipa | grep sk-` находит ключ за 5 секунд. Shared secret в iOS хранится в XOR-обфусцированном массиве байт в коде — не криптография, но blocks `strings`.
**How to apply**: (a) iOS → `HMAC<SHA256>.authenticationCode(key: secret, data: bundleID+timestamp+sha256(body))`; (b) Worker → verify HMAC; reject if timestamp >60s old или если BUNDLE_ID не совпадает. Paттерн: `stillo-tts-proxy/src/worker.ts`.

## 10. Token budget в длинных сессиях
**Rule**: При контексте >60% переходить на «только grep, только offset/limit reads, только 1 xcodebuild».
**Why**: Context compaction приводит к потере деталей; если токенов мало, нужно делать максимум полезной работы на минимум чтений.
**How to apply**: `Read file offset=N limit=50` вместо полного Read; `grep -c` вместо перечисления всех совпадений; subagents только для тяжёлого ресёрча, не для мелких правок.

## 11. Simulator automation pitfalls
**Rule**: osascript `click at {x, y}` — координаты относительно экрана, не окна. Scale factor симулятора ≠ 1.
**Why**: iPhone 17 Pro Max в симуляторе: логическое разрешение 1320×2868, визуальное окно ~454×971 (scale 0.344). Клик по (x_logical * scale) часто попадает в соседнюю кнопку.
**How to apply**: (a) Получить window bounds через AppleScript; (b) применить scale = window_width / 1320; (c) пересчитать y координаты с учётом title bar высоты (~39pt). Тестировать 1 клик → скрин → оценить — прежде чем автоматизировать серию.

## 12. Git pre-submission sanity
**Rule**: `git status` должен работать без ошибок перед любой submission-related операцией.
**Why**: Corrupted `.git/index` в этой сессии блокирует commits — это сигнал о sleep/wake incident или low-disk. Submission workflow может требовать clean git state (например, fastlane).
**How to apply**: При `fatal: .git/index: unable to map` → `cp .git/index .git/index.bak && rm .git/index && git reset` восстанавливает index из HEAD без потери working-tree изменений.

## 13. Dynamic Type via Font.system(.style)
**Rule**: Использовать `Font.system(.title, weight: .bold)` а не `Font.system(size: 28, weight: .bold)`.
**Why**: Hard-coded pt-размеры игнорируют Accessibility Slider — AX5 юзер видит тот же текст, получает rejection за 5.1 / ADA в US.
**How to apply**: Централизация в `DesignSystem.swift`; использовать semantic styles (.largeTitle, .title, .title2, .headline, .body, .callout, .subheadline, .footnote, .caption). Для custom weight/width — `.system(.body, design: .default).weight(.medium)`.

## 14. CLAUDE.md workflow — verify-before-done
**Rule**: «Готово» = доказано что работает. Build passes ≠ app works. Smoke test обязателен.
**Why**: Compile-time verification ловит syntax, но не ловит runtime crashes, missing assets, broken navigation. В этой сессии я нашёл i18n bug только потому что прогнал smoke test в симуляторе.
**How to apply**: После любого Release-build — обязательно boot simulator, install IPA/.app, пройти golden path (launch → core feature → settings → deep link). Скрины — бонус, smoke — mandatory.
