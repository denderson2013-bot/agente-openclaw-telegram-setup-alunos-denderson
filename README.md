# Agente OpenClaw + Telegram -- Setup automatizado (versao publica pra alunos)

Instala o **OpenClaw original puro** (https://github.com/openclaw/openclaw) numa VPS Ubuntu, conectado ao Telegram, rodando 24/7 via systemd. Sem customizacao: um agente generico, com o nome que voce escolher (ex: Bia, Paula, Lucas).

Suporta dois caminhos de LLM no mesmo agente:

- **GLM 4.5/5 Turbo (Z.ai)** -- mais barato (~US$50-80/mes), otimo em PT-BR, perfeito pra rodar 24/7
- **GPT Codex 5.5 (OpenAI)** -- mais robusto, gasta da sua assinatura ChatGPT Plus. Login via OAuth no navegador, NAO precisa de API key.

---

## INSTALACAO 5 MIN -- Sem mexer em terminal (caminho recomendado)

> Voce nao precisa saber comando nenhum. O Claude Code (ou outro agente que faca SSH) que voce usa no PC faz SSH na sua VPS automaticamente, instala o OpenClaw puro, configura GLM ou GPT como backend, sobe o agente. Voce so responde perguntas.

**6 passos:**

1. Compre uma VPS Ubuntu 22.04+ (Hostinger KVM, Hetzner CX22, DigitalOcean -- 2-4 GB RAM ja serve)
2. Anote IP, usuario (`root`) e senha que o provedor te mandou
3. Abra o Claude Code no seu PC ([claude.com/code](https://claude.com/code) ou Cursor IDE)
4. Cole o prompt de [`prompt-instalador.txt`](./prompt-instalador.txt)
5. Responda as perguntas (qual LLM, IP, tokens, nome do agente)
6. Quando o agente estiver no ar, abra o Telegram e converse

**Guia detalhado:** [`INSTRUCAO-PARA-ALUNO.md`](./INSTRUCAO-PARA-ALUNO.md)

---

## Caminho avancado (manual, pra quem ja sabe terminal)

### 1. Na VPS limpa (Ubuntu 22.04+), como root:

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
```

Instala: Node 22 (via nvm), Python 3, ffmpeg, tmux e o **OpenClaw CLI original** (`npm install -g openclaw@latest`). OpenClaw exige Node 22.19+ (24 recomendado).

### 2. Criar a config base (`/root/.openclaw/openclaw.json`)

Config minima do OpenClaw com o canal Telegram nativo:

```json
{
  "agent": { "name": "Bia", "model": "" },
  "gateway": { "port": 18789, "bind": "loopback" },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "SEU_TOKEN_DO_BOTFATHER",
      "dmPolicy": "allowlist",
      "allowFrom": ["SEU_USER_ID_NUMERICO"],
      "groupPolicy": "allowlist"
    }
  }
}
```

> OpenClaw NAO tem `channels add telegram`. O canal e definido no `openclaw.json`. Com `dmPolicy: "allowlist"` + seu `user_id` em `allowFrom`, voce ja fala com o bot sem precisar de pairing.

### 3. Escolher o backend de LLM

**Opcao A -- GLM 4.5/5 Turbo via Z.ai (API key, mais barato):**

```bash
# Provider OpenAI-compativel custom
openclaw config set models.providers.zai '{
  "baseUrl": "https://api.z.ai/api/coding/paas/v4",
  "apiKey": "SUA_KEY_ZAI",
  "api": "openai-completions",
  "models": [{"id":"glm-5-turbo","name":"GLM-5-Turbo","input":["text"],"contextWindow":204800,"maxTokens":131072}]
}' --strict-json --merge
openclaw models set zai/glm-5-turbo
```

**Opcao B -- GPT Codex 5.5 via OpenAI (OAuth da assinatura, mais robusto, SEM API key):**

```bash
# Provider 'openai', auth OAuth. Em VPS headless use device-code (imprime URL pra colar no navegador).
openclaw models auth login --provider openai --device-code
openclaw models set openai/gpt-5.5
```

Copia a URL que o CLI imprime, cola no navegador do seu PC ja logado no ChatGPT Plus, autoriza. O CLI captura o token sozinho. A partir dai todo uso consome da sua quota da assinatura.

### 4. Subir o gateway via systemd

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/systemd/openclaw-gateway.service -o /etc/systemd/system/openclaw-gateway.service
systemctl daemon-reload
systemctl enable --now openclaw-gateway
systemctl status openclaw-gateway
```

O gateway sobe na porta 18789 e mantem o Telegram polling vivo 24/7.

### 5. Mandar `/start` no bot do Telegram

Pronto. O agente OpenClaw responde.

---

## Arquitetura

```
[Telegram]  <==>  [OpenClaw Gateway systemd 24/7 :18789]
                            |
                            v
                  [Backend LLM: GLM (Z.ai) OU GPT Codex 5.5 (openai/OAuth)]
                            |
                            v
                  [Agente OpenClaw (nome escolhido pelo aluno)]
```

Resiliencia:
- Gateway via systemd `Restart=always`
- Canal Telegram nativo do OpenClaw (sem bot externo Python)
- Backup automatico de `openclaw.json.last-good`
- Cron opcional de healthcheck (`openclaw doctor` a cada 5 min)

---

## Requisitos

- VPS Ubuntu 22.04+ (2-4 GB RAM, 20-50 GB disco) **ou** macOS 13+
- LLM (uma das opcoes):
  - **GLM:** API key Z.ai paga (~US$50-80/mes uso medio)
  - **GPT Codex:** assinatura ChatGPT Plus ativa (auth OAuth, sem API key)
- Conta Telegram (pra @BotFather + @userinfobot)
- (Opcional) OpenAI API key pra audio Whisper
- (Opcional) ElevenLabs API key pra voz

---

## Comparativo GLM vs GPT (resumo)

| Aspecto | GLM 4.5/5 Turbo | GPT Codex 5.5 |
|---|---|---|
| Auth | API key direta (Z.ai) | OAuth no navegador (sem API key, gasta da assinatura ChatGPT Plus) |
| Provider no openclaw.json | `zai` (custom) | `openai` (nativo) |
| Modelo primary | `zai/glm-5-turbo` | `openai/gpt-5.5` |
| Custo | barato | depende do plano ChatGPT Plus |
| Qualidade | excelente em PT-BR | top-tier global |

---

## Comandos do dia a dia

```bash
journalctl -u openclaw-gateway -f       # logs ao vivo
systemctl restart openclaw-gateway      # restart
openclaw gateway status                 # status do gateway
openclaw models list                    # ver modelos
openclaw models set openai/gpt-5.5      # trocar LLM (ou zai/glm-5-turbo)
openclaw models status --probe          # checar LLM acessivel
openclaw doctor                         # healthcheck completo
```

---

## Issues / Suporte

https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues

Doc oficial do OpenClaw: https://docs.openclaw.ai
