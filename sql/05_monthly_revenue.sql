-- =============================================================================
-- Arquivo: sql/05_monthly_sales.sql
-- Descrição: Agrega vendas mensais e métricas para análise de padrões e sazonalidade.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Inclui contagem de compradores distintos, transações totais e receita.
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'monthly_agg': Agrega por mês/ano da transação.
-- ---------------------------------------------------------------------------------
WITH monthly_agg AS (
    SELECT
        strftime('%m/%Y', created_at) AS mes_ano,  -- Formato MM/YYYY
        COUNT(DISTINCT user_id) AS compradores,    -- Número único de usuários que compraram
        COUNT(*) AS num_transacoes,                -- Contagem total de transações no mês
        SUM(paid_value) AS receita                 -- Soma dos valores pagos no mês
    FROM user_transactions
    GROUP BY strftime('%m/%Y', created_at)         -- Agrupa todas as métricas por mês/ano
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Retorna métricas mensais ordenadas cronologicamente
-- ---------------------------------------------------------------------------------
SELECT
    ma.mes_ano,                             -- Mês/Ano da agregação
    ma.compradores,                         -- Compradores únicos no mês
    ma.num_transacoes,                      -- Total de transações no mês
    ma.receita                              -- Receita total no mês
FROM monthly_agg ma                         -- Fonte de métricas mensais
ORDER BY 
    substr(ma.mes_ano, 4, 4),              -- Ordena primeiro por ano
    substr(ma.mes_ano, 1, 2);              -- Depois por mês

-- Fim do script: 05_monthly_sales.sql
-- =============================================================================
