import Foundation

enum ShowcaseMode {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-showcase")
        #else
        false
        #endif
    }

    static var forcesAICard: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-forceAICard")
        #else
        false
        #endif
    }

    static var importFilePath: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "importFile")
        #else
        nil
        #endif
    }

    static var forcesPremium: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-forcePremium")
        #else
        false
        #endif
    }

    static var resetsPromotion: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-resetPromotion")
        #else
        false
        #endif
    }
}
