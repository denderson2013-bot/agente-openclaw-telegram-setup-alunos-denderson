# SETUP-AGENTE.md v3 -- Instalacao do OpenClaw ORIGINAL puro + Telegram

> Claude (ou outro agente que esteja executando), esse arquivo e pra VOCE executar.
>
> ## PERSISTENCIA (LER PRIMEIRO -- NAO DESISTE NO PRIMEIRO ERRO)
>
> Se qualquer comando der erro, NAO pare nem desista: diagnostique com `openclaw config validate`
> e `openclaw doctor`, corrija e continue. So considere a instalacao concluida quando o agente
> responder de verdade no Telegram. Persista ate o objetivo. Erro nao e parada -- e o proximo passo
> do diagnostico. Roteiro testado ao vivo em Ubuntu 25.10 com OpenClaw 2026.6.5 (latest).
>
> O objetivo e instalar o **OpenClaw original puro** (https://github.com/openclaw/openclaw) numa VPS Ubuntu,
> conectado ao Telegram, rodando 24/7 via systemd. Sem customizacao, sem subagentes prontos, sem skills extras.
> Um agente generico, com o nome que o aluno escolher (ex: Bia, Paula, Lucas).
>
> O instalador nativo do OpenClaw (`openclaw onboard`) e interativo e as vezes engasga numa VPS headless.
> Esse passo a passo contorna isso com etapas controladas, idempotentes e com checagem de erro a cada bloco.
>
> Modos de execucao:
>
> **MODO A -- Local:** o aluno ja esta dentro da VPS. Pula direto pra ETAPA 0.
>
> **MODO B -- Remoto (recomendado):** voce roda no PC do aluno (Mac/Win/Linux). O aluno te da IP/usuario/senha
> da VPS. Voce faz SSH e executa tudo remotamente. Le a secao "INSTRUCOES PRO AGENTE REMOTO (MODO B)" abaixo.
>
> Resultado final em qualquer modo:
> - OpenClaw gateway rodando 24/7 via systemd
> - Backend LLM escolhido (GLM via Z.ai OU GPT Codex via OAuth) ativo
> - Telegram funcionando ponta a ponta com o nome do agente que o aluno escolheu

---

## REGRA DE FLUXO DE LLM (OBRIGATORIA -- LER PRIMEIRO)

A **PRIMEIRA** pergunta que voce faz (depois de coletar IP/usuario/senha da VPS) e:

> "Qual LLM voce quer usar: **GLM 4.5 Turbo** (mais barato, API key Z.ai) ou **GPT Codex 5.5**
> (assinatura ChatGPT Plus, OAuth no navegador, sem API key)?"

So **depois da resposta** voce decide qual credencial coletar. Os dois caminhos sao mutuamente exclusivos:

- **Se GLM:** voce pede a **API key Z.ai** e usa ela na configuracao. Nao mencione OAuth nem ChatGPT Plus.
- **Se GPT Codex:** voce **NAO pede API key** (nao existe API key pra Codex CLI). Em vez disso, voce roda o
  login OAuth na VPS, captura a **URL** que o CLI imprime, manda a URL pro aluno colar no navegador do PC dele
  **ja logado no ChatGPT Plus**, ele autoriza, e o CLI da VPS detecta sozinho.

NUNCA pergunte "API key do LLM" antes de saber qual LLM o aluno escolheu.

---

## INSTRUCOES PRO AGENTE REMOTO (MODO B)

### Pre-checks no PC do aluno

Garanta `ssh` e `sshpass` localmente:

**Mac/Linux:**
```bash
which ssh
which sshpass || echo "instale sshpass: Mac 'brew install hudochenkov/sshpass/sshpass' | Ubuntu 'sudo apt-get install -y sshpass'"
```

**Windows:** instrua o aluno a usar WSL2.

### Coleta de dados da VPS (uma pergunta por vez)

1. "Qual o IP publico da sua VPS?" -> `VPS_IP`
2. "Qual o usuario de acesso? (geralmente `root`)" -> `VPS_USER`
3. "Qual a senha que o provedor te mandou?" -> `VPS_PASS` (NUNCA mostra em log)

### Helper de SSH

```bash
ssh_run() {
  sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$VPS_USER@$VPS_IP" "$@"
}
ssh_run_tty() {
  sshpass -p "$VPS_PASS" ssh -tt -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$VPS_USER@$VPS_IP" "$@"
}
ssh_copy() {
  sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$1" "$VPS_USER@$VPS_IP:$2"
}
```

### Teste a conexao

```bash
ssh_run "uname -a && head -5 /etc/os-release"
```

Daqui em diante, toda linha `bash` do manual abaixo voce executa via `ssh_run` (ou `ssh_run_tty` quando precisar de terminal interativo, como o login OAuth do Codex). Pra editar arquivos use `cat <<'EOF' | ssh_run "cat > /caminho"` ou `ssh_copy`.

No final, peca pro aluno mandar `/start` no bot. Confirme que respondeu. Missao cumprida.

---

## O QUE A v2 INSTALA

OpenClaw **original puro** (https://github.com/openclaw/openclaw), nada customizado:

1. **OpenClaw CLI** instalado globalmente via npm (`openclaw@latest`)
2. **Backend LLM intercambiavel:**
   - **Opcao A:** GLM 4.5/5 Turbo via Z.ai (provider custom OpenAI-compativel)
   - **Opcao B:** GPT Codex 5.5 via OpenAI Codex (provider `openai`, auth OAuth da assinatura ChatGPT Plus)
3. **Canal Telegram nativo** do OpenClaw (sem bot externo Python)
4. **systemd `openclaw-gateway`** rodando 24/7
5. (Opcional) Audio: Whisper (entrada) via OpenAI API key, TTS (saida) via ElevenLabs

Sem subagentes pre-configurados, sem skills custom, sem banco de memoria custom. O agente nasce generico e o aluno personaliza depois se quiser.

---

## Regras de execucao

1. Leia esse arquivo INTEIRO antes de comecar
2. Execute na ordem exata
3. Pergunte uma coisa por vez, espere a resposta
4. Apos cada bloco grande, valide com o check indicado
5. Se falhar, PARE e explique. Nao chute solucao
6. Fala PT-BR direto

---

## ETAPA 0 -- COLETAR DADOS DO AGENTE

Colete, uma pergunta por vez:

| Variavel | Pergunta pro aluno | Exemplo |
|---|---|---|
| `AGENTE_NAME` | "Qual nome voce quer dar ao seu agente?" (so cosmetico no systemd na 2026.6.5 -- ver ETAPA 2) | `Bia` |
| `OWNER_NAME` | "Qual seu nome (vai aparecer como dono do agente)?" | `Joao` |
| `LLM_BACKEND` | "Qual LLM: `glm` ou `gpt-codex`?" (REGRA DE FLUXO acima) | `glm` |
| `ZAI_API_KEY` | (so se GLM) "Cola sua API key Z.ai" | `xx.xxx-xxx` |
| `TELEGRAM_BOT_TOKEN` | "Token do bot que voce criou no @BotFather" | `123:AAH...` |
| `TELEGRAM_USER_ID` | "Seu ID numerico no Telegram (mande msg pra @userinfobot)" | `123456789` |
| `TELEGRAM_BOT_USERNAME` | "Username do bot (sem o @)" | `bia_ai_bot` |
| `OPENAI_API_KEY` | (opcional) "Chave OpenAI pra transcrever audios via Whisper" | `sk-proj-...` |
| `ELEVENLABS_API_KEY` | (opcional) "Chave ElevenLabs pra voz" | `sk_...` |
| `ELEVENLABS_VOICE_ID` | (opcional) "Voice ID. Default Rachel" | `21m00Tcm4TlvDq8ikWAM` |

Guarde esses valores. Voce vai usa-los nas etapas seguintes.

---

## ETAPA 1 -- BOOTSTRAP (dependencias + OpenClaw)

Roda o bootstrap na VPS. Instala Node 22 (via nvm), Python 3, ffmpeg, tmux e o **OpenClaw CLI original** (`npm install -g openclaw@latest`):

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
```

Avise: "to instalando Node, ffmpeg e o OpenClaw na sua VPS, leva ~5-10 min".

Valida (idempotente -- se algo faltar, reroda o bootstrap):

```bash
node --version       # v22.x ou superior (Node 24 recomendado pelo OpenClaw)
python3 --version    # 3.10+
ffmpeg -version | head -1
openclaw --version   # qualquer versao recente
```

> **Troubleshooting:** se `openclaw --version` falhar com "command not found", o npm global bin nao esta no PATH.
> Reroda o bootstrap (ele cria symlinks em /usr/local/bin) ou exporta o PATH do nvm:
> `export PATH="$(npm config get prefix)/bin:$PATH"`.

---

## ETAPA 2 -- CRIAR A CONFIG DO TELEGRAM (via `config patch`, NAO na mao)

OpenClaw le a config de `~/.openclaw/openclaw.json` (no Linux como root: `/root/.openclaw/openclaw.json`).

> **NAO escreva o `openclaw.json` na mao.** Na versao 2026.6.5 o schema mudou e escrever os blocos
> `agent: {name, model}` e `gateway: {port, bind}` a mao quebra com:
> `OpenClaw config is invalid: <root>: Invalid input`. O jeito certo e usar `openclaw config patch`,
> que **valida na escrita** (merge nao destrutivo). O schema do canal `telegram` exige `dmPolicy` e
> `groupPolicy` (enums).

Garante a pasta e aplica o patch do canal Telegram:

```bash
mkdir -p /root/.openclaw
chmod 700 /root/.openclaw

cat > /tmp/oc-telegram.json <<JSON
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_BOT_TOKEN",
      "dmPolicy": "allowlist",
      "groupPolicy": "allowlist",
      "allowFrom": ["$TELEGRAM_USER_ID"]
    }
  }
}
JSON

