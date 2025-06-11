# Fatal Model Data Analysis Case

Bem-vindo ao repositório do Case de Análise de Dados da Fatal Model, desenvolvido para a Atlas Technologies. Este projeto simula um contexto real de análise de dados em uma plataforma B2C de acompanhantes, com foco em entender o comportamento dos anunciantes, métricas de engajamento e avaliar uma promoção histórica usando **SQL** para extração/transformação e **Python (Seaborn)** para visualização.

---

## 📋 Estrutura Geral do Repositório

```
data-analyst-test-01-martech/
├── README.md                  # Documentação completa do projeto
├── data/                      # Dados brutos (CSV originais)
│   ├── users.csv             # Informações de usuários/anunciantes
│   └── user_transactions.csv # Histórico de transações
├── sql/                       # Scripts SQL organizados por etapa analítica
│   ├── 01_user_status.sql          # Cálculo de status de usuário (ativos, banidos)
│   ├── 02_daily_sales.sql          # Vendas diárias e sazonalidade
│   ├── 03_spend_per_user.sql       # Usuários pagantes e ARPU
│   ├── 04_monthly_revenue.sql      # Receita por mês
│   ├── 05_promotion_period.sql     # Identificação do período promocional
│   ├── 06_promotion_impact.sql     # Impacto da promoção em receita e transações
│   └── 07_discount_simulation.sql  # Simulação de receita líquida para níveis de desconto
├── notebooks/                 # Jupyter Notebooks para storytelling e visualizações
│   └── analysis.ipynb         # Carga de dados, consultas SQL e plots Seaborn
├── scripts/                   # Scripts auxiliares em Python
│   └── promo_simulation.py    # Simulação Monte Carlo de desconto ideal
└── LICENSE                    # Licença MIT
```

---

## 📖 Contexto Inicial e Storytelling

A **Fatal Model** é uma plataforma B2C que conecta anunciantes (acompanhantes) a clientes, oferecendo planos pagos que aumentam a visibilidade dos anúncios. Cada plano (3, 7 ou 30 dias) adiciona pontos de listagem: mais pontos, maior ranqueamento. Usuários também podem usar a plataforma gratuitamente.

**Storytelling** começa apresentando o cenário de negócio:

1. **Por que a análise importa?** Entender a base ativa vs. banida revela saúde da plataforma. Mensurar compradores e ticket médio direta influencia receita e decisões de marketing.
2. **Picos e sazonalidade:** reconhecer padrões de compra (datas específicas) permite planejar promoções e alocação de recursos.
3. **Promoção histórica de 85%:** avaliar custo-benefício de descontos profundos para primeiras compras e projetar estratégias de descontos futuros.

Ao longo do **notebook** (`analysis.ipynb`), cada seção começa com uma pergunta de negócio, segue com a query SQL correspondente, exibe tabela/resultados e ilustra insights com gráficos Seaborn, culminando em recomendações claras.

---

## 🎯 Objetivos do Case

### Desafio 1: Comportamento da Base

* **Taxas de Status**: Proporção de usuários ativos, onboarding, desabilitados e deletados.
* **Padrão de Compras**: Volume e receita diária, sazonalidade.
* **Usuários Pagantes & ARPU**: Contagem de pagantes e valor médio por usuário.
* **Faturamento Mensal**: Tendência de receita ao longo de meses.

### Desafio 2: Promoção 85% Off

* **Identificação do Período**: Baseado em `discount_percent ≥ 85%`.
* **Impacto**: Mudanças em receita e número de transações pré, durante e pós-promocional.
* **ROI**: Cálculo de receita efetiva vs. projeção sem desconto.
* **Desconto Ideal**: Simulações de receita líquida para diferentes níveis de desconto.

---

## 🔍 Workflow Analítico

1. **Carga e inspeção inicial**

   * Importar CSVs em pandas.
   * Explorar colunas e tipos de dados.
2. **Transformação com SQL**

   * Utilizar `sqlite3` ou conexão a BD para executar scripts em `sql/`.
   * Criar views para cada CTE e importar resultados ao notebook.
3. **Visualização com Seaborn**

   * Plotar gráficos de barras, linhas e mapas de calor.
   * Anotar insights diretamente nos plots.
4. **Simulações e recomendações**

   * Rodar simulações de desconto no script Python.
   * Discutir trade-offs preço × volume.
5. **Storytelling no Notebook**

   * Cada seção inicia com pergunta, segue com SQL, mostra pandas dataframe e Seaborn plot, e finaliza com interpretação e recomendação.

---

## 🧩 Descrição dos Dados

**users.csv** e **user\_transactions.csv** conforme descrito no `README.md` anterior. Mantém mesmo dicionário de colunas.

---

## 📑 Notebooks e Scripts

* **notebooks/analysis.ipynb**: Notebook completo com narrativa, queries e viz.
* **scripts/promo\_simulation.py**: Simulação Monte Carlo para avaliação de níveis de desconto.

---

## 🚀 Como Executar Localmente

1. Clone o repositório:

   ```bash
   git clone https://github.com/seu-usuario/fatalmodel-case.git
   cd fatalmodel-case
   ```
2. Instale dependências:

   ```bash
   pip install pandas seaborn matplotlib sqlite3
   ```
3. Abra o Jupyter Notebook:

   ```bash
   jupyter notebook notebooks/analysis.ipynb
   ```
4. Execute células sequencialmente: as queries SQL rodarão contra um banco SQLite em memória, e os plots Seaborn serão gerados inline.

---

## 🤝 Contato

Para dúvidas, abra uma *issue* ou contate **Patrícia Souza**: [patricia.souza@atlastechnol.com](mailto:patricia.souza@atlastechnol.com)

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License**. Consulte o arquivo `LICENSE` para detalhes.
