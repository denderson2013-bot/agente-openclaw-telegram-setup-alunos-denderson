# Agente Avalanche (OpenClaw 2026.6.5) + Telegram -- Setup automatizado (versao publica pra alunos)

Instala o **agente Avalanche completo** sobre o **OpenClaw 2026.6.5** (https://github.com/openclaw/openclaw) numa VPS Ubuntu, conectado ao Telegram, rodando 24/7 via systemd. Vem com a alma Avalanche, **12 subagentes** (Jonathan, Paulo, Juliana, Rafael, clone do dono e 7 SDRs) e **4 skills** (proposta comercial, landing page com 10 templates, BMAD Instagram, criar subagente). Voce escolhe o nome do agente principal (ex: Bia, Paula, Lucas) e o seu nome (dono).

> **Versao do OpenClaw fixada em 2026.6.5** (nunca `@latest`): a 2026.6.9 tem regressao de polling do Telegram e a 2026.4.24 e velha demais.

Suporta dois caminhos de LLM no mesmo agente:

- **GLM 4.5/5 Turbo (Z.ai)** -- mais barato (~US$50-80/mes), otimo em PT-BR, perfeito pra rodar 24/7
- **GPT Codex 5.5 (OpenAI)** -- mais robusto, gasta da sua assinatura ChatGPT Plus. Login via OAuth no navegador, NAO precisa de API key.

---

## INSTALACAO 5 MIN -- Sem mexer em terminal (caminho recomendado)

> Voce nao precisa saber comando nenhum. O Claude Code (ou outro agente que faca SSH) que voce usa no PC faz SSH na sua VPS automaticamente, instala o OpenClaw 2026.6.5 + a alma Avalanche + 12 subagentes + 4 skills, configura GLM ou GPT como backend, sobe o agente. Voce so responde perguntas.

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

Instala: Node 22 (via nvm), Python 3, ffmpeg, tmux, o **OpenClaw CLI 2026.6.5** (`npm install -g openclaw@2026.6.5` -- pin fixo, NUNCA `@latest`) e baixa os arquivos Avalanche (`workspace/`, `agents/`, `skills/`, `database/`) pra `~/agente-avalanche/`. OpenClaw exige Node 22.19+ (24 recomendado).

> Depois do bootstrap, o caminho completo (copiar a alma, instalar as 4 skills e registrar os 12 subagentes via `openclaw agents add`) esta no [`SETUP-AGENTE.md`](./SETUP-AGENTE.md) (ETAPAS 2.7 e 2.8). Os passos manuais abaixo cobrem o nucleo (Telegram + LLM + gateway).

### 2. Configurar o Telegram via `config patch` (NAO escreva o JSON na mao)

> ⚠️ **OpenClaw 2026.6.5:** escrever o `openclaw.json` na mao (blocos `agent`/`gateway`) quebra com
> `OpenClaw config is invalid: <root>: Invalid input` -- o schema mudou. Use `openclaw config patch`,
> que valida na escrita. `dmPolicy` e `groupPolicy` sao enums obrigatorios.

```bash
cat > /tmp/oc-telegram.json <<JSON
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "SEU_TOKEN_DO_BOTFATHER",
      "dmPolicy": "allowlist",
      "groupPolicy": "allowlist",
      "allowFrom": ["SEU_USER_ID_NUMERICO"]
    }
  }
}
JSON
openclaw config patch --file /tmp/oc-telegram.json && rm -f /tmp/oc-telegram.json

# OBRIGATORIO: sem isto o gateway NEM SOBE (exit 78 / "missing gateway.mode")
openclaw config set gateway.mode local
openclaw config validate            # "Config valid"
```

> Enums: `dmPolicy` = `pairing|allowlist|open|disabled` ; `groupPolicy` = `open|disabled|allowlist`.
> `allowlist` nos dois + seu `user_id` em `allowFrom` libera voce direto, sem pairing.
>
> **Nome do agente:** `openclaw config set agent.name` **nao existe** na 2026.6.5 (da `Invalid input`).
> Use `openclaw agents set-identity --agent main --name "SeuNome" --emoji "🦞"` (confirmado ao vivo).

### 3. Escolher o backend de LLM

**Opcao A -- GLM 4.5/5 Turbo via Z.ai (API key, mais barato):**

```bash
# Provider OpenAI-compativel custom -- via config patch (valida na escrita)
cat > /tmp/oc-zai.json <<JSON
{"models":{"providers":{"zai":{
  "baseUrl": "https://api.z.ai/api/coding/paas/v4",
  "apiKey": "SUA_KEY_ZAI",
  "api": "openai-completions",
  "models": [{"id":"glm-5-turbo","name":"GLM-5-Turbo","input":["text"],"contextWindow":204800,"maxTokens":131072}]
}}}}
JSON
openclaw config patch --file /tmp/oc-zai.json && rm -f /tmp/oc-zai.json
openclaw models set zai/glm-5-turbo
```

**Opcao B -- GPT Codex 5.5 via OpenAI (OAuth da assinatura, mais robusto, SEM API key):**

```bash
# Provider 'openai', auth OAuth. Em VPS headless use device-code (imprime URL pra colar no navegador).
openclaw models auth login --provider openai --device-code
openclaw models set openai/gpt-5.5
```

O CLI imprime a URL `https://auth.openai.com/codex/device` + um **Code** (ex `EDYT-MLUDG`). Abre a URL no navegador do seu PC ja logado no ChatGPT Plus, digita o code, autoriza. O CLI da VPS detecta sozinho e imprime `OpenAI device code complete`. A partir dai todo uso consome da sua quota da assinatura.

### 4. Subir o gateway via systemd

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/systemd/openclaw-gateway.service -o /etc/systemd/system/openclaw-gateway.service
# Aponta o ExecStart pro binario real e ajusta o nome na Description
sed -i "s#__OPENCLAW_BIN__#$(command -v openclaw || echo /usr/local/bin/openclaw)#" /etc/systemd/system/openclaw-gateway.service
sed -i "s/AGENTE_NAME_PLACEHOLDER/OpenClaw/" /etc/systemd/system/openclaw-gateway.service
systemctl daemon-reload
systemctl enable --now openclaw-gateway
systemctl status openclaw-gateway
```

> Antes de subir o gateway, instale a alma + skills (ETAPA 2.7 do SETUP-AGENTE.md) e registre os 12 subagentes (ETAPA 2.8, via `openclaw agents add`). As skills sao auto-descobertas de `~/.openclaw/skills/<nome>/SKILL.md` (nao entram no `openclaw.json`); os subagentes vivem em `agents.list[]`.

> Se o gateway nao subir: `journalctl -u openclaw-gateway -n 50 --no-pager`, depois `openclaw config validate`
> e `openclaw doctor`. Causas reais na 2026.6.5: faltou `gateway.mode local`, JSON escrito na mao
> (`Invalid input`), ou placeholder sobrando no unit. Erro nao e parada -- diagnostica e segue ate o bot
> responder no Telegram.

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
       [Agente principal (nome do aluno) + 12 subagentes + 4 skills]
                            |
                            v
        [(opcional) PostgreSQL + pgvector -- memoria persistente]
```

Resiliencia:
- Gateway via systemd `Restart=always`
- Canal Telegram nativo do OpenClaw (sem bot externo Python)
- Backup automatico de `openclaw.json.last-good`
- Cron opcional de healthcheck (`scripts/heartbeat.sh` ou `openclaw doctor`)
- 12 subagentes registrados em `agents.list[]`; 4 skills auto-descobertas em `~/.openclaw/skills/`

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
