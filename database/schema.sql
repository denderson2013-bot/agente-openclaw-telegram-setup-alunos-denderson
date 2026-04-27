-- ============================================
-- OpenClaw Memory Schema (mem0 + custom tables)
-- ============================================
-- Aplica em /root/.openclaw/openclaw_memory:
--   sudo -u postgres psql -d openclaw_memory -f schema.sql
-- ============================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================
-- TABELA mem0_memories (usada pelo plugin openclaw-mem0)
-- O plugin cria sozinho na primeira execucao, mas deixamos
-- DDL aqui pra documentacao + indices manuais.
-- ============================================
CREATE TABLE IF NOT EXISTS mem0_memories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     TEXT NOT NULL DEFAULT 'default',
    content     TEXT NOT NULL,
    embedding   vector(1536),
    metadata    JSONB DEFAULT '{}'::jsonb,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS mem0_memories_embedding_hnsw
    ON mem0_memories USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS mem0_memories_user_id_idx
    ON mem0_memories (user_id);

CREATE INDEX IF NOT EXISTS mem0_memories_metadata_gin
    ON mem0_memories USING gin (metadata);

CREATE INDEX IF NOT EXISTS mem0_memories_content_trgm
    ON mem0_memories USING gin (content gin_trgm_ops);

-- ============================================
-- conversation_history (snapshot de toda mensagem)
-- Alimentada pelo cron flush-conversation-to-db.sh
-- ============================================
CREATE TABLE IF NOT EXISTS conversation_history (
    id           BIGSERIAL PRIMARY KEY,
    session_id   TEXT,
    agent_id     TEXT NOT NULL DEFAULT 'main',
    role         TEXT NOT NULL,    -- user | assistant | system | tool
    content      TEXT NOT NULL,
    embedding    vector(1536),
    channel      TEXT,             -- telegram | discord | whatsapp | local
    metadata     JSONB DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS conversation_history_embedding_hnsw
    ON conversation_history USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS conversation_history_agent_idx
    ON conversation_history (agent_id, created_at DESC);

CREATE INDEX IF NOT EXISTS conversation_history_session_idx
    ON conversation_history (session_id);

-- ============================================
-- memory_chunks (knowledge base do workspace, indexada)
-- Alimentada pelo cron 'openclaw memory reindex'
-- ============================================
CREATE TABLE IF NOT EXISTS memory_chunks (
    id           BIGSERIAL PRIMARY KEY,
    source       TEXT NOT NULL,
    content      TEXT NOT NULL,
    embedding    vector(1536),
    metadata     JSONB DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memory_chunks_embedding_hnsw
    ON memory_chunks USING hnsw (embedding vector_cosine_ops);

CREATE INDEX IF NOT EXISTS memory_chunks_source_idx
    ON memory_chunks (source);

-- ============================================
-- memory_facts (fatos curtos consolidados)
-- ============================================
CREATE TABLE IF NOT EXISTS memory_facts (
    id           BIGSERIAL PRIMARY KEY,
    fact         TEXT NOT NULL,
    embedding    vector(1536),
    importance   SMALLINT DEFAULT 5,
    expires_at   TIMESTAMPTZ,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memory_facts_embedding_hnsw
    ON memory_facts USING hnsw (embedding vector_cosine_ops);

-- ============================================
-- transcript_chunks (audios transcritos via Whisper)
-- ============================================
CREATE TABLE IF NOT EXISTS transcript_chunks (
    id            BIGSERIAL PRIMARY KEY,
    source_call   TEXT NOT NULL,
    content       TEXT NOT NULL,
    embedding     vector(1536),
    metadata      JSONB DEFAULT '{}'::jsonb,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS transcript_chunks_embedding_hnsw
    ON transcript_chunks USING hnsw (embedding vector_cosine_ops);

-- ============================================
-- job_queue (jobs em fila com retry exponencial)
-- ============================================
CREATE TABLE IF NOT EXISTS job_queue (
    id              BIGSERIAL PRIMARY KEY,
    type            TEXT NOT NULL,
    payload         JSONB NOT NULL,
    status          TEXT DEFAULT 'pending',  -- pending | running | done | failed
    attempts        INT DEFAULT 0,
    max_attempts    INT DEFAULT 5,
    scheduled_for   TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    error_log       TEXT
);

CREATE INDEX IF NOT EXISTS job_queue_status_scheduled_idx
    ON job_queue (status, scheduled_for);

-- ============================================
-- View util pra ver memoria recente
-- ============================================
CREATE OR REPLACE VIEW recent_conversation AS
SELECT
    id,
    agent_id,
    role,
    LEFT(content, 200) AS content_preview,
    channel,
    created_at
FROM conversation_history
ORDER BY created_at DESC
LIMIT 50;
