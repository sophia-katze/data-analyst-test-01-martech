-- =============================================================================
-- Arquivo: sql/06_promotion_period.sql
-- Descrição: Mesma lógica de ≥85% de promoções nas primeiras compras,
--            agora referenciando user_transactions em vez de df_transactions_raw.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-13
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'first_tx': Seleciona apenas as primeiras compras de cada usuário,
-- normalizando discount_percent nulo para 0.
-- ---------------------------------------------------------------------------------
WITH first_tx AS (
    SELECT
        DATE(created_at)                       AS tx_date,          -- Extrai só a data
        COALESCE(discount_percent, 0)         AS discount_pct      -- Substitui nulos por 0
    FROM user_transactions
    WHERE initial_purchase = 1                                    -- Só primeiras compras
),

-- ---------------------------------------------------------------------------------
-- CTE 'daily_rates': Agrega por dia o total de primeiras compras,
-- quantas tiveram desconto, e calcula a taxa de promoção.
-- ---------------------------------------------------------------------------------
daily_rates AS (
    SELECT
        tx_date,                                               -- Dia da análise
        COUNT(*)                        AS total_firsts,       -- Total de primeiras compras
        SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END)  
                                        AS promo_count,        -- Número de compras com desconto
        ROUND(
          100.0 * SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END)
                / COUNT(*), 2
        )                               AS promo_rate_pct      -- % de promoções
    FROM first_tx
    GROUP BY tx_date
    HAVING total_firsts >= 5                                    -- Volume mínimo para estabilidade
),

-- ---------------------------------------------------------------------------------
-- CTE 'high_promo_days': Filtra somente dias onde ≥85% das primeiras compras
-- foram promocionais.
-- ---------------------------------------------------------------------------------
high_promo_days AS (
    SELECT
        tx_date,                                               -- Dia da promoção alta
        total_firsts,                                          -- Total de primeiras compras
        promo_count,                                           -- Compras com desconto
        promo_rate_pct                                         -- Taxa de promoções
    FROM daily_rates
    WHERE promo_rate_pct >= 85                                -- Limiar de 85%
),

-- ---------------------------------------------------------------------------------
-- CTE 'consec': Marca dias consecutivos de alta promoção.
-- ---------------------------------------------------------------------------------
consec AS (
    SELECT
        tx_date,                                               -- Dia da promoção alta
        total_firsts,                                          -- Total de primeiras compras
        promo_count,                                           -- Compras com desconto
        promo_rate_pct,                                        -- Taxa de promoções
        CASE 
          WHEN DATE(tx_date, '-1 day') = LAG(tx_date) OVER (ORDER BY tx_date)
          THEN 1 ELSE 0 
        END                           AS is_consecutive_day     -- 1 se segue dia anterior
    FROM high_promo_days
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Exibe dias de alta promoção e flag de consecutividade.
-- ---------------------------------------------------------------------------------
SELECT
    hp.tx_date                  AS data_transacao,           -- Data da transação
    hp.total_firsts             AS total_primeiras_compras,  -- Total de primeiras compras
    hp.promo_count              AS compras_com_desconto,      -- Compras com desconto
    hp.promo_rate_pct           AS taxa_promocional_pct,      -- % de promoções
    COALESCE(c.is_consecutive_day, 0) AS dia_consecutivo       -- 1 se faz parte de sequência
FROM high_promo_days hp
LEFT JOIN consec c USING (tx_date)
ORDER BY hp.tx_date;                                        -- Ordena cronologicamente

-- Fim do script: 06_promotion_period.sql
-- =============================================================================
