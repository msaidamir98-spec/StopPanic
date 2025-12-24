# 🛑 StopPanic

> iOS-приложение для помощи при панических атаках. Дыхательные техники, заземление, дневник эпизодов, карта настроения и интеграция с HealthKit — всё в одном месте.

![Platform](https://img.shields.io/badge/platform-iOS%2026.2%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Xcode](https://img.shields.io/badge/Xcode-26%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📱 О проекте

**StopPanic** — нативное SwiftUI-приложение, которое помогает людям, страдающим от панических атак и тревожных расстройств. Приложение предоставляет мгновенные инструменты помощи прямо во время приступа, а также долгосрочные инструменты для отслеживания и понимания своих паттернов.

### Автор

**Саид Магдиев** (MSK-PRODUKT)

---

## ✨ Возможности

### 🆘 Экстренная помощь
- **Кнопка «Я в панике»** — мгновенный доступ к пошаговой помощи
- **SOS-кнопка** с анимацией пульса и записью в HealthKit
- **Пошаговый протокол** КПТ-заземления (5 шагов)
- **Управляемое дыхание** (паттерн 4-4-6: вдох–задержка–выдох)

### 🧘 Техники успокоения
- **4-7-8 дыхание** — успокаивающая техника
- **Заземление 5-4-3-2-1** — через органы чувств
- **Мышечное расслабление** — прогрессивная релаксация
- **Сессия спокойствия** — комбинированная сессия (дыхание → заземление → рефлексия)

### 📔 Дневник и аналитика
- Запись панических эпизодов с интенсивностью и заметками
- Запись триггеров с привязкой к локации
- Статистика за день и за неделю
- Отслеживание серий (streak) практик

### 🗺️ Карта настроения
- Отметки настроения с геопривязкой (1–10)
- Визуализация паттернов по местоположению
- Выявление «безопасных» и «тревожных» зон

### ❤️ Интеграция с HealthKit
- Чтение пульса в реальном времени
- Запись mindful-сессий при паническом эпизоде
- Визуальная индикация повышенного пульса (> 100 BPM)

### 👤 Профиль пользователя
- Имя, возраст, цели терапии
- Данные терапевта
- Персональные заметки

### 🎨 Дизайн
- Тёмная «космическая» тема (CosmicHomeKit)
- Плавные градиенты и анимации
- Haptic-обратная связь (CoreHaptics)
- Glassmorphism-эффекты
- Адаптивный UI с rounded-шрифтами

---

## 🏗️ Архитектура

Проект следует паттерну **MVVM** (Model — View — ViewModel):

```
StopPanic/
├── StopPanicApp.swift            # Точка входа, онбординг-флоу
├── StopPanic.entitlements        # HealthKit entitlement
│
├── Models/                       # Модели данных
│   ├── CourseStep.swift          # Курсы и прогресс
│   ├── DiaryEpisode.swift        # Эпизод паники
│   ├── EpisodeTrigger.swift      # Триггеры эпизодов
│   ├── MoodState.swift           # Состояния настроения + MoodPin
│   ├── Technique.swift           # Техника успокоения
│   └── UserProfile.swift         # Профиль пользователя
│
├── ViewModels/                   # Бизнес-логика
│   ├── HomeViewModel.swift       # Главный экран, статистика
│   ├── NowHelpViewModel.swift    # Экстренная помощь, дыхание
│   └── CalmSessionPhase.swift    # Сессия спокойствия (фазы)
│
├── Views/                        # UI-компоненты
│   ├── ContentView.swift         # Корневой TabView
│   ├── HomeView.swift            # Главный экран
│   ├── NowHelpView.swift         # Экран «Я в панике»
│   ├── SosView.swift             # SOS-кнопка с пульсом
│   ├── CalmSessionView.swift     # Сессия спокойствия
│   ├── MoodMapView.swift         # Карта настроения
│   ├── ProfileView.swift         # Профиль
│   ├── OnboardingPage.swift      # Онбординг
│   ├── AppTheme.swift            # Тема и цвета
│   └── HealthKitManager.swift    # HealthKit-интеграция
│
├── Services/                     # Сервисный слой (хранение, логика)
│   ├── DiaryService.swift        # Дневник эпизодов (JSON)
│   ├── MoodMapService.swift      # Карта настроения + CLLocation
│   ├── NotificationService.swift # Локальные уведомления
│   ├── TechniqueLibrary.swift    # Каталог техник
│   └── UserProfileService.swift  # Профиль пользователя (JSON)
│
├── CosmicHomeKit/                # UI-кит в космическом стиле
│   ├── CosmicBreathingSessionView.swift
│   ├── CosmicGlass.swift         # Glassmorphism-эффекты
│   ├── CosmicGrounding54321View.swift
│   ├── CosmicHaptics.swift       # Хаптик-обратная связь
│   ├── CosmicHomeShellView.swift
│   ├── CosmicPanicFlowView.swift
│   ├── CosmicQuickLogView.swift
│   ├── CosmicRouter.swift        # Навигация
│   ├── CosmicTheme.swift         # Космическая тема
│   └── CosmicUIComponents.swift  # Переиспользуемые компоненты
│
└── Assets.xcassets/              # Ресурсы (иконки, цвета)
```

### Ключевые принципы
- **Чистый SwiftUI** — без UIKit (кроме haptics)
- **@StateObject / @ObservedObject** — реактивное управление состоянием
- **Локальное хранение** — JSON-файлы в Documents (без сервера)
- **Нативные фреймворки** — HealthKit, CoreLocation, CoreHaptics, UserNotifications

---

## 🔧 Системные требования

| Компонент | Версия |
|-----------|--------|
| macOS | 15.0+ (Sequoia) |
| Xcode | 26.0+ |
| Swift | 5.0+ |
| iOS (deploy target) | 26.2+ |
| Устройства | iPhone + iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Реальное устройство | Рекомендуется (HealthKit, CoreLocation) |

---

## 🚀 Установка и запуск

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd StopPanic
```

### 2. Откройте проект в Xcode

```bash
open StopPanic.xcodeproj
```

### 3. Настройка подписи

1. Откройте **StopPanic.xcodeproj** → выберите target **StopPanic**
2. Перейдите во вкладку **Signing & Capabilities**
3. Выберите свою **Team** (Apple Developer Account)
4. Xcode автоматически создаст provisioning profile

### 4. Сборка и запуск

- Выберите **симулятор** (iPhone 15 Pro рекомендуется) или **реальное устройство**
- Нажмите **⌘R** (Run) или кнопку ▶ в Xcode

> ⚠️ **Примечание:** Для полной работы HealthKit и CoreLocation необходимо реальное устройство (на симуляторе данные будут фиктивными).

### 5. Сборка из командной строки (опционально)

```bash
xcodebuild -project StopPanic.xcodeproj \
           -scheme StopPanic \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

---

## 📦 Зависимости

Проект **не использует сторонних зависимостей** — только нативные фреймворки Apple:

| Фреймворк | Использование |
|-----------|--------------|
| **SwiftUI** | Весь UI |
| **HealthKit** | Пульс, mindful-сессии |
| **CoreLocation** | Карта настроения (геопозиция) |
| **CoreHaptics** | Тактильная обратная связь |
| **UserNotifications** | Локальные уведомления-напоминания |
| **Combine** | Реактивные потоки данных |

---

## 🔑 Entitlements и разрешения

Приложение запрашивает следующие разрешения:

- **HealthKit** (`com.apple.developer.healthkit`) — чтение пульса, запись mindful-сессий
- **Location When In Use** — для карты настроения
- **Notifications** — напоминания о практиках

> Не забудьте добавить описания в `Info.plist`:
> - `NSHealthShareUsageDescription` — зачем приложение читает данные здоровья
> - `NSHealthUpdateUsageDescription` — зачем пишет данные
> - `NSLocationWhenInUseUsageDescription` — зачем нужна геопозиция

---

## 🎯 Планы развития

- [ ] Полноценный дневник эпизодов (вкладка «Дневник»)
- [ ] Каталог техник с детальными описаниями (вкладка «Техники»)
- [ ] Apple Watch companion-приложение
- [ ] Виджеты на главный экран (WidgetKit)
- [ ] Экспорт данных (PDF/CSV)
- [ ] Графики и тренды (Charts framework)
- [ ] Локализация (EN, TR)
- [ ] CloudKit синхронизация между устройствами

---

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку фичи (`git checkout -b feature/amazing-feature`)
3. Закоммитьте изменения (`git commit -m 'Add amazing feature'`)
4. Запушьте ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

---

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. Подробности см. в файле [LICENSE](LICENSE).

---

## 📞 Контакты

**Саид Магдиев** — MSK-PRODUKT

Bundle ID: `MSK-PRODUKT.StopPanic`

---

<p align="center">
  <i>Сделано с ❤️ для тех, кому бывает страшно.</i>
</p>
