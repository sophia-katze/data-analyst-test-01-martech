-- =============================================================================
-- Arquivo: sql/06_promotion_first_purchase.sql
-- Descrição: Identifica datas de primeiras compras com valor muito abaixo da média do plano (>85% de desconto)
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Foca em desvios atípicos para detecção de campanhas ocultas de desconto
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE: valor_medio_plano - calcula valor médio pago por plano (baseline)
-- ---------------------------------------------------------------------------------
WITH valor_medio_plano AS (
  SELECT
    plan,
    ROUND(AVG(paid_value), 2) AS media_pago
  FROM user_transactions
  GROUP BY plan
),

-- ---------------------------------------------------------------------------------
-- CTE: primeira_compra_usuario - identifica a primeira compra de cada usuário
-- ---------------------------------------------------------------------------------
primeira_compra_usuario AS (
  SELECT
    user_id,
    MIN(DATE(created_at)) AS data_primeira
  FROM user_transactions
  GROUP BY user_id
),

-- ---------------------------------------------------------------------------------
-- CTE: transacoes_primeira_compra - seleciona transações da primeira compra
-- ---------------------------------------------------------------------------------
transacoes_primeira_compra AS (
  SELECT
    ut.user_id,
    DATE(ut.created_at) AS data,
    ut.plan,
    ut.paid_value,
    vmp.media_pago,
    1 - (ut.paid_value / NULLIF(vmp.media_pago, 0)) AS desconto_relativo
  FROM user_transactions ut
  INNER JOIN primeira_compra_usuario f
    ON ut.user_id = f.user_id
    AND DATE(ut.created_at) = f.data_primeira
  INNER JOIN valor_medio_plano vmp
    ON ut.plan = vmp.plan
  WHERE vmp.media_pago > 0
)

-- ---------------------------------------------------------------------------------
-- Consulta final: retorna datas em que houve transações com desconto > 85%
-- ---------------------------------------------------------------------------------
SELECT
  data,
  COUNT(*) AS num_transacoes_promocionais,
  ROUND(AVG(paid_value), 2) AS valor_medio_pago,
  ROUND(AVG(media_pago), 2) AS valor_medio_original,
  ROUND(AVG(desconto_relativo) * 100, 2) AS desconto_medio_pct
FROM transacoes_primeira_compra
WHERE desconto_relativo >= 0.85
GROUP BY data
ORDER BY data;

-- Fim do script: 06_promotion_first_purchase.sql
-- =============================================================================
