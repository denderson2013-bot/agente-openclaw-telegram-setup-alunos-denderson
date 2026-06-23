# Como instalar seu agente Avalanche (OpenClaw 2026.6.5) + Telegram (sem mexer em terminal)

> Caminho recomendado pra alunos que NAO querem copiar comandos manualmente na VPS.
> Voce abre o Claude Code (ou outro agente que faca SSH) no seu PC, cola UM prompt, responde algumas perguntas, e o agente faz o resto: SSH na VPS, instalacao do OpenClaw 2026.6.5 + a alma Avalanche + 12 subagentes + 4 skills, escolha do LLM (GLM ou GPT Codex), configuracao do Telegram, gateway 24/7.
>
> O agente final e o **agente Avalanche completo** sobre OpenClaw 2026.6.5 (https://github.com/openclaw/openclaw): a mesma alma e a mesma equipe de subagentes/skills da operacao do Denderson, com o nome que voce escolher pro principal (ex: Bia, Paula, Lucas) e o seu nome como dono.
>
> Se voce e desenvolvedor e prefere fazer manualmente, veja o `README.md` (caminho avancado) + `SETUP-AGENTE.md`.

---

## Passo 1 -- Compre uma VPS Ubuntu 22.04 (ou superior)

| Provedor | Plano sugerido | Custo aprox |
|---|---|---|
| **Hostinger** | KVM 2 (2GB RAM) | R$25-50/mes |
| **Hetzner** | CX22 (4GB RAM, 2 vCPU) | EUR 4-6/mes |
| **DigitalOcean** | Basic 2GB | US$12/mes |
| **Vultr** | Cloud Compute 2GB | US$12/mes |

Importante:
- Sistema operacional: **Ubuntu 22.04** (ou 24.04)
- Minimo: **2 GB RAM** (4 GB confortavel)
- Disco: **minimo 20 GB**

---

## Passo 2 -- Anote os dados de acesso da VPS

O provedor te manda:
- **IP publico** (ex: `123.45.67.89`)
- **Usuario** (geralmente `root`)
- **Senha** (string aleatoria)

Anote num lugar seguro. O agente vai te perguntar isso depois.

---

## Passo 3 -- Decida qual LLM voce quer no backend

### Opcao A: GLM 4.5/5 Turbo (Z.ai) -- recomendado pra comecar

**Bom porque:** mais barato (~US$50-80/mes uso medio), context window grande, otimo em PT-BR.

**Como contratar:**
1. Cria conta em [z.ai](https://z.ai)
2. Adiciona meio de pagamento
3. Gera uma API key (parece com `xx.xxx-xxx`)
4. Anota a key

### Opcao B: GPT Codex 5.5 (OpenAI) -- recomendado pra producao

**Bom porque:** mais robusto, qualidade top-tier. Usa a sua assinatura ChatGPT Plus, NAO precisa de API key. O consumo sai da sua quota da assinatura.

**Como contratar:**
1. Tenha conta ChatGPT Plus ativa.
2. So isso. Quando o Claude Code rodar o login OAuth na sua VPS, o CLI vai imprimir uma URL (`https://auth.openai.com/codex/device`) e um codigo curto (ex: `EDYT-MLUDG`).
3. Voce abre essa URL no navegador do seu PC, ja logado na sua conta ChatGPT Plus, e digita o codigo.
4. Autoriza o acesso. O CLI captura o token automaticamente (`OpenAI device code complete`). Pronto, conectado.

> Voce pode comecar com GLM e depois migrar pra GPT sem reinstalar nada (so refaz a auth do outro e `openclaw models set`).

---

## Passo 4 -- Abra o Claude Code (ou outro agente) no seu PC

- **Claude Code oficial:** [claude.com/code](https://claude.com/code) (recomendado)
- **Cursor IDE:** ja vem com integracao Claude

Faz login.

---

## Passo 5 -- Cole o prompt dentro do Claude Code

Copie o prompt de [`prompt-instalador.txt`](./prompt-instalador.txt) e cole na conversa.

Resumo do que esta nele (a REGRA DE FLUXO e o coracao):

> A PRIMEIRA pergunta que o agente faz (depois de IP/usuario/senha da VPS) e qual LLM voce quer: **GLM 4.5 Turbo** (mais barato, API key Z.ai) ou **GPT Codex 5.5** (assinatura ChatGPT Plus, OAuth no navegador, sem API key). So depois da sua resposta ele coleta a credencial certa. Os caminhos sao excludentes -- voce nunca precisa fornecer os dois.

---

## Passo 6 -- Responda as perguntas (uma por vez)

Na ordem:

1. **IP da VPS** -> cole o IP
2. **Usuario** -> geralmente `root`
3. **Senha** -> a senha do provedor
4. **Qual LLM voce quer?** -> responde `glm` ou `gpt-codex`
5. **Credencial do LLM (depende da escolha em 4):**
   - **Se `glm`:** o agente te pede a API key Z.ai. Voce cola, ele configura, fim.
   - **Se `gpt-codex`:** o agente NAO te pede API key. Ele roda o login OAuth na VPS, captura a URL que o CLI imprime, te manda. Voce cola no navegador do seu PC ja logado no ChatGPT Plus, autoriza. O CLI detecta sozinho. Nao precisa colar nada de volta.
6. **Nome do agente** -> ex: `Bia`, `Paula`, `Lucas`, `Marcus`
7. **Seu nome** -> seu nome real
8. **Token do bot Telegram** -> o agente te guia:
   - Telegram -> `@BotFather` -> `/newbot`
   - Escolhe nome (ex: `Bia AI`) e username (ex: `bia_ai_bot`)
   - Copia o token (ex: `1234567890:AAH...`) e cola
9. **Seu user_id no Telegram** -> o agente te guia:
   - Telegram -> `@userinfobot` -> manda qualquer msg
   - Copia o numero (ex: `123456789`) e cola
10. **(Opcional) Chave OpenAI** -> [platform.openai.com/api-keys](https://platform.openai.com/api-keys). Habilita audio Whisper.
11. **(Opcional) Chave ElevenLabs** -> [elevenlabs.io](https://elevenlabs.io). Voz natural nas respostas em audio.

Calma. Uma resposta por vez.

---

## Passo 7 -- Aguarde a instalacao

O agente vai:

1. Fazer SSH na sua VPS automaticamente
2. Rodar o `bootstrap.sh` (Node, Python, ffmpeg, **OpenClaw 2026.6.5** + arquivos Avalanche) -- ~5-10 min
3. Configurar o canal Telegram e o nome do seu agente (via `openclaw config patch` + `agents set-identity`)
4. Instalar a alma + 4 skills e registrar os 12 subagentes
5. Autenticar o LLM escolhido (GLM via API key ou GPT Codex via OAuth)
6. Subir o systemd `openclaw-gateway` (roda 24/7)
7. Testar a conexao com o Telegram

Quando ele falar **"agente no ar"**, abra o Telegram e mande `/start` pro seu bot. Ele responde.

> Se aparecer algum erro durante a instalacao, fica tranquilo: o Claude Code foi instruido a NAO desistir
> no primeiro erro -- ele diagnostica (`openclaw config validate` + `openclaw doctor`), conserta e continua
> ate o bot responder de verdade no Telegram.

---

## Como usar agora

- **Conversar:** abra o chat do bot (ex: `@bia_ai_bot`) e converse normalmente
- **Mandar audio:** o bot transcreve via Whisper (se voce configurou OpenAI) e responde
- **Receber audio:** peca "responde em audio" se voce configurou ElevenLabs

- **Delegar pra equipe:** peca pro agente principal acionar um subagente (ex: "manda o Jonathan escrever um roteiro", "pede pra Juliana montar o processo", "Paulo, sobe esse site"). Sao 12 subagentes: Jonathan (copy), Paulo (dev), Juliana (ops/design), Rafael (projetos), o clone do dono (trafego) e 7 SDRs (Davi, Lucas, Felipe, Matheus, Amanda, Carolina, Bianca).
- **Usar as skills:** "monta uma proposta comercial", "cria uma landing page" (10 templates), "analisa esse perfil do Instagram (BMAD)", "cria um subagente novo".

> Isso e o agente Avalanche completo sobre OpenClaw 2026.6.5. Pra criar mais subagentes ou skills depois, use a skill `criar-subagente` ou veja a doc oficial em https://docs.openclaw.ai

---

## Por que assim (o que rola por baixo)

OpenClaw e um agente CLI nativo (Node.js) que roda na sua VPS como servico systemd. O **canal Telegram e nativo do OpenClaw** -- nao precisa de bot externo.

Quando voce manda mensagem no Telegram:
1. O canal Telegram do OpenClaw recebe via polling
2. OpenClaw injeta a mensagem no agente principal
3. O backend LLM (GLM ou GPT Codex) gera a resposta
4. OpenClaw envia de volta no Telegram

O agente sobrevive a reboots e auto-reinicia se cair (systemd `Restart=always`).

---

## Problemas comuns

**Claude diz que nao consegue fazer SSH:**
Confirme IP, usuario `root`, senha. Se a VPS for nova, espere 2-3 min pra ela bootar.

**O bootstrap demora muito:**
Normal, ate ~10 min em VPS lenta. Deixe rodar.

**`openclaw` nao e encontrado depois de instalar:**
O npm global bin nao esta no PATH. Reroda o bootstrap (ele cria symlink em /usr/local/bin).

**GPT Codex pede browser pra OAuth:**
Normal. O agente te manda uma URL pra abrir no navegador do seu PC. Voce loga no ChatGPT Plus, autoriza, e o token e salvo na VPS automaticamente.

**Telegram nao responde depois de tudo pronto:**
- Token do `@BotFather` certo? `user_id` do `@userinfobot` certo?
- Ja mandou `/start` na primeira vez?
- `openclaw doctor` na VPS pra ver o healthcheck
- `systemctl status openclaw-gateway` pra ver se o gateway esta vivo

**Quero trocar o LLM (GLM <-> GPT):**
Refaz a auth do outro provider e `openclaw models set <provider/model>`, depois `systemctl restart openclaw-gateway`.

---

## Suporte

Issues: https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues

Doc oficial do OpenClaw: https://docs.openclaw.ai

Bom uso. Bem-vindo ao mundo dos agentes autonomos OpenClaw.
