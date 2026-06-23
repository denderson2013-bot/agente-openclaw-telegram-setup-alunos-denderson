# SETUP-AGENTE.md v4 -- Agente Avalanche COMPLETO sobre OpenClaw 2026.6.5 + Telegram

> Claude (ou outro agente que esteja executando), esse arquivo e pra VOCE executar.
>
> ## PERSISTENCIA (LER PRIMEIRO -- NAO DESISTE NO PRIMEIRO ERRO)
>
> Se qualquer comando der erro, NAO pare nem desista: diagnostique com `openclaw config validate`
> e `openclaw doctor`, corrija e continue. So considere a instalacao concluida quando o agente
> responder de verdade no Telegram. Persista ate o objetivo. Erro nao e parada -- e o proximo passo
> do diagnostico. Roteiro testado ao vivo em Ubuntu com OpenClaw **2026.6.5** (versao FIXA -- ver ETAPA 1).
>
> O objetivo e instalar o **agente Avalanche COMPLETO** (alma da Naia + 12 subagentes + 4 skills +
> banco de memoria) sobre o **OpenClaw 2026.6.5** numa VPS Ubuntu, conectado ao Telegram, rodando
> 24/7 via systemd. O aluno escolhe o nome do agente principal (ex: Bia, Paula, Lucas) e o nome dele
> (dono); a alma, os subagentes e as skills sao a mesma engenharia que roda na operacao do Denderson.
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
> - OpenClaw 2026.6.5 gateway rodando 24/7 via systemd
> - Backend LLM escolhido (GLM via Z.ai OU GPT Codex via OAuth) ativo
> - Alma Avalanche (SOUL/AGENTS/IDENTITY/USER/STARTUP/00-SEGURANCA) no workspace principal
> - 12 subagentes registrados (Jonathan, Paulo, Juliana, Rafael, clone do dono, e 7 SDRs)
> - 4 skills (proposta comercial, landing page com 10 templates, BMAD Instagram, criar subagente)
> - Banco PostgreSQL de memoria (opcional, ETAPA 4.5)
> - Telegram funcionando ponta a ponta com o nome do agente que o aluno escolheu

---

## VERSAO DO OPENCLAW -- FIXA EM 2026.6.5 (NAO USE @latest)

> ⚠️ Use **`openclaw@2026.6.5`** sempre. NAO use `@latest`.
> - A `2026.6.9` tem **regressao de polling do Telegram** (double `getUpdates` -> `conflict`).
> - A `2026.4.24` (do v1) e velha demais e tem outro schema de config.
> - A `2026.6.5` foi validada ao vivo (KVM8): `openclaw config validate` -> `Config valid`, Telegram ok,
>   subagentes registrados via `openclaw agents add`, skills auto-descobertas. E a versao deste roteiro.

---

## REGRA DE FLUXO DE LLM (OBRIGATORIA -- LER PRIMEIRO)

A **PRIMEIRA** pergunta que voce faz (depois de coletar IP/usuario/senha da VPS) e:

> "Qual LLM voce quer usar: **GLM 4.5/5 Turbo** (mais barato, API key Z.ai) ou **GPT Codex 5.5**
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

## O QUE O SETUP INSTALA (agente Avalanche completo)

OpenClaw 2026.6.5 (pin fixo) + toda a customizacao Avalanche:

1. **OpenClaw CLI 2026.6.5** instalado globalmente via npm (`openclaw@2026.6.5`)
2. **Backend LLM intercambiavel:**
   - **Opcao A:** GLM 4.5/5 Turbo via Z.ai (provider custom OpenAI-compativel)
   - **Opcao B:** GPT Codex 5.5 via OpenAI Codex (provider `openai`, auth OAuth da assinatura ChatGPT Plus)
3. **Canal Telegram nativo** do OpenClaw (sem bot externo Python)
4. **systemd `openclaw-gateway`** rodando 24/7
5. **Alma Avalanche** no workspace principal: `SOUL.md`, `AGENTS.md`, `IDENTITY.md`, `USER.md`,
   `STARTUP.md`, `MEMORY.md`, `00-SEGURANCA.md` + `scripts/` (heartbeat, flush pro banco)
6. **12 subagentes** registrados em `agents.list[]` (alma de cada um em `workspace-<nome>/SOUL.md`):
   Jonathan (copy), Paulo (dev), Juliana (ops/design), Rafael (projetos), clone do dono (trafego),
   e 7 SDRs (Davi, Lucas, Felipe, Matheus, Amanda, Carolina, Bianca)
