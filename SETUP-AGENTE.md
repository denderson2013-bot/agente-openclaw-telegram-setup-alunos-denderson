# SETUP-AGENTE.md v1 -- Instalacao automatica do agente OpenClaw + Telegram

> Claude (ou outro agente que esteja executando), esse arquivo e pra voce executar. Pode ser executado em DOIS modos:
>
> **MODO A -- Local (aluno avancado):** o aluno ja rodou o bootstrap na VPS e ja esta dentro dela. Pula direto pra ETAPA 0.
>
> **MODO B -- Remoto (aluno leigo):** voce esta rodando no PC do aluno (Mac/Win/Linux). O aluno tem so o IP/senha da VPS na mao. Voce vai fazer SSH na VPS e executar tudo remotamente. Le a secao **"INSTRUCOES PRO AGENTE QUE ESTA EXECUTANDO REMOTAMENTE"** abaixo.
>
> Sua missao em qualquer modo:
> - OpenClaw gateway rodando 24/7 via systemd
> - 12 subagentes configurados
> - Backend LLM (GLM ou GPT Codex) ativo
> - Telegram funcionando ponta a ponta
> - (Opcional) Audio bidirecional via Whisper + ElevenLabs

---

## INSTRUCOES PRO AGENTE QUE ESTA EXECUTANDO REMOTAMENTE (MODO B)

### Pre-checks no PC do aluno

Antes de tentar SSH, garanta que tem `ssh` e `sshpass` disponiveis localmente:

**Mac/Linux:**
```bash
which ssh
which sshpass || (
  # Mac:  brew install sshpass    (ou hudochenkov/sshpass tap)
  # Linux Debian/Ubuntu: sudo apt-get install -y sshpass
  echo "instale sshpass conforme o SO do aluno"
)
```

**Windows:** prefira instruir o aluno a usar WSL2.

### Coleta de dados da VPS (uma pergunta por vez)

1. "Qual o IP publico da sua VPS?" -> `VPS_IP`
2. "Qual o usuario de acesso? (geralmente `root`)" -> `VPS_USER`
3. "Qual a senha que o provedor te mandou?" -> `VPS_PASS` (NUNCA mostra ela em log)

### Helper de SSH

```bash
ssh_run() {
  sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$VPS_USER@$VPS_IP" "$@"
}

ssh_copy() {
  sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$1" "$VPS_USER@$VPS_IP:$2"
}
```

### Teste a conexao

```bash
ssh_run "uname -a && cat /etc/os-release | head -5"
```

### Rode o bootstrap remotamente

```bash
ssh_run "curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash"
```

5-10 min. Avise: "to instalando Node, Postgres, OpenClaw CLI e dependencias na sua VPS, espera ~10 min".

### Auth do LLM remotamente

**Se GLM:** so cola a API key no `.env` (ETAPA 3) e fim. Nao precisa browser.

**Se GPT Codex:**
1. `ssh_run "openclaw configure"` (modo interativo)
2. Pergunta `LLM provider` -> `openai-codex`
3. Mode -> `oauth`
4. A CLI imprime URL. Captura essa URL e manda pro aluno.
5. "Abra essa URL no navegador do seu PC, faca login com sua conta ChatGPT Plus, autorize, copie o codigo."
6. Cola o codigo via `ssh_run "openclaw configure --paste-token CODIGO"`
7. Valida: `ssh_run "openclaw config get auth.profiles"`

### Continue o setup remoto

Daqui em diante, todas as `bash` lines do manual abaixo voce executa via `ssh_run`. Quando precisar editar arquivo, use `cat <<'EOF' | ssh_run "cat > /caminho/do/arquivo"` ou `ssh_copy`.

### Final

Apos systemd subir, peca pro aluno mandar `/start` no bot. Confirme. Missao cumprida.

---

## v1 -- O QUE TEM

A v1 (abril 2026) replica fielmente o setup das duas KVMs da Naia do {{DONO}}:

