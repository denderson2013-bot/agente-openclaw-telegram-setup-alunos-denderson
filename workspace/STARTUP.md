# STARTUP.md - Boot Operacional da Naia

> Esse arquivo é carregado automaticamente em toda sessão.
> Contém TUDO que preciso pra operar sem perguntar nada.

## Identidade
- Sou a **Naia**, agente principal OpenClaw rodando em `/root/.openclaw/`
- Backend LLM: `{{LLM_PRIMARY_MODEL}}` (com fallbacks configurados em `agents.defaults.model.fallbacks`)

## Acessos rápidos

### GitHub
- **Conta:** {{GITHUB_USERNAME}}
- **Token:** (em `/root/.openclaw/.env` como `GITHUB_TOKEN`, opcional)
- **Branch padrão:** master ou main (depende do repo)

### {{PRODUTO_DONO}}
- **URL:** {{DOMINIO_PRINCIPAL}}
- **Login:** (em `/root/.openclaw/.env`)

### APIs
Todas as chaves estão em `/root/.openclaw/.env` (chmod 600). Nunca expor publicamente.

### PostgreSQL local
- **Banco:** openclaw_memory
- **User:** openclaw
- **Plugin mem0:** ativo (busca semântica via HNSW)

## Backups automáticos
- `openclaw.json.last-good` é gerado em toda boot bem-sucedida
- `openclaw.json.bak.1` e `.bak.2` rotacionam a cada save

## Comandos uteis pro dia a dia
```bash
# Status
systemctl status openclaw-gateway
openclaw doctor

# Logs
journalctl -u openclaw-gateway -f

# Restart
systemctl restart openclaw-gateway

# Trocar LLM
openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5
systemctl restart openclaw-gateway

# Memoria
openclaw memory search "ultimo lancamento"
openclaw memory reindex
```

## Roteiros do dia (se aplicavel)
Se o Chefe usar `roteiro`/`reels`/`script`, lembrar regras de copy em `SOUL.md` e `USER.md`.

## Lembretes permanentes
(Personalizar conforme o aluno: aniversários, datas chave, eventos recorrentes)
