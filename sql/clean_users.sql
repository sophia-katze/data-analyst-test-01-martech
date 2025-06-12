-- =============================================================================
-- Arquivo: sql/clean_users.sql
-- Descrição: Limpeza e preparação da tabela de usuários (df_users).
--            Remove duplicatas, trata valores nulos e adiciona flags de status.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-12
-- Observação: 
--   - Remove duplicatas baseado em todas as colunas
--   - Mantém registros mesmo com nulos em colunas não críticas
--   - Adiciona flag de status ativo (is_active)
--   - Preserva dados históricos importantes
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'deduplicated_users': Remove registros duplicados mantendo apenas uma ocorrência
-- ---------------------------------------------------------------------------------
WITH deduplicated_users AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY user_id 
            ORDER BY data_criado DESC
        ) AS rn
    FROM users_raw
),

-- ---------------------------------------------------------------------------------
-- CTE 'cleaned_users': Tratamento de valores nulos e adição de novas colunas
-- ---------------------------------------------------------------------------------
cleaned_users AS (
    SELECT
        ad_id,
        user_id,
        data_criado,
        data_primeira_mdc_aprovada,
        status_descricao,
        quantidade_planos_ativos,
        seguidores,
        -- Tratamento de geografia
        COALESCE(cidade, 'DESCONHECIDO') AS cidade,
        COALESCE(uf, 'DESCONHECIDO') AS uf,
        data_deletado,
        ultimo_visto,
        data_primeira_compra,
        data_ultima_compra,
        quantidade_de_compras,
        total_investido,
        posts,
        posts_ativos,
        videos_ativos,
        data_desabilitado_ate,
        status_documentos,
        -- Flag de usuário ativo
        CASE 
            WHEN data_deletado IS NULL THEN TRUE 
            ELSE FALSE 
        END AS is_active
    FROM deduplicated_users
    WHERE rn = 1  -- Mantém apenas o primeiro registro de cada duplicata
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Seleciona todas as colunas tratadas
-- ---------------------------------------------------------------------------------
SELECT *
FROM cleaned_users;

-- Fim do script: clean_users.sql
-- =============================================================================