# Aba Bolsa em pixel art

## Intenção
Uma aba visual e divertida: um escritório em pixel art, visto na diagonal (isométrico), em que cada mesa é uma ação. As mesas mostram as maiores altas e baixas do dia na bolsa brasileira. A pessoa abre para "ver o pregão" e volta no dia seguinte porque as mesas mudam.

## Objetivos
- Quarta aba "Bolsa", depois de Investimentos.
- 12 mesas: as 6 maiores altas e as 6 maiores baixas do dia entre ações com liquidez.
- Cada mesa: funcionário em pixel art, tela verde (alta) ou vermelha (baixa), etiqueta com código e variação.
- Tocar numa mesa abre um cartão com nome, preço, variação, volume e um atalho para a aba Investimentos.
- Atualiza ao abrir e ao puxar para baixo; mostra o horário da atualização.
- 5 idiomas, como o resto do app.

## Não objetivos
- Não é jogo de compra e venda.
- Não é recomendação de investimento (o mesmo aviso da aba Investimentos).
- Sem dados intradiários em tempo real; usa a variação do dia que a fonte entrega.

## Abordagens consideradas
1. Pixel art desenhada no código (SwiftUI Canvas): grátis e leve, bonecos mais simples.
2. Arte gerada no PixelLab e animada no app. **Escolhida pelo usuário.**
3. Misto. Descartada pela escolha acima.

## Decisões
- Arte original gerada no PixelLab (a referência é de um pacote pago e não é copiada): piso isométrico, mesa com monitor, funcionário comemorando e funcionário preocupado, plantas e decoração. Imagens incluídas no app.
- No código: cor da tela, etiqueta, leve animação (balanço do boneco, piscar da tela) e toque.
- Dados: a mesma fonte pública da aba Investimentos (brapi, lista de ações), filtrando pelas mais negociadas antes de escolher altas e baixas.

## Calls do construtor (podem ser corrigidas)
- Aba sem bloqueio Premium.
- Ícone da aba: prédio (building.2).
- Com mercado fechado, mostra o último pregão e avisa.
- Se não houver internet, mostra o escritório vazio com mensagem e botão de tentar de novo.