openclaw config patch --file /tmp/oc-telegram.json
rm -f /tmp/oc-telegram.json
```

> **Enums validos:**
> - `dmPolicy`  = `pairing` | `allowlist` | `open` | `disabled`
> - `groupPolicy` = `open` | `disabled` | `allowlist`
>
> Usar `allowlist` nos dois + seu `user_id` em `allowFrom` libera voce (o dono) direto, sem pairing.
> Como o `$TELEGRAM_BOT_TOKEN` e `$TELEGRAM_USER_ID` ja entram expandidos no heredoc (sem aspas no `JSON`),
> nao precisa de `sed` depois. O arquivo temporario e apagado pra nao deixar o token em `/tmp`.

### Nome do agente (FIX -- VERIFICAR)

> ⚠️ Na 2026.6.5 **NAO existe** `openclaw config set agent.name "..."` -- da `Invalid input` (o objeto
> `agent` no schema nao tem `properties` simples pra um "name"). Esse passo foi REMOVIDO do roteiro.
> O agente sobe e responde no Telegram **sem** nome custom (testado ao vivo).
>
> Se o aluno quiser nome/persona, o caminho NAO esta confirmado nesta versao. Antes de tentar qualquer
> coisa, inspecione o schema da VPS pra descobrir o campo real:
> ```bash
> openclaw config schema | less        # procure por "agent", "persona", "name", "identity"
> openclaw configure --help            # pode existir um fluxo de persona/identidade
> openclaw onboard --help
> ```
> So aplique se o schema confirmar o caminho. Se nao confirmar, **deixe sem nome custom** e siga em frente
> (funciona). NAO invente sintaxe.

Valida a config e faz backup do estado bom:

```bash
openclaw config validate              # deve dizer "Config valid"
cp /root/.openclaw/openclaw.json /root/.openclaw/openclaw.json.last-good
```

---

## ETAPA 2.5 -- DEFINIR `gateway.mode` (OBRIGATORIO -- sem isso o gateway NEM SOBE)

> **FIX critico:** na 2026.6.5 o `gateway.mode` e OBRIGATORIO. Sem ele o systemd morre na hora com
> `Gateway start blocked: existing config is missing gateway.mode ... set gateway.mode=local manually`
> (exit 78 / CONFIG). NAO pule este passo.

```bash
openclaw config set gateway.mode local
openclaw config validate              # deve dizer "Config valid"
```

---

## ETAPA 3 -- AUTENTICAR E DEFINIR O LLM ESCOLHIDO

> Ordem que FUNCIONOU ao vivo: (1) patch do telegram [ETAPA 2] -> (2) `gateway.mode local` [ETAPA 2.5]
> -> (3) auth do LLM [esta etapa] -> (4) `openclaw models set ...` -> (5) systemd `enable --now` [ETAPA 5]
> -> (6) validar no Telegram [ETAPA 6].

### Opcao A -- GLM 4.5/5 Turbo (Z.ai, API key)

GLM e um provider OpenAI-compativel custom. Adiciona o provider e o modelo via `openclaw config set` (merge nao destrutivo), depois define como primary.

```bash
# Adiciona o provider zai (OpenAI-compativel) com a key do aluno.
# Usa um arquivo temporario com config patch (valida na escrita) -- a key entra expandida no heredoc.
cat > /tmp/oc-zai.json <<JSON
{
  "models": {
    "providers": {
      "zai": {
        "baseUrl": "https://api.z.ai/api/coding/paas/v4",
        "apiKey": "$ZAI_API_KEY",
        "api": "openai-completions",
        "models": [
          {"id": "glm-5-turbo", "name": "GLM-5-Turbo", "input": ["text"], "contextWindow": 204800, "maxTokens": 131072},
          {"id": "glm-5.1", "name": "GLM-5.1", "input": ["text"], "contextWindow": 204800, "maxTokens": 131072}
        ]
      }
    }
  }
}
JSON
openclaw config patch --file /tmp/oc-zai.json
rm -f /tmp/oc-zai.json

