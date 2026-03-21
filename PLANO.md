# Missile Rogue — Plano de Execucao MVP 1.0

## Stack
- **Engine:** Godot 4.4 + GDScript
- **Testes:** GdUnit4 (TDD — red/green/refactor)
- **Ads:** GodotAdMob (Poing Studios)
- **Plataformas:** iOS + Android

## Abordagem TDD
Cada fase segue o ciclo:
1. **RED** — escrever testes primeiro (logica pura em classes RefCounted)
2. **GREEN** — implementar logica pra passar os testes
3. **REFACTOR** — integrar com nodes/cenas no Godot

Separacao: logica pura em `systems/` (testavel), apresentacao em `entities/` e `scenes/` (fino, delega pra systems).

---

## Fase 1 — Tela Jogavel + Disparo [CONCLUIDA]

### Implementacao
- Tela vertical 1080x1920, fundo escuro
- 3 baterias na base (triangulos azuis com _draw)
- Toque na tela > missil voa ate o ponto > explode em area circular
- Municao limitada (10) com recarga automatica (3s)
- Selecao automatica da bateria mais proxima do toque

### Arquivos
- `project.godot` — resolucao, stretch, main scene
- `scenes/main.tscn` + `scenes/main.gd` — gerenciador de cenas
- `scenes/game/game.tscn` + `scenes/game/game.gd` — gameplay, input, instancia baterias
- `entities/battery/battery.tscn` + `entities/battery/battery.gd` — municao, disparo, visual
- `entities/missiles/player_missile.tscn` + `entities/missiles/player_missile.gd` — voo, explosao

---

## Fase 1.5 — Setup TDD + Refactor [ATUAL]

### Implementacao
- Instalar GdUnit4 (AssetLib ou manual)
- Extrair logica pura das entidades da Fase 1 pra classes RefCounted
- Refatorar entidades pra delegar logica pros systems
- Escrever testes retroativos

### Arquivos — Classes puras
- `systems/battery_data.gd` — municao, recarga (RefCounted)
- `systems/missile_data.gd` — movimento, chegada (RefCounted)
- `systems/battery_selector.gd` — selecao por proximidade (RefCounted)

### Arquivos — Refatorar
- `entities/battery/battery.gd` — usar BatteryData
- `entities/missiles/player_missile.gd` — usar MissileData
- `scenes/game/game.gd` — usar BatterySelector

### Arquivos — Testes
- `test/entities/battery_test.gd`
- `test/entities/player_missile_test.gd`
- `test/systems/battery_selector_test.gd`

### Testes (11)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 1 | battery_test | test_initial_ammo_equals_max | Bateria comeca com municao cheia |
| 2 | battery_test | test_can_fire_when_has_ammo | can_fire() true com municao |
| 3 | battery_test | test_cannot_fire_when_empty | can_fire() false sem municao |
| 4 | battery_test | test_consume_ammo_decrements | Disparo reduz municao em 1 |
| 5 | battery_test | test_reload_restores_ammo | Recarga restaura ao maximo |
| 6 | missile_test | test_calculate_step_moves_toward_target | Passo move na direcao correta |
| 7 | missile_test | test_has_arrived_when_close_enough | Detecta chegada ao destino |
| 8 | missile_test | test_has_arrived_false_when_far | Nao marca chegada quando distante |
| 9 | selector_test | test_selects_closest_battery | Escolhe bateria mais proxima |
| 10 | selector_test | test_skips_empty_battery | Ignora baterias sem municao |
| 11 | selector_test | test_returns_neg_one_when_all_empty | Retorna -1 quando todas vazias |

---

## Fase 2 — Cidades + Condicao de Derrota

### Implementacao
- 3 cidades na base da tela (entre as baterias)
- Cidade e Area2D que detecta colisao com inimigo
- Ao ser atingida: cidade morre (visual muda, para de colidir)
- Todas as cidades mortas = game over (run termina)
- Cidade destruida ignora hits adicionais

