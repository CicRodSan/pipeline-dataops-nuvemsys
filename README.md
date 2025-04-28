# Pipeline de DataOps com Azure e Azure Dataset

## Visão Geral

Este projeto demonstra um pipeline de DataOps completo na Azure, usando dados públicos do Azure Open Datasets (NOAA ISD). O fluxo cobre desde a infraestrutura, ingestão, transformação com Databricks, até testes automatizados de integridade dos dados.

## Componentes do Projeto

- **Infraestrutura (IaC):**  
  Definida em Bicep (`infra/main.bicep`, `infra/parameters.json`), cria Storage Account, Data Factory, SQL Server, Database e Application Insights.

- **Pipelines e Datasets (ADF):**  
  Os arquivos em `infra/pipelines/` definem:
  - Linked Services para Blob Storage (seu e do NOAA)
  - Datasets de entrada (NOAAISDSource, FonteDados) e saída (DestinoDados)
  - Pipeline de ingestão (`ingestao.adf.json`): copia dados Parquet do NOAA para seu Blob Storage.
  - Pipeline de transformação (`transformacao.json`): executa notebook Databricks para processar os dados.

- **Notebook de Transformação:**  
  O notebook `notebooks/transformacao_dados.ipynb` contém instruções para criar um cluster Databricks e código PySpark para processar os dados copiados do Azure Dataset.

- **Testes Automatizados:**  
  O arquivo `tests/test_integridade_dados.py` valida a integridade dos dados transformados usando PySpark e pytest, checando esquema, valores nulos, ano dos registros e faixas de temperatura.

- **CI/CD:**  
  O workflow `.github/workflows/deploy.yml` automatiza a implantação da infraestrutura e dos pipelines no Azure via GitHub Actions.

## Como funciona o pipeline

1. **Ingestão:**  
   O pipeline ADF copia dados Parquet do NOAA ISD (armazenados em Azure Open Datasets) para seu Blob Storage, usando autenticação anônima.

2. **Transformação:**  
   Um notebook Databricks lê os dados do Blob Storage, processa e salva os resultados em outro contêiner.

3. **Validação:**  
   Testes automatizados garantem a qualidade dos dados transformados.

## Como usar

1. Faça o deploy da infraestrutura com Bicep.
2. Execute os pipelines do Data Factory para ingestão e transformação.
3. Rode os testes de integridade para validar os dados processados.

## Estrutura dos arquivos

- `infra/main.bicep`, `infra/parameters.json`: Infraestrutura Azure.
- `infra/pipelines/`: JSONs de Linked Services, Datasets e Pipelines do ADF.
- `notebooks/transformacao_dados.ipynb`: Notebook Databricks para transformação.
- `tests/test_integridade_dados.py`: Testes de integridade dos dados.
- `.github/workflows/deploy.yml`: CI/CD para deploy automatizado.
- `docs/`: Documentação e diagrama de arquitetura.

## Exemplos de Uso

### 1. Deploy da Infraestrutura

Execute o deploy da infraestrutura Azure usando a Azure CLI:

```bash
az deployment group create \
  --resource-group <nome-do-resource-group> \
  --template-file infra/main.bicep \
  --parameters @infra/parameters.json
```

### 2. Execução dos Pipelines no Data Factory

Após o deploy, acesse o Azure Data Factory pelo portal e execute os pipelines:
- **Pipeline de Ingestão:** Copia dados do dataset público NOAA ISD para seu Blob Storage.
- **Pipeline de Transformação:** Executa o notebook Databricks para processar os dados.

### 3. Execução do Notebook Databricks

No Databricks:
1. Importe ou sincronize o notebook `notebooks/transformacao_dados.ipynb`.
2. Crie e selecione um cluster conforme instruções no início do notebook.
3. Execute as células para processar os dados Parquet copiados pelo pipeline.

### 4. Rodando os Testes de Integridade

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

- **Customização:**
  - Você pode adaptar os pipelines para outros datasets públicos do Azure, bastando criar novos linked services e datasets.
  - O notebook pode ser expandido para realizar outras transformações ou análises.

- **CI/CD:**
  - O deploy automatizado via GitHub Actions está em `.github/workflows/deploy.yml`.
  - Basta um push na branch `main` para acionar o pipeline de deploy.

- **Documentação:**
  - Consulte `docs/arquitetura.drawio` para o diagrama da solução.
  - O arquivo `docs/processo.org` pode ser usado para documentar o fluxo ou decisões do projeto.