# Define o modelo primary e um fallback
openclaw models set zai/glm-5-turbo
openclaw models fallbacks add zai/glm-5.1
```

Valida:
```bash
openclaw config validate            # "Config valid"
openclaw models list --provider zai
openclaw models status --probe      # deve mostrar zai acessivel
```

> **Troubleshooting GLM:** `401/403` = API key Z.ai sem credito ou errada. `provider not found` = o `config set`
> nao gravou; confere `openclaw config get models.providers.zai`.

### Opcao B -- GPT Codex 5.5 (OAuth da assinatura ChatGPT Plus, SEM API key)

O provider correto no OpenClaw e **`openai`** (a rota Codex/subscription roda pelo plugin `codex` nativo).
A auth e OAuth, consome da quota da assinatura ChatGPT Plus do aluno. NAO existe API key pra Codex -- nao procure.

Como a VPS e headless, use o **device-code flow** (imprime URL pra abrir no navegador do aluno):

```bash
openclaw models auth login --provider openai --device-code
```

O CLI imprime uma **URL** (`https://auth.openai.com/codex/device`) **e um Code** (ex: `EDYT-MLUDG`).
Testado ao vivo: esse fluxo FUNCIONA. Captura a URL e o Code e manda pro aluno:

> "Abre `https://auth.openai.com/codex/device` no navegador do seu PC, ja logado na sua conta ChatGPT Plus.
> Digita o codigo **EDYT-MLUDG** (o que aparecer pra voce), autoriza. Nao precisa colar nada de volta aqui --
> o CLI da VPS detecta sozinho e imprime `OpenAI device code complete`."

