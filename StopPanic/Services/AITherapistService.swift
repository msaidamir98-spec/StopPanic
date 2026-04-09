import Combine
import Foundation

/// AI-терапевт, специализированный на панических атаках
/// Использует научно обоснованные техники CBT, ACT, DBT
@MainActor
final class AITherapistService: ObservableObject {
    // MARK: Lifecycle

    init() {
        let welcome = AIMessage(
            content:
            "Привет! Я твой AI-помощник в борьбе с паникой. 💙" +
                "\n\nИспользую техники CBT, ACT и DBT. Как ты себя чувствуешь?",
            role: .assistant
        )
        messages.append(welcome)
    }

    // MARK: Internal

    @Published
    var messages: [AIMessage] = []
    @Published
    var isTyping: Bool = false

    func sendMessage(_ text: String) async {
        messages.append(AIMessage(content: text, role: .user))
        trimMessagesIfNeeded()
        isTyping = true

        let technique = analyzeTechnique(for: text)
        let response = await generateResponse(for: text, technique: technique)

        messages.append(AIMessage(content: response, role: .assistant, technique: technique))
        isTyping = false
    }

    func emergencyMode() async {
        messages.append(AIMessage(content: "🆘 ЭКСТРЕННАЯ ПОМОЩЬ", role: .user))
        isTyping = true
        try? await Task.sleep(nanoseconds: 500_000_000)

        let response = """
        🔴 **Я здесь. Ты в безопасности.**

        Паническая атака — это НЕ опасно. Она пройдёт.

        **Техника 5-4-3-2-1:**
        👁️ **5** вещей, которые ты ВИДИШЬ
        ✋ **4** вещи, которые можешь ПОТРОГАТЬ
        👂 **3** звука, которые СЛЫШИШЬ
        👃 **2** запаха
        👅 **1** вкус

        Начни — назови 5 вещей, которые видишь.
        """
        messages.append(AIMessage(content: response, role: .assistant, technique: .grounding))
        isTyping = false
    }

    // MARK: Private

    /// Keep message history manageable — retain first (welcome) + last 50 messages
    private func trimMessagesIfNeeded() {
        let maxMessages = 50
        guard messages.count > maxMessages + 1 else { return }
        let welcome = messages[0]
        messages = [welcome] + messages.suffix(maxMessages)
    }

    private func analyzeTechnique(for text: String) -> AIMessage.TherapyTechnique {
        let t = text.lowercased()
        if t.contains("паник") || t.contains("умира") || t.contains("не могу дышать") {
            return .grounding
        }
        if t.contains("мысл") || t.contains("дума") || t.contains("кажется") { return .cbt }
        if t.contains("бою") || t.contains("страх") || t.contains("тревог") { return .act }
        if t.contains("дыш") || t.contains("вдох") { return .breathwork }
        return .cbt
    }

    private func generateResponse(for text: String, technique: AIMessage.TherapyTechnique?) async
        -> String
    {
        try? await Task.sleep(nanoseconds: UInt64.random(in: 800_000_000 ... 1_500_000_000))

        switch technique {
        case .grounding:
            return
                "Я понимаю, что страшно. Но ты в безопасности. 💙" +
                "\n\nДавай заземлимся: назови **5 вещей**, которые видишь прямо сейчас."
        case .cbt:
            return
                "Давай разберём эту мысль 🧠\n\nКогнитивные искажения:" +
                "\n• **Катастрофизация** — «Случится худшее!»" +
                "\n• **Чёрно-белое мышление** — «Если не идеально — ужасно»" +
                "\n\nКакое ближе к твоей ситуации?"
        case .act:
            return
                "Страх — нормальная эмоция. 🌊" +
                "\n\nПредставь тревогу как волну:" +
                " она приходит, поднимается и обязательно уходит." +
                "\n\n**Ты не волна. Ты — океан.**"
        case .breathwork:
            return
                "Страх — нормальная эмоция. 🌊" +
                "\n\nПредставь тревогу как волну:" +
                " она приходит, поднимается и обязательно уходит." +
                "\n\n**Ты не волна. Ты — океан.**"
        default:
            return
                "Спасибо, что делишься. 💙" +
                " Расскажи подробнее — чем больше я знаю, тем точнее помогу."
        }
    }
}