7. **4 skills** auto-descobertas (`~/.openclaw/skills/`): `gerar-proposta-comercial`,
   `gerar-landing-page` (10 templates), `analisar-instagram-bmad`, `criar-subagente`
8. **(Opcional)** Banco PostgreSQL + pgvector de memoria (ETAPA 4.5)
9. **(Opcional)** Audio: Whisper (entrada) via OpenAI API key, TTS (saida) via ElevenLabs

> Os arquivos de alma/skills/subagentes vivem no repo
> (`workspace/`, `skills/`, `agents/`) e o bootstrap (ETAPA 1) baixa tudo pra `/root/agente-avalanche/`.
> As ETAPAS 2.7 e 2.8 copiam pra dentro do `~/.openclaw/` e registram os subagentes.

---

## Regras de execucao

1. Leia esse arquivo INTEIRO antes de comecar
2. Execute na ordem exata
3. Pergunte uma coisa por vez, espere a resposta
4. Apos cada bloco grande, valide com o check indicado
5. Se falhar, diagnostica (`openclaw config validate` + `openclaw doctor`), corrige e segue. Nao chuta sintaxe nova
6. Fala PT-BR direto

---

## ETAPA 0 -- COLETAR DADOS DO AGENTE

Colete, uma pergunta por vez:

| Variavel | Pergunta pro aluno | Exemplo |
|---|---|---|
| `AGENTE_NAME` | "Qual nome voce quer dar ao seu agente principal?" | `Bia` |
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

Define o modelo dos subagentes que voce vai usar na ETAPA 2.8 (depende do LLM):
- Se `glm`: `SUBAGENT_MODEL="zai/glm-5-turbo"`
- Se `gpt-codex`: `SUBAGENT_MODEL="openai/gpt-5.5"`

---

## ETAPA 1 -- BOOTSTRAP (dependencias + OpenClaw 2026.6.5 + arquivos Avalanche)

Roda o bootstrap na VPS. Instala Node 22 (via nvm), Python 3, ffmpeg, tmux, o **OpenClaw CLI 2026.6.5**
(`npm install -g openclaw@2026.6.5`) e baixa os arquivos Avalanche (`workspace/`, `skills/`, `agents/`,
`database/`) pra `/root/agente-avalanche/`:

```bash
curl -fsSL https://raw.githubusercontent.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/main/bootstrap.sh | bash
```

Avise: "to instalando Node, ffmpeg, o OpenClaw 2026.6.5 e os arquivos do agente na sua VPS, leva ~5-10 min".

Valida (idempotente -- se algo faltar, reroda o bootstrap):

```bash
node --version       # v22.x ou superior (Node 24 recomendado pelo OpenClaw)
python3 --version    # 3.10+
ffmpeg -version | head -1
openclaw --version   # DEVE dizer: OpenClaw 2026.6.5
ls /root/agente-avalanche/workspace /root/agente-avalanche/skills /root/agente-avalanche/agents
```

> **Troubleshooting:** se `openclaw --version` falhar com "command not found", o npm global bin nao esta no PATH.
> Reroda o bootstrap (ele cria symlinks em /usr/local/bin) ou exporta o PATH do nvm:
> `export PATH="$(npm config get prefix)/bin:$PATH"`.
> Se a versao nao for 2026.6.5: `npm install -g openclaw@2026.6.5` e refaz o symlink
> `ln -sf "$(npm config get prefix)/bin/openclaw" /usr/local/bin/openclaw`.

---

## ETAPA 2 -- CRIAR A CONFIG DO TELEGRAM (via `config patch`, NAO na mao)

OpenClaw le a config de `~/.openclaw/openclaw.json` (no Linux como root: `/root/.openclaw/openclaw.json`).

> **NAO escreva o `openclaw.json` na mao.** Na versao 2026.6.5 o schema mudou e escrever blocos a mao
> quebra com `OpenClaw config is invalid: <root>: Invalid input`. O jeito certo e usar
> `openclaw config patch`, que **valida na escrita** (objetos fazem merge recursivo; arrays/escalares
> sao substituidos; `null` apaga o caminho). O schema do canal `telegram` exige `dmPolicy` e
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

### Nome/identidade do agente principal (FIX 2026.6.5 -- usar `agents set-identity`)

