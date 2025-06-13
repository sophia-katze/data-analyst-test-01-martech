-- =============================================================================
-- Arquivo: sql/07_promotion_impact.sql
-- Descrição: Avalia mudanças nos principais indicadores de receita de usuários 
--            antes, durante e depois da promoção de 85% nas primeiras compras.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-13
-- Observação: Usa três CTEs para segmentar períodos, classificar transações e agregar métricas.
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'promo_period': Determina início e fim do período promocional.
-- ---------------------------------------------------------------------------------
WITH promo_period AS (
    SELECT
        MIN(tx_date) AS promo_start,  -- Data inicial da promoção
        MAX(tx_date) AS promo_end     -- Data final da promoção
    FROM (
        -- Reutiliza lógica de dias de alta promoção (taxa ≥85% em primeiras compras)
        WITH first_tx AS (
            SELECT DATE(created_at) AS tx_date,
                   COALESCE(discount_percent, 0) AS discount_pct
            FROM user_transactions
            WHERE initial_purchase = 1
        ),
        daily_rates AS (
            SELECT
                tx_date,
                COUNT(*) AS total_firsts,
                SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END) AS promo_count,
                ROUND(
                  100.0 * SUM(CASE WHEN discount_pct > 0 THEN 1 ELSE 0 END)
                  / COUNT(*)
                , 2) AS promo_rate_pct
            FROM first_tx
            GROUP BY tx_date
            HAVING total_firsts >= 5
        )
        SELECT tx_date
        FROM daily_rates
        WHERE promo_rate_pct >= 85
    )
),

-- ---------------------------------------------------------------------------------
-- CTE 'tx_with_period': Classifica cada primeira compra em 'antes', 'durante' ou 'depois'.
-- ---------------------------------------------------------------------------------
tx_with_period AS (
    SELECT
        ut.user_id,
        DATE(ut.created_at) AS tx_date,                    -- Data da transação
        COALESCE(ut.transaction_paid_value, 0) AS revenue,  -- Receita obtida
        CASE
            WHEN DATE(ut.created_at) < pp.promo_start THEN 'antes'
            WHEN DATE(ut.created_at) BETWEEN pp.promo_start AND pp.promo_end THEN 'durante'
            ELSE 'depois'
        END AS period_flag                                 -- Período relativo à promoção
    FROM user_transactions ut
    CROSS JOIN promo_period pp
    WHERE ut.initial_purchase = 1
),

-- ---------------------------------------------------------------------------------
-- CTE 'metrics': Agrega principais indicadores por período.
-- ---------------------------------------------------------------------------------
metrics AS (
    SELECT
        period_flag,
        COUNT(DISTINCT user_id) AS total_users,  -- Total de usuários com 1ª compra
        COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END) AS paying_users,  -- Usuários pagantes
        SUM(revenue) AS total_revenue,           -- Receita total no período
        ROUND(
            SUM(revenue) * 1.0
            / NULLIF(COUNT(DISTINCT CASE WHEN revenue > 0 THEN user_id END), 0)
        , 2) AS avg_revenue_per_user             -- Receita média por usuário pagante
    FROM tx_with_period
    GROUP BY period_flag
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Ordena e exibe as métricas para antes, durante e depois.
-- ---------------------------------------------------------------------------------
SELECT
    period_flag               AS periodo,                   -- 'antes'/'durante'/'depois'
    total_users               AS total_usuarios,            -- Qtde de usuários no período
    paying_users              AS usuarios_pagantes,         -- Usuários que geraram receita
    total_revenue             AS receita_total,             -- Receita bruta
    avg_revenue_per_user      AS receita_media_por_pagante  -- Receita média por pagante
FROM metrics
ORDER BY 
    CASE period_flag
      WHEN 'antes' THEN 1
      WHEN 'durante' THEN 2
      WHEN 'depois'  THEN 3
    END;

-- Fim do script: 07_promotion_impact.sql
-- =============================================================================
