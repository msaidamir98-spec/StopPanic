import Observation

// MARK: - AudioController

/// Фасад над аудио-стеком (композиция, не замещение).
///
/// Предоставляет высокоуровневые операции для кнопок UI и координатора.
/// Внутри — 3 специализированных сервиса сохраняют свои SRP-зоны:
///   • `ambient` — фоновый звук (loops, crossfade, preview)
///   • `guide`   — двухуровневый каскад голоса (VoiceBank → AVSpeech, 100% offline)
///   • `bank`    — предзаписанные MP3-фразы
///
/// Views импортируют только Facade → один source of truth, легче тестировать.
/// Старые прямые обращения через `coordinator.ambientSound` и т.д. остаются
/// рабочими — эта прослойка дополняет, а не ломает.
@Observable
@MainActor
final class AudioController {
    // MARK: - Composed Services

    let ambient: AmbientSoundService
    let guide: AudioGuideService
    let bank: VoiceBankService

    // MARK: - Init

    init(
        ambient: AmbientSoundService,
        guide: AudioGuideService,
        bank: VoiceBankService
    ) {
        self.ambient = ambient
        self.guide = guide
        self.bank = bank
    }

    // MARK: - Source of Truth

    /// Единственный источник истины для «какая мелодия сейчас выбрана».
    var currentTrack: AmbientSoundService.SoundTrack {
        get { ambient.selectedTrack }
        set { ambient.selectedTrack = newValue }
    }

    /// Играет ли прямо сейчас что-либо из ambient-плеера.
    var isAmbientPlaying: Bool { ambient.isPlaying }

    /// Громкость ambient 0–1.
    var ambientVolume: Double {
        get { ambient.volume }
        set { ambient.volume = newValue }
    }

    // MARK: - High-level operations

    /// Стартовать выбранный ambient-трек (если не играет).
    func startAmbient() {
        guard !ambient.isPlaying else { return }
        ambient.play()
    }

    /// Остановить ambient с fade-out.
    func stopAmbient() {
        ambient.stop()
    }

    /// Toggle ambient play/stop — для soundscape-кнопок.
    func toggleAmbient() {
        ambient.toggle()
    }

    /// SOS-протокол: гарантирует play currentTrack + прерывание превью.
    /// Вызывается из AppCoordinator.triggerSOS() и любых other SOS entry points.
    func activateSOS() {
        ambient.stopPreview()
        ambient.playSelectedTrack()
    }

    /// «Paniс kill-switch» — полная тишина. Используется для onDisappear
    /// экранов, где аудио не должно пережить закрытие.
    func silenceAll() {
        ambient.stopPreview()
        ambient.stop()
        guide.stop()
    }

    // MARK: - Voice shortcuts (pass-through)

    /// Безопасная короткая фраза «Ты в безопасности». Используется в SOS-flow.
    func speakSafe() { guide.speakSafe() }

    /// Озвучить фазу дыхания (inhale/hold/exhale).
    func speakBreathPhase(_ phase: AudioGuideService.BreathVoicePhase) {
        guide.speakBreathPhase(phase)
    }

    /// Приглушить ambient на время голосовой подсказки.
    func duckForVoice() { ambient.duckForVoice() }

    /// Восстановить ambient после голоса.
    func unduck() { ambient.unduck() }
}
