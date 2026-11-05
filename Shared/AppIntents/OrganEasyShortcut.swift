import AppIntents

struct OrganEasyShortcut: AppShortcutsProvider {
    
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddMonthlyEntryIntent(),
            phrases: [
                "Adicionar uma conta no \(.applicationName)",
                "Criar uma conta no \(.applicationName)"
            ],
            shortTitle: "Nova conta",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: FindBillsIntent(),
            phrases: [
                "Consultar minhas contas no \(.applicationName)",
                "Ver minhas contas no \(.applicationName)"
            ],
            shortTitle: "Consultar contas",
            systemImageName: "magnifyingglass"
        )
    }
    
}
