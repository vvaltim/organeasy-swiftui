//
//  OrganEasyApp.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

@main
struct OrganEasyApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabBar()
                .accentColor(.indigo)
                .environment(\.locale, Locale(identifier: "pt_BR"))
        }
    }
}

/**
 
 Descrição do Ícone para o OrganEasy
 Formato: Quadrado, sem cantos arredondados (o iOS aplica o arredondamento automaticamente).
 Cor de fundo: Indigo (#4B0082 ou use .indigo do SwiftUI como referência).
 Elemento central: Um gráfico de barras simples (remetendo à lib Charts e ao controle financeiro), com barras de diferentes alturas, em branco ou tons claros.
 Elemento secundário: Um símbolo de cifrão ($) ou uma moeda estilizada, sobrepondo parcialmente o gráfico, para reforçar a ideia de finanças.
 Estilo: Flat, minimalista, sem sombras ou gradientes pesados, para combinar com o visual do SwiftUI.
 Detalhe opcional: Um pequeno “check” ou círculo indicando organização/conclusão, em um canto do ícone.
 
 **/