### Arquivos
- `systems/city_data.gd` — estado alive/dead, take_hit, all_dead (RefCounted)
- `entities/city/city.tscn` + `entities/city/city.gd` — visual, colisao, usa CityData
- `scenes/game/game.gd` — instancia 3 cidades, monitora game over
- `test/entities/city_test.gd`

### Testes (4)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 12 | city_test | test_city_starts_alive | Cidade comeca viva |
| 13 | city_test | test_city_dies_on_hit | take_hit() mata a cidade |
| 14 | city_test | test_destroyed_city_ignores_further_hits | Hit em cidade morta nao causa erro |
| 15 | city_test | test_all_cities_dead_returns_true | all_dead() retorna true quando todas mortas |

---

## Fase 3 — Missil Basico Inimigo + Ameaca

### Implementacao
- Missil Basico desce do topo em linha reta ate cidade aleatoria
- Velocidade e quantidade escalam com Nivel de Ameaca
- Explosao do jogador destroi inimigo (colisao area vs area)
- Inimigo atinge cidade: cidade morre
- Nivel de Ameaca (0-100): sobe por tempo vivo (lento) + abates (rapido)
- Spawn system instancia inimigos no topo em posicoes aleatorias

### Arquivos
- `systems/enemy_data.gd` — tipo, velocidade, moeda de drop (RefCounted)
- `systems/threat_system.gd` — nivel 0-100, update por tempo/kill (RefCounted)
- `systems/spawn_system.gd` — intervalo, distribuicao por ameaca (RefCounted)
- `entities/missiles/basic_enemy.tscn` + `entities/missiles/basic_enemy.gd` — Area2D, movimento, colisao
- `scenes/game/game.gd` — conecta spawn, threat, colisoes
- `test/entities/basic_enemy_test.gd`
- `test/systems/threat_system_test.gd`
- `test/systems/spawn_system_test.gd`

### Testes (13)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 16 | enemy_test | test_basic_enemy_moves_toward_target | Inimigo se move em direcao a cidade-alvo |
| 17 | enemy_test | test_basic_enemy_speed_configurable | Velocidade pode ser configurada |
| 18 | enemy_test | test_basic_enemy_drops_credit | Drop e do tipo credito |
| 19 | threat_test | test_threat_starts_at_zero | Ameaca comeca em 0 |
| 20 | threat_test | test_threat_increases_over_time | Ameaca sobe passivamente com tempo |
| 21 | threat_test | test_threat_increases_on_kill | Ameaca sobe ao matar inimigo |
| 22 | threat_test | test_threat_caps_at_100 | Ameaca nunca passa de 100 |
| 23 | threat_test | test_kill_increases_faster_than_time | Contribuicao ativa > passiva |
| 24 | spawn_test | test_only_basic_below_50 | Abaixo de 50: 100% basico |
| 25 | spawn_test | test_fast_appears_at_50 | A partir de 50: basico + rapido |
| 26 | spawn_test | test_cluster_appears_at_75 | A partir de 75: basico + rapido + cluster |
| 27 | spawn_test | test_boss_at_100 | Ameaca 100: boss, sem spawns normais |
| 28 | spawn_test | test_spawn_interval_decreases_with_threat | Intervalo diminui conforme ameaca sobe |

---

## Fase 4 — Economia (Moedas)

### Implementacao
- 4 moedas: Credito (CR), Cristal (CS), Void (VO), Eter
- Carteira acumula durante a run
- Matar inimigo basico dropa 1 CR automaticamente
- CR, CS, VO resetam na ascensao; Eter nunca reseta
- Metodos: add, spend, get, reset_run_currencies

### Arquivos
- `systems/currency_system.gd` — carteira, 4 moedas (RefCounted)
- `scenes/game/game.gd` — ao destruir inimigo, chama currency.add()
- `test/systems/currency_system_test.gd`

