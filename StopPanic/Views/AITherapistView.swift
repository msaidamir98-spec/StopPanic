import SwiftUI

/// Экран AI-терапевта
struct AITherapistView: View {
    // MARK: Internal

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                messagesScroll
                inputBar
            }
        }
    }

    // MARK: Private

    @StateObject
    private var therapist = AITherapistService()
    @State
    private var inputText = ""
    @FocusState
    private var isInputFocused: Bool

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Терапевт")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Circle().fill(.green).frame(width: 8, height: 8)
                    Text("Онлайн 24/7")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
            Button {
                Task { await therapist.emergencyMode() }
            } label: {
                Text("🆘 SOS")
                    .font(.headline)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(AppTheme.danger)
                    .clipShape(Capsule())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(AppTheme.card.opacity(0.9))
    }

    // MARK: - Messages

    private var messagesScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(therapist.messages) { msg in
                        messageBubble(msg).id(msg.id)
                    }
                    if therapist.isTyping { typingDots }
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }
            .onChange(of: therapist.messages.count) {
                withAnimation {
                    proxy.scrollTo(therapist.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    private var typingDots: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    Circle()
                        .fill(AppTheme.primary)
                        .frame(width: 8, height: 8)
                        .opacity(0.6)
                }
            }
            .padding(12)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Как вы себя чувствуете...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .foregroundColor(.white)
                .focused($isInputFocused)
            Button {
                guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                let text = inputText
                inputText = ""
                Task { await therapist.sendMessage(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(inputText.isEmpty ? .gray : AppTheme.primary)
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(AppTheme.card.opacity(0.95))
    }

    private func messageBubble(_ msg: AIMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer() }
            VStack(alignment: msg.role == .user ? .trailing : .leading, spacing: 4) {
                if let t = msg.technique {
                    Text(t.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(AppTheme.primary.opacity(0.3))
                        .clipShape(Capsule())
                        .foregroundColor(AppTheme.primary)
                }
                Text(LocalizedStringKey(msg.content))
                    .padding(12)
                    .background(msg.role == .user
                        ? AppTheme.primary.opacity(0.25)
                        : AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundColor(.white)
                Text(msg.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(
                maxWidth: 300,
                alignment: msg.role == .user ? .trailing : .leading
            )
            if msg.role == .assistant { Spacer() }
        }
    }
}

#Preview { AITherapistView() }
