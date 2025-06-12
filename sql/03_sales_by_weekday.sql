-- =============================================================================
-- Arquivo: sql/03_sales_by_weekday.sql
-- Descrição: Agrega vendas por dia da semana, analisando padrões sazonais.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Usa strftime('%w', ...) para extrair o dia da semana (0=Domingo, ..., 6=Sábado).
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'weekday_agg': Agrega métricas por dia da semana com base na data da transação.
-- ---------------------------------------------------------------------------------
WITH weekday_agg AS (
    SELECT
        CAST(strftime('%w', created_at) AS INTEGER) AS dia_semana_num,  -- Dia da semana como número (0=Domingo)
        CASE strftime('%w', created_at)
            WHEN '0' THEN 'Domingo'
            WHEN '1' THEN 'Segunda'
            WHEN '2' THEN 'Terça'
            WHEN '3' THEN 'Quarta'
            WHEN '4' THEN 'Quinta'
            WHEN '5' THEN 'Sexta'
            WHEN '6' THEN 'Sábado'
        END AS dia_semana_nome,                                         -- Nome do dia da semana (PT-BR)
        COUNT(DISTINCT user_id) AS compradores,                         -- Compradores únicos
        COUNT(*) AS num_transacoes,                                     -- Total de transações
        SUM(paid_value) AS receita                                      -- Receita total
    FROM user_transactions
    GROUP BY dia_semana_num, dia_semana_nome
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Ordena resultados do Domingo ao Sábado.
-- ---------------------------------------------------------------------------------
SELECT
    dia_semana_num,     -- Dia da semana (0–6)
    dia_semana_nome,    -- Nome do dia da semana (PT-BR)
    compradores,
    num_transacoes,
    receita
FROM weekday_agg
ORDER BY dia_semana_num;

-- Fim do script: 03_sales_by_weekday.sql
-- =============================================================================
