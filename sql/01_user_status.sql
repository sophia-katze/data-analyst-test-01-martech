-- =============================================================================
-- Arquivo: sql/01_user_status.sql
-- Descrição: Cálculo detalhado da quantidade e proporção de usuários
--             segmentados pelo campo 'status_descricao'.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Usa duas CTEs para clareza e reuso de resultados intermediários.
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'total_users': Computa o total de registros na tabela 'users'.
-- ---------------------------------------------------------------------------------
WITH total_users AS (
    SELECT
        COUNT(*) AS total  -- Contagem total de usuários na base
    FROM users
),

-- ---------------------------------------------------------------------------------
-- CTE 'status_counts': Agrupa usuários por 'status_descricao' e conta cada categoria.
-- ---------------------------------------------------------------------------------
status_counts AS (
    SELECT
        status_descricao,      -- Descrição do status (Ativo, Onboarding, etc.)
        COUNT(*) AS qtd_status -- Quantidade de usuários em cada status
    FROM users
    GROUP BY status_descricao
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Combina contagens com total para calcular porcentagens.
-- Ordem decrescente por porcentagem para destacar status mais prevalentes.
-- ---------------------------------------------------------------------------------
SELECT
    sc.status_descricao,                                      -- Nome do status
    sc.qtd_status,                                            -- Número de usuários nesse status
    ROUND(100.0 * sc.qtd_status / tu.total, 2) AS pct_status  -- Porcentagem (%) desse status no total
FROM status_counts sc                                        -- Fonte das contagens por status
CROSS JOIN total_users tu                                    -- Junta o total de usuários (CTE) para cálculo de porcentagem
ORDER BY pct_status DESC;                                    -- Ordena do maior para o menor percentual

-- Fim do script: 01_user_status.sql
-- =============================================================================