### Testes (7)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 29 | currency_test | test_wallet_starts_empty | Todas as moedas comecam em 0 |
| 30 | currency_test | test_add_credits | add("credits", 50) soma corretamente |
| 31 | currency_test | test_add_crystals | add("crystals", 10) soma corretamente |
| 32 | currency_test | test_add_void | add("void", 5) soma corretamente |
| 33 | currency_test | test_spend_deducts | spend() deduz o valor |
| 34 | currency_test | test_spend_fails_without_funds | spend() retorna false sem saldo |
| 35 | currency_test | test_reset_run_currencies_keeps_eter | Reset zera CR/CS/VO mas mantem Eter |

---

## Fase 5 — HUD Minimo

### Implementacao
- CanvasLayer sobreposto ao gameplay
- Barra de Ameaca (topo)
- Moedas da run em tempo real (topo direito)
- Indicador de municao nas baterias (base)
- Sem testes unitarios (UI pura, testado visualmente)

### Arquivos
- `scenes/game/hud.tscn` + `scenes/game/hud.gd` — labels, barras, conexao com systems
- `scenes/game/game.tscn` — adiciona HUD como filho

### Testes
Nenhum — fase de UI pura, validada visualmente no Godot.

---

## Fase 6 — Loja + Upgrades Tier 1

### Implementacao
- Fluxo: game over > tela de loja > compra upgrades > nova run
- 12 upgrades Tier 1 com custo exponencial (curva do GDD)
- Efeitos aplicados no gameplay: +municao, +velocidade, +raio, +creditos, etc
- Tier 1 completo: AMMO PACK, HYPER DRIVE, WARHEAD+, PROFIT MATRIX, OVERCHARGE, HEAD START, TIME WARP, CHAIN REACTION, TRIPLE BURST, OVERDRIVE, EARLY WARNING, CITY SHIELD
- Custo: base * multiplicador ^ nivel

### Arquivos
- `systems/upgrade_system.gd` — todos os upgrades, custo exponencial, efeitos (RefCounted)
- `scenes/shop/shop.tscn` + `scenes/shop/shop.gd` — UI da loja, lista upgrades, botao comprar
- `scenes/main.gd` — fluxo game over > shop > nova run
- `test/systems/upgrade_system_test.gd`
- `test/balance/cost_curve_test.gd`

### Testes (14)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 36 | upgrade_test | test_upgrade_starts_at_level_zero | Todo upgrade comeca nivel 0 |
| 37 | upgrade_test | test_cost_exponential_level_1 | Custo nivel 1 = base_cost |
| 38 | upgrade_test | test_cost_exponential_level_6 | Custo nivel 6 segue curva exponencial |
| 39 | upgrade_test | test_buy_increments_level | Comprar sobe nivel em 1 |
| 40 | upgrade_test | test_buy_deducts_currency | Comprar deduz moeda correta |
| 41 | upgrade_test | test_buy_fails_without_funds | Compra falha sem saldo |
| 42 | upgrade_test | test_buy_fails_at_max_level | Compra falha no nivel maximo |
| 43 | upgrade_test | test_ammo_pack_effect | AMMO PACK: +8 municao por nivel |
| 44 | upgrade_test | test_hyper_drive_effect | HYPER DRIVE: +8% velocidade por nivel |
| 45 | upgrade_test | test_warhead_effect | WARHEAD+: +8% raio por nivel |
| 46 | upgrade_test | test_profit_matrix_effect | PROFIT MATRIX: +8% creditos por nivel |
| 47 | upgrade_test | test_get_total_invested | Total investido soma tudo gasto |
| 48 | cost_test | test_credit_cost_matches_gdd_table | Custos conferem: 50, 120, 300, 750, 2000, 6000 |
| 49 | cost_test | test_accumulated_cost_matches_gdd | Acumulados conferem: 50, 170, 470, 1220, 3220, 9220 |

