#!/usr/bin/env python3
"""
Generate pre-recorded voice phrases for Stillo app.
Uses Microsoft Edge TTS (free, premium quality).
English: en-US-JennyNeural (warm, caring female)
Russian: ru-RU-SvetlanaNeural (natural female)
"""
import asyncio
import os
import edge_tts

OUTPUT_DIR = "Stillo/Resources/Voice"

# All phrases the app needs, keyed by filename
PHRASES = {
    "en": {
        "voice": "en-US-JennyNeural",
        "rate": "-15%",  # slightly slower for calming effect
        "phrases": {
            "breathe_in":       "Breathe in",
            "hold":             "Hold",
            "breathe_out":      "Breathe out, slowly",
            "ground_see":       "Name five things you can see",
            "ground_touch":     "Touch four things around you",
            "ground_hear":      "Listen for three sounds",
            "ground_smell":     "Notice two things you can smell",
            "ground_taste":     "Focus on one taste",
            "you_did_it":       "You did it. You are safe.",
            "you_are_safe":     "You are safe. I am here with you.",
            "welcome":          "Welcome. Take a deep breath.",
            "session_start":    "Let's begin. Find a comfortable position.",
            "great_job":        "Great job. You're doing wonderfully.",
            "almost_done":      "Almost done. Stay with me.",
            "relax_shoulders":  "Relax your shoulders. Let the tension go.",
            "close_eyes":       "Gently close your eyes if you feel comfortable.",
            "focus_breath":     "Focus on your breath. Nothing else matters right now.",
            "panic_intro":      "I'm here with you. This will pass. Let's breathe together.",
            "sos_calm":         "You are not in danger. Your body is just reacting. Let's calm it down together.",
        }
    },
    "ru": {
        "voice": "ru-RU-SvetlanaNeural",
        "rate": "-15%",
        "phrases": {
            "breathe_in":       "Вдох",
            "hold":             "Задержи",
            "breathe_out":      "Выдох, медленно",
            "ground_see":       "Назови пять вещей, которые ты видишь",
            "ground_touch":     "Потрогай четыре предмета рядом с тобой",
            "ground_hear":      "Прислушайся к трём звукам",
            "ground_smell":     "Заметь два запаха вокруг",
            "ground_taste":     "Сосредоточься на одном вкусе",
            "you_did_it":       "У тебя получилось. Ты в безопасности.",
            "you_are_safe":     "Ты в безопасности. Я с тобой.",
            "welcome":          "Добро пожаловать. Сделай глубокий вдох.",
            "session_start":    "Давай начнём. Найди удобное положение.",
            "great_job":        "Отлично. Ты молодец.",
            "almost_done":      "Почти закончили. Оставайся со мной.",
            "relax_shoulders":  "Расслабь плечи. Отпусти напряжение.",
            "close_eyes":       "Мягко закрой глаза, если тебе комфортно.",
            "focus_breath":     "Сосредоточься на дыхании. Сейчас ничего больше не важно.",
            "panic_intro":      "Я с тобой. Это пройдёт. Давай подышим вместе.",
            "sos_calm":         "Ты не в опасности. Твоё тело просто реагирует. Давай вместе его успокоим.",
        }
    }
}


async def generate_phrase(voice: str, rate: str, text: str, output_path: str):
    """Generate a single phrase as MP3"""
    communicate = edge_tts.Communicate(text, voice, rate=rate)
    await communicate.save(output_path)
    size = os.path.getsize(output_path)
    print(f"  ✅ {os.path.basename(output_path)} ({size // 1024}KB)")


async def main():
    total = 0
    for lang, config in PHRASES.items():
        lang_dir = os.path.join(OUTPUT_DIR, lang)
        os.makedirs(lang_dir, exist_ok=True)
        
        voice = config["voice"]
        rate = config["rate"]
        phrases = config["phrases"]
        
        print(f"\n🎤 Generating {lang.upper()} ({voice}):")
        
        for key, text in phrases.items():
            output_path = os.path.join(lang_dir, f"{key}.mp3")
            await generate_phrase(voice, rate, text, output_path)
            total += 1
    
    print(f"\n🎉 Done! Generated {total} audio files.")
    print(f"📂 Output: {OUTPUT_DIR}/")


if __name__ == "__main__":
    asyncio.run(main())