> Na 2026.6.5 **NAO existe** `openclaw config set agent.name "..."` (da `Invalid input`). O caminho
> CONFIRMADO ao vivo e o subcomando `openclaw agents set-identity`, que escreve em `agents.list[].identity`:
>
> ```bash
> openclaw agents set-identity --agent main --name "$AGENTE_NAME" --emoji "🦞"
> openclaw config validate            # deve dizer "Config valid"
> ```
>
> (`--agent main` e o agente principal; a flag `--from-identity` le de um `IDENTITY.md` se preferir.)

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

## ETAPA 2.7 -- INSTALAR A ALMA + SKILLS AVALANCHE (copia pra dentro do ~/.openclaw)

Copia a alma pro workspace principal e as skills pra pasta de skills (auto-descoberta pelo OpenClaw).

```bash
SRC=/root/agente-avalanche

# 1) Alma no workspace principal
mkdir -p /root/.openclaw/workspace/scripts
cp "$SRC"/workspace/*.md            /root/.openclaw/workspace/
cp "$SRC"/workspace/scripts/*.sh    /root/.openclaw/workspace/scripts/ 2>/dev/null || true
chmod +x /root/.openclaw/workspace/scripts/*.sh 2>/dev/null || true

# 2) Skills auto-descobertas (cada skill e uma pasta com SKILL.md)
mkdir -p /root/.openclaw/skills
cp -r "$SRC"/skills/*               /root/.openclaw/skills/
chmod +x /root/.openclaw/skills/*/scripts/*.sh 2>/dev/null || true
```

Personaliza os placeholders da alma com o nome do agente e do dono (a alma usa `{{...}}`):

```bash
# Substitui os placeholders mais comuns em todos os .md do workspace
for f in /root/.openclaw/workspace/*.md; do
  sed -i "s/{{AGENTE_NAME}}/$AGENTE_NAME/g; s/{{DONO}}/$OWNER_NAME/g; s/{{OWNER_NAME}}/$OWNER_NAME/g" "$f"
done
```

> Se um arquivo tiver outros placeholders (`{{PRODUTO_DONO}}`, `{{DONO_SLUG}}` etc.), pergunte o valor
> ao aluno e troque tambem. Nao deixe `{{...}}` cru na alma -- o agente le isso literalmente.

Valida que as skills foram descobertas:

```bash
openclaw skills list 2>&1 | grep -iE "proposta|landing|bmad|instagram|subagente" || \
  openclaw skills list | head -40
```

> As 4 skills Avalanche aparecem com `Source = openclaw-managed` (auto-descobertas da pasta `skills/`).
> Elas **NAO** entram no `openclaw.json` -- so existir a pasta `~/.openclaw/skills/<nome>/SKILL.md` basta
> (confirmado ao vivo na 2026.6.5).

---

## ETAPA 2.8 -- REGISTRAR OS 12 SUBAGENTES (via `openclaw agents add`)

> **METODO CONFIRMADO AO VIVO (2026.6.5):** subagentes vivem em `agents.list[]`. NAO de para registra-los
> com `openclaw config patch` num bloco `agents.list` manual -- o patch **substitui** o array e o CLI
> recusa com `Refusing to replace agents.list; it would remove existing entries`. O caminho certo, que
> faz APPEND nao destrutivo, valida na escrita e cria o workspace+sessions de cada um, e o subcomando
> dedicado **`openclaw agents add`**.

Para cada subagente: cria o agente, define identidade e copia a alma dele (`agents/<arquivo>.md`)
pro `SOUL.md` do workspace dele. `$SUBAGENT_MODEL` foi definido na ETAPA 0
(`zai/glm-5-turbo` pra GLM, `openai/gpt-5.5` pra Codex).

