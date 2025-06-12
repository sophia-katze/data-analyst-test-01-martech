-- =============================================================================
-- Arquivo: sql/04_spend_per_user.sql
-- Descrição: Análise de usuários pagantes e ARPU (Average Revenue Per User)
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Calcula métricas de conversão e valor médio por usuário pagante
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'spend_per_user': Calcula o gasto total por usuário
-- ---------------------------------------------------------------------------------
WITH spend_per_user AS (
  SELECT
    user_id,
    SUM(paid_value) AS total_spent
  FROM user_transactions
  GROUP BY user_id
),

-- ---------------------------------------------------------------------------------
-- CTE 'user_counts': Calcula contagens e percentuais de usuários pagantes
-- ---------------------------------------------------------------------------------
user_counts AS (
  SELECT
    COUNT(*)                                   AS total_users,
    COUNT(sp.user_id)                          AS paying_users,
    ROUND(100.0 * COUNT(sp.user_id)/COUNT(*),2) AS pct_paying
  FROM users u
  LEFT JOIN spend_per_user sp USING(user_id)
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Calcula ARPU (Average Revenue Per User)
-- ---------------------------------------------------------------------------------
SELECT
  total_users,
  paying_users,
  pct_paying,
  ROUND(total_spent_sum / paying_users,2) AS arpu
FROM (
  SELECT
    uc.*,
    SUM(sp.total_spent) OVER() AS total_spent_sum
  FROM user_counts uc
  LEFT JOIN spend_per_user sp ON TRUE
) t
LIMIT 1;

-- Fim do script: 04_spend_per_user.sql
-- =============================================================================