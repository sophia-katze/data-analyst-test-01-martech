-- =============================================================================
-- Arquivo: sql/02_daily_sales.sql
-- Descrição: Agrega vendas diárias e métricas para análise de padrões e sazonalidade.
-- Autor: Sophia Katze de Paula
-- Data: 2025-06-11
-- Observação: Inclui contagem de compradores distintos, transações totais e receita.
-- =============================================================================

-- ---------------------------------------------------------------------------------
-- CTE 'daily_agg': Agrega por data de criação da transação.
-- ---------------------------------------------------------------------------------
WITH daily_agg AS (
    SELECT
        DATE(created_at) AS data,               -- Data da transação (sem hora)
        COUNT(DISTINCT user_id) AS compradores,  -- Número único de usuários que compraram
        COUNT(*) AS num_transacoes,            -- Contagem total de transações no dia
        SUM(paid_value) AS receita             -- Soma dos valores pagos no dia
    FROM user_transactions
    GROUP BY DATE(created_at)                  -- Agrupa todas as métricas por data
)

-- ---------------------------------------------------------------------------------
-- Consulta final: Calcula métrica de receita no mesmo dia e compara com 7 dias atrás.
-- Usa função LAG para gerar coluna de receita 7 dias anteriores para análise de sazonalidade.
-- ---------------------------------------------------------------------------------
SELECT
    da.data,                                -- Data da agregação
    da.compradores,                         -- Compradores únicos no dia
    da.num_transacoes,                      -- Total de transações no dia
    da.receita,                             -- Receita total no dia
    LAG(da.receita, 7) OVER (ORDER BY da.data) AS receita_7d_atras  -- Receita há 7 dias
FROM daily_agg da                           -- Fonte de métricas diárias
ORDER BY da.data;                          -- Ordena cronologicamente

-- Fim do script: 02_daily_sales.sql
-- =============================================================================