```bash
SRC=/root/agente-avalanche

# Funcao helper: registra um subagente (idempotente) + alma + identidade
add_subagente() {
  local id="$1" nome="$2" emoji="$3" almafile="$4"
  local ws="/root/.openclaw/workspace-$id"

  # Registra no agents.list (append nao destrutivo). Se ja existir, ignora o erro e segue.
  openclaw agents add "$id" --non-interactive \
    --workspace "$ws" --model "$SUBAGENT_MODEL" 2>&1 | grep -vi "already" || true

  # Identidade (nome + emoji)
  openclaw agents set-identity --agent "$id" --name "$nome" --emoji "$emoji" 2>/dev/null || true

  # Alma do subagente vira o SOUL.md do workspace dele
  mkdir -p "$ws"
  if [ -f "$SRC/agents/$almafile" ]; then
    cp "$SRC/agents/$almafile" "$ws/SOUL.md"
    sed -i "s/{{DONO}}/$OWNER_NAME/g; s/{{OWNER_NAME}}/$OWNER_NAME/g; s/{{AGENTE_NAME}}/$AGENTE_NAME/g" "$ws/SOUL.md"
  fi
}

# 12 subagentes (id | nome | emoji | arquivo de alma)
add_subagente jonathan "Jonathan" "✍️"  jonathan-copy.md
add_subagente paulo    "Paulo"    "💻"  paulo-dev.md
add_subagente juliana  "Juliana"  "🎨"  juliana-ops.md
add_subagente rafael   "Rafael"   "📋"  rafael-projetos.md
add_subagente davi     "Davi"     "📞"  davi-sdr.md
add_subagente lucas    "Lucas"    "📞"  lucas-sdr.md
add_subagente felipe   "Felipe"   "📞"  felipe-sdr.md
add_subagente matheus  "Matheus"  "📞"  matheus-sdr.md
add_subagente amanda   "Amanda"   "📞"  amanda-sdr.md
add_subagente carolina "Carolina" "📞"  carolina-sdr.md
add_subagente bianca   "Bianca"   "📞"  bianca-sdr.md

# Clone do dono (id = slug do nome do dono em minusculo, sem espaco/acento)
DONO_SLUG="$(echo "$OWNER_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9')"
add_subagente "$DONO_SLUG" "$OWNER_NAME Clone" "📈" dono-clone.md
```

> **Personas extras (mesmo agente, outra alma):** `dono-clone-dm.md` (responder DMs do Insta) e
> `amanda-crm.md` (gestao do produto do dono) sao VARIANTES de persona de subagentes ja registrados
> (o clone do dono e a Amanda). Voce nao registra um agente novo pra eles; eles ficam como referencia
> em `/root/agente-avalanche/agents/` e o aluno pode trocar o `SOUL.md` do workspace correspondente
> se quiser usar aquela persona. Por isso sao 12 IDs registrados e 14 arquivos de alma.

Valida que os 12 subagentes (mais o `main`) estao na config:

```bash
openclaw config validate                       # "Config valid"
openclaw agents list                            # deve listar main + os 12
openclaw config get agents.list | grep -E '"id"'
```

> Se algum subagente faltar, reroda so o `add_subagente` dele. O `openclaw agents add` e idempotente
> no append (se o id ja existe ele avisa e nao duplica).

---

## ETAPA 3 -- AUTENTICAR E DEFINIR O LLM ESCOLHIDO

> Ordem que FUNCIONOU ao vivo: (1) patch do telegram [ETAPA 2] -> (2) `gateway.mode local` [ETAPA 2.5]
> -> (3) alma+skills [ETAPA 2.7] -> (4) subagentes [ETAPA 2.8] -> (5) auth do LLM [esta etapa] ->
> (6) `openclaw models set ...` -> (7) systemd `enable --now` [ETAPA 5] -> (8) validar no Telegram [ETAPA 6].

### Opcao A -- GLM 4.5/5 Turbo (Z.ai, API key)

GLM e um provider OpenAI-compativel custom. Adiciona o provider e o modelo via `openclaw config patch`
(valida na escrita), depois define como primary.

```bash
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

openclaw models set zai/glm-5-turbo
openclaw models fallbacks add zai/glm-5.1
```

Valida:
```bash
openclaw config validate            # "Config valid"
openclaw models list --provider zai
openclaw models status --probe      # deve mostrar zai acessivel
```

> **Troubleshooting GLM:** `401/403` = API key Z.ai sem credito ou errada. `provider not found` = o patch
> nao gravou; confere `openclaw config get models.providers.zai`.
> **Subagentes:** se voce escolheu GLM, o `$SUBAGENT_MODEL` da ETAPA 2.8 deve ser `zai/glm-5-turbo`.

### Opcao B -- GPT Codex 5.5 (OAuth da assinatura ChatGPT Plus, SEM API key)

O provider correto no OpenClaw e **`openai`** (a rota Codex/subscription roda pelo plugin `codex` nativo).
A auth e OAuth, consome da quota da assinatura ChatGPT Plus do aluno. NAO existe API key pra Codex -- nao procure.