1. **OpenClaw 2026.4.24** instalado globalmente via npm
2. **Backend LLM intercambiavel:**
   - **Opcao A:** GLM 4.5/5 Turbo via Z.ai (provider `zai`, baseUrl `https://api.z.ai/api/coding/paas/v4`, api `openai-completions`, auth `api_key`)
   - **Opcao B:** GPT Codex 5.5 via OpenAI Codex CLI (provider `openai-codex`, auth `oauth`)
3. **12 subagentes:** main + jonathan, paulo, juliana, rafael, {{DONO_SLUG}}, davi, lucas, felipe, matheus, amanda, carolina, bianca
4. **Channels nativos:** Telegram (obrigatorio), Discord (opcional), WhatsApp (opcional)
5. **Plugin mem0** pra memoria persistente vetorial (HNSW + pgvector + OpenAI embeddings)
6. **Skills:** openai-image-gen, openai-whisper-api, sag (semantic agent graph), goplaces (opcional)
7. **systemd `openclaw-gateway`** rodando 24/7

---

## Regras de execucao

1. Leia esse arquivo INTEIRO antes de comecar
2. Execute na ordem exata
3. Pergunte uma coisa por vez, espere a resposta
4. Apos cada bloco grande, valide com check
5. Se falhar, pare e explique. Nao chute solucao
6. Fala PT-BR direto. Sem travessoes

---

## ETAPA 0 -- PLACEHOLDERS (PERSONALIZACAO)

Esse repo e a versao publica. Antes das ETAPAS tecnicas, colete uma pergunta por vez pra preencher os placeholders `{{NOME}}` espalhados por todos os arquivos. Depois faz find+replace global.

**Tabela completa de placeholders:**

| # | Placeholder | Pergunta pro aluno | Exemplo |
|---|---|---|---|
| 1 | `{{DONO}}` | "Qual seu primeiro nome (ou apelido) que vai aparecer no agente?" | `Joao` |
| 2 | `{{DONO_NOME_COMPLETO}}` | "E seu nome completo?" | `Joao Silva` |
| 3 | `{{DONO_SLUG}}` | "Versao 'slug' do seu nome (lowercase, sem espacos, sem acentos). Default: lowercase do anterior." | `joao` |
| 4 | `{{DONO_UPPER}}` | "Nome em CAIXA ALTA (default: uppercase do {{DONO}})" | `JOAO` |
| 5 | `{{EMAIL_DONO}}` | "Seu email" | `joao@meusite.com` |
| 6 | `{{NICHO_DONO}}` | "Nome da sua empresa/marca/produto principal" | `Empresa X` |
| 7 | `{{NICHO_DONO_SLUG}}` | "Slug da empresa" | `empresax` |
| 8 | `{{NICHO_DONO_UPPER}}` | "Empresa em CAIXA ALTA" | `EMPRESAX` |
| 9 | `{{TELEGRAM_USER_ID_DONO}}` | "Seu ID numerico no Telegram. Mande qualquer msg pra @userinfobot e cola o numero." | `123456789` |
| 10 | `{{TELEGRAM_BOT_TOKEN}}` | "Token do bot que voce criou no @BotFather" | `1234567890:AAH...` |
| 11 | `{{TELEGRAM_BOT_USERNAME}}` | "Username do bot (com `_bot` no final, sem o @)" | `meuagente_bot` |
| 12 | `{{INSTAGRAM_HANDLE_DONO}}` | "Seu @ no Instagram (sem o @). Pula se nao tiver." | `joao.silva` |
| 13 | `{{VPS_IP}}` | "IP da VPS principal" | `123.45.67.89` |
| 14 | `{{VPS_IP_ALT}}` | "(Opcional) IP de VPS secundaria" | `123.45.67.90` |
| 15 | `{{DOMINIO_PRINCIPAL}}` | "Seu dominio raiz (sem https, sem www). Pula se nao tiver." | `meusite.com` |
| 16 | `{{DOMINIO_AI}}` | "(Opcional) Dominio secundario .ai ou outro" | `meusite.ai` |
| 17 | `{{LLM_BACKEND}}` | "Qual LLM principal? `glm` ou `gpt-codex`" | `glm` |
| 18 | `{{ZAI_API_KEY}}` | "(Se GLM) API key do Z.ai" | `xx.xxx-xxx` |
| 19 | `{{OPENAI_CODEX_OAUTH_EMAIL}}` | "(Se GPT) email da conta ChatGPT Plus" | `joao@meusite.com` |
| 20 | `{{OPENAI_API_KEY}}` | "(Opcional) API key OpenAI pra Whisper + image gen + mem0 embeddings" | `sk-proj-...` |
| 21 | `{{ELEVENLABS_API_KEY}}` | "(Opcional) API key ElevenLabs pra TTS" | `sk_...` |
| 22 | `{{ELEVENLABS_VOICE_ID}}` | "(Opcional) Voice ID. Default: 21m00Tcm4TlvDq8ikWAM (Rachel)" | `21m00Tcm4TlvDq8ikWAM` |
| 23 | `{{DISCORD_BOT_TOKEN}}` | "(Opcional) Discord bot token" | `MTQ...` |
| 24 | `{{DISCORD_USER_ID_DONO}}` | "(Opcional) Seu user ID no Discord" | `123456789012345678` |
| 25 | `{{PRODUTO_DONO}}` | "Nome do seu produto/SaaS principal" | `Meu CRM` |
| 26 | `{{PRODUTO_DONO_SLUG}}` | "Slug do produto" | `meu-crm` |
| 27 | `{{SENHA_PADRAO}}` | "Senha admin (TROCA depois!). Default: ano+empresa." | `meusite2026` |
| 28 | `{{GITHUB_USERNAME}}` | "Seu username no GitHub" | `joaodev` |
| 29 | `{{AGENTE_NAME}}` | "Nome do agente principal (lowercase, sem espacos). Vai aparecer no banco e nos services." | `bia` |
| 30 | `{{OWNER_NAME}}` | "Nome do dono (vai aparecer no system prompt da Naia). Default: {{DONO}}" | `Joao` |

