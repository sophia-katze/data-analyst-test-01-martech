from pyspark.sql import SparkSession
from pyspark.sql.functions import col, date_format, count
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# scripts/promo_simulation.py
# Autor: Sophia Katze de Paula 
# Data: 2025-06-11
# Este módulo oferece funções para identificar o período promocional
# e simular receitas líquidas para diferentes níveis de desconto

# Cria ou retorna SparkSession existente
def obter_spark(app_name="PromoSimulation"):
    """Inicializa e retorna uma SparkSession."""
    return SparkSession.builder.appName(app_name).getOrCreate()

# Função para carregar transações como DataFrame Spark
def carregar_transacoes_spark(spark: SparkSession, caminho_csv: str):
    """Lê o CSV de user_transactions em um DataFrame Spark com schema inferido."""
    return (
        spark.read
             .option("header", True)
             .option("inferSchema", True)
             .csv(caminho_csv)
             .withColumn("data_tx", col("created_at").cast("date"))
    )

# Identifica período de promoção com desconto médio >= limite
def identificar_periodo_promocional(df_transacoes, limite_desconto=0.85):
    """
    Retorna a data de início e fim onde o desconto médio diário >= limite_desconto.
    - df_transacoes: DataFrame Spark contendo colunas 'data_tx' e 'discount_percent'.
    - limite_desconto: float entre 0 e 1, ex: 0.85 para 85%.
    """
    # Calcula desconto médio por dia
    df_desconto = (
        df_transacoes
            .groupBy("data_tx")
            .agg({'discount_percent':'avg'})
            .withColumnRenamed('avg(discount_percent)', 'desconto_medio')
    )
    # Filtra dias promocionais
    dias = (
        df_desconto
            .filter(col('desconto_medio') >= limite_desconto)
            .select('data_tx')
            .orderBy('data_tx')
            .toPandas()
    )
    if dias.empty:
        return None, None
    return dias['data_tx'].min(), dias['data_tx'].max()

# Simulação Monte Carlo de receita líquida
def simular_receita_descontos(df_transacoes, periodo, niveis_desconto, n_sim=5000):
    """
    Realiza simulações de receita líquida para cada nível de desconto.
    - df_transacoes: DataFrame Spark com colunas 'data_tx' e 'full_value'.
    - periodo: tupla (data_inicio, data_fim).
    - niveis_desconto: lista de inteiros [0,10,...,90].
    - n_sim: número de iterações Monte Carlo.
    Retorna DataFrame pandas com resultado para cada desconto.
    """
    inicio, fim = periodo
    # Filtra transações dentro do período promocional
    df_promo = df_transacoes.filter((col('data_tx') >= inicio) & (col('data_tx') <= fim))
    # Coleta no driver contagens diárias e valores cheios
    contagens_diarias = (
        df_promo
            .groupBy('data_tx')
            .agg(count('*').alias('qtd_tx'))
            .select('qtd_tx')
            .toPandas()['qtd_tx'].values
    )
    valores_cheios = df_promo.select('full_value').toPandas()['full_value'].values

    resultados = []
    for d in niveis_desconto:
        receita_media = []
        for _ in range(n_sim):
            tx = np.random.choice(contagens_diarias)
            amostra = np.random.choice(valores_cheios, size=tx, replace=True)
            liquido = amostra.sum() * (1 - d/100)
            receita_media.append(liquido)
        resultados.append({
            'discount_pct': d,
            'mean_revenue': np.mean(receita_media),
            'revenue_5th_pct': np.percentile(receita_media, 5),
            'revenue_95th_pct': np.percentile(receita_media, 95)
        })
    return pd.DataFrame(resultados)

# Plot dos resultados de simulação
def plotar_simulacao(df_resultados):
    """
    Gera gráfico de receita média e intervalo de confiança (5-95%).
    - df_resultados: DataFrame pandas com colunas 'discount_pct', 'mean_revenue', 'revenue_5th_pct', 'revenue_95th_pct'.
    """
    sns.set_theme(style='whitegrid')
    plt.figure(figsize=(10,6))
    plt.plot(df_resultados['discount_pct'], df_resultados['mean_revenue'], marker='o', label='Receita Média')
    plt.fill_between(
        df_resultados['discount_pct'],
        df_resultados['revenue_5th_pct'],
        df_resultados['revenue_95th_pct'],
        alpha=0.3,
        label='Intervalo 5-95%'
    )
    plt.xlabel('Percentual de Desconto')
    plt.ylabel('Receita Líquida (R$)')
    plt.title('Simulação Monte Carlo: Receita vs Desconto')
    plt.legend()
    plt.tight_layout()
    plt.show()
