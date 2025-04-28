import pytest
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, year
from pyspark.sql.types import StructType, StructField, StringType, DoubleType, TimestampType, LongType

# --- Configuração ---
# Substitua pelo nome da sua conta de armazenamento
STORAGE_ACCOUNT_NAME = "datavalidation456"
CONTAINER_NAME = "output"
TRANSFORMED_DATA_FOLDER = "transformed_weather_data"
TRANSFORMED_DATA_PATH = f"wasbs://{CONTAINER_NAME}@{STORAGE_ACCOUNT_NAME}.blob.core.windows.net/{TRANSFORMED_DATA_FOLDER}/"
EXPECTED_YEAR = 2023 # O ano que foi filtrado no notebook

# Esquema esperado após a transformação
EXPECTED_SCHEMA = StructType([
    StructField("station_id_usaf", StringType(), True),
    StructField("station_id_wban", StringType(), True),
    StructField("timestamp", TimestampType(), True),
    StructField("latitude", DoubleType(), True),
    StructField("longitude", DoubleType(), True),
    StructField("elevation", DoubleType(), True),
    StructField("temperature", DoubleType(), True)
])

# --- Fixture PySpark --- 
# Cria uma sessão Spark para os testes
@pytest.fixture(scope="session")
def spark_session():
    spark = (
        SparkSession.builder
        .appName("TestDataIntegrityNOAA")
        # Adicione configurações adicionais se necessário (ex: para autenticação)
        # .config("spark.jars.packages", "org.apache.hadoop:hadoop-azure:3.3.1") # Exemplo se precisar do conector
        # .config("fs.azure.account.key.<storage_account_name>.blob.core.windows.net", "<storage_key>") # Exemplo com chave
        .getOrCreate()
    )
    yield spark
    spark.stop()

# --- Testes ---

def test_data_path_exists(spark_session):
    """Verifica se o caminho dos dados transformados existe e contém arquivos Parquet."""
    try:
        files = spark_session.sparkContext._jvm.org.apache.hadoop.fs.FileSystem.get(spark_session.sparkContext._jsc.hadoopConfiguration()).globStatus(
            spark_session.sparkContext._jvm.org.apache.hadoop.fs.Path(f"{TRANSFORMED_DATA_PATH}*.parquet")
        )
        assert len(files) > 0, f"Nenhum arquivo Parquet encontrado em {TRANSFORMED_DATA_PATH}"
    except Exception as e:
        pytest.fail(f"Erro ao acessar o caminho {TRANSFORMED_DATA_PATH}: {e}")

@pytest.fixture(scope="module")
def transformed_data(spark_session):
    """Lê os dados transformados para uso em múltiplos testes."""
    try:
        df = spark_session.read.parquet(TRANSFORMED_DATA_PATH)
        return df
    except Exception as e:
        pytest.fail(f"Falha ao ler dados Parquet de {TRANSFORMED_DATA_PATH}: {e}")

def test_schema_matches(transformed_data):
    """Verifica se o esquema do DataFrame corresponde ao esperado."""
    assert transformed_data.schema == EXPECTED_SCHEMA, \
        f"Esquema inesperado. Esperado: {EXPECTED_SCHEMA}. Obtido: {transformed_data.schema}"

def test_no_null_key_columns(transformed_data):
    """Verifica se colunas chave não possuem valores nulos."""
    key_columns = ["station_id_usaf", "timestamp", "temperature"]
    for column_name in key_columns:
        null_count = transformed_data.filter(col(column_name).isNull()).count()
        assert null_count == 0, f"Coluna '{column_name}' contém {null_count} valores nulos."

def test_data_filtered_by_year(transformed_data):
    """Verifica se todos os registros são do ano esperado (filtrado no notebook)."""
    distinct_years = transformed_data.select(year(col("timestamp")).alias("data_year")).distinct().collect()
    years_found = [row.data_year for row in distinct_years]
    
    assert len(years_found) == 1, f"Encontrados múltiplos anos: {years_found}. Esperado apenas {EXPECTED_YEAR}."
    assert years_found[0] == EXPECTED_YEAR, f"Ano incorreto encontrado: {years_found[0]}. Esperado: {EXPECTED_YEAR}."

def test_temperature_range(transformed_data):
    """Verifica se a temperatura está dentro de um intervalo razoável (exemplo)."""
    min_temp, max_temp = transformed_data.selectExpr("min(temperature)", "max(temperature)").first()
    # Exemplo de limites - ajuste conforme necessário para dados meteorológicos reais
    assert min_temp >= -100, f"Temperatura mínima inesperada: {min_temp}"
    assert max_temp <= 100, f"Temperatura máxima inesperada: {max_temp}"

# Para executar os testes localmente (requer PySpark e Pytest instalados):
# pytest tests/test_integridade_dados.py
