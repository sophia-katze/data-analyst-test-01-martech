-- =============================================================================
-- Arquivo: sql/clean_user_transactions.sql
-- Descrição: Limpeza e preparação da tabela de transações (transactions_raw).
--            Remove duplicatas e valores críticos nulos, adiciona flags.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-12
-- Observação:
--   - Remove transações sem ID ou valores financeiros
--   - Mantém registros não aprovados como importantes para análise
--   - Adiciona flag de aprovação (is_approved)
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'critical_nulls_removed': Remove registros com valores críticos nulos
-- ---------------------------------------------------------------------------------
WITH critical_nulls_removed AS (
    SELECT *
    FROM transactions_raw
    WHERE 
        transaction_id IS NOT NULL
        AND full_value IS NOT NULL
        AND paid_value IS NOT NULL
),

-- ---------------------------------------------------------------------------------
-- CTE 'deduplicated_transactions': Remove transações duplicadas
-- ---------------------------------------------------------------------------------
deduplicated_transactions AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id, user_id, created_at 
            ORDER BY approved_at DESC
        ) AS rn
    FROM critical_nulls_removed
),

-- ---------------------------------------------------------------------------------
-- CTE 'cleaned_transactions': Tratamento de valores nulos e adição de flags
-- ---------------------------------------------------------------------------------
cleaned_transactions AS (
    SELECT
        created_at,
        approved_at,
        uf,
        payment_method,
        -- Tratamento de período (assume 0 como padrão)
        COALESCE(period, 0) AS period,
        quantity,
        plan,
        -- Assume não ser primeira compra quando nulo
        COALESCE(initial_purchase, FALSE) AS initial_purchase,
        full_value,
        transaction_paid_value,
        paid_value,
        transaction_id,
        user_id,
        userable_id,
        -- Desconto padrão 0 quando não informado
        COALESCE(discount_percent, 0) AS discount_percent,
        -- Flag de transação aprovada
        CASE 
            WHEN approved_at IS NOT NULL THEN TRUE 
            ELSE FALSE 
        END AS is_approved
    FROM deduplicated_transactions
    WHERE rn = 1  -- Mantém apenas o primeiro registro de cada duplicata
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Seleciona todas as colunas tratadas
-- ---------------------------------------------------------------------------------
SELECT *
FROM cleaned_transactions;

-- Fim do script: clean_user_transactions.sql
-- =============================================================================