**Como executar a substituicao:**

```bash
mkdir -p /opt/openclaw-build && cd /opt/openclaw-build
git clone https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson .

cat > /tmp/replace.txt <<EOF
{{DONO}}|VALOR_REAL_1
{{DONO_NOME_COMPLETO}}|VALOR_REAL_2
{{DONO_SLUG}}|VALOR_REAL_3
{{DONO_UPPER}}|VALOR_REAL_4
{{EMAIL_DONO}}|VALOR_REAL_5
{{NICHO_DONO}}|VALOR_REAL_6
{{NICHO_DONO_SLUG}}|VALOR_REAL_7
{{NICHO_DONO_UPPER}}|VALOR_REAL_8
{{TELEGRAM_USER_ID_DONO}}|VALOR_REAL_9
{{TELEGRAM_BOT_TOKEN}}|VALOR_REAL_10
{{TELEGRAM_BOT_USERNAME}}|VALOR_REAL_11
{{VPS_IP}}|VALOR_REAL_12
{{DOMINIO_PRINCIPAL}}|VALOR_REAL_13
{{LLM_BACKEND}}|VALOR_REAL_14
{{ZAI_API_KEY}}|VALOR_REAL_15
{{OPENAI_API_KEY}}|VALOR_REAL_16
{{ELEVENLABS_API_KEY}}|VALOR_REAL_17
{{PRODUTO_DONO}}|VALOR_REAL_18
{{SENHA_PADRAO}}|VALOR_REAL_19
{{GITHUB_USERNAME}}|VALOR_REAL_20
{{AGENTE_NAME}}|VALOR_REAL_21
{{OWNER_NAME}}|VALOR_REAL_22
EOF

while IFS='|' read -r placeholder valor; do
  find . -type f \( -name "*.md" -o -name "*.txt" -o -name "*.sh" -o -name "*.py" -o -name "*.sql" -o -name "*.json" -o -name "*.example" -o -name "*.service" -o -name ".env*" \) \
    -print0 | xargs -0 sed -i "s|$placeholder|$valor|g"
done < /tmp/replace.txt

grep -r "{{[A-Z_]*}}" . | head -10  # deve ser ZERO matches
```

