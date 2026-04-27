# Como instalar seu agente OpenClaw + Telegram em 5 minutos (sem mexer em terminal)

> Caminho recomendado pra alunos que NAO querem ficar copiando comandos manualmente na VPS.
> Voce vai abrir o Claude Code (ou outro agente que faca SSH) no seu PC, colar UM prompt, responder algumas perguntas, e o agente faz o resto pra voce: SSH na VPS, instalacao do OpenClaw, escolha do LLM (GLM ou GPT Codex), configuracao do Telegram, deploy.
>
> Se voce e desenvolvedor e prefere fazer manualmente, veja o `README.md` (caminho avancado).

---

## Passo 1 -- Compre uma VPS Ubuntu 22.04 (ou superior)

Recomendacoes:

| Provedor | Plano sugerido | Custo aprox |
|---|---|---|
| **Hostinger** | KVM 4 (4GB RAM, 2 vCPU) | R$30-60/mes |
| **Hetzner** | CX22 (4GB RAM, 2 vCPU) | EUR 4-6/mes |
| **DigitalOcean** | Basic 4GB | US$24/mes |
| **Vultr** | Cloud Compute 4GB | US$24/mes |

Importante na hora de comprar:
- Sistema operacional: **Ubuntu 22.04** (ou 24.04)
- Minimo: **4 GB RAM** (8 GB recomendado se for usar prospect ou rodar 2 agentes na mesma VPS)
- Disco: **minimo 50 GB**
- Localizacao: qualquer uma. Brasil (Sao Paulo) reduz latencia, mas EUA/Europa funciona igual.

---

## Passo 2 -- Anote os dados de acesso da VPS

Quando a VPS estiver pronta, o provedor te manda:

- **IP publico** (ex: `123.45.67.89`)
- **Usuario** (geralmente `root`)
- **Senha** (string aleatoria)

Anote num lugar seguro. O agente vai te perguntar isso depois.

---

## Passo 3 -- Decida qual LLM voce quer no backend

OpenClaw suporta varios LLMs simultaneamente. Voce define um **primary** e quantos **fallbacks** quiser.

### Opcao A: GLM 4.5/5 Turbo (Z.ai) -- recomendado pra comecar

**Bom porque:** mais barato (~US$80/mes uso medio), context window 200k tokens, otimo em PT-BR.

