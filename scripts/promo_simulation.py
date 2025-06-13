# =============================================================================
# Arquivo: scripts/promo_simulation_refactored.py
# Descrição: Módulo para detectar períodos promocionais e simular receita líquida
#             utilizando pandas e scikit-learn para amostragem.
# Autor: Sophia Katze de Paula
# Data: 2025-06-12
# Observação: Refatorado para usar pandas e sklearn.utils.resample em vez de numpy puro.
# =============================================================================

import pandas as pd
from sklearn.utils import resample
import seaborn as sns
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------------
# Função: carregar_transacoes_pandas
# Descrição: Lê CSV de transações e retorna DataFrame Pandas com colunas normalizadas
# Parâmetros:
#   caminho_csv (str): caminho para o arquivo CSV de transações
# Retorno:
#   pd.DataFrame: DataFrame com coluna 'data_tx' e demais originais renomeadas
# ---------------------------------------------------------------------------------
def carregar_transacoes_pandas(caminho_csv: str) -> pd.DataFrame:
    df = (pd.read_csv(caminho_csv, parse_dates=['created_at'])
            .rename(columns={'created_at': 'data_tx'}))
    return df

# ---------------------------------------------------------------------------------
# Função: identificar_periodo_promocional
# Descrição: Identifica intervalo de datas em que o desconto médio diário excede limite
# Parâmetros:
#   df_transacoes (pd.DataFrame): DataFrame contendo 'data_tx' e 'discount_percent'
#   limite_desconto (float): valor entre 0 e 1 que define promoção (ex: 0.85)
# Retorno:
#   tupla(pd.Timestamp|None, pd.Timestamp|None): (data_inicio, data_fim) da promoção
# ---------------------------------------------------------------------------------
def identificar_periodo_promocional(df_transacoes: pd.DataFrame,
                                   limite_desconto: float = 0.85):
    # Agrupa por dia calculando desconto médio
    df_avg = (df_transacoes
              .groupby('data_tx')['discount_percent']
              .mean()
              .reset_index(name='avg_discount'))
    
    # Filtra dias que atendem ao critério
    mask = df_avg['avg_discount'] >= (limite_desconto * 100)
    dias_promocao = df_avg.loc[mask, 'data_tx']
    
    # Retorna intervalo ou None
    if dias_promocao.empty:
        return None, None
    return dias_promocao.min(), dias_promocao.max()

# ---------------------------------------------------------------------------------
# Função: simular_receita_descontos
# Descrição: Executa bootstrap via sklearn para simular receita líquida
# Parâmetros:
#   df_transacoes (pd.DataFrame): deve conter 'data_tx' e 'full_value'
#   periodo (tuple): (data_inicio, data_fim) para filtrar simulação
#   niveis_desconto (list): lista de descontos em % (0-100)
#   n_sim (int): número de amostras bootstrap
# Retorno:
#   pd.DataFrame: métricas de receita para cada nível de desconto
# ---------------------------------------------------------------------------------
def simular_receita_descontos(df_transacoes: pd.DataFrame,
                              periodo: tuple,
                              niveis_desconto: list,
                              n_sim: int = 5000) -> pd.DataFrame:
    inicio, fim = periodo
    # Filtra transações no período
    df_promo = df_transacoes.loc[
        (df_transacoes['data_tx'] >= inicio) &
        (df_transacoes['data_tx'] <= fim)
    ]
    
    # Prepara dados para bootstrap
    valores = df_promo['full_value']
    resultados = []
    
    for desc in niveis_desconto:
        medias = []
        for _ in range(n_sim):
            # Amostragem com reposição
            amostra = resample(valores, replace=True, n_samples=len(valores))
            receita = amostra.sum() * (1 - desc/100)
            medias.append(receita)
        resultados.append({
            'discount_pct': desc,
            'mean_revenue': pd.Series(medias).mean(),
            'revenue_5th_pct': pd.Series(medias).quantile(0.05),
            'revenue_95th_pct': pd.Series(medias).quantile(0.95)
        })
    return pd.DataFrame(resultados)

# ---------------------------------------------------------------------------------
# Função: plotar_simulacao
# Descrição: Plota resultados da simulação de receita versus desconto
# Parâmetros:
#   df_resultados (pd.DataFrame): colunas 'discount_pct', 'mean_revenue',
#                                 'revenue_5th_pct', 'revenue_95th_pct'
# ---------------------------------------------------------------------------------
def plotar_simulacao(df_resultados: pd.DataFrame):
    sns.set_theme(style='whitegrid')
    plt.figure(figsize=(10, 6))
    plt.plot(df_resultados['discount_pct'], df_resultados['mean_revenue'], marker='o', label='Receita Média')
    plt.fill_between(
        df_resultados['discount_pct'],
        df_resultados['revenue_5th_pct'],
        df_resultados['revenue_95th_pct'],
        alpha=0.3,
        label='Intervalo 5-95%'
    )
    plt.xlabel('Percentual de Desconto (%)')
    plt.ylabel('Receita Líquida')
    plt.title('Simulação Monte Carlo de Receita vs Desconto')
    plt.legend()
    plt.tight_layout()
    plt.show()