So depois disso, segue pra ETAPA 1.

---

## ETAPA 1 -- BOOTSTRAP

> Pre-requisito ja feito pelo aluno via `bootstrap.sh`. Confirma:

```bash
node --version       # v22.x
python3 --version    # 3.10+
psql --version       # PostgreSQL 16
openclaw --version   # 2026.4.24
claude --version     # 2.1.81 (auth backup)
tmux -V              # 3.x
pnpm --version       # 10.x
ffmpeg -version | head -1
```

Se algo faltar, manda o aluno rodar de novo:
```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
```

---

## ETAPA 2 -- AUTENTICAR O LLM ESCOLHIDO

Pergunta ao aluno: "Qual LLM voce quer? `glm` (Z.ai, mais barato) ou `gpt-codex` (OpenAI, mais robusto)?"

### Opcao A -- GLM 4.5/5 Turbo (Z.ai)

Pergunta a API key Z.ai. Salva como `ZAI_API_KEY`.

```bash
mkdir -p /root/.openclaw
chmod 700 /root/.openclaw

# Salva no .env (lido pelo gateway via systemd EnvironmentFile)
cat > /root/.openclaw/.env <<EOF
OPENAI_API_KEY={{OPENAI_API_KEY}}
EOF
chmod 600 /root/.openclaw/.env

# Vai aparecer dentro do openclaw.json na ETAPA 4
```

### Opcao B -- GPT Codex 5.5 (OAuth)

```bash
openclaw configure
# Escolhe profile: openai-codex
# Mode: oauth
# Segue prompt do CLI (gera URL pra abrir no navegador)
```

Quando o CLI imprime URL, captura e manda pro aluno.

Aluno autoriza, copia codigo. Roda:
```bash
# OpenClaw faz o exchange automaticamente quando o aluno cola o codigo no terminal interativo
# Apos sucesso, valida:
openclaw config get auth.profiles
# Deve mostrar profile "openai-codex:<email>" presente
```

### (Opcional) Anthropic auth

Se vai usar `claude-opus-4-6` como fallback:
```bash
claude auth login --claudeai
# Browser flow, igual ao Claude Code
```

---

## ETAPA 3 -- INICIALIZAR BANCO POSTGRESQL (mem0 backend)

```bash
PGPASS=$(openssl rand -hex 24)
echo "PG_PASSWORD_OPENCLAW=$PGPASS" >> /root/.agente-secrets.env
chmod 600 /root/.agente-secrets.env

sudo -u postgres psql -c "CREATE USER openclaw WITH PASSWORD '$PGPASS';"
sudo -u postgres psql -c "CREATE DATABASE openclaw_memory OWNER openclaw;"
sudo -u postgres psql -d openclaw_memory -c "CREATE EXTENSION IF NOT EXISTS vector;"
sudo -u postgres psql -d openclaw_memory -c "GRANT ALL PRIVILEGES ON DATABASE openclaw_memory TO openclaw;"
```

Aplica `database/schema.sql`:
```bash
sudo -u postgres psql -d openclaw_memory -f /opt/openclaw-build/database/schema.sql
```

Adiciona ao `.env`:
```bash
echo "DATABASE_URL=postgres://openclaw:$PGPASS@127.0.0.1:5432/openclaw_memory" >> /root/.openclaw/.env
echo "MEM0_DB_URL=postgres://openclaw:$PGPASS@127.0.0.1:5432/openclaw_memory" >> /root/.openclaw/.env
```

