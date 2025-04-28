# Pipeline de DataOps com Azure e Azure Dataset

## Visão Geral

Este projeto demonstra um pipeline de DataOps completo na Azure, usando dados públicos do Azure Open Datasets (NOAA ISD). O fluxo cobre desde a infraestrutura, ingestão, transformação com Databricks, monitoramento com Application Insights, até testes automatizados de integridade dos dados.

## Componentes do Projeto

- **Infraestrutura (IaC):**  
  Definida em Bicep (`infra/main.bicep`, `infra/parameters.json`), cria Storage Account, Data Factory, Key Vault, SQL Server, Database, Log Analytics e Application Insights com configuração segura.

- **Pipelines e Datasets (ADF):**  
  Os arquivos em `infra/pipelines/` definem:
  - Linked Services para Blob Storage (seu e do NOAA) e Databricks
  - Datasets de entrada (NOAAISDSource, FonteDados) e saída (DestinoDados)
  - Pipeline de ingestão (`ingestao.adf.json`): copia dados Parquet do NOAA para seu Blob Storage
  - Pipeline de transformação (`transformacao.json`): executa notebook Databricks com parâmetros
  - Pipeline de monitoramento (`monitoramento.json`): monitora execuções e envia alertas

- **Notebook de Transformação:**  
  O notebook `notebooks/transformacao_dados.ipynb` contém código PySpark completo para:
  - Ler dados brutos do Blob Storage
  - Mapear dinamicamente colunas ao esquema padrão
  - Filtrar por ano e remover valores nulos
  - Converter unidades de temperatura quando necessário
  - Calcular métricas de qualidade de dados
  - Salvar dados transformados no formato Parquet

- **Testes Automatizados:**  
  O arquivo `tests/test_integridade_dados.py` valida a integridade dos dados transformados usando PySpark e pytest, checando esquema, valores nulos, ano dos registros e faixas de temperatura.

- **Documentação Técnica:**
  - Diagrama de arquitetura detalhado em `docs/arquitetura.drawio`
  - Documentação do processo e decisões técnicas em `docs/processo.org`

- **CI/CD:**  
  O workflow `.github/workflows/deploy.yml` automatiza a implantação da infraestrutura e dos pipelines no Azure via GitHub Actions.

## Segurança e Boas Práticas

- **Gerenciamento de Segredos:**
  - Senhas e tokens armazenados no Key Vault (não hardcoded)
  - Suporte para identidades gerenciadas
  - Implementado TLS 1.2 para todas as conexões
  
- **Monitoramento e Alertas:**
  - Application Insights para métricas operacionais
  - Pipeline dedicado para monitoramento
  - Alertas via webhook para falhas
  - Log Analytics para análise de logs

## Como funciona o pipeline

1. **Ingestão:**  
   O pipeline ADF copia dados Parquet do NOAA ISD (armazenados em Azure Open Datasets) para seu Blob Storage, usando autenticação anônima.

2. **Transformação:**  
   Um notebook Databricks lê os dados do Blob Storage, processa e salva os resultados no container "output" na pasta "transformed_weather_data".

3. **Validação:**  
   Testes automatizados garantem a qualidade dos dados transformados.
   
4. **Monitoramento:**
   O pipeline de monitoramento verifica status de execuções e envia métricas para Application Insights.

## Como usar

1. Faça o deploy da infraestrutura com Bicep.
2. Configure o cluster Databricks e o linked service com seu ID de cluster.
3. Execute os pipelines do Data Factory para ingestão e transformação.
4. Rode os testes de integridade para validar os dados processados.

## Estrutura dos arquivos

- `infra/main.bicep`, `infra/parameters.json`: Infraestrutura Azure com segurança integrada.
- `infra/pipelines/`: JSONs de Linked Services, Datasets e Pipelines do ADF.
- `notebooks/transformacao_dados.ipynb`: Notebook Databricks com código completo para transformação.
- `tests/test_integridade_dados.py`: Testes de integridade dos dados.
- `.github/workflows/deploy.yml`: CI/CD para deploy automatizado.
- `docs/`: Documentação técnica e diagrama de arquitetura.

## Exemplos de Uso

### 1. Deploy da Infraestrutura

Execute o deploy da infraestrutura Azure usando a Azure CLI:

```bash
az deployment group create \
  --resource-group <nome-do-resource-group> \
  --template-file infra/main.bicep \
  --parameters @infra/parameters.json
```

### 2. Configuração do Databricks

1. Crie um workspace e cluster no Azure Databricks.
2. Gere um token de acesso em User Settings > Access Tokens.
3. Atualize o linked service do Databricks com seu ID de cluster e token.
4. Importe o repositório GitHub no workspace Databricks ou faça upload do notebook.

### 3. Execução dos Pipelines no Data Factory

Após o deploy, acesse o Azure Data Factory pelo portal e execute os pipelines:
- **Pipeline de Ingestão:** Copia dados do dataset público NOAA ISD para seu Blob Storage.
- **Pipeline de Transformação:** Executa o notebook Databricks para processar os dados.
- **Pipeline de Monitoramento:** Monitora o status dos outros pipelines.

### 4. Execução do Notebook Databricks

No Databricks:
1. Importe ou sincronize o notebook `notebooks/transformacao_dados.ipynb`.
2. Conecte ao cluster criado.
3. Execute as células para processar os dados Parquet copiados pelo pipeline.

### 5. Rodando os Testes de Integridade

Instale as dependências necessárias:
```bash
pip install pytest pyspark
```

Execute os testes:
```bash
pytest tests/test_integridade_dados.py
```

Os testes validam:
- Existência dos arquivos Parquet transformados
- Esquema dos dados
- Ausência de valores nulos em colunas-chave
- Ano dos registros
- Faixa de temperatura

---

## Mais Detalhes

- **Dataset Público:**
  - O pipeline utiliza o dataset NOAA ISD disponível em Azure Open Datasets, acessado via linked service anônimo.
  - O dataset é lido em formato Parquet e copiado para seu próprio Blob Storage para processamento.

- **Transformações Implementadas:**
  - Mapeamento dinâmico de colunas para padronização dos nomes
  - Filtragem por ano (2023)
  - Limpeza de valores nulos em campos críticos
  - Conversão automática de unidades de temperatura (F para C)
  - Métricas de qualidade de dados (completude, distribuição)

- **Segurança e Monitoramento:**
  - Todas as conexões usam HTTPS com TLS 1.2
  - Senhas e tokens armazenados no Key Vault
  - Métricas enviadas para Application Insights
  - Logs consolidados em Log Analytics Workspace

- **CI/CD:**
  - O deploy automatizado via GitHub Actions está em `.github/workflows/deploy.yml`.
  - Basta um push na branch `main` para acionar o pipeline de deploy.

- **Documentação:**
  - Consulte `docs/arquitetura.drawio` para o diagrama da solução.
  - O arquivo `docs/processo.org` contém detalhes sobre decisões arquiteturais e técnicas.
  - Relatórios e análises em `docs/relatorio-final.pdf`.