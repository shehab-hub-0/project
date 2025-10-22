"""
examples/pyspark_streaming_kafka.py

A minimal PySpark Structured Streaming example that:
 - reads JSON messages from Kafka topic
 - parses them
 - writes to HDFS parquet (or Hive external table path) for demonstration

Notes:
 - This is intended to be executed with spark-submit inside the spark image or from host with Spark configured.
 - Adjust --packages to include the Kafka Spark connector if needed (org.apache.spark:spark-sql-kafka-0-10_2.12)
"""

import os
from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col
from pyspark.sql.types import StructType, StringType, IntegerType

KAFKA_TOPIC = os.environ.get("KAFKA_TOPIC", "example-topic")
KAFKA_BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP", "kafka:9092")
OUTPUT_PATH = os.environ.get("OUTPUT_PATH", "hdfs://namenode:9000/user/hive/warehouse/stream_output")

schema = StructType() \
    .add("id", StringType()) \
    .add("value", IntegerType())

def main():
    spark = SparkSession.builder \
        .appName("pyspark_streaming_kafka") \
        .master("spark://spark-master:7077") \
        .config("spark.hadoop.fs.defaultFS", "hdfs://namenode:9000") \
        .getOrCreate()

    df = spark \
        .readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", KAFKA_BOOTSTRAP) \
        .option("subscribe", KAFKA_TOPIC) \
        .option("startingOffsets", "earliest") \
        .load()

    json_df = df.selectExpr("CAST(value AS STRING) as json_str") \
        .select(from_json(col("json_str"), schema).alias("data")) \
        .select("data.*")

    query = json_df.writeStream \
        .format("parquet") \
        .option("path", OUTPUT_PATH) \
        .option("checkpointLocation", "/tmp/checkpoints/pyspark_streaming") \
        .outputMode("append") \
        .start()

    print("Streaming started. Check Spark UI at http://localhost:8080 (or Spark Master UI inside codespace).")
    query.awaitTermination()

if __name__ == "__main__":
    main()