> O plugin `openclaw-mem0` usa esse banco automaticamente quando habilitado em `openclaw.json` plugins.entries.openclaw-mem0.

---

## ETAPA 4 -- CRIAR `openclaw.json` BASEADO NO LLM ESCOLHIDO

Copia o template do repo:
```bash
cp /opt/openclaw-build/.openclaw-template/openclaw.json /root/.openclaw/openclaw.json
```

Aplica os placeholders ja substituidos. Em particular:

**Se GLM:**
- `models.providers.zai.apiKey` = `{{ZAI_API_KEY}}`
- `models.providers.zai.baseUrl` = `https://api.z.ai/api/coding/paas/v4`
- `models.providers.zai.api` = `openai-completions`
- `agents.defaults.model.primary` = `zai/glm-5-turbo`
- `agents.defaults.model.fallbacks` = `["zai/glm-5.1", "zai/glm-5"]`
- `auth.profiles.zai:default` = `{provider: "zai", mode: "api_key"}`

**Se GPT Codex:**
- `agents.defaults.model.primary` = `openai-codex/gpt-5.5`
- `agents.defaults.model.fallbacks` = `["anthropic/claude-opus-4-6"]`
- `auth.profiles."openai-codex:{{OPENAI_CODEX_OAUTH_EMAIL}}"` = `{provider: "openai-codex", mode: "oauth"}`
- `auth.profiles."anthropic:claude-cli"` = `{provider: "claude-cli", mode: "oauth"}`

Em ambos casos:
- `gateway.port` = `18789`
- `gateway.bind` = `loopback`
- `gateway.auth.token` = `$(openssl rand -hex 32)` (gerar e salvar em `.env` como `OPENCLAW_GATEWAY_TOKEN`)
- `channels.telegram.botToken` = `{{TELEGRAM_BOT_TOKEN}}`
- `channels.telegram.allowFrom` = `["{{TELEGRAM_USER_ID_DONO}}"]`
- `agents.defaults.workspace` = `/root/.openclaw/workspace`
- `agents.list` = 13 entries (main + 12 subagentes -- ver template)
- `plugins.entries.openclaw-mem0.enabled` = `true`
- `skills.entries.openai-whisper-api.apiKey` = `{{OPENAI_API_KEY}}`
- `skills.entries.openai-image-gen.apiKey` = `{{OPENAI_API_KEY}}`

Aplica chmod restritivo (contem secrets):
```bash
chmod 600 /root/.openclaw/openclaw.json
chmod 600 /root/.openclaw/.env
```

Backup automatico:
```bash
cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.last-good
```

Valida o JSON:
```bash
openclaw config validate
# Deve dar OK em todas as secoes
```

---

## ETAPA 5 -- CRIAR WORKSPACE DOS AGENTES

```bash
mkdir -p /root/.openclaw/workspace
mkdir -p /root/.openclaw/workspace-{jonathan,paulo,juliana,rafael,{{DONO_SLUG}},davi,lucas,felipe,matheus,amanda,carolina,bianca}

# Copia os system prompts/SOUL.md de cada agente
cp -r /opt/openclaw-build/workspace/* /root/.openclaw/workspace/

# Cria diretorios necessarios
mkdir -p /root/.openclaw/workspace/{memory,scripts}
mkdir -p /root/.openclaw/{cron,delivery-queue,credentials,flows,logs,media,telegram}

chmod -R 700 /root/.openclaw
```

Workspace contem:
- `SOUL.md` -- identidade da Naia (Quem ela e, missao, hierarquia, regras)
- `USER.md` -- perfil do dono (preencher com info do aluno)
- `BOOTSTRAP.md` -- protocolo de boot (ler memoria, decisoes, projetos)
- `STARTUP.md` -- checklist de inicio de sessao
- `MEMORY.md` -- indice das memorias persistentes
- `IDENTITY.md` -- visual + tom de voz da Naia
- `00-SEGURANCA.md` -- regras anti-jailbreak
- `AGENTS.md` -- lista dos 12 subagentes com missao de cada
- `SUBAGENTS.md` -- guia detalhado de delegacao
- `GUIA-SUBAGENTES.md` -- como usar a tool Agent
- `TOOLS.md` -- tools disponiveis pra Naia (browser, mcp, etc.)