**Marco: core loop roguelite completo** — morre > loja > compra > nova run mais forte

---

## Fase 7 — Inimigos Tier 2 e 3

### Implementacao

- Distribuicao de spawn por faixa de ameaca (tabela GDD)
- Upgrades Tier 2 (8 upgrades, Cristais) e Tier 3 (6 upgrades, Void)
- Desbloqueio de Tier ao matar primeiro inimigo do tipo

### Arquivos
- `entities/missiles/fast_enemy.tscn` + `entities/missiles/fast_enemy.gd` — ziguezague, trail ciano
- `entities/missiles/cluster_enemy.tscn` + `entities/missiles/cluster_enemy.gd` — lento, spawna fragmentos
- `entities/missiles/cluster_fragment.tscn` + `entities/missiles/cluster_fragment.gd` — fragmento divergente
- `systems/enemy_data.gd` — adicionar configs FAST e CLUSTER
- `systems/spawn_system.gd` — distribuicao por faixa
- `systems/upgrade_system.gd` — adicionar Tier 2 e Tier 3
- `test/entities/fast_enemy_test.gd`
- `test/entities/cluster_enemy_test.gd`
- `test/balance/spawn_distribution_test.gd`

### Testes (9)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 50 | fast_test | test_fast_enemy_has_higher_speed | Rapido e mais veloz que basico |
| 51 | fast_test | test_fast_enemy_drops_crystal | Drop e do tipo cristal |
| 52 | fast_test | test_fast_enemy_zigzag_offset | Movimento tem offset lateral (ziguezague) |
| 53 | cluster_test | test_cluster_has_lower_speed | Cluster e mais lento que basico |
| 54 | cluster_test | test_cluster_fragments_between_3_and_5 | Fragmentos gerados: 3 a 5 |
| 55 | cluster_test | test_each_fragment_drops_void | Cada fragmento dropa 1 Void |
| 56 | cluster_test | test_cluster_drops_nothing_directly | Cluster em si nao dropa nada |
| 57 | distribution_test | test_distribution_0_49_matches_gdd | 0-49: 100% basico |
| 58 | distribution_test | test_distribution_75_99_matches_gdd | 75-99: 55% basico, 30% rapido, 15% cluster |

---

## Fase 8 — Especial (Nova Bomb)

### Implementacao
- Barra de carga (0-100%) visivel no HUD
- Carrega ao destruir inimigos
- Botao dedicado na base esquerda, acessivel pelo polegar
- Ativacao: explosao que destroi todos os inimigos visiveis
- Upgrades Void modificam: raio, freeze, campo gravitacional

### Arquivos
- `systems/special_system.gd` — carga, ativacao, reset (RefCounted)
- `scenes/game/hud.gd` — barra de carga + botao Nova Bomb
- `scenes/game/game.gd` — conecta special_system
- `test/systems/special_system_test.gd`

### Testes (5)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 59 | special_test | test_charge_starts_at_zero | Carga comeca em 0 |
| 60 | special_test | test_charge_increases_on_kill | Matar inimigo carrega a barra |
| 61 | special_test | test_charge_caps_at_100 | Carga nao passa de 100 |
| 62 | special_test | test_activate_requires_full_charge | Ativacao so funciona com carga cheia |
| 63 | special_test | test_activate_resets_charge | Apos ativar, carga volta pra 0 |

---

## Fase 9 — Boss Overlord

### Implementacao
- Aparece quando Ameaca atinge 100 (spawns normais cessam)
- Movimento horizontal no topo da tela
- Atira rajadas em leque
- Rage mode abaixo de 40% HP (mais agressivo)
- HP calibrado pra exigir 100% dos upgrades
- Derrotar = vitoria, encerra a run