**Como contratar:**
1. Cria conta em [z.ai](https://z.ai)
2. Adiciona meio de pagamento
3. Gera uma API key (vai parecer com `xx.xxx-xxx`)
4. Anota a key

### Opcao B: GPT Codex 5.5 (OpenAI Codex CLI) -- recomendado pra producao

**Bom porque:** mais robusto, qualidade top-tier global. Usa a sua assinatura ChatGPT Plus, NAO precisa de API key, NAO precisa habilitar nada extra. O consumo sai da sua quota da assinatura.

**Como contratar:**
1. Tenha conta ChatGPT Plus ativa (US$20/mes base; pra agente rodando 24/7 em producao costuma compensar um plano maior, ~US$200/mes).
2. So isso. Quando o Claude Code rodar `openclaw configure` na sua VPS, o CLI vai imprimir uma URL no terminal.
3. Voce copia essa URL e cola no navegador do seu PC, ja logado na sua conta ChatGPT Plus.
4. Autoriza o acesso. O CLI captura o token automaticamente e salva. Pronto, conectado.

> **Voce pode comecar com GLM e depois migrar pra GPT** sem reinstalar nada. Veja `docs/MIGRACAO.md`.

---

## Passo 4 -- Abra o Claude Code (ou outro agente) no seu PC

Voce pode usar qualquer agente que faca SSH:

- **Claude Code oficial:** [claude.com/code](https://claude.com/code) (recomendado)
- **Cursor IDE:** ja vem com integracao Claude
- **VS Code + extensao Claude Code**

Faz login.

---

## Passo 5 -- Cole o prompt magico dentro do Claude Code

Copie o prompt abaixo e cole na conversa:

```
Quero instalar meu agente autonomo OpenClaw + Telegram numa VPS Ubuntu.

Acessa o repositorio publico https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson e segue o passo a passo de SETUP-AGENTE.md.

Vou te dar as informacoes conforme voce pedir:
- IP, usuario e senha da VPS
- Qual LLM eu quero usar: GLM 4.5 Turbo (mais barato, ~US$80/mes via API key Z.ai) ou GPT Codex 5.5 (mais robusto, gasta da minha assinatura ChatGPT Plus, sem API key, login via OAuth no navegador)
- Se GLM: API key Z.ai. Se GPT Codex: voce me passa uma URL pra eu colar no navegador ja logado no ChatGPT, eu autorizo, e o CLI conecta sozinho
- Nome do meu agente (ex: Bia, Paula, Lucas)
- Meu nome
- Token do bot Telegram (eu crio no @BotFather quando voce pedir)
- Meu user_id Telegram (eu pego no @userinfobot quando voce pedir)
- (Opcional) Chave OpenAI pra transcrever audios via Whisper
- (Opcional) Chave ElevenLabs pra voz

Faz SSH na VPS por mim, instala o ambiente todo (bootstrap.sh), configura o agente OpenClaw com o LLM escolhido, sobe systemd, e me confirma quando estiver no ar conversando comigo no Telegram.
```

Tambem disponivel em [`prompt-instalador.txt`](./prompt-instalador.txt) pra copiar facil.

---

## Passo 6 -- Responda as perguntas (calmamente, uma por vez)

O agente vai te perguntar (na ordem exata, uma por vez):

> **Importante:** o agente SEMPRE pergunta qual LLM voce quer (passo 4) ANTES de coletar token do LLM (passo 5). Os caminhos GLM e GPT-Codex sao excludentes -- voce nunca precisa fornecer os dois.

1. **IP da VPS** -> cole o IP que o provedor te deu
2. **Usuario** -> geralmente `root`
3. **Senha** -> a senha que o provedor te enviou
4. **Qual LLM voce quer?** -> responde `glm` ou `gpt-codex`
5. **Token do LLM (depende da escolha em 4):**
   - **Se voce respondeu `glm`:** o agente vai te pedir sua API key Z.ai (gera no painel z.ai). Voce cola, ele salva no `.env` da VPS, fim.
   - **Se voce respondeu `gpt-codex`:** o agente NAO te pede API key. Em vez disso, ele roda `openclaw configure` na sua VPS, captura a URL OAuth que o CLI imprime, te manda essa URL. Voce cola no navegador do seu PC ja logado no ChatGPT Plus, autoriza. O CLI da VPS detecta a autorizacao automaticamente. Nao precisa colar nenhuma chave de volta.
6. **Nome do agente** -> escolha um nome (ex: `Bia`, `Paula`, `Lucas`, `Marcus`)
7. **Seu nome** -> seu nome real (vai aparecer nos logs)
8. **Token do bot Telegram** -> nesse momento o agente pode te guiar:
   - Abra o Telegram
   - Procure `@BotFather`
   - Mande `/newbot`
   - Escolha um nome (ex: `Bia AI`) e username (ex: `bia_ai_bot`)
   - Copie o token que aparece (ex: `1234567890:AAH...`)
   - Cole no agente
9. **Seu user_id no Telegram** -> o agente pode te guiar:
   - No Telegram, procure `@userinfobot`
   - Mande qualquer msg
   - Copie o numero (ex: `123456789`)
   - Cole no agente
10. **(Opcional) Chave OpenAI** -> [platform.openai.com/api-keys](https://platform.openai.com/api-keys). Habilita audio Whisper, image gen, mem0 embeddings.
11. **(Opcional) Chave ElevenLabs** -> [elevenlabs.io/profile](https://elevenlabs.io/profile). Voz natural nas respostas em audio.

Calma. Uma resposta por vez. O agente espera voce.

---

## Passo 7 -- Aguarde a instalacao

Enquanto ele trabalha, ele vai:

1. Fazer SSH na sua VPS automaticamente
2. Rodar o `bootstrap.sh` (instala Node, Python, Postgres, OpenClaw CLI, Claude Code CLI, etc) -- leva ~5-10 min
3. Configurar `openclaw.json` baseado no LLM escolhido (GLM ou GPT Codex)
4. Criar os 12 subagentes (jonathan, paulo, juliana, rafael, {{DONO_SLUG}}, davi, lucas, felipe, matheus, amanda, carolina, bianca)
5. Rodar `openclaw configure` pra adicionar o canal Telegram com seu token
6. Subir o systemd `openclaw-gateway` (servico que roda 24/7)
7. Testar a conexao com o Telegram

Quando ele falar **"agente no ar"**, abra o Telegram e mande um "/start" pro seu bot. Ele responde.

---

## Pronto. Como usar agora

- **Conversar:** abra o chat do bot (ex: `@bia_ai_bot`) e converse normalmente
- **Mandar audio:** o bot transcreve via Whisper (se voce configurou OpenAI) e responde
- **Receber audio:** peca pro agente "responde em audio" se voce configurou ElevenLabs
- **Tarefas longas:** peca coisas tipo "pesquisa X na internet", "cria um codigo Y", "agenda Z" -- o agente delega pros 12 subagentes especializados (paulo, juliana, jonathan, rafael, {{DONO}} Clone, 7 SDRs)

---

## Por que assim (entenda o que rola por baixo)

OpenClaw e um agente CLI nativo (escrito em Node.js) que roda na sua VPS como servico systemd. Diferente do Claude Code, o **canal Telegram e nativo do OpenClaw** -- nao precisa de bot externo Python como o setup do Claude Code.

Quando voce manda mensagem no Telegram:
1. Plugin Telegram do OpenClaw recebe via long polling
2. OpenClaw injeta a mensagem no agente principal (`main`, batizado de Naia)
3. Naia decide se delega pra um subagente (paulo, juliana, etc.) ou responde direto
4. Backend LLM (GLM ou GPT Codex) gera a resposta
5. OpenClaw envia de volta no Telegram, mantendo memoria persistente via plugin `openclaw-mem0`

O agente sobrevive a reboots, perda de conexao, falhas de LLM (cai no fallback automatico) e mantem historico via `mem0` + workspace files.

---

## Problemas comuns

**Claude diz que nao consegue fazer SSH:**
Confirme: IP correto, usuario `root`, senha correta. Se a VPS for nova, espere 2-3 min pra ela bootar antes de tentar.

**O bootstrap demora muito:**
Normal. Instalar Node, Postgres, OpenClaw CLI etc pode levar ate 10 min em VPS lenta. Deixe rodar.

**OpenClaw nao instala:**
Verifica que o Node ta na versao 20+ (`node --version`). Se nao, roda `nvm install 22 && nvm use 22` antes de `npm install -g openclaw@2026.4.24`.

**GPT Codex pede browser pra OAuth:**
Normal. O agente vai te pedir pra **copiar uma URL** e abrir no navegador do **seu PC**. Voce loga, autoriza, e o token e salvo na VPS automaticamente.

**Telegram nao responde depois de tudo pronto:**
- Cheque: o token do `@BotFather` esta certo? O `user_id` do `@userinfobot` esta certo?
- Voce ja mandou `/start` pro bot na primeira vez?
- Roda `openclaw doctor` na VPS pra ver healthcheck completo
- Roda `systemctl status openclaw-gateway` pra ver se o gateway esta vivo

**Quero parar/reiniciar o agente:**
Peca pro Claude do seu PC: "faz SSH na minha VPS e reinicia o openclaw-gateway". Ele faz.

**Quero trocar o LLM (de GLM pra GPT, ou vice-versa):**
Veja `docs/MIGRACAO.md`. E so editar `agents.defaults.model.primary` no `openclaw.json` e reiniciar o gateway.

---

## Suporte

Issues: https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues

Bom uso. Bem-vindo ao mundo dos agentes autonomos OpenClaw.
