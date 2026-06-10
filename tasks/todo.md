# Stillō — Pre-App-Store Todo

> Обновлено: 2026-06-10. История прошлых сессий — внизу.
> Источник истины по состоянию: `obsiddian/StopPanic/StopPanic — Кристалл знания.md`

## Session 2026-06-10 — Полный аудит + фиксы (Cowork)

### ✅ Done (код)
- [x] Crisis line: `"UK"` → `"GB"` + регион устройства вместо региона языка (`SOSService.swift`, `CrisisLineView.swift`)
- [x] Deep link `stillo://breathe` (виджет) обрабатывается; двойной `onOpenURL` → один (StilloApp)
- [x] Breathing sheet реально презентуется (`MainTabView.sheet`) — раньше флаг был no-op
- [x] Локализация: +22 ключа × 6 языков, −17 мёртвых OpenAI-ключей × 8 → парность 748×8
- [x] 8 × `Localizable.strings.bak` удалены (уезжали в бандл со строками OpenAI)
- [x] `InfoPlist.strings`: ложный `NSHealthUpdateUsageDescription` удалён (read-only)
- [x] Виджет локализован (6 ключей × 8 языков, `StilloWidget/Resources/`)
- [x] Мёртвый voice-код удалён (`speakLocal`, `.system`), миграция UserDefaults
- [x] Watch: кнопка 112 работает (sheet + crisis line + запрос на iPhone)
- [x] Watch: SOS fallback `transferUserInfo` + честный статус delivered/queued
- [x] Watch: live HR через `HKWorkoutSession` (.mindAndBody)
- [x] iOS принимает queued-SOS (`didReceiveUserInfo`) и `showCrisisLine`
- [x] Громкость 0 больше не сбрасывается на дефолт после рестарта

### ✅ Done (клинический пакет, evidence-based — см. docs/Product_Plan_2026-06.md §5)
- [x] «Глубоко вдохни» → «Медленный вдох носом» ×8 языков (Meuret/CART: гипервентиляция)
- [x] Живой BPM убран с экрана SOS (JAHA 2024: интероцептивная бдительность)
- [x] Streak-пуш без 🔥/loss-framing ×8 языков
- [x] RU кризисная линия: взрослая ЦЭПП МЧС +7 495 989-50-50 (была детская) + watch ru
- [x] Дневник в Free безлимитный (Decision 2026-05-01); paywall: дневник → Apple Watch
- [x] Психообразование: первый степ SOS-флоу («пик за минуты, это не опасно») + post-episode карточка, 3 ключа ×8 → парность 751×8
- [x] Пути в .claude/agents/*.md починены (System → _Archive/Кристалл)

### ✅ Done (конфиг/доки)
- [x] pbxproj: **Embed Watch Content** (watch теперь попадает в ipa!)
- [x] pbxproj: таргет **StilloTests** + scheme Testables + `PRODUCT_MODULE_NAME = Stillo`
- [x] pbxproj: exception set — `Products.storekit`, entitlements не уезжают в бандл
- [x] `pipeline.sh`: `--mode=test`; archive подставляет `.entitlements.full` (в /tmp)
- [x] `ExportOptions.plist` создан; `.gitignore` больше не прячет `.full`
- [x] `PremiumManagerTests`: freeDiaryLimit 3 → 7
- [x] `privacy.html`: §4 OpenAI/Worker удалён (приложение офлайн), дата обновлена
- [x] `AppStore_Listing.md`: цены → Pricing C ($0.99/$4.99/$9.99, ₽49/₽149/₽299), OpenAI-упоминания удалены, «30+ стран» → честные 12
- [x] README переписан под актуальное состояние

### ✅ Верифицировано на Mac (2026-06-10, через Xcode GUI)
- [x] Проект открывается, pbxproj-хирургия валидна (таргет StilloTests виден, Watch-зависимость собирается)
- [x] Build SUCCEEDED, приложение запускается на iPhone 17 Pro Max (iOS 26.4 sim)
- [x] **Тесты: 10 tests / 3 suites — ALL PASSED** (Product → Test)
- [x] Smoke: онбординг → Home → SOS-флоу: психообразование («Это паническая атака…») → заземление (голос ground_see) → финал «Ты справился!» + карточка «тело справилось бы само» → запись в дневник. VoiceBank 34/34 [ru], BPM-капсулы на SOS нет
- [x] Консоль чистая (BGTaskScheduler error 3 в симуляторе — норма; WCSession not paired — нет Watch-сима)

### ⏳ Осталось проверить руками (не критично для дев-цикла)
- [ ] Виджет: добавить на home screen симулятора → тап → breathing sheet
- [ ] Watch-сценарий на спаренном Watch-симуляторе или реальных часах
- [ ] «Recovered References» группа в навигаторе Xcode — глянуть, что внутри (артефакт pbxproj-правок; сборке не мешает)
- [ ] **Закоммитить изменения** (`git add -A && git commit`) — изменений много, всё работает

### ❓ Решения за Саидом
- [x] ~~freeDiaryLimit~~ → решено 2026-06-10: безлимит в Free (по Decision C)
- [ ] WATCHOS_DEPLOYMENT_TARGET = 26.0 — осознанно высокий? (iOS 17.0)

### 📋 User-only (внешний блокер)
- [ ] Apple Developer Program $99/год → ASC: App Record, 3 IAP (цены C!), screenshots, TestFlight, Submit
- [ ] Опубликовать privacy.html/terms.html (GitHub Pages)
- [ ] Voice quality audit: прослушать 68 mp3 (punch-list Кристалла, P0)

---

## Архив: Session 2026-04-19

Все пункты той сессии выполнены (HealthKit disclosure, ASO, скриншоты, i18n 738×8 — устарело, см. выше). Детали — в git-истории этого файла.
