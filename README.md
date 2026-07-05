# Stillō

> iOS + watchOS приложение скорой самопомощи при панической атаке.
> Один тап SOS → живой голос → дыхание 4-7-8 → заземление 5-4-3-2-1 → запись в дневник.
> 100% офлайн. Ни одного сетевого вызова (кроме StoreKit).

| Параметр | Значение |
|---|---|
| Bundle ID | `MSK-PRODUKT.StopPanic` |
| App name | **Stillō** (с макроном) |
| Таргеты | `Stillo` (iOS 17+), `StilloWatch Watch App` (watchOS 26), `StilloWidgetExtension`, `StilloTests` |
| Team | `6K26HD4XFR` |
| Языки | 8 (en, ru, de, es, fr, ja, pt-BR, zh-Hans) — голос RU/EN, остальные текст |
| Стек | Swift 5 (approachable concurrency, MainActor default), SwiftUI, Core Data (+CloudKit private), HealthKit (read-only HR/HRV), StoreKit 2, WatchConnectivity, BGTaskScheduler, AVFoundation |
| Зависимости | 0 сторонних |

## Архитектура (кратко)

- `@Observable AppCoordinator` (Core/AppCoordinator.swift) — DI-контейнер, создаёт 18 сервисов в `bootstrap()`, раздаёт через `@Environment`.
- Дизайн-система: namespace `SP` в `Core/DesignSystem.swift` — никакого хардкода цветов/шрифтов.
- Аудио: shared AVAudioSession, **НИКОГДА не `setActive(false)`** (см. Антипаттерны). Голос — только VoiceBank mp3 (34 фразы × RU/EN), синтез удалён.
- Данные: дневник → Core Data; настройки → UserDefaults; всё on-device.
- Deep links: `stillo://sos`, `stillo://breathe` (виджет). Обработчик — ТОЛЬКО в `StilloApp.onOpenURL`.

```
Stillo/
├── Core/          # AppCoordinator, DesignSystem (SP), MainTabView, Persistence
├── Models/        # DiaryEpisode, Achievement, HeartAnalysis, PanicPrediction, SOSContact
├── Screens/       # Home, SOS, Tools, Journal, Soundscape, Profile, Settings, Onboarding
├── Services/      # 18 сервисов: Ambient/Voice/AudioGuide, Premium, Streak, HealthKit...
├── Views/         # Переиспользуемые view
└── Resources/     # 8×.lproj, Audio (6 m4a), Voice/{ru,en} (68 mp3)
```

## Сборка

```bash
# Дев-сборка на iPhone (rsync → /tmp → strip entitlements → build → deploy → commit):
Scripts/pipeline.sh "Phase XX: что сделал"

# Тесты (симулятор):
Scripts/pipeline.sh --mode=test

# App Store архив (entitlements .full подставляются автоматически):
Scripts/pipeline.sh --mode=archive "v1.0.0"
```

⚠️ Никогда не билдить напрямую из рабочей директории и не коммитить stripped entitlements — см. `Деплой` в vault.

## App Store

- Чеклист и ASO-копия 8 локалей: `docs/AppStore_Listing.md`
- Privacy policy / terms: `docs/privacy.html`, `docs/terms.html` (хостить на GitHub Pages)
- Цены (Pricing C, 2026-05-01): Lifetime $9.99 / Yearly $4.99 (7д trial) / Monthly $0.99; Tier 2 RU ₽299/₽149/₽49
- SKU: `com.stillo.premium.{monthly,yearly,lifetime}`
- Внешний блокер: активация Apple Developer Program ($99/год)

## Дисклеймер

Stillō — инструмент самопомощи, не медицинское устройство и не замена терапии.
