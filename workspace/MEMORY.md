# MEMORY.md - Índice de Memórias da Naia

Esse arquivo lista todos os arquivos de memória persistente. Cada arquivo tem propósito específico:

## Estrutura

```
memory/
├── decisions.md       ← Decisões permanentes do Chefe
├── projects.md        ← Projetos ativos
├── lessons.md         ← Lições aprendidas
├── people.md          ← Contatos importantes
├── pending.md         ← Aguardando input do Chefe
├── tom-de-voz-{{DONO_SLUG}}.md ← Tom de voz do Chefe (analisado de transcrições)
├── sales-pipeline.md  ← Pipeline de vendas (se aplicável)
├── security-log.md    ← Log de eventos de segurança
└── daily/YYYY-MM-DD.md ← Notas diárias (rascunho, consolidar depois)
```

## Como usar

- **MEMORY.md = índice.** Não duplicar conteúdo dos topic files.
- **Notas diárias = rascunho.** Consolidar em topic files semanalmente.
- **Lição aprendida?** → `memory/lessons.md`
- **Decisão do Chefe?** → `memory/decisions.md`
- **Projeto novo?** → `memory/projects.md`
- **Pendência?** → `memory/pending.md`

## Memória vetorial (PostgreSQL + pgvector + plugin openclaw-mem0)

Banco `openclaw_memory` na VPS. Acessível via:

```bash
# SQL direto
sudo -u postgres psql -d openclaw_memory -c "SELECT * FROM mem0_memories ORDER BY created_at DESC LIMIT 10"

# CLI OpenClaw
openclaw memory search "ultimo lancamento de produto"
openclaw memory reindex
```

Tabelas indexadas com HNSW:
- `mem0_memories` (memorias semanticas geridas pelo plugin)
- `conversation_history` (todas as conversas)
- `memory_chunks` (chunks de workspace files)
- `memory_facts` (fatos curtos consolidados)
- `transcript_chunks` (audios transcritos via Whisper)

## Princípio
**Se importa, escreve em arquivo.** O que não tá escrito, não existe. Acordo zerada toda sessão. Esses arquivos são minha continuidade.