Como a VPS e headless, use o **device-code flow** (imprime URL pra abrir no navegador do aluno):

```bash
openclaw models auth login --provider openai --device-code
```

O CLI imprime uma **URL** (`https://auth.openai.com/codex/device`) **e um Code** (ex: `EDYT-MLUDG`).
Captura a URL e o Code e manda pro aluno:

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
> **Subagentes:** se voce escolheu Codex, o `$SUBAGENT_MODEL` da ETAPA 2.8 deve ser `openai/gpt-5.5`.

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

## ETAPA 4.5 -- (OPCIONAL) BANCO DE MEMORIA POSTGRES + pgvector

A alma referencia scripts de memoria (`flush-conversation-to-db.sh`) e o `database/schema.sql` cria as
tabelas (`conversation_history`, `memory_chunks`, `memory_facts`, `transcript_chunks`, `job_queue` +
`mem0_memories` do plugin). So instale se o aluno quiser memoria persistente.

```bash
apt install -y postgresql postgresql-contrib
sudo -u postgres psql -c "CREATE DATABASE openclaw_memory;" 2>/dev/null || true
# pgvector (se disponivel no apt; senao, compila do source):
apt install -y postgresql-16-pgvector 2>/dev/null || true
sudo -u postgres psql -d openclaw_memory -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true

# Aplica o schema
sudo -u postgres psql -d openclaw_memory -f /root/agente-avalanche/database/schema.sql

# Grava a DATABASE_URL no .env pros scripts de flush lerem
echo "DATABASE_URL=postgresql://postgres@localhost/openclaw_memory" >> /root/.openclaw/.env
chmod 600 /root/.openclaw/.env

# Cron de flush a cada 2h (so se o banco existir)
( crontab -l 2>/dev/null; echo "0 */2 * * * /bin/bash /root/.openclaw/workspace/scripts/flush-conversation-to-db.sh" ) | crontab -
```

> Detalhes de cada tabela e dos crons em `/root/agente-avalanche/database/README.md`.
> Sem banco, o agente funciona igual -- so nao tem memoria semantica de longo prazo persistida.

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

> O unit so referencia o `.env` se ele existir. Se voce nao criou `/root/.openclaw/.env` nas ETAPAS 4/4.5,
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

Teste tambem um subagente: pede pro agente principal delegar algo (ex: "manda o Jonathan escrever um gancho")
e confirma que o subagente responde.

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
- subagente nao responde -> confere `openclaw agents list` e se o `workspace-<id>/SOUL.md` existe.

> Se `dmPolicy` estivesse em `pairing` (nao e o nosso caso, usamos `allowlist`), seria preciso aprovar:
> `openclaw pairing list telegram` -> `openclaw pairing approve telegram <CODE>`.

---

## ETAPA 7 -- (OPCIONAL) CRON DE HEALTHCHECK

Mantem o gateway de pe se cair (a alma traz `scripts/heartbeat.sh` pra isso):

```bash
( crontab -l 2>/dev/null; echo "30 * * * * /bin/bash /root/.openclaw/workspace/scripts/heartbeat.sh" ) | crontab -
```

> Ou um healthcheck minimo sem o script:
> `*/5 * * * * /usr/local/bin/openclaw doctor >/dev/null 2>&1 || /usr/bin/systemctl restart openclaw-gateway`
> Ajusta o caminho do `openclaw` (`which openclaw`) e do `systemctl` se forem diferentes na VPS.

---

## ETAPA 8 -- VALIDACAO FINAL

```bash
systemctl is-active openclaw-gateway   # active
openclaw --version                      # OpenClaw 2026.6.5
openclaw doctor                         # sem erros criticos
openclaw models status --probe          # LLM escolhido acessivel
openclaw agents list                    # main + 12 subagentes
openclaw skills list | grep -iE "proposta|landing|bmad|subagente"   # 4 skills Avalanche
```

Mensagem final pro aluno:
- OpenClaw: `2026.6.5`
- LLM ativo: `<glm | gpt-codex>`
- Bot Telegram: `@TELEGRAM_BOT_USERNAME`
- Agente: `AGENTE_NAME` (+ 12 subagentes + 4 skills)
- Comandos uteis: ETAPA 9

---

## ETAPA 9 -- COMANDOS DO DIA A DIA