Subagentes:
- `workspace-paulo/SOUL.md` -- dev full-stack
- `workspace-juliana/SOUL.md` -- sub-gerente operacional
- `workspace-jonathan/SOUL.md` -- copywriter
- `workspace-rafael/SOUL.md` -- gestor de projetos
- `workspace-{{DONO_SLUG}}/SOUL.md` -- clone do dono pra trafego
- `workspace-davi/SOUL.md` ate `workspace-bianca/SOUL.md` -- 7 SDRs

---

## ETAPA 6 -- SUBIR systemd `openclaw-gateway`

```bash
cp /opt/openclaw-build/systemd/openclaw-gateway.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now openclaw-gateway
```

Valida:
```bash
systemctl is-active openclaw-gateway
journalctl -u openclaw-gateway -n 30 --no-pager
openclaw health
```

Saidas esperadas:
- `is-active`: `active`
- logs: `[gateway] listening on 127.0.0.1:18789`
- `openclaw health`: `OK` em todos os componentes

---

## ETAPA 7 -- VALIDAR TELEGRAM PONTA A PONTA

```bash
# Ver lista de canais habilitados
openclaw channels list

# Deve mostrar telegram = enabled

# Doctor completo
openclaw doctor
```

Pede pro aluno:
1. Abrir Telegram
2. Buscar `@{{TELEGRAM_BOT_USERNAME}}`
3. Mandar `/start`
4. Confirmar que recebeu resposta

Se nao receber, debug:
```bash
journalctl -u openclaw-gateway -f --no-pager &
# Aluno manda outra msg
# Olha o stream
```

Erros comuns:
- `401 from Telegram API` -> token errado, valida com @BotFather (`/mybots` -> seu bot -> API token)
- `User <ID> not in allowFrom` -> falta adicionar o user_id na config
- `No model available` -> auth do LLM nao foi feita ou expirou (volta ETAPA 2)

---

## ETAPA 8 -- (OPCIONAL) AUDIO BIDIRECIONAL

**Whisper (audio entrada):**
Se aluno deu `OPENAI_API_KEY`, ja foi configurado em `skills.entries.openai-whisper-api.apiKey` na ETAPA 4. Audio entra automatico.

Testa: aluno manda audio voice no Telegram. OpenClaw transcreve e processa.

**ElevenLabs TTS (audio saida):**
Adiciona em `openclaw.json` na secao `messages.tts`:
```json
"tts": {
  "auto": "off",
  "provider": "elevenlabs",
  "elevenlabs": {
    "apiKey": "{{ELEVENLABS_API_KEY}}",
    "voiceId": "{{ELEVENLABS_VOICE_ID}}"
  }
}
```

Reinicia: `systemctl restart openclaw-gateway`.

Aluno pede ao agente "responde em audio" -> Naia gera ElevenLabs e envia.

---

## ETAPA 9 -- (OPCIONAL) DISCORD / WHATSAPP

**Discord:**
```bash
openclaw channels add discord --token {{DISCORD_BOT_TOKEN}}
# Ou edita openclaw.json: channels.discord.enabled = true, .token = "..."
systemctl restart openclaw-gateway
```

**WhatsApp (via Baileys, pareamento QR):**
```bash
openclaw channels add whatsapp
# Imprime QR code. Aluno escaneia com Whats Web do celular pessoal
# Salva sessao em /root/.openclaw/credentials/whatsapp/
systemctl restart openclaw-gateway
```

---

## ETAPA 10 -- CRONS DE MANUTENCAO

