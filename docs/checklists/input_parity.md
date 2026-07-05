# Checklist de Paridade de Entrada

> **Regra do projeto (GDD §15.4):** toda mecânica nova passa por este
> checklist ANTES do merge. Se alguma resposta for "não", a mecânica é
> redesenhada — nunca lançada "só no PC" ou "adaptada depois".

## Mecânica: ______________________  |  Data: __________  |  Autor: __________

### 1. Teclado e mouse
- [ ] Todas as ações da mecânica estão mapeadas como ações semânticas no `Actions`?
- [ ] Nenhum bind fixo — tudo remapeável pelo InputMap?
- [ ] Funciona sem precisão de pixel (tolerâncias generosas)?

### 2. Gamepad (Xbox e PlayStation)
- [ ] Todas as ações acessíveis sem combinações de mais de 2 botões?
- [ ] UI da mecânica navegável 100% por direcional com foco visível?
- [ ] Glifos corretos por marca aparecem nos prompts?

### 3. Touchscreen
- [ ] Nenhum gesto exige precisão excessiva dos dedos?
- [ ] Nenhuma ação exige segurar por mais de ~1,5s (fadiga)?
- [ ] Botões contextuais aparecem SÓ quando a ação é possível?
- [ ] Funciona nas zonas ergonômicas (polegares), sem esticar a mão?
- [ ] Testado em phone_small E tablet (breakpoints do UIScale)?

### 4. Paridade
- [ ] O jogador realiza EXATAMENTE as mesmas ações nas três entradas?
- [ ] Nenhum tuning esconde perda de função (assistência ≠ mecânica diferente)?
- [ ] Tempo de aprendizado estimado < 5 min sem tutorial nas três entradas?

### Veredito
- [ ] APROVADA  /  [ ] REDESENHAR — motivo: ______________________