### Arquivos
- `entities/boss/overlord.tscn` + `entities/boss/overlord.gd` — movimento, rajadas, rage, HP
- `systems/enemy_data.gd` — config BOSS
- `scenes/game/game.gd` — spawn boss em Ameaca 100, condicao de vitoria
- `test/entities/boss_test.gd`

### Testes (5)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 64 | boss_test | test_boss_starts_with_full_hp | Boss comeca com HP maximo |
| 65 | boss_test | test_boss_takes_damage | Explosao reduz HP do boss |
| 66 | boss_test | test_boss_rage_mode_below_40_percent | Abaixo de 40% HP ativa rage |
| 67 | boss_test | test_boss_defeat_at_zero_hp | HP 0 = boss derrotado |
| 68 | boss_test | test_boss_hp_requires_full_upgrades | DPS com 100% upgrades > DPS necessario pra matar |

---

## Fase 10 — Sistema de Ascensao

### Implementacao
- Prestige voluntario: jogador escolhe ascender
- Reset: upgrades Tier 1-3 voltam pra nivel 0, moedas de run (CR/CS/VO) zeram
- Ganho: Eter = total investido nos Tiers 1-3 / 200
- Eter acumula permanentemente, nunca reseta
- Tier 4: 4 upgrades permanentes (ASCENDANT CORE, VOID RESONANCE, ETERNAL CITY, OMEGA PROTOCOL)
- Contador de ascensoes

### Arquivos
- `systems/ascension_system.gd` — calculo eter, reset, contador (RefCounted)
- `systems/upgrade_system.gd` — adicionar Tier 4, metodo reset_tiers()
- `scenes/ascension/ascension.tscn` + `scenes/ascension/ascension.gd` — tela de ascensao
- `scenes/shop/shop.gd` — botao de ascensao
- `test/systems/ascension_system_test.gd`

### Testes (7)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 69 | ascension_test | test_eter_calculation_500_invested | 500 / 200 = 2 Eter |
| 70 | ascension_test | test_eter_calculation_8000_invested | 8000 / 200 = 40 Eter |
| 71 | ascension_test | test_ascension_resets_tiers_1_2_3 | Todos os upgrades T1-T3 voltam pra 0 |
| 72 | ascension_test | test_ascension_resets_run_currencies | CR, CS, VO zerados |
| 73 | ascension_test | test_eter_accumulates_across_ascensions | Eter de multiplas ascensoes soma |
| 74 | ascension_test | test_tier4_survives_ascension | Upgrades Tier 4 nao resetam |
| 75 | ascension_test | test_ascension_counter_increments | Contador sobe 1 a cada ascensao |

---

## Fase 11 — Persistencia

### Implementacao
- Save local em JSON (user://)
- Salva: Eter, upgrades Tier 4, contador de ascensoes, desbloqueios de tier
- Carrega ao abrir o jogo
- Trata arquivo corrompido ou ausente com defaults

### Arquivos
- `systems/save_system.gd` — to_dict, from_dict, save_to_file, load_from_file (RefCounted)
- `scenes/main.gd` — carrega save ao iniciar
- `test/systems/save_system_test.gd`

### Testes (4)

| # | Arquivo | Teste | Valida |
|---|---------|-------|--------|
| 76 | save_test | test_save_and_load_roundtrip | Salvar e carregar retorna mesmos dados |
| 77 | save_test | test_load_missing_file_returns_defaults | Arquivo inexistente retorna valores padrao |
| 78 | save_test | test_corrupted_data_returns_defaults | JSON invalido retorna valores padrao |
| 79 | save_test | test_eter_persists | Eter permanece entre save/load |

---

## Fase 12 — Ads Voluntarios

### Implementacao
- Reviver apos game over: 1 ad = continua run com 1 cidade revivida (max 1x por run)
- Dobrar creditos da run: 1 ad na loja
- Max 2 ofertas de ad por sessao de loja
- Botao de recusar sempre visivel
- GodotAdMob wrapper pra rewarded ads

### Arquivos
- `systems/ad_system.gd` — wrapper GodotAdMob, controle de limites
- `scenes/game/game.gd` — oferta de reviver pos game over
- `scenes/shop/shop.gd` — oferta de dobrar creditos

### Testes
Nenhum — depende de SDK externo (GodotAdMob). Testado manualmente em builds de device.

---

## Balanceamento (transversal)

### Arquivos
- `test/balance/cost_curve_test.gd`
- `test/balance/threat_scaling_test.gd`
- `test/balance/spawn_distribution_test.gd`

### Testes (ja contados nas fases acima)
Os testes de balanceamento validam que os numeros do codigo conferem com as tabelas do GDD:
- Curva de custo exponencial (Fase 6)
- Distribuicao de spawn por faixa de ameaca (Fase 7)
- Marcos de ameaca (Fase 3)
- Taxa de conversao de Eter (Fase 10)

---

## Resumo de Testes por Fase

| Fase | Testes | Acumulado |
|------|--------|-----------|
| 1.5 Setup TDD | 11 | 11 |
| 2 Cidades | 4 | 15 |
| 3 Inimigos + Ameaca | 13 | 28 |
| 4 Economia | 7 | 35 |
| 5 HUD | 0 | 35 |
| 6 Loja + Upgrades | 14 | 49 |
| 7 Inimigos T2/T3 | 9 | 58 |
| 8 Especial | 5 | 63 |
| 9 Boss | 5 | 68 |
| 10 Ascensao | 7 | 75 |
| 11 Persistencia | 4 | 79 |
| 12 Ads | 0 | 79 |
| **Total** | **79** | |

---

## Estrutura de Arquivos

```
missile-rogue/
├── scenes/
│   ├── main.tscn + main.gd
│   ├── game/       game.tscn + game.gd + hud.tscn + hud.gd
│   ├── menu/       main_menu.tscn + main_menu.gd
│   ├── shop/       shop.tscn + shop.gd
│   └── ascension/  ascension.tscn + ascension.gd
├── entities/
│   ├── missiles/   player_missile, basic_enemy, fast_enemy, cluster_enemy, cluster_fragment
│   ├── boss/       overlord
│   ├── city/       city
│   └── battery/    battery
├── systems/        (logica pura, testavel — RefCounted)
│   ├── battery_data.gd
│   ├── missile_data.gd
│   ├── battery_selector.gd
│   ├── city_data.gd
│   ├── enemy_data.gd
│   ├── threat_system.gd
│   ├── spawn_system.gd
│   ├── currency_system.gd
│   ├── upgrade_system.gd
│   ├── ascension_system.gd
│   ├── special_system.gd
│   ├── save_system.gd
│   └── ad_system.gd
├── test/           (GdUnit4)
│   ├── entities/   battery, missile, city, basic_enemy, fast_enemy, cluster_enemy, boss
│   ├── systems/    selector, threat, spawn, currency, upgrade, ascension, special, save
│   └── balance/    cost_curve, threat_scaling, spawn_distribution
├── resources/
│   ├── upgrades/
│   └── enemies/
├── addons/gdUnit4/
└── assets/         sprites/ particles/ audio/ fonts/
```

## Marcos de Verificacao

| Marco | Fase | Criterio |
|-------|------|----------|
| Primeiro jogavel | 1 | Toque dispara missil que explode |
| TDD ativo | 1.5 | 11 testes passando, GdUnit4 rodando |
| Primeiro desafio | 3 | Inimigos descem, jogador intercepta, morre |
| Core loop fecha | 6 | Morre > loja > compra > nova run mais forte |
| Profundidade | 7 | 3 tipos de inimigo, ameaca escala ate 99 |
| Objetivo final | 9 | Boss derrotavel com upgrades completos |
| Prestige | 10 | Ascensao funcional, Tier 4 permanente |
| MVP 1.0 | 12 | Save + ads + loop completo |
