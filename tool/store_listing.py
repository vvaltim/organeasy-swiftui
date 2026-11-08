import json
import os

SITE = 'https://organeasyfinancas.web.app'
LEGAL = {
    'pt-BR': ('Assinatura opcional para remover anúncios: cobrança anual pela conta Apple, com renovação automática, salvo cancelamento nos Ajustes com pelo menos 24 horas de antecedência.', 'Termos', 'Privacidade'),
    'en-US': ('Optional subscription to remove ads: billed yearly to your Apple account and renewed automatically unless canceled in Settings at least 24 hours in advance.', 'Terms', 'Privacy'),
    'es-ES': ('Suscripción opcional para eliminar anuncios: cobro anual en tu cuenta de Apple, con renovación automática salvo cancelación en Ajustes con al menos 24 horas de antelación.', 'Términos', 'Privacidad'),
    'fr-FR': ('Abonnement facultatif pour supprimer les publicités : facturé chaque année sur votre compte Apple et renouvelé automatiquement, sauf annulation dans Réglages au moins 24 heures à l’avance.', 'Conditions', 'Confidentialité'),
    'it': ('Abbonamento facoltativo per rimuovere la pubblicità: addebito annuale sull’account Apple con rinnovo automatico, salvo disdetta in Impostazioni con almeno 24 ore di anticipo.', 'Termini', 'Privacy'),
}
LISTINGS = {
    'pt-BR': {
        'name': 'OrganEasy: Contas e Finanças',
        'subtitle': 'Controle de gastos com IA',
        'keywords': 'orçamento,despesas,boleto,vencimento,salário,economizar,planilha,dinheiro,mensal,renda,pessoal',
        'promo': 'Conheça a Minha IA: analise o mês, converse sobre suas contas e veja quanto deve sobrar. Tudo roda no seu aparelho.',
        'description': """Saiba quanto entra, quanto sai e quanto deve sobrar no mês, sem planilha e sem conectar sua conta do banco.

O OrganEasy organiza suas contas por mês e reúne tudo o que vence em um só lugar.

MINHA IA
Uma aba feita para mostrar como está o seu mês:
• Previsão do saldo, com o que já foi pago e o que falta pagar
• Nota do mês, calculada com contas em dia e saldo
• Próximos vencimentos e contas atrasadas
• Gráfico dos últimos 6 meses e maiores gastos
• Análise do mês e chat sobre as suas contas

CONTAS DO MÊS
• Lançamentos de receitas e despesas por mês
• Marque contas como pagas com um gesto
• Recorrências para repetir as contas fixas
• Atalhos da Siri
• Sincronização pelo iCloud

SEUS DADOS SÃO SEUS
A inteligência roda no próprio aparelho. O app não pede acesso ao banco e não rastreia você.

A análise e o chat exigem um aparelho compatível com Apple Intelligence e, na versão grátis, são liberados com um vídeo. A aba Minha IA tem anúncios.""",
    },
    'en-US': {
        'name': 'OrganEasy: Bills & Budget AI',
        'subtitle': 'Expense tracker & money plan',
        'keywords': 'expenses,spending,planner,finance,personal,monthly,income,salary,savings,paycheck,due,ledger',
        'promo': 'Meet My AI: analyze your month, chat about your bills and see what should be left over. Everything runs on your device.',
        'description': """Know what comes in, what goes out and what should be left this month, with no spreadsheets and no bank login.

OrganEasy organizes your bills by month and keeps every due date in one place.

MY AI
A tab built to show how your month is going:
• Balance forecast, with what is paid and what is left to pay
• Monthly score based on bills on time and your balance
• Upcoming and overdue bills
• Six-month chart and top expenses
• Month analysis and chat about your bills

MONTHLY BILLS
• Income and expense entries by month
• Mark bills as paid with one swipe
• Recurring items for fixed bills
• Siri shortcuts
• iCloud sync

YOUR DATA IS YOURS
The AI runs on your device. The app never asks for bank access and does not track you.

Analysis and chat require an Apple Intelligence compatible device and, in the free version, are unlocked with a video. The My AI tab contains ads.""",
    },
    'es-ES': {
        'name': 'OrganEasy: Cuentas y Gastos',
        'subtitle': 'Control de finanzas con IA',
        'keywords': 'presupuesto,ahorro,dinero,facturas,vencimiento,personal,mensual,salario,ingresos,planificador',
        'promo': 'Conoce Mi IA: analiza tu mes, conversa sobre tus cuentas y mira cuánto debería sobrar. Todo funciona en tu dispositivo.',
        'description': """Sabe cuánto entra, cuánto sale y cuánto debería sobrar este mes, sin hojas de cálculo y sin conectar tu banco.

OrganEasy organiza tus cuentas por mes y reúne todos los vencimientos en un solo lugar.

MI IA
Una pestaña hecha para mostrar cómo va tu mes:
• Previsión del saldo, con lo pagado y lo que falta por pagar
• Nota del mes, según las cuentas al día y el saldo
• Próximos vencimientos y cuentas atrasadas
• Gráfico de los últimos 6 meses y mayores gastos
• Análisis del mes y chat sobre tus cuentas

CUENTAS DEL MES
• Ingresos y gastos por mes
• Marca cuentas como pagadas con un gesto
• Recurrencias para las cuentas fijas
• Atajos de Siri
• Sincronización con iCloud

TUS DATOS SON TUYOS
La inteligencia funciona en tu dispositivo. La app no pide acceso al banco y no te rastrea.

El análisis y el chat requieren un dispositivo compatible con Apple Intelligence y, en la versión gratuita, se desbloquean con un vídeo. La pestaña Mi IA contiene anuncios.""",
    },
    'fr-FR': {
        'name': 'OrganEasy: Budget et Factures',
        'subtitle': 'Suivi des dépenses avec IA',
        'keywords': 'finances,argent,comptes,épargne,mensuel,salaire,revenus,échéance,personnel,gestion,planificateur',
        'promo': 'Découvrez Mon IA : analysez votre mois, discutez de vos factures et voyez ce qu’il devrait rester. Tout fonctionne sur votre appareil.',
        'description': """Sachez ce qui entre, ce qui sort et ce qu’il devrait rester ce mois-ci, sans tableur et sans connecter votre banque.

OrganEasy organise vos factures par mois et réunit toutes vos échéances au même endroit.

MON IA
Un onglet conçu pour montrer où en est votre mois :
• Prévision du solde, avec ce qui est payé et ce qu’il reste à payer
• Note du mois, selon les factures à jour et le solde
• Prochaines échéances et factures en retard
• Graphique des 6 derniers mois et principales dépenses
• Analyse du mois et discussion sur vos factures

FACTURES DU MOIS
• Revenus et dépenses par mois
• Marquez les factures comme payées d’un geste
• Récurrences pour les factures fixes
• Raccourcis Siri
• Synchronisation iCloud

VOS DONNÉES VOUS APPARTIENNENT
L’intelligence fonctionne sur votre appareil. L’app ne demande pas d’accès à la banque et ne vous suit pas.

L’analyse et la discussion exigent un appareil compatible avec Apple Intelligence et, dans la version gratuite, se débloquent avec une vidéo. L’onglet Mon IA contient des publicités.""",
    },
    'it': {
        'name': 'OrganEasy: Spese e Bollette',
        'subtitle': 'Budget del mese con IA',
        'keywords': 'finanze,soldi,risparmio,conti,mensile,stipendio,entrate,scadenze,personale,gestione,pianificatore',
        'promo': 'Scopri La mia IA: analizza il mese, parla delle tue bollette e vedi quanto dovrebbe avanzare. Tutto funziona sul tuo dispositivo.',
        'description': """Scopri quanto entra, quanto esce e quanto dovrebbe avanzare questo mese, senza fogli di calcolo e senza collegare la banca.

OrganEasy organizza le bollette per mese e riunisce tutte le scadenze in un unico posto.

LA MIA IA
Una scheda pensata per mostrare come va il tuo mese:
• Previsione del saldo, con ciò che è pagato e ciò che resta da pagare
• Voto del mese, in base alle bollette puntuali e al saldo
• Prossime scadenze e bollette in ritardo
• Grafico degli ultimi 6 mesi e spese maggiori
• Analisi del mese e chat sulle tue bollette

BOLLETTE DEL MESE
• Entrate e uscite per mese
• Segna le bollette come pagate con un gesto
• Ricorrenze per le spese fisse
• Comandi rapidi di Siri
• Sincronizzazione iCloud

I TUOI DATI SONO TUOI
L’intelligenza funziona sul tuo dispositivo. L’app non chiede l’accesso alla banca e non ti traccia.

Analisi e chat richiedono un dispositivo compatibile con Apple Intelligence e, nella versione gratuita, si sbloccano con un video. La scheda La mia IA contiene pubblicità.""",
    },
}
LIMITS = {'name': 30, 'subtitle': 30, 'keywords': 100, 'promo': 170, 'description': 4000}

lines = [f'support_url: {SITE}/suporte', f'marketing_url: {SITE}', f'privacy_url: {SITE}/privacidade', '']
for locale, item in LISTINGS.items():
    legal, terms, privacy = LEGAL[locale]
    item['description'] = f"{item['description']}\n\n{legal}\n{terms}: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/\n{privacy}: {SITE}/privacidade"
    for field, limit in LIMITS.items():
        assert len(item[field]) <= limit, (locale, field, len(item[field]))
    words = item['keywords'].split(',')
    assert len(words) == len(set(words)), locale
    name_words = {w.strip(':&').lower() for w in (item['name'] + ' ' + item['subtitle']).split()}
    repeated = name_words & set(words)
    assert not repeated, (locale, repeated)
    lines += [f'===== {locale} =====', *(f"{f} ({len(item[f])}/{LIMITS[f]}): {item[f]}" for f in LIMITS), '']

os.makedirs('publicacao', exist_ok=True)
open('publicacao/FICHA_APP_STORE.txt', 'w').write('\n'.join(lines))
json.dump(LISTINGS, open('publicacao/ficha.json', 'w'), ensure_ascii=False, indent=2)
print('ok')
