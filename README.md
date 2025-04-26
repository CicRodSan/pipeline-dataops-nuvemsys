# Pipeline de DataOps com Azure

Este projeto demonstra um pipeline de DataOps de ponta a ponta usando tecnologias Azure, incluindo Bicep para Infraestrutura como Código (IaC), Azure Data Factory (ADF) para orquestração de dados, Azure Blob Storage para armazenamento e Azure SQL Database (opcionalmente, para armazenamento estruturado).

O pipeline é implantado automaticamente usando GitHub Actions.

## Arquitetura

(Consulte `docs/arquitetura.drawio` para um diagrama visual)

1.  **Infraestrutura (IaC):** Os arquivos Bicep (`infra/main.bicep` e `infra/parameters.json`) definem os recursos do Azure necessários:
    *   Resource Group
    *   Storage Account (para dados brutos e processados)
    *   Data Factory (para orquestrar o fluxo de dados)
    *   SQL Server e Database (para dados relacionais, se necessário)
    *   Application Insights (para monitoramento)
2.  **Orquestração (ADF):** Os pipelines, datasets e linked services do Data Factory são definidos como JSON em `infra/pipelines/`.
    *   `linkedservice_blobstorage.json`: Conecta o ADF à conta de armazenamento.
    *   `dataset_fontedados.json`: Representa os dados de entrada no contêiner `input` do Blob Storage.
    *   `dataset_destinodados.json`: Representa os dados de saída no contêiner `output` do Blob Storage.
    *   `ingestao.adf.json`: Pipeline simples que copia dados de `FonteDados` para `DestinoDados`.
    *   (Outros arquivos como `monitoramento.json`, `transformacao.json` podem conter definições adicionais de pipelines/datasets).
3.  **Transformação (Opcional):** Um notebook Jupyter (`notebooks/transformacao_dados.ipynb`) pode ser usado para tarefas de transformação de dados mais complexas, potencialmente integrado ao pipeline do ADF.
4.  **Testes:** Testes de integridade de dados (`tests/test_integridade_dados.py`) podem ser implementados para garantir a qualidade dos dados.
5.  **CI/CD (GitHub Actions):** O workflow `.github/workflows/deploy.yml` automatiza:
    *   Login no Azure.
    *   Criação do Resource Group.
    *   Implantação da infraestrutura Bicep.
    *   Implantação dos componentes do Data Factory (Linked Service, Datasets, Pipelines).
    *   Validação dos recursos criados.

## Como Usar

1.  **Pré-requisitos:**
    *   Conta do Azure com uma assinatura ativa.
    *   Azure CLI instalada.
    *   Credenciais do Azure configuradas como um segredo `AZURE_CREDENTIALS` no repositório GitHub.
2.  **Implantação:**
    *   Faça um push para a branch `main`. O workflow do GitHub Actions será acionado automaticamente, provisionando a infraestrutura e implantando os pipelines.
3.  **Monitoramento:**
    *   Acesse o portal do Azure para monitorar os recursos, incluindo o Data Factory e o Application Insights.

## Estrutura do Projeto

```
.
├── .github/workflows/      # Workflows do GitHub Actions (CI/CD)
│   └── deploy.yml
├── docs/                   # Documentação (arquitetura, processos)
├── infra/                  # Infraestrutura como Código (Bicep) e definições do ADF
│   ├── main.bicep          # Template Bicep principal
│   ├── parameters.json     # Parâmetros para o template Bicep
│   └── pipelines/          # Definições JSON do Azure Data Factory
│       ├── dataset_destinodados.json
│       ├── dataset_fontedados.json
│       ├── ingestao.adf.json
│       ├── linkedservice_blobstorage.json
│       ├── monitoramento.json
│       └── transformacao.json
├── notebooks/              # Notebooks Jupyter para análise/transformação
│   └── transformacao_dados.ipynb
├── tests/                  # Testes automatizados
│   └── test_integridade_dados.py
├── LICENSE                 # Licença do projeto
└── README.md               # Este arquivo
```