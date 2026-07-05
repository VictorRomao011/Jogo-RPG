# ECOS DE VAETHIR
## Game Design Document — Versão 1.0

> **Gênero:** RPG de Mundo Aberto com Simulação Sistêmica
> **Plataformas:** PC (Windows) e Android (nativo, não port)
> **Engine:** Godot 4.x
> **Pilar central:** *O mundo não existe para o jogador. O jogador existe no mundo.*

---

# ÍNDICE

1. [Visão Geral e Pilares de Design](#1-visão-geral-e-pilares-de-design)
2. [Lore e Cosmologia](#2-lore-e-cosmologia)
3. [História do Mundo](#3-história-do-mundo)
4. [Continente e Regiões](#4-continente-e-regiões)
5. [Facções](#5-facções)
6. [Economia Dinâmica](#6-economia-dinâmica)
7. [IA dos NPCs](#7-ia-dos-npcs)
8. [Combate](#8-combate)
9. [Crafting](#9-crafting)
10. [Sobrevivência](#10-sobrevivência)
11. [Progressão](#11-progressão)
12. [Eventos Dinâmicos](#12-eventos-dinâmicos)
13. [Exploração e Narrativa Ambiental](#13-exploração-e-narrativa-ambiental)
14. [Interface e UX Multiplataforma](#14-interface-e-ux-multiplataforma)
15. [Controles Adaptativos](#15-controles-adaptativos)
16. [Pipeline Técnico](#16-pipeline-técnico)
17. [Estrutura Completa do Projeto](#17-estrutura-completa-do-projeto)
18. [Roadmap de Desenvolvimento](#18-roadmap-de-desenvolvimento)

---

# 1. VISÃO GERAL E PILARES DE DESIGN

## 1.1 O que é Ecos de Vaethir

Ecos de Vaethir é um RPG de mundo aberto onde **não existe uma história principal
que te puxa pelo braço**. Existe um continente vivo — Vaethir — que funciona,
respira e muda com ou sem o jogador. NPCs acordam, trabalham, comem, fofocam,
adoecem, brigam, se apaixonam por rotas comerciais lucrativas e morrem em
emboscadas que ninguém roteirizou. Facções disputam territórios de verdade,
com soldados de verdade, que consomem comida de verdade, comprada de fazendeiros
de verdade — e quando a comida falta, a guerra muda de rumo.

O jogador é largado nesse mundo com uma roupa surrada, memórias fragmentadas
(um gancho de lore, não uma quest) e uma pergunta: *o que você vai fazer?*

## 1.2 Os Sete Pilares

| # | Pilar | O que significa na prática |
|---|-------|---------------------------|
| 1 | **Mundo primeiro, jogador depois** | Toda simulação roda de forma autônoma. O jogador é um agente entre agentes. |
| 2 | **Curiosidade é a bússola** | Sem marcadores de quest. Navegação por referências visuais, rumores e dedução. |
| 3 | **Fazer é aprender** | Progressão 100% por uso. Sem classes, sem XP, sem níveis. |
| 4 | **Consequência sem sermão** | O mundo reage às ações, mas nunca julga com telas de "escolha moral". |
| 5 | **Sistemas que conversam** | Clima afeta economia, economia afeta facções, facções afetam NPCs, NPCs afetam o jogador. |
| 6 | **Fricção boa, irritação nunca** | Sobrevivência e dificuldade criam histórias, não tédio. |
| 7 | **Uma experiência, duas plataformas** | PC e Android nascem juntos. Nenhuma mecânica depende de um único método de entrada. |

## 1.3 O que este jogo NÃO é

- Não é um theme park de missões com 300 ícones no mapa.
- Não é um survival hardcore de medidores agressivos.
- Não é um looter com dano numérico inflacionado.
- Não é um sandbox vazio: densidade de conteúdo artesanal > tamanho de mapa.

## 1.4 Fantasia central do jogador

> "Eu vi fumaça atrás da colina. Fui olhar. Era uma caravana atacada por
> saqueadores da Máscara Rubra. Ajudei os mercadores, um deles era primo do
> ferreiro de Bruma Alta, que passou a me dar desconto. Semanas depois, a
> Máscara Rubra me marcou: agora mandam caçadores atrás de mim. Nada disso
> era missão. Tudo isso é a minha história."

---

# 2. LORE E COSMOLOGIA

## 2.1 A premissa: O Silêncio

Vaethir era um continente governado por ressonância. Toda a magia, tecnologia
e religião derivava dos **Coros** — correntes de som primordial que fluíam por
veios subterrâneos de um mineral chamado **vethrita**, cristalizando-se em
enormes **Sinos-Raiz** nas profundezas das montanhas. Cantores treinados
("Ressoadores") canalizavam os Coros para curar, construir, mover pedra,
prever o clima.

Há 173 anos, em uma única noite, **todos os Sinos-Raiz pararam ao mesmo tempo.**

Esse evento é chamado de **O Silêncio**. Ninguém sabe a causa. A civilização
que dependia dos Coros — o **Império Cantante de Ottheria** — colapsou em uma
geração. Cidades móveis pararam onde estavam e viraram ruínas. Ressoadores
enlouqueceram ou definharam. A magia não morreu completamente: restaram
**Ecos** — bolsões instáveis de ressonância residual que se acumulam em ruínas,
cavernas e criaturas, tornando-os estranhos, valiosos e perigosos.

**Regra de ouro do lore:** o jogo NUNCA explica o Silêncio diretamente.
Cada ruína, cada facção e cada eco carrega uma peça e uma interpretação.
O jogador monta a própria teoria. (Ver §13 — narrativa ambiental.)

## 2.2 Cosmologia

- **Os Coros:** quatro correntes primordiais, cada uma associada a um domínio:
  - **Coro Fundo** (pedra, peso, permanência) — reverenciado por mineradores e construtores.
  - **Coro Verde** (crescimento, sangue, fome) — reverenciado por lavradores e curandeiros.
  - **Coro Errante** (vento, viagem, troca) — reverenciado por mercadores e nômades.
  - **Coro Claro** (memória, luz, verdade) — reverenciado por arquivistas e juízes.
- **Ecos:** fragmentos residuais dos Coros. Manifestam-se como distorções:
  zonas onde o som se comporta errado, plantas que crescem em espiral, animais
  com comportamento anômalo. Ecos podem ser **colhidos** (recurso raro de
  crafting e comércio, ver §6 e §9) — mas colher Ecos "apaga" a anomalia local,
  o que algumas facções consideram profanação.
- **Religião pós-Silêncio:** não há deuses ativos. Há quatro **Credos**
  (um por Coro) que divergem violentamente sobre o que o Silêncio significa:
  castigo, teste, morte dos deuses, ou apenas um fenômeno natural.

## 2.3 Tom

Melancolia luminosa. Não é dark fantasy niilista: é um mundo em **convalescença**.
As pessoas replantam, reconstroem, renegociam. A tragédia tem 173 anos — ninguém
vivo a presenciou, mas todos vivem nas suas ruínas. Referência tonal: o
otimismo teimoso de BOTW sobre os ossos de um mundo à FromSoftware.

---

# 3. HISTÓRIA DO MUNDO

## 3.1 Linha do tempo (Eras)

| Era | Período | Eventos |
|-----|---------|---------|
| **Era do Primeiro Canto** | ~2000–800 a.S.* | Tribos descobrem os Sinos-Raiz. Primeiros Ressoadores. Fundação das rotas de vethrita. |
| **Era Cantante** | 800 a.S.–0 | Império de Ottheria unifica Vaethir. Cidades móveis, pontes de som, agricultura ressonante. Auge e decadência: colheita industrial de vethrita, "afinação" forçada de povos anexados. |
| **O Silêncio** | Ano 0 | Todos os Sinos-Raiz param em uma noite. |
| **Era da Queda** | 0–60 d.S. | Fome, êxodos, guerras por celeiros. 70% da população morre ou migra. Ottheria fragmenta-se. |
| **Era das Cinzas** | 60–120 d.S. | Senhores locais, companhias mercenárias e credos consolidam territórios. Surgem as facções atuais. |
| **Era Presente ("A Retomada")** | 120–173 d.S. | Reconstrução. Redescoberta de rotas. Corrida pelos Ecos. **O jogo começa no ano 173.** |

*a.S. = antes do Silêncio; d.S. = depois do Silêncio.*

## 3.2 O gancho do jogador (não é uma quest)

O jogador acorda em uma balsa encalhada na costa de **Pelagem Cinza**, sem
memória dos últimos meses, com um fragmento de Eco **dentro do próprio corpo** —
percebível por certos NPCs e criaturas ("você soa estranho"). Isso gera:

- Reações sistêmicas: cães rosnam, Ressoadores decaídos o procuram, o Credo
  Claro o estuda, a Guilda do Fole quer comprá-lo (literalmente).
- Zero missões. O fragmento é um **modificador de simulação**, não um McGuffin.
  Se o jogador nunca investigar, tudo bem. O mundo continua.

## 3.3 História viva (o mundo continua sendo escrito)

A linha do tempo NÃO termina no início do jogo. O simulador de facções (§5, §12)
gera novos eventos históricos datados — cercos, tratados, pragas, descobertas —
registrados num **Registro do Mundo** interno. Bardos, arautos e fofocas de
taverna narram esses eventos ao jogador com atraso e distorção proporcionais
à distância (notícia de longe chega tarde e errada — como em Kenshi, mas
falada).

---

# 4. CONTINENTE E REGIÕES

## 4.1 Vaethir — visão geral

Um único continente artesanal (~64 km² jogáveis no PC; mesmo layout no Android),
desenhado região por região à mão. **Nada de geração procedural de terreno na
versão final** — procedural é usado apenas em ferramentas de autoria (espalhar
vegetação-base que os artistas depois editam).

O mapa segue a filosofia de **atração por silhueta** (BOTW): de qualquer ponto
elevado, o jogador vê 3–5 pontos de interesse genuínos que geram perguntas
("por que aquela torre está torta?", "o que é aquele brilho no desfiladeiro?").

## 4.2 As oito regiões

### 4.2.1 Pelagem Cinza (região inicial — costa oeste)
- **Bioma:** costa fria, falésias, pinheirais, névoa matinal constante.
- **Tema:** chegada e sobrevivência modesta. Vilas de pescadores, restos de
  um porto imperial afundado visível na maré baixa (explorável na maré baixa —
  o ciclo de maré é real).
- **Assentamentos:** Bruma Alta (vila-hub, ~40 NPCs), Cais Quebrado (~15 NPCs).
- **Facções presentes:** Liga dos Portos (fraca), Credo Errante, saqueadores da Máscara Rubra.
- **Perigos:** lobos costeiros, marés, hipotermia noturna.
- **Segredo de região:** o Sino-Raiz submerso de Ottheria-Oeste ainda vibra
  uma vez por noite — só perceptível se o jogador dormir no porto afundado.

### 4.2.2 Os Celeiros de Sol (planícies centrais)
- **Bioma:** campos dourados, rios lentos, carvalhos isolados.
- **Tema:** o coração econômico. Quem controla os Celeiros alimenta Vaethir.
  Palco principal da guerra de facções (Baronato do Trigo × Companhia da Balança).
- **Assentamentos:** Vila Moinho (~60 NPCs), fazendas independentes (8–12,
  cada uma com família própria e rotina completa).
- **Sistêmica única:** colheitas reais por estação; incêndios de campo se
  alastram com o vento; gafanhotos como evento dinâmico (§12).

### 4.2.3 Serra do Bordão (cadeia montanhosa norte)
- **Bioma:** picos nevados, minas, vilas agarradas em encostas.
- **Tema:** mineração de vethrita morta (ainda valiosa como liga de metal) e
  o Credo Fundo, que considera as minas templos.
- **Perigos:** avalanches (dirigidas por som — gritar/lutar em zonas marcadas
  por placas rachadas dispara neve), frio severo, os **Cegos-de-Pedra**
  (criaturas de eco que caçam por vibração — dá para atravessar seus túneis
  andando devagar, sem armadura pesada).
- **Segredo de região:** um Sino-Raiz intacto porém mudo, com um acampamento
  de estudiosos rivais ao redor (dois credos, tensão armada, sem quest — pura
  panela de pressão sistêmica).

### 4.2.4 Voralt, a Cidade que Parou (metrópole-ruína leste)
- **Bioma:** cidade imperial móvel que congelou no meio de um passo. Bairros
  inclinados, "pernas" de pedra de 200m, interiores intactos.
- **Tema:** a maior dungeon do jogo — e também uma cidade viva: catadores,
  contrabandistas e o Credo Claro colonizaram os primeiros anéis. Anéis
  profundos: distorções de eco severas.
- **Design:** metroidvania vertical dentro do mundo aberto. Sem loading (PC) /
  streaming por bairro (Android).

### 4.2.5 Lamaçal de Ferro (pântanos sudeste)
- **Bioma:** mangue enferrujado — a água carrega óxido dos exércitos imperiais
  afogados.
- **Tema:** ninguém manda aqui. Refúgio de foras-da-lei, desertores e da
  única cultura que prospera: sanguessugas medicinais e ferro de lama.
- **Perigos:** doenças (a principal fonte do jogo, §10), areia movediça,
  os **Afogados** (não são mortos-vivos — são ecos coletivos com forma).

### 4.2.6 Estepe de Khevra (sul árido)
- **Bioma:** estepe rachada, cânions, tempestades de poeira.
- **Tema:** os clãs nômades khevri e suas rotas de sal. Cultura de
  hospitalidade codificada: o jogador que aprende os ritos (observando!) tem
  acesso a comércio e abrigo; quem viola, vira presa.
- **Sistêmica única:** os acampamentos khevri se movem de verdade pelo mapa
  seguindo pasto e água (migração simulada).

### 4.2.7 Bosque de Vidro (floresta noroeste)
- **Bioma:** floresta onde o Silêncio "congelou" um coro em pleno ar: árvores
  parcialmente vitrificadas, som que viaja errado (áudio posicional
  deliberadamente distorcido aqui).
- **Tema:** a região mais densa em Ecos e a mais perigosa. Fauna anômala.
  O Credo Verde mantém vigílias na borda para impedir colheita de Ecos.
- **Regra de design:** zero NPCs vendedores dentro; tudo que o jogador traz
  de lá tem valor alto e história.

### 4.2.8 Arquipélago da Voz Partida (ilhas ao norte — endgame de exploração)
- **Bioma:** ilhas vulcânicas ligadas por pontes de som petrificadas.
- **Tema:** onde os primeiros Sinos foram encontrados. Acesso apenas por barco
  próprio (crafting avançado) ou passagem cara. As respostas mais profundas
  sobre o Silêncio estão aqui — em camadas, nunca explícitas.

## 4.3 Malha de conexão

- **Estradas imperiais** (rápidas, patrulhadas ou saqueadas conforme o estado
  das facções) × **trilhas** (lentas, ricas em descobertas).
- **Rotas comerciais** são entidades da simulação (§6): caravanas reais
  percorrem rotas reais; bandidos reais as emboscam em gargalos reais.
- **Sem fast-travel mágico.** Transporte diegético: caronas em caravanas
  (pagas, com viagem simulada em tempo acelerado e chance de evento), barcos
  costeiros, montarias.

---

# 5. FACÇÕES

## 5.1 Regras universais de facção

1. Nenhuma facção é "boa" ou "má" — cada uma tem uma tese razoável e métodos
   questionáveis.
2. Toda facção tem: **objetivos simulados** (expandir, enriquecer, converter,
   sobreviver), **recursos reais** (ouro, comida, soldados, influência),
   **territórios**, **relações** com as demais (-100..+100) e **memória** de
   eventos.
3. Facções agem sem o jogador: o simulador estratégico (tick a cada hora de
   jogo) toma decisões de guerra, comércio e diplomacia baseadas em recursos
   e relações.
4. Reputação do jogador é **por facção e por assentamento**, propagada por
   testemunhas e fofoca (§7.6) — não um número global mágico. Crime sem
   testemunha não existe.

## 5.2 As facções principais

### A Companhia da Balança
- **Tese:** "O comércio reconstruirá Vaethir; fronteiras são ruído."
- **Estrutura:** guilda mercantil com exército contratado. Controla a moeda
  de fato (o *marco de balança*).
- **Métodos sombrios:** monopólios forçados, dívidas predatórias, compra de
  colheitas inteiras para criar escassez lucrativa.
- **Simulação:** maximiza lucro de rotas; contrata mercenários quando rotas
  são atacadas; financia o lado que estiver perdendo em guerras longas
  (guerra longa = lucro).

### O Baronato do Trigo
- **Tese:** "Quem alimenta, governa. Ordem feudal é o único remédio provado."
- **Estrutura:** aliança de senhores rurais dos Celeiros com leva militar
  camponesa.
- **Métodos sombrios:** servidão por dívida, justiça sumária, xenofobia
  contra khevri.
- **Simulação:** expande por anexação de fazendas independentes; briga com a
  Balança por taxação de rotas.

### Os Quatro Credos (Fundo, Verde, Errante, Claro)
- Quatro igrejas irmãs e rivais. Compartilham liturgia, divergem sobre o
  Silêncio. O **Claro** cataloga Ecos (e o jogador). O **Verde** protege
  anomalias. O **Fundo** sela ruínas "profanadas". O **Errante** dá abrigo a
  viajantes e espalha notícias (vetor de fofoca de longo alcance).
- **Simulação:** competem por conversão de assentamentos (um assentamento
  convertido muda feriados, comportamento e comércio).

### A Máscara Rubra
- **Tese:** "Vaethir morreu. Nós somos os vermes, e vermes têm direito ao cadáver."
- **Estrutura:** confederação de bandos saqueadores com código interno rígido.
- **Nuance:** aceita qualquer um — é a única "meritocracia" real do continente.
  Muitos membros são camponeses arruinados pelo Baronato ou endividados pela
  Balança. Emboscam caravanas, mas mantêm mercados negros onde qualquer
  reputação é bem-vinda.
- **Simulação:** intensidade de saques inversamente proporcional à prosperidade
  regional (desespero recruta).

### Os Clãs Khevri
- **Tese:** "A terra não é de ninguém; nós apenas a percorremos."
- **Estrutura:** sete clãs nômades com conselho sazonal.
- **Simulação:** migram; comerciam sal e couro; entram em guerra apenas
  defensivamente, mas nunca esquecem (memória de facção com decay lentíssimo).

### A Guilda do Fole
- **Tese:** "O Silêncio foi a alforria: a engenhosidade humana não precisa de deuses cantores."
- **Estrutura:** engenheiros, ferreiros e alquimistas. Neutra em guerras,
  vende para todos.
- **Métodos sombrios:** compra Ecos para experimentos que às vezes... vazam
  (fonte de eventos dinâmicos de monstros).

### Os Decaídos (facção-fantasma)
- Descendentes de Ressoadores, marcados geneticamente pelos Coros. Não têm
  território — têm **indivíduos infiltrados** em todas as outras facções, que
  se reconhecem por sinais. Percebem o fragmento do jogador. A "facção" é uma
  rede de sussurros, não um exército.

## 5.3 Guerra de facções (mecânica)

- Guerras nascem de **pressões simuladas** (comida, insulto diplomático,
  rota disputada), nunca de script.
- Estados: `tensão → escaramuças → guerra aberta → exaustão → tratado/anexação`.
- Efeitos visíveis: patrulhas mudam, preços mudam, refugiados aparecem em
  vilas vizinhas, NPCs alistados somem das rotinas (e às vezes voltam feridos,
  ou não voltam — a viúva usa luto, a forja fica sem ferreiro).
- O jogador pode participar em qualquer nível (soldado, sabotador,
  contrabandista de armas para ambos os lados, medik neutro) **sem menus de
  "juntar-se à facção"** — papel emerge de ações repetidas e confiança
  individual de NPCs.

---

# 6. ECONOMIA DINÂMICA

## 6.1 Princípio

Cada moeda tem lastro em **produção simulada**. Nada de baús com ouro infinito
nem vendedores com estoque mágico.

## 6.2 Modelo (3 camadas)

### Camada 1 — Produção
- Cada assentamento tem **edifícios produtores** (fazenda, mina, serraria,
  forja, cervejaria...) operados por NPCs específicos. NPC morto/doente/alistado
  = produção cai de verdade.
- Produção depende de estação, clima e segurança (fazendeiro não colhe sob
  ataque).

### Camada 2 — Mercado local
- Cada assentamento mantém estoque e **preços por oferta/demanda local**:
  `preço = base × (demanda/oferta)^elasticidade`, com elasticidade por
  categoria (comida inelástica, luxo elástico).
- Mercadores individuais têm **inventário próprio, capital próprio e
  especialidade** — e podem falir.
- Escassez real: cerco a Vila Moinho = pão a 8× o preço em 2 semanas, fome,
  migração de NPCs.

### Camada 3 — Rotas e arbitragem
- Caravanas NPC compram barato onde sobra e vendem caro onde falta — são o
  mecanismo físico de equalização de preços. Cada caravana é entidade no mundo:
  pode ser escoltada, roubada, atrasada por neve.
- **O jogador compete no mesmo sistema:** arbitragem manual é uma carreira
  viável (e treina Comércio, §11).
- Inflação: facções em guerra cunham moeda para pagar soldados → preços sobem
  na zona de influência. Deflação em colapsos de demanda.

## 6.3 Regras anti-frustração

- Preços mudam com inércia (média móvel), nunca teleportam.
- HUD nunca mostra gráficos de economia: o jogador percebe pelos diálogos
  ("o sal triplicou desde que fecharam o desfiladeiro"), pelas prateleiras e
  pelos preços.

---

# 7. IA DOS NPCS

## 7.1 Arquitetura em dois níveis

- **Nível Encenado (raio ~150m do jogador):** NPCs completos — corpo animado,
  percepção, diálogo, pathfinding local.
- **Nível Abstrato (resto do mundo):** os mesmos NPCs como registros de
  simulação — posição lógica, agenda, transações, saúde. Transição
  imperceptível ("LOD de simulação"). *Nada é fake: um NPC abstrato viajando
  de Bruma Alta a Voralt existe na estrada e pode ser encontrado no caminho.*

## 7.2 Ficha de todo NPC nomeado (~450 no lançamento)

| Campo | Exemplo (Mira, ferreira de Bruma Alta) |
|-------|----------------------------------------|
| **Profissão** | Ferreira (produz ferraduras, facas; conserta) |
| **Rotina** | 6h forja acesa → 12h almoço na taverna → 14h entregas → 19h jantar → 22h dorme |
| **Objetivos** | Curto: comprar carvão barato. Longo: mandar a filha estudar com o Credo Claro |
| **Memórias** | Lista de eventos testemunhados/ouvidos, com autor, veracidade e decay |
| **Amizades** | Rede social ponderada (-100..+100 por NPC), muda por interação |
| **Medos** | Máscara Rubra (irmão morto em saque); trovões |
| **Inventário** | Real: ferramentas, 3 dias de comida, 62 marcos escondidos sob a tábua |
| **Preferências** | Gosta: hidromel, honestidade direta. Odeia: pechincha agressiva, khevri (preconceito herdado — pode mudar) |
| **Personalidade** | 5 eixos: coragem, empatia, ganância, lealdade, abertura |

## 7.3 Decisão: Utility AI hierárquica

A cada tick, o NPC pontua ações candidatas por **necessidades** (fome, sono,
segurança, social, dever, ambição), modificadas por personalidade e contexto.
A rotina é o "hábito" (peso alto por padrão); necessidades urgentes ou eventos
a quebram. Resultado: rotinas estáveis que **flexionam** — a ferreira falta à
forja para cuidar da filha doente; o guarda covarde "não vê" o crime.

## 7.4 Percepção e testemunho

- Visão (cone + oclusão + luz), audição (raio + material), ambos degradados
  por clima (tempestade = furto fácil — sistemas conversando).
- Crimes exigem testemunha para gerar consequência. Testemunha decide por
  personalidade: denuncia, chantageia, ignora ou aplaude (um Máscara Rubra
  aprova seu furto).

## 7.5 Diálogo

- Sistema de **tópicos + conhecimento**: NPCs só falam do que sabem
  (memórias + fofocas + profissão). Sem "vendedores de exposition".
- Diálogos entre NPCs são reais (trocam informação de verdade — fofoca é
  transporte de dados, não vinheta de áudio).
- O jogador aprende rumores ouvindo — sentar na taverna é gameplay.

## 7.6 Fofoca (o sistema nervoso do mundo)

`evento → testemunhas → propagação por rede social e viajantes → distorção
por distância/personalidade → decay`. Reputação do jogador, notícias de
guerra e preços viajam por esse canal. Velocidade realista: sua fama não
teleporta.

## 7.7 Ciclo de vida

NPCs podem morrer (combate, doença, idade — tempo de jogo longo). Papéis
econômicos vagos são reocupados por herdeiros/aprendizes/migrantes **com
atraso e degradação de qualidade** (o aprendiz não forja como a mestra) —
morte tem custo visível, mundo não quebra.

---

# 8. COMBATE

## 8.1 Filosofia

Difícil, legível, curto. Lutas de 10–40 segundos que parecem perigosas do
início ao fim. Habilidade do jogador > números. Fugir é sempre uma opção
tática respeitada pelo design (e pela IA inimiga, que também foge).

## 8.2 Núcleo mecânico

- **Stamina como moeda universal:** atacar, defender, esquivar, correr —
  tudo gasta. Gestão de stamina é o jogo.
- **Três ataques** (rápido / forte / especial da arma) + **defesa** (bloqueio
  com escudo/arma, aparo com janela estreita, esquiva direcional).
- **Postura:** pressão contínua quebra postura → abre execução/ripostas.
  Vale para o jogador também.
- **Sem lock-on obrigatório:** soft-target assist configurável (essencial
  para touch, útil para todos).
- **Armas com identidade:** lança controla distância, machado quebra postura,
  faca é rápida e silenciosa, arco exige física de projétil real. Sem "dano
  por nível": uma faca no pescoço de um barão mata o barão.
- **Ferimentos localizados leves:** perna ferida = manca; braço = ataque
  lento. Cura de verdade requer descanso/medicina (§10).

## 8.3 IA de combate

- **Táticas de grupo:** papéis emergentes (cercador, provocador, arqueiro
  recuado); inimigos se comunicam por chamados audíveis (o jogador ouve e
  antecipa).
- **Terreno:** IA usa cobertura contra arcos, empurra em direção a
  penhascos, chuta fogueiras para espalhar fogo, derruba a ponte de corda.
- **Moral real:** inimigos avaliam a luta. Perderam metade do bando? Fogem —
  e **lembram** (§7.2): o sobrevivente que fugiu pode voltar com reforços
  amanhã, ou espalhar seu nome como pesadelo (fofoca).
- **Reforços diegéticos:** chifres e sinos chamam ajuda que existe de verdade
  na simulação (se a patrulha já morreu, ninguém vem).

## 8.4 Furtividade

Sistêmica, não binária: luz, ruído por superfície, peso do equipamento,
linha de visão. Guardas investigam com inteligência crescente (procuram em
padrão, chamam colega, acendem tochas).

---

# 9. CRAFTING

## 9.1 Filosofia

Crafting é **conhecimento**, não lista de receitas desbloqueáveis por nível.
O jogador aprende: vendo NPCs trabalharem, desmontando itens, experimentando,
ou sendo ensinado (relação com NPC artesão).

## 9.2 Domínios

| Domínio | Estações | Nota de design |
|---------|----------|----------------|
| **Forja** | bigorna + fornalha | Minijogo curto de timing/temperatura (opcional: automático com qualidade média) |
| **Alquimia** | bancada + fogo | Propriedades de ingredientes descobertas por experimentação (efeitos consistentes por seed de mundo... não! **fixos por design** — conhecimento transfere entre jogatinas, wiki-friendly) |
| **Culinária** | fogueira/cozinha | Comida boa = buffs de descanso; comida estragada = doença |
| **Curtume/Tecelagem** | bastidor | Roupas por camadas térmicas (§10) |
| **Construção leve** | — | Acampamento próprio: barraca → cabana melhorável. Sem city-builder. |
| **Engenhoca** | oficina da Guilda | Armadilhas, luneta, fechaduras — ponte com Ecos no endgame |

## 9.3 Qualidade e materiais

- Qualidade do item = f(matéria-prima, habilidade do artesão, estação usada).
- Itens **degradam com uso e são consertáveis** (mercado real para NPCs
  ferreiros; nunca degradação irritante — durabilidade generosa, aviso claro).
- Ecos como material raro: efeitos estranhos e poderosos, sempre com
  contrapartida (uma lâmina de eco "canta" — furtividade impossível).

---

# 10. SOBREVIVÊNCIA

## 10.1 Filosofia: "fricção que gera história, nunca contador de tarefas"

Três medidores lentos e **um princípio**: estar mal nunca mata sozinho —
apenas torna o mundo mais perigoso (debuffs), forçando decisões interessantes.

| Sistema | Ritmo | Efeito de negligência |
|---------|-------|----------------------|
| **Fome** | 2 refeições/dia bastam | Stamina máxima encolhe. Nunca drena vida. |
| **Sono** | dormir 1×/dia (ou cochilos) | Percepção borrada, aparo mais difícil, alucinações leves em privação extrema (sussurros de eco...) |
| **Clima/Temperatura** | roupas por camadas, abrigo, fogo | Frio: stamina regenera devagar → hipotermia (aí sim, perigosa). Calor: sede acelerada. |
| **Doenças** | contraídas por comida ruim, ferimentos sujos, pântano, contato | Cada doença tem sintomas mecânicos e cura específica (conhecimento + economia de remédios). Epidemias são eventos dinâmicos que afetam NPCs também. |

- Dormir requer segurança razoável (acampamento, estalagem, abrigo) — dormir
  na estrada aberta é possível e arriscado (emboscada simulada real, não
  roleta).
- **Zero micro-gestão:** comer é 1 gesto; o jogo nunca interrompe combate ou
  diálogo com avisos de fome.

---

# 11. PROGRESSÃO

## 11.1 Sem classes, sem níveis, sem XP

**Aprender fazendo** (Kingdom Come/Outward): cada habilidade sobe pelo uso
real, com curva logarítmica (rápido no início, lento no domínio) e **sem
grind viável**: repetição sem risco/contexto rende quase nada (bater em rato
preso não treina espada; lutar algo que pode te matar, sim — ganho escala com
desafio real).

## 11.2 Habilidades (18)

**Corpo:** Vigor (correr/carregar), Fôlego, Natação, Escalada*, Furtividade
**Combate:** Lâminas curtas, Lâminas longas, Hastes, Impacto, Arcos, Bloqueio/Aparo, Luta livre
**Mundo:** Comércio, Persuasão, Medicina, Alquimia, Forja, Sobrevivência (rastrear/acampar/clima)

*Escalada estilo BOTW-lite: superfícies escaláveis generosas, custo de
stamina, proibitivo na chuva.

## 11.3 Conhecimento como progressão paralela

A metade "invisível" da progressão é do **jogador**, não do personagem:
mapas são desenhados por descoberta; propriedades alquímicas anotadas num
caderno diegético; ritos khevri aprendidos por observação; rotas lucrativas
memorizadas. Um jogador veterano com personagem novo já é poderoso — a la
Elden Ring/Kenshi.

## 11.4 Perks orgânicos

Marcos de uso concedem **técnicas** (não bônus numéricos): Fôlego 40 →
mergulho longo; Aparo 60 → riposta desarmadora; Comércio 50 → ler tendência
de preço na conversa. Técnicas mudam o *verbo*, não o número.

---

# 12. EVENTOS DINÂMICOS

## 12.1 Motor de eventos ("O Dramaturgo")

Um diretor de simulação que **não inventa histórias — expõe as que a
simulação já criou**. Monitora pressões (comida, tensão de facções, clima,
população de fauna, atividade do jogador) e materializa consequências como
eventos situados, com pesos que evitam repetição (cada template tem centenas
de permutações de atores, local, clima, hora e desfecho — e atores têm
memória, então o "mesmo" evento nunca é o mesmo).

## 12.2 Categorias

- **Econômicos:** caravana atrasada, falência, greve de mineiros, boom de
  colheita, mercador fugindo com dívidas.
- **Conflito:** emboscadas (reais: bandidos escolhem gargalos), escaramuças
  de fronteira, cerco, deserção em massa, senhor da guerra emergente
  (um capitão da Máscara Rubra vitorioso demais unifica bandos).
- **Naturais:** tempestades, nevascas que fecham passos (economia sente),
  seca, incêndio de campo, migração de manadas (predadores seguem, vilas de
  caçadores prosperam ou definham).
- **De Eco:** ruína "acorda" (nova dungeon temporária), zona de distorção
  migra, criatura anômala nasce (experimento vazado da Guilda do Fole),
  o Sino submerso soa mais alto que o normal — uma noite apenas.
- **Sociais:** casamento, feira sazonal, peregrinação, julgamento público,
  epidemia, êxodo de refugiados fundando um assentamento novo (!).

## 12.3 Regras

1. Todo evento existe fisicamente no mundo (nada de popup).
2. Todo evento pode acontecer sem o jogador e ser conhecido só pelo rastro
   (a caravana queimada na estrada conta o que você perdeu).
3. Nenhum evento é obrigatório, nenhum tem marcador.
4. Grandes eventos deixam **cicatrizes permanentes** (vila queimada fica
   queimada até NPCs a reconstruírem, tábua por tábua, ao longo de semanas).

---

# 13. EXPLORAÇÃO E NARRATIVA AMBIENTAL

## 13.1 Navegação sem marcadores

- **Mapa diegético:** pergaminho que o personagem desenha ao explorar (nível
  de detalhe = habilidade Sobrevivência + pontos altos visitados). Jogador
  pode anotar livremente (pins manuais próprios, nunca automáticos).
- **Direções por referência:** NPCs dão instruções humanas ("siga o rio até
  o carvalho partido, depois o sol da manhã fica à sua direita"). A
  qualidade da instrução depende do NPC conhecer o caminho (conhecimento
  real, §7.5).
- **Legibilidade do mundo:** torres, fumaça, pássaros circulando, trilhas
  pisadas — o level design é o GPS.

## 13.2 Toda ruína conta uma história (método)

Cada local artesanal é escrito com a técnica **"3 camadas de leitura"**:
1. **Relance (30s):** silhueta e uma anomalia visível que pergunta algo.
2. **Exploração (5–15min):** layout, objetos e restos que respondem parcialmente
   e recompensam (loot contextual — o que faria sentido estar aqui).
3. **Arqueologia (opcional):** cartas, frescos, disposição dos esqueletos,
   detalhe que **recontextualiza** as camadas 1–2 e conecta a outra ruína ou
   facção. Sem texto de lore expositivo — mostrar, não contar.

**Meta de densidade:** ~140 locais artesanais únicos + cavernas únicas
(cada caverna com um autor e um conceito — regra "nenhum copy-paste").

## 13.3 A "história principal" que quase desaparece

O fragmento de Eco do jogador é um **fio opcional de arqueologia pessoal**:
7 locais (não listados, não marcados) contêm ressonâncias que reagem ao
fragmento. Quem conecta os 7 entende (a sua versão de) o que causou o
Silêncio e ganha uma escolha silenciosa e sistêmica sobre o próprio fragmento.
Sem cutscene final. O mundo continua no dia seguinte.

---

# 14. INTERFACE E UX MULTIPLATAFORMA

## 14.1 Princípios

1. **HUD quase invisível:** medidores só aparecem quando relevantes
   (stamina só em esforço; fome só quando importa). Modo "HUD zero" suportado.
2. **Diegético onde possível:** mapa é item, caderno é item, relógio não
   existe (sol/sino da vila).
3. **Uma UI, três entradas:** cada tela funciona 100% com mouse, gamepad e
   toque desde o design (não adaptada depois).

## 14.2 Sistema responsivo

- Layout por **âncoras + containers fluidos** do Godot; tipografia em
  unidades escaláveis com mínimo legível garantido (≥ 12sp físico no Android).
- **Breakpoints:** phone-small, phone-large, tablet, desktop, ultrawide —
  mudam densidade e disposição (inventário: grade 4 col. no phone / 8 no
  desktop + painéis laterais no ultrawide), nunca removem função.
- Safe-area (notch/ilha) respeitada; UI crítica nunca sob polegares.

## 14.3 Telas principais

Inventário (grade + peso), Caderno (mapa/notas/alquimia/rumores ouvidos),
Personagem (habilidades + ferimentos/doenças), Crafting contextual por
estação, Diálogo (roda no touch/gamepad, lista no mouse), Configurações
(vídeo/áudio/controles/acessibilidade por plataforma).

## 14.4 Acessibilidade (dia um)

Remapeamento total, tamanho de fonte, alto contraste, daltonismo (nunca
informação só por cor), legendas com direção de som (crucial: áudio é
gameplay), modo "assistência de mira" gradual, opção de reduzir chacoalho
de câmera.

---

# 15. CONTROLES ADAPTATIVOS

## 15.1 Camada de abstração de ações

Todo o gameplay consome **ações semânticas** (`move`, `look`, `attack_light`,
`attack_heavy`, `parry`, `dodge`, `interact`, `sneak`, `sprint`, `camera`),
nunca inputs crus. Três "esquemas de dispositivo" mapeiam para as mesmas
ações — **detecção automática e troca a quente** (plugou gamepad no celular?
UI e esquema mudam instantaneamente).

## 15.2 PC — teclado e mouse

- WASD + mouse-look; todos os binds remapeáveis; sensibilidade X/Y separada.
- Ataques no mouse (leve/pesado por clique/segurar), aparo em botão dedicado.
- Atalhos numéricos para cinto de itens; menus com hover states e tooltips.

## 15.3 PC/Android — gamepad (Xbox e PlayStation)

- Layout consagrado: gatilhos = ataque/mira; ombros = bloqueio/itens;
  glifos corretos por marca; vibração contextual.
- UI navegável 100% por direcional com foco visível.

## 15.4 Android — touch

- **Stick virtual dinâmico** (nasce onde o polegar toca, zona esquerda) +
  câmera por arrasto na zona direita.
- **Botões contextuais:** o botão de interação só existe quando há algo
  interagível; em combate, cluster direito vira ataque/esquiva/aparo
  (posições ergonômicas editáveis, 3 presets + editor livre).
- **Gestos com julgamento:** swipe curto = esquiva direcional; segurar =
  ataque forte; pinça = zoom do mapa. Nenhum gesto de precisão em situação
  de pressão. **Soft-lock de alvo levemente mais assistivo no touch por
  padrão** — mesma mecânica, tuning honesto por dispositivo.
- Haptics nativos (aparo, passos de criatura grande, sino distante).
- Regra de validação: **toda mecânica nova passa pelo checklist KB+M /
  gamepad / touch antes do merge** (template no repositório).

---

# 16. PIPELINE TÉCNICO

## 16.1 Engine e justificativa

**Godot 4.x** (Forward+ no PC, **Mobile renderer** no Android):
- Um projeto → export Windows + APK/AAB nativo, sem port.
- Leve, open-source, sem royalties; GDScript para iteração + C#/GDExtension
  para hot paths de simulação se necessário.

## 16.2 Arquitetura de código (alto nível)

```
[ Núcleo de Simulação — determinístico, sem cena ]
  WorldClock ─ WorldState ─ EconomySim ─ FactionSim ─ NPCSim ─ EventDirector
        │  (tick lógico: 1/s abstrato; timeslicing)
[ Camada de Encenação — cenas Godot ]
  RegionStreamer ─ NPCBodies ─ CombatActors ─ WeatherFX ─ AudioScape
        │
[ Camada de Entrada/UI ]
  ActionMap (KB+M / pad / touch) ─ HUD responsivo ─ Telas
```

- **Simulação separada da renderização** (headless-testável: o mundo roda em
  testes de CI sem gráficos — validamos economia/facções por 1000 dias
  simulados por script).
- **Dados como recursos declarativos:** itens, NPCs, facções, receitas,
  eventos = arquivos `.tres`/JSON versionáveis e moddáveis.
- **Save:** snapshot do WorldState (comprimido) + delta de cenas. Save em
  qualquer lugar; autosave em dormir/viajar.

## 16.3 Performance por plataforma

| Aspecto | PC | Android |
|---------|----|---------|
| Renderer | Forward+ | Mobile (Vulkan/GLES fallback) |
| Alvo | 60+ fps desbloqueado, ultrawide, 4K | 60 fps (top de linha), 30 fps estável (intermediário) |
| Qualidade | presets + escala de resolução + opções finas | 4 presets automáticos por benchmark de 1º boot |
| Streaming | raio amplo, LODs generosos | raio menor, imposters agressivos, texturas ASTC |
| Simulação | tick pleno | mesmo mundo, timeslicing maior (lógica idêntica, latência de tick abstrato maior — invisível) |
| Bateria | — | cap de fps opcional, modo economia (30fps+shadows low), pausa real em background |
| Memória | — | orçamento 1.5GB; pools; zero alocação em frame loop |
| Loading | — | região inicial < 8s em A54-class |

## 16.4 Qualidade e testes

- CI: `gdlint` + testes unitários (GUT) do núcleo de simulação + **soak test**
  headless (300 dias de mundo/noite) com asserts de sanidade (ninguém com
  preço negativo, população estável, guerras terminam).
- Telemetria de build interna (fps, memória) por cena de teste padrão.

---

# 17. ESTRUTURA COMPLETA DO PROJETO

```
Jogo-RPG/
├── project.godot                  # Configuração Godot (autoloads, input map, layers)
├── export_presets.cfg             # Presets Windows + Android
├── docs/
│   ├── GDD.md                     # Este documento
│   └── checklists/
│       └── input_parity.md        # Checklist KB+M/pad/touch por mecânica
├── source/
│   ├── core/                      # Núcleo de simulação (sem dependência de cena)
│   │   ├── world_clock.gd         # Tempo, calendário, estações
│   │   ├── world_state.gd         # Estado canônico do mundo + save/load
│   │   ├── sim_scheduler.gd       # Timeslicing dos ticks de simulação
│   │   ├── economy/
│   │   │   ├── economy_sim.gd     # Mercados, preços, produção
│   │   │   ├── market.gd          # Mercado local de um assentamento
│   │   │   └── caravan.gd         # Caravanas como agentes de rota
│   │   ├── factions/
│   │   │   ├── faction_sim.gd     # Estratégia, guerra, diplomacia
│   │   │   └── faction.gd         # Estado de uma facção
│   │   ├── npc/
│   │   │   ├── npc_sim.gd         # Registro/tick abstrato dos NPCs
│   │   │   ├── npc_record.gd      # Ficha (rotina, memórias, social...)
│   │   │   ├── needs.gd           # Utility AI: necessidades e scoring
│   │   │   └── gossip.gd          # Propagação de informação
│   │   ├── events/
│   │   │   ├── event_director.gd  # "O Dramaturgo"
│   │   │   └── event_template.gd  # Templates parametrizáveis
│   │   └── weather/
│   │       └── weather_sim.gd     # Clima regional + efeitos sistêmicos
│   ├── game/                      # Camada de encenação
│   │   ├── player/
│   │   │   ├── player.gd/.tscn    # Controlador, stamina, ferimentos
│   │   │   ├── skills.gd          # Progressão por uso
│   │   │   └── survival.gd        # Fome/sono/temperatura/doença
│   │   ├── combat/
│   │   │   ├── combat_actor.gd    # Base comum jogador/NPC em combate
│   │   │   ├── weapon.gd          # Identidade de armas
│   │   │   └── combat_ai.gd       # Táticas de grupo, moral, terreno
│   │   ├── npc_body/
│   │   │   └── npc_body.gd/.tscn  # Corpo encenado + percepção
│   │   ├── world/
│   │   │   ├── region_streamer.gd # Streaming de regiões
│   │   │   └── interactable.gd    # Base de interação
│   │   └── crafting/
│   │       └── crafting.gd        # Receitas por conhecimento
│   ├── ui/
│   │   ├── hud/                   # HUD mínima + controles touch
│   │   └── screens/               # Inventário, caderno, personagem...
│   └── autoload/                  # Singletons: Sim, Actions, UIScale
│       ├── sim.gd                 # Dono do WorldState + save/load
│       ├── actions.gd             # Abstração KB+M/pad/touch + hot-swap
│       └── ui_scale.gd            # Breakpoints e escala de fonte
├── data/                          # Conteúdo declarativo (moddável)
│   ├── items/    ├── npcs/   ├── factions/
│   ├── recipes/  ├── events/ ├── regions/
│   └── economy/
├── assets/                        # Arte, áudio, fontes (placeholder no proto)
├── scenes/                        # Cenas de região e locais artesanais
│   └── regions/
└── tests/                         # GUT: unidade + soak de simulação
```

---

# 18. ROADMAP DE DESENVOLVIMENTO

| Fase | Entrega | Critério de pronto |
|------|---------|--------------------|
| **0. Fundação** *(atual)* | Projeto Godot multiplataforma, núcleo de simulação (clock/economia/facções/NPC abstrato/eventos/clima), input abstrato 3 esquemas, HUD responsiva, protótipo jogável cinza | Soak 300 dias sem asserts; mesmo build roda em desktop e touch |
| 1. Fatia Vertical | Bruma Alta viva (40 NPCs encenados com rotina), combate v1, sobrevivência v1, 5 locais artesanais | "Teste da taverna": observar 10 min gera 3 histórias verossímeis |
| 2. Sistemas Profundos | Fofoca completa, crime/testemunho, crafting por conhecimento, caravanas encenadas, guerra de facções v1 | Guerra emerge e termina sem script em soak |
| 3. Conteúdo | 8 regiões, ~140 locais, 450 NPCs nomeados, os 7 locais do fio do Eco | Densidade: nunca >90s de viagem sem algo autoral |
| 4. Polimento & Ports | Otimização Android final, acessibilidade, balanceamento por playtest cego (sem tutorial!) | Novato entende controles em <5 min nas 3 entradas |

---

*"O melhor elogio possível: dois jogadores conversando descobrirem que
jogaram jogos completamente diferentes — no mesmo mundo."*
