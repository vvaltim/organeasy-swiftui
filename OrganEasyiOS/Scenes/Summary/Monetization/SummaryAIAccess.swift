import Combine
import Foundation

/// Um vídeo premiado libera a IA por 30 minutos. Assinantes têm acesso direto.
@MainActor
final class SummaryAIAccess: ObservableObject {
    static let shared = SummaryAIAccess()

    private enum Constants {
        static let unlockDuration: TimeInterval = 30 * 60
    }

    @Published private(set) var unlockedUntil: Date?
    @Published private(set) var isLoadingVideo = false
    @Published private(set) var wasVideoDismissed = false

    var isUnlocked: Bool {
        if ShowcaseMode.isEnabled { return true }
        guard let unlockedUntil else { return false }
        return unlockedUntil > .now
    }

    /// Com acesso, age na hora. Sem acesso, o vídeo vem antes da mesma ação.
    func perform(hasAccess: Bool, action: @escaping @MainActor () -> Void) {
        guard !hasAccess else {
            action()
            return
        }

        Task {
            await watchVideo()
            if isUnlocked { action() }
        }
    }

    func watchVideo() async {
        guard !isLoadingVideo else { return }
        isLoadingVideo = true
        wasVideoDismissed = false
        defer { isLoadingVideo = false }

        switch await AdsCoordinator.shared.presentRewarded() {
        case .earned, .unavailable:
            // Sem vídeo disponível, o usuário não fica bloqueado por falha do anúncio.
            unlockedUntil = Date.now.addingTimeInterval(Constants.unlockDuration)
        case .dismissed:
            wasVideoDismissed = true
        }
    }
}
