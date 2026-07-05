# Ecos de Vaethir

RPG de mundo aberto sistêmico para **PC (Windows)** e **Android** — nascido
multiplataforma, não portado. O mundo vive com ou sem o jogador: NPCs têm
rotina, memória e fofoca; a economia tem oferta, demanda e inflação; facções
guerreiam por pressões simuladas; eventos emergem da simulação, nunca de script.

**Leia primeiro:** [`docs/GDD.md`](docs/GDD.md) — o Game Design Document
completo (lore, regiões, facções, sistemas, pipeline e roadmap).

## Estado atual

**Fase 0 (Fundação) — concluída**

- ✅ Núcleo de simulação headless: relógio/estações, clima sistêmico,
  economia de 3 camadas com caravanas reais, guerra de facções emergente,
  NPCs com necessidades/memórias/fofoca, motor de eventos ("Dramaturgo").
- ✅ Camada de entrada adaptativa: teclado+mouse, gamepad e touch (stick
  virtual dinâmico + botões contextuais) alimentando as mesmas ações semânticas.
- ✅ HUD responsiva "quase invisível" com breakpoints (phone → ultrawide) e safe-area.
- ✅ Testes headless: unidade + soak (300 dias de mundo sem jogador).

**Fase 1 (Fatia Vertical) — em andamento**

- ✅ Combate v1: ataques leve/forte, bloqueio, aparo com janela, esquiva com
  iframes, postura e ferimentos localizados — mesmas regras para todos.
- ✅ Bandidos com IA tática: cercam sem empilhar, pressionam postura quebrada,
  recuam, chamam reforços com chifre diegético e FOGEM — e a fuga vira
  rumor real no Registro do Mundo.
- ✅ Diálogo por conhecimento: NPCs falam do que sabem (memórias, fofocas,
  notícias que chegam com atraso real). Sem falas oniscientes.
- ✅ "Teste da taverna": perto de NPCs socializando, o jogador ouve o que
  eles realmente sabem — sentar na taverna é gameplay.
- ✅ Ponte simulação→encenação: eventos de conflito do Dramaturgo viram
  emboscadas físicas; matar um saqueador na frente de testemunhas vira
  reputação por fofoca.
- ✅ Descanso na fogueira (o mundo avança de verdade) e morte sem game over
  (você acorda na praia; o mundo seguiu).
- ⏳ Próximo: rotinas encenadas dos 40 NPCs com interiores, 5 locais
  artesanais, percepção/crime completo.

## Requisitos

- [Godot 4.4+](https://godotengine.org/download) (edição padrão, GDScript)
- Para Android: export templates + Android SDK configurados no Godot
  ([docs](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html))

## Rodar o protótipo

```bash
godot --path .          # abre no editor: F5 para jogar
```

- **PC:** WASD + mouse | Shift corre | C agacha | Espaço pula | E interage | Q aparo
- **Gamepad:** stick esquerdo move | A/✕ pula | X/□ interage | LB/L1 aparo
- **Touch:** stick virtual (metade esquerda) | arrastar (metade direita) olha |
  botões contextuais aparecem quando fazem sentido

## Testes

```bash
godot --headless --path . --script tests/unit_tests.gd
godot --headless --path . --script tests/soak_test.gd -- 300   # 300 dias sem jogador
```

## Exportar

```bash
godot --headless --path . --export-release "Windows" build/windows/EcosDeVaethir.exe
godot --headless --path . --export-debug "Android" build/android/EcosDeVaethir.apk
```

## Estrutura

| Pasta | Conteúdo |
|-------|----------|
| `source/core/` | Núcleo de simulação (sem cena; roda headless em CI) |
| `source/game/` | Encenação: jogador, combate, NPCs encenados, streaming |
| `source/ui/` | HUD responsiva + controles touch |
| `source/autoload/` | Singletons: `Sim`, `Actions`, `UIScale` |
| `data/` | Conteúdo declarativo (JSON moddável): facções, regiões, bens, NPCs, eventos, receitas |
| `docs/` | GDD + checklist de paridade de entrada |
| `tests/` | Testes headless de unidade e soak |

## Regra de ouro do repositório

Toda mecânica nova passa pelo checklist
[`docs/checklists/input_parity.md`](docs/checklists/input_parity.md)
(teclado+mouse / gamepad / touch) antes do merge. Se não funcionar de forma
intuitiva em alguma das três entradas, ela é redesenhada — não adaptada.
