# Missile Rogue

Roguelite mobile vertical de defesa de cidades. Proteja suas cidades contra ondas de misseis inimigos com progressao permanente e sistema de ascensao (prestige).

## Conceito

O jogador defende 3 cidades contra misseis inimigos que caem do topo da tela. Toque na tela para disparar misseis interceptadores que explodem em area. O jogo base e intencionalmente dificil — a progressao por upgrades e o caminho para ir mais longe.

## Gameplay

- **Disparo por toque** — toque em qualquer ponto da tela para disparar da bateria mais proxima
- **3 baterias + 3 cidades** na base da tela
- **Municao limitada** com recarga automatica
- **Especial (Nova Bomb)** — carrega ao destruir inimigos, limpa a tela com onda expansiva
- **Game over** quando todas as cidades sao destruidas

## Inimigos

| Tipo | Cor | Comportamento | Drop |
|------|-----|---------------|------|
| Basico | Rosa | Trajetoria reta | Creditos |
| Rapido | Verde | Ziguezague entre cidades | Cristais |
| Cluster | Violeta | Lento, explode em fragmentos em parabola | Void Orbs |
| Boss Overlord | Vermelho | Ameaca 100, rajadas em leque, rage mode | Victoria |

## Progressao

**Ciclo**: jogar > acumular moedas > comprar upgrades > chegar mais longe > repetir

- **4 moedas**: Creditos, Cristais, Void Orbs, Eter
- **Loja com Tiers** desbloqueados progressivamente (custo exponencial)
- **Ascensao (prestige)**: reseta Tiers 1-3 e moedas de run, converte investimento em Eter permanente
- **Tier 4**: upgrades permanentes comprados com Eter

## Escalada Dinamica

Sem timer fixo. O **Nivel de Ameaca** (0-100) sobe com:
- Tempo vivo (passivo, lento)
- Inimigos destruidos (ativo, rapido)

A composicao de spawn e velocidade escalam com a ameaca. Boss aparece em ameaca 100.

## Visual

Estetica **neon retro 80s / synthwave**:
- Background procedural com grid em perspectiva e cenario aleatorio (cidade ou montanhas)
- Todos os assets desenhados com primitivas geometricas (sem sprites)
- Outline neon com glow sobre preenchimento escuro
- Explosoes multicoloridas com flicker
- Cogumelo nuclear ao impacto dos misseis inimigos
- Trilha luminosa nos misseis

## Tech

- **Godot 4.4** (GDScript)
- **Orientacao**: vertical (1080x1920)
- **Renderizacao**: toda procedural via `_draw()` — sem assets de imagem
- **Testes**: gdUnit4
- **Plataforma**: Android (APK)

## Estrutura

```
scenes/
  main.gd          # Controlador de fluxo (game > shop > ascension)
  game/             # Cena de jogo, HUD, background synthwave
  shop/             # Loja de upgrades
  ascension/        # Tela de ascensao/prestige
entities/
  missiles/         # Player, inimigos (basic, fast, cluster), efeitos
  battery/          # Baterias de disparo
  city/             # Cidades defendidas
  boss/             # Boss Overlord
  nova_bomb_wave.*  # Especial expansivo
systems/            # Logica pura (currency, upgrades, threat, spawn, save)
test/               # Testes unitarios e de balanceamento
```

## Build

Requer Godot 4.4+ com export template Android configurado.

```bash
# Gerar APK de debug
/caminho/para/godot --headless --export-debug "Android" build/missile-rogue.apk
```
