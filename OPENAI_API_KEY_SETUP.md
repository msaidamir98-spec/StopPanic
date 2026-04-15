# 🔐 Настройка OpenAI API Key для Stillō

## Способ 1: Embedded Key (рекомендуемый для разработчика)

### Шаг 1: Создай файл конфигурации

Создай файл `Stillo/Services/OpenAITTSConfig.swift`:

```swift
// OpenAITTSConfig.swift
// ⚠️ НИКОГДА не коммить этот файл в Git!
// Добавлен в .gitignore

import Foundation

@objc(OpenAITTSConfig)
class OpenAITTSConfig: NSObject {
    @objc static let apiKey = "sk-ВСТАВЬ-СЮДА-СВОЙ-КЛЮЧ"
}
```

### Шаг 2: Добавь в .gitignore

```
# OpenAI API Key — NEVER commit
Stillo/Services/OpenAITTSConfig.swift
```

### Шаг 3: Проверь

1. Открой приложение → Settings → OpenAI TTS → Enable
2. Статус должен показать "Connected — voice ready" (зелёный кружок)
3. Нажми "Test Voice" → должен зазвучать голос OpenAI

---

## Способ 2: Через Keychain (для пользователей)

Если embedded key НЕ задан, пользователь может ввести свой ключ:
- Settings → OpenAI TTS → Enable → ввести ключ в поле API Key

Ключ хранится в iOS Keychain (зашифрован, не попадает в бэкапы).

---

## Способ 3: Через Backend-прокси (для продакшена)

Для публикации в App Store рекомендуется:
1. Создать свой backend (Cloudflare Workers / Vercel / Railway)
2. Backend проксирует запросы к OpenAI
3. API-ключ хранится только на сервере
4. В приложении вместо прямого вызова OpenAI → вызов своего backend

Пример Cloudflare Worker:
```javascript
export default {
  async fetch(request) {
    const body = await request.json();
    const resp = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.OPENAI_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });
    return new Response(resp.body, { headers: { 'Content-Type': 'audio/mpeg' } });
  }
};
```

---

## Приоритет ключей

1. **Embedded key** (`OpenAITTSConfig.apiKey`) — если файл существует
2. **Keychain key** (введён пользователем) — если embedded пуст
3. **Нет ключа** → OpenAI TTS отключён, используется VoiceBank (оффлайн)

---

## Стоимость

- `tts-1`: ~$0.015 за 1000 символов (~$0.01 за одну фразу)
- `tts-1-hd`: ~$0.030 за 1000 символов
- Кэширование на диске снижает расходы в 10-50x при повторных фразах