> No MODO B (remoto), rode esse comando com `ssh_run_tty` (precisa de terminal) e leia o stdout pra extrair
> a URL e o Code.

Aguarde o CLI imprimir `OpenAI device code complete` (30-60s apos o aluno autorizar). Depois define o modelo:

```bash
openclaw models set openai/gpt-5.5
openclaw config validate         # "Config valid"
openclaw models status --probe   # deve mostrar openai autenticado e acessivel
```

> **Troubleshooting Codex:** se travar esperando o callback e o aluno nao autorizar em ~5 min, aborta (Ctrl-C)
> e refaz o `openclaw models auth login --provider openai --device-code`. Nunca tente "API key pra Codex".

---

## ETAPA 4 -- (OPCIONAL) AUDIO

**Whisper (audio de entrada):** se o aluno deu `OPENAI_API_KEY`, exporta pro gateway ler:

```bash
mkdir -p /root/.openclaw
echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> /root/.openclaw/.env
chmod 600 /root/.openclaw/.env
```

> Audio de entrada do Telegram e transcrito automaticamente quando ha `OPENAI_API_KEY` no ambiente do gateway.

**ElevenLabs (audio de saida):** se o aluno deu `ELEVENLABS_API_KEY`, adiciona em `messages.tts`:

```bash
cat > /tmp/oc-tts.json <<JSON
{
  "messages": {
    "tts": {
      "auto": "off",
      "provider": "elevenlabs",
      "elevenlabs": {
        "apiKey": "$ELEVENLABS_API_KEY",
        "voiceId": "${ELEVENLABS_VOICE_ID:-21m00Tcm4TlvDq8ikWAM}"
      }
    }
  }
}
JSON
openclaw config patch --file /tmp/oc-tts.json
rm -f /tmp/oc-tts.json
openclaw config validate
```

