#!/bin/bash
# ============================================
# Flush conversation history to PostgreSQL
# ============================================
# Roda pelo cron a cada 2h:
#   0 */2 * * * /bin/bash /root/.openclaw/workspace/scripts/flush-conversation-to-db.sh
#
# Le sessoes recentes do OpenClaw e salva em conversation_history.
# Usa OpenClaw CLI pra extrair sessoes (formato JSONL em agents/main/sessions/).
# ============================================

set -e

LOG=/var/log/openclaw-flush.log
SESSIONS_DIR="/root/.openclaw/agents/main/sessions"
SOURCE="/root/.openclaw/.env"

# Carrega DATABASE_URL do .env
if [[ -f "$SOURCE" ]]; then
    set -a
    source "$SOURCE"
    set +a
fi

if [[ -z "$DATABASE_URL" ]]; then
    echo "$(date -Iseconds) [ERROR] DATABASE_URL not set" >> "$LOG"
    exit 1
fi

# Itera sobre arquivos .jsonl modificados nas ultimas 3 horas
find "$SESSIONS_DIR" -name "*.jsonl" -mmin -180 -not -name "*.deleted.*" 2>/dev/null | while read -r session_file; do
    session_id=$(basename "$session_file" .jsonl)

    # Insere cada linha como uma row em conversation_history
    while IFS= read -r line; do
        # Extrai role e content via jq
        role=$(echo "$line" | jq -r '.role // empty' 2>/dev/null)
        content=$(echo "$line" | jq -r '.content // empty' 2>/dev/null)
        timestamp=$(echo "$line" | jq -r '.timestamp // empty' 2>/dev/null)

        if [[ -n "$role" && -n "$content" ]]; then
            # Escapa aspas simples pro SQL
            content_escaped=$(echo "$content" | sed "s/'/''/g")
            psql "$DATABASE_URL" -c "
                INSERT INTO conversation_history (session_id, agent_id, role, content, channel, created_at)
                VALUES ('$session_id', 'main', '$role', '$content_escaped', 'openclaw', NOW())
                ON CONFLICT DO NOTHING;
            " > /dev/null 2>&1 || true
        fi
    done < "$session_file"
done

echo "$(date -Iseconds) [OK] flush done" >> "$LOG"