```bash
# Logs ao vivo
journalctl -u openclaw-gateway -f
# Restart
systemctl restart openclaw-gateway
# Ver / trocar modelo
openclaw models list
openclaw models set openai/gpt-5.5        # ou zai/glm-5-turbo
systemctl restart openclaw-gateway
# Status do gateway e dos modelos
openclaw gateway status
openclaw models status --probe
openclaw doctor
# Subagentes
openclaw agents list
openclaw agents add <id> --non-interactive --workspace /root/.openclaw/workspace-<id> --model <modelo>
openclaw agents set-identity --agent <id> --name "Nome" --emoji "🙂"
# Skills (auto-descobertas da pasta -- basta criar ~/.openclaw/skills/<nome>/SKILL.md)
openclaw skills list
# Editar a alma do principal ou de um subagente e reiniciar
nano /root/.openclaw/workspace/SOUL.md            # principal
nano /root/.openclaw/workspace-jonathan/SOUL.md   # subagente
systemctl restart openclaw-gateway
```

**Trocar de LLM depois (GLM <-> Codex):** so refaz a auth do outro provider (ETAPA 3, opcao A ou B) e
`openclaw models set <provider/model>`, depois `systemctl restart openclaw-gateway`.

**Criar subagente novo:** usa a skill `criar-subagente` (`~/.openclaw/skills/criar-subagente/`) ou o fluxo
manual da ETAPA 2.8 (`openclaw agents add` + `set-identity` + `SOUL.md`).

---

## TROUBLESHOOTING (resumo dos erros do instalador na 2026.6.5)

| Problema | Solucao |
|---|---|
| `openclaw onboard` trava/engasga numa VPS headless | E por isso que esse setup NAO usa `onboard` interativo. Use os passos controlados acima (config + `models set` + `agents add` + systemd). |
| `OpenClaw config is invalid: <root>: Invalid input` | Schema 2026.6.5 mudou. NAO escreve JSON na mao. Usa `openclaw config patch --file ...` (ETAPA 2) + `openclaw config validate`. |
| `Gateway start blocked ... missing gateway.mode` (exit 78) | Faltou a ETAPA 2.5: `openclaw config set gateway.mode local`. |
| `agent.name` da `Invalid input` | Esse campo nao existe na 2026.6.5. Use `openclaw agents set-identity --agent main --name "..."` (ETAPA 2). |
| `Refusing to replace agents.list; it would remove existing entries` | NAO registre subagente com `config patch` num bloco `agents.list`. Usa `openclaw agents add` (ETAPA 2.8), que faz append nao destrutivo. |
| Skills nao aparecem | Confere que cada skill e uma pasta `~/.openclaw/skills/<nome>/` com `SKILL.md` dentro. `openclaw skills list` deve mostrar `Source = openclaw-managed`. Skills NAO entram no `openclaw.json`. |
| Unit nao sobe e tem `__OPENCLAW_BIN__`/`PLACEHOLDER` | `sed` da ETAPA 5 nao rodou. Refaz a substituicao do binario e do nome. |
| Gateway nao sobe | `journalctl -u openclaw-gateway -n 50 --no-pager`. Roda `openclaw config validate` + `openclaw doctor`. Restaura `.last-good` se preciso. |
| Telegram nao recebe msg | `openclaw doctor`. Confere `botToken` e `allowFrom`. |
| GLM da 401/403 | API key Z.ai sem credito/expirada. |
| Codex pede login de novo | OAuth expirou. `openclaw models auth login --provider openai --device-code`. |
| `openclaw: command not found` | npm global bin fora do PATH. `export PATH="$(npm config get prefix)/bin:$PATH"` ou reroda o bootstrap. |
| Versao errada (nao 2026.6.5) | `npm install -g openclaw@2026.6.5` + refaz symlink em /usr/local/bin. NUNCA `@latest` (6.9 quebra o polling do Telegram). |
| VPS reboot e nao volta | `systemctl is-enabled openclaw-gateway` tem que dar `enabled`. Se nao: `systemctl enable openclaw-gateway`. |

---

## FIM DO SETUP v4

Agente Avalanche completo (alma + 12 subagentes + 4 skills) sobre OpenClaw 2026.6.5.
Documentacao oficial do OpenClaw: https://docs.openclaw.ai
Issues desse setup: https://github.com/denderson2013-bot/agente-openclaw-telegram-setup-alunos-denderson/issues
