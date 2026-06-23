# Database Schema

PostgreSQL 16 + pgvector. O plugin `openclaw-mem0` cria a tabela `mem0_memories` automaticamente; este schema documenta + adiciona tabelas auxiliares (history, facts, transcripts, jobs).

## Aplicar

```bash
sudo -u postgres psql -d openclaw_memory -f schema.sql
```

## Tabelas

| Tabela | Quem alimenta | Pra que serve |
|---|---|---|
| `mem0_memories` | Plugin `openclaw-mem0` | Memoria semantica de longo prazo da Naia |
| `conversation_history` | Cron `flush-conversation-to-db.sh` (a cada 2h) | Historico bruto de toda mensagem |
| `memory_chunks` | `openclaw memory reindex` (cron 9h) | Chunks do workspace indexados |
| `memory_facts` | Manual ou Naia escrevendo via SQL | Fatos curtos (50-200 chars) |
| `transcript_chunks` | Skill `openai-whisper-api` apos call | Audios transcritos |
| `job_queue` | Scripts custom (opcional) | Jobs em fila com retry |

## Indices HNSW

Todos os campos `embedding vector(1536)` tem indice HNSW pra busca semantica <50ms mesmo com 30k+ vetores.

## Backup

```bash
pg_dump openclaw_memory | gzip > /var/backups/openclaw_memory_$(date +%F).sql.gz
```