```bash
crontab -l > /tmp/cron.tmp 2>/dev/null || true
cat >> /tmp/cron.tmp <<'EOF'
# Healthcheck OpenClaw a cada 5 min
*/5 * * * * /usr/bin/openclaw doctor --quiet >> /var/log/openclaw-doctor.log 2>&1 || /usr/bin/systemctl restart openclaw-gateway

# Flush conversation pro banco a cada 2h
0 */2 * * * /bin/bash /root/.openclaw/workspace/scripts/flush-conversation-to-db.sh

# Reindex memoria toda manha 9h
0 9 * * * /usr/bin/openclaw memory reindex >> /var/log/openclaw-memory.log 2>&1

# Heartbeat a cada hora
30 * * * * /usr/bin/openclaw config get meta.lastTouchedVersion >> /var/log/openclaw-heartbeat.log 2>&1
EOF
crontab /tmp/cron.tmp
rm /tmp/cron.tmp
```

---

## ETAPA 11 -- RESTART E VALIDAR FINAL

```bash
systemctl restart openclaw-gateway
sleep 5

# Bot vivo
systemctl is-active openclaw-gateway

# Doctor
openclaw doctor

# Banco respondendo
sudo -u postgres psql -d openclaw_memory -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';"

# LLM respondendo
openclaw infer simple --model "$(openclaw config get agents.defaults.model.primary)" --prompt "Responde com OK."
```

Mensagem final pro aluno:
- LLM ativo: `<glm | gpt-codex>`
- Bot Telegram: `@{{TELEGRAM_BOT_USERNAME}}`
- Comandos uteis (ETAPA 12)
- Custos estimados (ver README.md)
- Como customizar Naia / subagentes (editar `/root/.openclaw/workspace/SOUL.md` etc.)

---

## ETAPA 12 -- COMANDOS UTEIS DO DIA A DIA

**Logs ao vivo:**
```bash
journalctl -u openclaw-gateway -f
openclaw logs -f
```

**Restart:**
```bash
systemctl restart openclaw-gateway
```

**Editar personalidade:**
```bash
nano /root/.openclaw/workspace/SOUL.md
# Nao precisa restart, agente le na proxima sessao
```

**Editar config:**
```bash
nano /root/.openclaw/openclaw.json
systemctl restart openclaw-gateway
```

**Trocar LLM (GLM <-> GPT):**
```bash
openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5
openclaw config set agents.defaults.model.fallbacks '["anthropic/claude-opus-4-6"]'
systemctl restart openclaw-gateway
```

**Ver memoria:**
```bash
openclaw memory search "ultimo lancamento"
sudo -u postgres psql -d openclaw_memory -c "SELECT COUNT(*) FROM mem0_memories"
```

---

## TROUBLESHOOTING

| Problema | Solucao |
|---|---|
| Gateway nao sobe | `journalctl -u openclaw-gateway -n 50`. Maioria e `openclaw.json` invalido. Restaura backup: `cp /root/.openclaw/openclaw.json.last-good /root/.openclaw/openclaw.json && systemctl restart openclaw-gateway` |
| Telegram nao recebe msg | `openclaw doctor`, depois `openclaw channels list`. Confirma token e allowFrom. |
| GLM da 401/403 | API key Z.ai sem credito ou expirada. Recarrega no painel. |
| GPT Codex pede login | OAuth expirou. `openclaw configure` -> profile openai-codex -> reauth. |
| Subagente nao responde | Verifica `agents.list[main].subagents.allowAgents`. Adiciona se faltar. |
| Mem0 nao salva | `psql -d openclaw_memory -c "SELECT 1"`. Se falhar, banco caiu. `systemctl restart postgresql`. |
| VPS reboot e nao volta | `systemctl is-enabled openclaw-gateway` -> tem que dar `enabled`. |
| Audio nao transcreve | Confere `skills.entries.openai-whisper-api.apiKey` no `openclaw.json`. |
| Audio nao sai | Confere `messages.tts.elevenlabs.apiKey` + voiceId valido. |

---

## FIM DO SETUP v1

Em caso de duvida, abrir issue:
https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues
