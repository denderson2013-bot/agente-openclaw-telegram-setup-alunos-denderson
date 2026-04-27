#!/bin/bash
# ============================================
# Heartbeat - confirma que o agente esta vivo
# ============================================
# Cron sugerido (a cada hora):
#   30 * * * * /bin/bash /root/.openclaw/workspace/scripts/heartbeat.sh
# ============================================

LOG=/var/log/openclaw-heartbeat.log

if systemctl is-active --quiet openclaw-gateway; then
    echo "$(date -Iseconds) [OK] gateway alive" >> "$LOG"
else
    echo "$(date -Iseconds) [WARN] gateway down, restarting..." >> "$LOG"
    systemctl restart openclaw-gateway
fi

# Health check via openclaw doctor
if ! /usr/bin/openclaw health > /dev/null 2>&1; then
    echo "$(date -Iseconds) [WARN] openclaw health failed" >> "$LOG"
fi
