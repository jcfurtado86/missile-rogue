# Missile Rogue

Roguelite mobile vertical. Defesa de cidades contra misseis com progressao permanente e sistema de ascensao (prestige).

## Pilares do Design

1. **Dificuldade intencional** — jogo base inviavel sem upgrades. Isso e o design, nao um bug.
2. **Progressao em ciclos** — comprar upgrades > chegar mais longe > acumular mais > repetir.
3. **Custo exponencial** — upgrades ficam progressivamente caros, tornando ascensao o caminho eficiente.
4. **Proporcionalidade direta** — % de upgrades comprados = ate onde o jogador chega.
5. **Escalada organica** — sem timer fixo, dificuldade responde ao desempenho.
6. **Ads respeitosos** — nunca forcados, sempre escolha do jogador.

## Planejamento de Implementacao (MVP 1.0)

### Fase 1 — Core Loop Minimo
- [ ] Tela de jogo vertical com area de toque
- [ ] 3 cidades + 3 baterias na base
- [ ] Sistema de disparo: toque > missil voa > explode em area
- [ ] Missil Basico inimigo (trajetoria reta, velocidade variavel)
- [ ] Deteccao de colisao: explosao vs inimigo, inimigo vs cidade
- [ ] Condicao de derrota: todas as cidades destruidas
- [ ] Drop de Creditos ao destruir inimigo

### Fase 2 — Escalada Dinamica
- [ ] Nivel de Ameaca (indice interno, 0-100)
- [ ] Contribuicao por tempo vivo (passiva, lenta)
- [ ] Contribuicao por inimigos destruidos (ativa, rapida)
- [ ] Spawn rate e velocidade escalam com Ameaca
- [ ] Marcos de Ameaca: 0, 10, 25, 50, 75, 90, 100

### Fase 3 — Inimigos
- [ ] Missil Basico: trajetoria reta, drop CR, visual rosa/vermelho
- [ ] Missil Rapido: ziguezague, drop CS, visual ciano, aparece Ameaca 50+
- [ ] Missil Cluster: lento, explode em 3-5 fragmentos, drop VO por fragmento, visual roxo, aparece Ameaca 75+
- [ ] Distribuicao de spawn por faixa de Ameaca (tabela do GDD)

### Fase 4 — Economia e Loja
- [ ] 4 moedas: Credito, Cristal, Void, Eter
- [ ] Carteira persistente entre runs (CR/CS/VO resetam na ascensao, Eter nunca)
- [ ] Loja com Tiers desbloqueados progressivamente
- [ ] Custo exponencial (curva do GDD)
- [ ] Tier 1: 12 upgrades (Creditos)
- [ ] Tier 2: 8 upgrades (Cristais)
- [ ] Aplicacao dos efeitos de cada upgrade no gameplay

### Fase 5 — Especial (Nova Bomb)
- [ ] Barra de carga no HUD (carrega ao destruir inimigos)
- [ ] Botao dedicado acessivel pelo polegar
- [ ] Explosao que destroi todos os inimigos visiveis
- [ ] Upgrades que modificam o especial (Tier 2 e 3)

### Fase 6 — Boss Overlord
- [ ] Aparece em Ameaca 100 (spawns normais cessam)
- [ ] Movimento horizontal no topo
- [ ] Rajadas em leque
- [ ] Rage mode abaixo de 40% HP
- [ ] Calibrado para exigir 100% dos upgrades
- [ ] Vitoria ao derrotar

### Fase 7 — Sistema de Ascensao
- [ ] Tela de ascensao com breakdown de moedas investidas
- [ ] Calculo de Eter: total investido / fator de conversao
- [ ] Reset de Tiers 1-3 e moedas de run
- [ ] Eter acumula permanentemente
- [ ] Tier 4: 4 upgrades permanentes (Eter)
- [ ] Contador de ascensoes

### Fase 8 — HUD e Interface
- [ ] Score + barra de Ameaca (topo)
- [ ] Carteira de moedas em tempo real (topo direito)
- [ ] HP do Boss quando ativo (topo)
- [ ] Indicador de municao nas baterias (base)
- [ ] Barra especial + botao Nova Bomb (base esquerda)
- [ ] Indicador de combo (base direita)
- [ ] Feedback visual: animacao de moeda ao matar inimigo

### Fase 9 — Monetizacao (Ads Voluntarios)
- [ ] Reviver apos game over (1x por run)
- [ ] Dobrar creditos da run (na loja)
- [ ] Max 2 ofertas de ad por sessao de loja
- [ ] Botao de recusar sempre visivel

### Fase 10 — Persistencia
- [ ] Save local com progresso permanente
- [ ] Eter, upgrades Tier 4, contador de ascensoes, historico

## Tabelas de Referencia Rapida

### Ameaca vs Spawn
| Ameaca | Basico | Rapido | Cluster |
|--------|--------|--------|---------|
| 0-49   | 100%   | -      | -       |
| 50-74  | 65%    | 35%    | -       |
| 75-99  | 55%    | 30%    | 15%     |
| 100    | -      | -      | Boss    |

### Custo Exponencial (Creditos, exemplo)
| Nivel | Custo | Acumulado |
|-------|-------|-----------|
| 1     | 50    | 50        |
| 2     | 120   | 170       |
| 3     | 300   | 470       |
| 4     | 750   | 1.220     |
| 5     | 2.000 | 3.220     |
| 6     | 6.000 | 9.220     |

### Conversao Eter
Total investido nos Tiers 1-3 / 200 = Eter ganho na ascensao