Se o aluno nao quer audio, pula essa etapa inteira.

---

## ETAPA 5 -- SUBIR O systemd `openclaw-gateway`

Baixa o unit do repo, ajusta o nome e sobe:

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/systemd/openclaw-gateway.service \
  -o /etc/systemd/system/openclaw-gateway.service

# 1) Substitui o nome do agente na descricao (se nao tiver nome, vira "OpenClaw")
sed -i "s/AGENTE_NAME_PLACEHOLDER/${AGENTE_NAME:-OpenClaw}/" /etc/systemd/system/openclaw-gateway.service

# 2) Aponta o ExecStart pro binario REAL desta VPS (geralmente /usr/local/bin/openclaw)
OPENCLAW_BIN="$(command -v openclaw || echo /usr/local/bin/openclaw)"
sed -i "s#__OPENCLAW_BIN__#$OPENCLAW_BIN#" /etc/systemd/system/openclaw-gateway.service

systemctl daemon-reload
systemctl enable --now openclaw-gateway
```

> **FIX:** o unit do repo NAO carrega mais placeholder cru no `ExecStart` -- ele traz `__OPENCLAW_BIN__`,
> que o `sed` acima troca pelo caminho real de `command -v openclaw`. E o `AGENTE_NAME_PLACEHOLDER` da
> Description vira o nome do agente (ou "OpenClaw" se o aluno nao deu nome). Se algum placeholder sobrar,
> o gateway nao sobe -- confere com `grep -E 'PLACEHOLDER|__OPENCLAW_BIN__' /etc/systemd/system/openclaw-gateway.service`
> (nao pode retornar nada).

> O unit so referencia o `.env` se ele existir. Se voce nao criou `/root/.openclaw/.env` na ETAPA 4,
> o systemd ignora (a linha usa `EnvironmentFile=-` com o `-` que torna o arquivo opcional).

Valida:

```bash
systemctl is-active openclaw-gateway      # deve dar: active
openclaw gateway status                    # deve mostrar running
journalctl -u openclaw-gateway -n 30 --no-pager
```

> **Troubleshooting:** se `is-active` der `failed`, roda `journalctl -u openclaw-gateway -n 50 --no-pager`.
> Causas reais ja vistas na 2026.6.5:
> - `Gateway start blocked: ... missing gateway.mode` (exit 78) -> faltou a ETAPA 2.5:
>   `openclaw config set gateway.mode local && systemctl restart openclaw-gateway`.
> - `OpenClaw config is invalid: <root>: Invalid input` -> alguem escreveu o JSON na mao. Refaz via
>   `openclaw config patch` (ETAPA 2) + `openclaw config validate`.
> - Placeholder sobrando no unit (`__OPENCLAW_BIN__` ou `PLACEHOLDER`) -> refaz os `sed` da ETAPA 5.
> - Sempre roda `openclaw config validate` e `openclaw doctor` antes de desistir.
>
> Se piorar, restaura o backup:
> `cp /root/.openclaw/openclaw.json.last-good /root/.openclaw/openclaw.json && systemctl restart openclaw-gateway`.

---

## ETAPA 6 -- VALIDAR TELEGRAM PONTA A PONTA

```bash
openclaw doctor
```

Pede pro aluno:
1. Abrir Telegram, buscar `@TELEGRAM_BOT_USERNAME` (o username dele)
2. Mandar `/start`
3. Confirmar que recebeu resposta

Se nao receber, debug ao vivo:

```bash
journalctl -u openclaw-gateway -f --no-pager
# aluno manda outra msg, voce olha o stream
```

Erros comuns:
- `401 from Telegram` -> token errado. Valida no @BotFather (`/mybots` -> bot -> API token).
- `user not in allowFrom` -> o user_id do aluno nao esta em `channels.telegram.allowFrom`. Confere com
  `openclaw config get channels.telegram.allowFrom` e adiciona o ID numerico certo.
- `no model` / `model not available` -> a auth do LLM (ETAPA 3) nao concluiu. Refaz a ETAPA 3.

> Se `dmPolicy` estivesse em `pairing` (nao e o nosso caso, usamos `allowlist`), seria preciso aprovar:
> `openclaw pairing list telegram` -> `openclaw pairing approve telegram <CODE>`.

---

## ETAPA 7 -- (OPCIONAL) CRON DE HEALTHCHECK

Mantem o gateway de pe se cair:

```bash
( crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/openclaw doctor >/dev/null 2>&1 || /usr/bin/systemctl restart openclaw-gateway" ) | crontab -
```

> Ajusta o caminho do `openclaw` (`which openclaw`) e do `systemctl` se forem diferentes na VPS.

---

## ETAPA 8 -- VALIDACAO FINAL

```bash
systemctl is-active openclaw-gateway   # active
openclaw doctor                         # sem erros criticos
openclaw models status --probe          # LLM escolhido acessivel
```

Mensagem final pro aluno:
- LLM ativo: `<glm | gpt-codex>`
- Bot Telegram: `@TELEGRAM_BOT_USERNAME`
- Agente: `AGENTE_NAME`
- Comandos uteis: ETAPA 9

---

## ETAPA 9 -- COMANDOS DO DIA A DIA

```bash
# Logs ao vivo
journalctl -u openclaw-gateway -f
# Restart
systemctl restart openclaw-gateway
# Editar config e reiniciar
nano /root/.openclaw/openclaw.json && systemctl restart openclaw-gateway
# Ver / trocar modelo
openclaw models list
openclaw models set openai/gpt-5.5        # ou zai/glm-5-turbo
systemctl restart openclaw-gateway
# Status do gateway e dos modelos
openclaw gateway status
openclaw models status --probe
openclaw doctor
```

**Trocar de LLM depois (GLM <-> Codex):** so refaz a auth do outro provider (ETAPA 3, opcao A ou B) e
`openclaw models set <provider/model>`, depois `systemctl restart openclaw-gateway`.

---

## TROUBLESHOOTING (resumo dos erros do instalador nativo)

| Problema | Solucao |
|---|---|
| `openclaw onboard` trava/engasga numa VPS headless | E por isso que esse setup NAO usa `onboard` interativo. Use os passos controlados acima (config + `models set` + systemd). |
| `OpenClaw config is invalid: <root>: Invalid input` | Schema 2026.6.5 mudou. NAO escreve JSON na mao. Usa `openclaw config patch --file ...` (ETAPA 2) + `openclaw config validate`. |
| `Gateway start blocked ... missing gateway.mode` (exit 78) | Faltou a ETAPA 2.5: `openclaw config set gateway.mode local`. |
| `agent.name` da `Invalid input` | Esse campo nao existe na 2026.6.5. Roda sem nome custom. Pra investigar: `openclaw config schema`. (VERIFICAR) |
| Unit nao sobe e tem `__OPENCLAW_BIN__`/`PLACEHOLDER` | `sed` da ETAPA 5 nao rodou. Refaz a substituicao do binario e do nome. |
| Gateway nao sobe | `journalctl -u openclaw-gateway -n 50 --no-pager`. Roda `openclaw config validate` + `openclaw doctor`. Restaura `.last-good` se preciso. |
| Telegram nao recebe msg | `openclaw doctor`. Confere `botToken` e `allowFrom`. |
| GLM da 401/403 | API key Z.ai sem credito/expirada. |
| Codex pede login de novo | OAuth expirou. `openclaw models auth login --provider openai --device-code`. |
| `openclaw: command not found` | npm global bin fora do PATH. `export PATH="$(npm config get prefix)/bin:$PATH"` ou reroda o bootstrap. |
| VPS reboot e nao volta | `systemctl is-enabled openclaw-gateway` tem que dar `enabled`. Se nao: `systemctl enable openclaw-gateway`. |

---

## FIM DO SETUP v3

OpenClaw original puro. Documentacao oficial: https://docs.openclaw.ai
Issues desse setup: https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues
