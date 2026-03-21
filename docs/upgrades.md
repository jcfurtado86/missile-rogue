# Upgrades — Planejamento

## Tier 1 — Creditos (CR)
| ID | Nome | Efeito/Nivel | Max | Custo Base | Status |
|---|---|---|---|---|---|
| ammo_pack | AMMO PACK | +8 municao por bateria | 6 | 50 | Implementado |
| hyper_drive | HYPER DRIVE | +8% velocidade do missil | 6 | 50 | Implementado |
| warhead | WARHEAD+ | +8% raio de explosao | 6 | 50 | Implementado |
| profit_matrix | PROFIT MATRIX | +8% creditos por abate | 6 | 50 | Implementado |
| overcharge | OVERCHARGE | +10% velocidade de carga especial | 5 | 50 | Definido |
| head_start | HEAD START | +15 creditos ao iniciar run | 5 | 50 | Implementado |
| time_warp | TIME WARP | +5% chance de desacelerar inimigo | 4 | 50 | Definido |
| chain_reaction | CHAIN REACTION | +5% chance de explosao em cadeia | 4 | 50 | Definido |
| triple_burst | TRIPLE BURST | +8% chance de tiro triplo | 4 | 50 | Definido |
| overdrive | OVERDRIVE | -1 abate necessario pra combo | 4 | 50 | Definido |
| early_warning | EARLY WARNING | Misseis rapidos piscam antes | 2 | 50 | Definido |
| city_shield | CITY SHIELD | +1 cidade inicial | 3 | 50 | Definido |

## Tier 2 — Cristais (CS)
| ID | Nome | Efeito/Nivel | Max | Custo Base | Status |
|---|---|---|---|---|---|
| nova_core | NOVA CORE | +15% raio do especial | 5 | 30 | Definido |
| critical_mass | CRITICAL MASS | +2% chance de explosao dupla | 5 | 30 | Definido |
| aura_field | AURA FIELD | +10% raio de repulsao | 4 | 30 | Definido |
| overlord_bane | OVERLORD BANE | +8% reducao de HP do boss | 4 | 30 | Definido |
| crystal_lens | CRYSTAL LENS | +20% ganho de todas as moedas | 4 | 30 | Definido |
| temporal_rift | TEMPORAL RIFT | +8% desaceleracao de ameaca | 5 | 30 | Definido |
| warp_reload | WARP RELOAD | +15% municao ao recarregar | 4 | 30 | Definido |
| iron_dome | IRON DOME | +1 cidade bonus | 2 | 30 | Definido |

## Tier 3 — Void (VO)
| ID | Nome | Efeito/Nivel | Max | Custo Base | Status |
|---|---|---|---|---|---|
| twin_cannons | TWIN CANNONS | +1 missil extra por tiro | 3 | 20 | Definido |
| temporal_freeze | TEMPORAL FREEZE | +1s de congelamento | 3 | 20 | Definido |
| phoenix_protocol | PHOENIX PROTOCOL | +1 cidade revivida ao morrer | 2 | 20 | Definido |
| singularity | SINGULARITY | +15% forca de atracao | 3 | 20 | Definido |
| mirror_array | MIRROR ARRAY | +3% chance de refletir | 4 | 20 | Definido |
| overclock | OVERCLOCK | +2s de cadencia dobrada | 3 | 20 | Definido |

## Tier 4 — Eter (ET) — Permanentes
| ID | Nome | Efeito/Nivel | Max | Custo Base | Status |
|---|---|---|---|---|---|
| ascendant_core | ASCENDANT CORE | +5% boost de void | 3 | 50 | Definido |
| void_resonance | VOID RESONANCE | +1 void ao usar especial | 2 | 50 | Definido |
| eternal_city | ETERNAL CITY | 1 cidade indestrutivel | 1 | 100 | Definido |
| omega_protocol | OMEGA PROTOCOL | +50% recompensas | 1 | 150 | Definido |

## Legenda de Status
- **Implementado**: upgrade registrado E efeito aplicado no gameplay
- **Definido**: upgrade registrado na loja mas efeito ainda nao implementado no gameplay

## Notas
- Custo exponencial: `base_cost * multiplier^level` (mult 2.4 tier1, 2.5 tier2-3, 2.0 tier4)
- Tiers 1-3 resetam na ascensao, Tier 4 e permanente
- Moedas de desbloqueio: tier aparece na loja quando o jogador ganha a primeira moeda daquele tipo
- Tier 4 aparece em tela separada somente apos ascender
