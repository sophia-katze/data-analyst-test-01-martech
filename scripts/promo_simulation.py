# Importa as bibliotecas necessárias para manipulação de dados, cálculos numéricos e visualização
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
# Importa funções específicas para transformação logística (sigmoid) e sua inversa
from scipy.special import logit, expit # Sigmoid function and its inverse

# Define função que modela como a taxa de conversão varia com o desconto
def modelar_uplift_conversao(
    taxa_conversao_base: float,    # Taxa de conversão sem desconto
    taxa_conversao_promo: float,   # Taxa de conversão com desconto promocional
    desconto_promo: float         # Valor do desconto promocional
) -> callable:
    """
    Documentação da função que explica seu propósito e parâmetros
    """
    
    # Define os pontos conhecidos de conversão (sem desconto e com desconto promocional)
    ponto_base = (0, taxa_conversao_base)
    ponto_promo = (desconto_promo, taxa_conversao_promo)

    # Converte as taxas de conversão para o espaço logit para linearização
    logit_base = logit(ponto_base[1])
    logit_promo = logit(ponto_promo[1])

    # Calcula a inclinação da reta no espaço logit
    slope = (logit_promo - logit_base) / (ponto_promo[0] - ponto_base[0])

    # Define função interna que faz a previsão de conversão para qualquer desconto
    def prever_conversao(desconto: float) -> float:
        """Função que calcula taxa de conversão para um dado desconto"""
        # Retorna taxa base se desconto for negativo
        if desconto < 0:
            return taxa_conversao_base

        # Faz interpolação linear no espaço logit
        logit_estimado = logit_base + slope * desconto
        
        # Converte resultado de volta para probabilidade
        taxa_estimada = expit(logit_estimado)
        return taxa_estimada

    # Retorna a função de previsão
    return prever_conversao

# Define função que executa simulação Monte Carlo da receita
def simular_receita_com_uplift(
    n_usuarios_potenciais: int,    # Número total de usuários possíveis
    dist_valor_transacao: pd.Series, # Distribuição dos valores de transação
    modelo_uplift: callable,       # Modelo de conversão vs desconto
    descontos: list,              # Lista de descontos a simular
    n_sim: int = 5000,            # Número de simulações por desconto
    random_state: int = 42,       # Semente aleatória para reprodutibilidade
) -> pd.DataFrame:
    """
    Documentação da função de simulação
    """
    # Define semente aleatória para reprodutibilidade
    np.random.seed(random_state)
    # Inicializa lista para armazenar resultados
    resultados = []

    # Itera sobre cada desconto a ser simulado
    for desconto in descontos:
        # Calcula taxa de conversão esperada para o desconto atual
        taxa_conversao_estimada = modelo_uplift(desconto)

        # Executa n_sim simulações para cada desconto
        for i in range(n_sim):
            # Simula número de compradores usando distribuição binomial
            n_compradores = np.random.binomial(n=n_usuarios_potenciais, p=taxa_conversao_estimada)

            # Amostra valores de compra da distribuição histórica
            valores_compras = dist_valor_transacao.sample(n=n_compradores, replace=True)
            valor_bruto_total = valores_compras.sum()

            # Calcula receita líquida após aplicar desconto
            receita_liquida = valor_bruto_total * (1 - desconto / 100)
            
            # Armazena resultados da simulação
            resultados.append({
                'sim_id': i,
                'discount': desconto,
                'revenue': receita_liquida,
                'n_buyers': n_compradores,
                'conversion_rate': taxa_conversao_estimada
            })

    # Converte resultados para DataFrame
    return pd.DataFrame(resultados)

# Define função que analisa resultados da simulação
def analisar_simulacao(df_sim: pd.DataFrame) -> tuple:
    """
    Documentação da função de análise
    """
    # Calcula medianas de receita por desconto
    medianas = df_sim.groupby('discount')['revenue'].median()
    # Identifica desconto que maximiza receita
    melhor_desconto = medianas.idxmax()
    # Obtém valor da maior receita mediana
    melhor_mediana_receita = medianas.max()
    # Retorna resultados da análise
    return melhor_desconto, melhor_mediana_receita, medianas

# Define função que plota resultados da simulação
def plotar_resultados_simulacao(
    df_sim: pd.DataFrame,          # DataFrame com resultados da simulação
    modelo_uplift: callable,       # Modelo de conversão vs desconto
    descontos_avaliados: list,    # Lista de descontos simulados
    receita_baseline: float       # Receita esperada sem promoção
) -> None:
    """
    Documentação da função de plotagem
    """
    # Define estilo dos gráficos
    sns.set_style("whitegrid")
    # Cria figura com dois subplots
    fig, axes = plt.subplots(1, 2, figsize=(20, 8))
    
    # Configura primeiro gráfico (curva de uplift)
    ax1 = axes[0]
    # Gera pontos para curva suave
    descontos_curva = np.linspace(0, max(descontos_avaliados), 100)
    # Calcula conversões para cada ponto
    conversoes_curva = [modelo_uplift(d) * 100 for d in descontos_curva]
    
    # Plota curva de uplift
    ax1.plot(descontos_curva, conversoes_curva, color='dodgerblue', linewidth=2.5)
    # Configura títulos e labels do primeiro gráfico
    ax1.set_title('Modelo de Uplift de Conversão', fontsize=16, pad=20)
    ax1.set_xlabel('Desconto Oferecido (%)', fontsize=12)
    ax1.set_ylabel('Taxa de Conversão Estimada (%)', fontsize=12)
    ax1.grid(True, which='both', linestyle='--', linewidth=0.5)
    
    # Configura segundo gráfico (boxplots de receita)
    ax2 = axes[1]
    # Analisa resultados para identificar melhor desconto
    melhor_desconto, melhor_receita, _ = analisar_simulacao(df_sim)
    
    # Plota boxplots de receita por desconto
    sns.boxplot(
        x='discount', y='revenue', data=df_sim, ax=ax2,
        palette='viridis', order=sorted(df_sim['discount'].unique())
    )
    
    # Adiciona linha de referência da receita baseline
    ax2.axhline(y=receita_baseline, color='red', linestyle='--', linewidth=2, label=f'Receita Baseline (R${receita_baseline:,.0f})')
    
    # Configura títulos e labels do segundo gráfico
    ax2.set_title('Simulação de Receita por Nível de Desconto', fontsize=16, pad=20)
    ax2.set_xlabel('Desconto Oferecido (%)', fontsize=12)
    ax2.set_ylabel('Receita Simulada (R$)', fontsize=12)
    ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda y, _: f'R${y:,.0f}'))
    ax2.legend()
    
    # Imprime resultados principais da simulação
    print(f"\n{' RESULTADOS DA SIMULAÇÃO ':=^80}")
    print(f"📈 Melhor desconto para maximizar a receita: {melhor_desconto}%")
    print(f"💰 Receita mediana estimada com este desconto: R${melhor_receita:,.2f}")
    print(f"💸 Receita mediana do cenário baseline (sem promoção): R${receita_baseline:,.2f}")
    # Calcula e imprime impacto percentual sobre baseline
    impacto_percentual = (melhor_receita - receita_baseline) / receita_baseline * 100
    print(f"🚀 Impacto estimado sobre o baseline: {impacto_percentual:+.2f}%")
    print("="*80)
    
    # Ajusta layout e exibe gráficos
    plt.tight_layout()
    plt.show()
