FROM openjdk:11-jdk-slim

# Set environment variables
ENV SPARK_VERSION=3.4.1
ENV HADOOP_VERSION=3
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
ENV PYSPARK_PYTHON=python3

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget python3 python3-pip procps && \
    rm -rf /var/lib/apt/lists/*

# Create spark user
RUN groupadd -r spark && useradd -r -g spark spark

# Download and install Spark
RUN wget -q "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    tar xzf "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /opt/ && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "$SPARK_HOME" && \
    chown -R spark:spark $SPARK_HOME

# Create directories
RUN mkdir -p /opt/spark/logs && \
    mkdir -p /opt/spark/work-dir && \
    chown -R spark:spark /opt/spark/logs && \
    chown -R spark:spark /opt/spark/work-dir

# Copy startup scripts
COPY <<EOF /opt/spark/start-master.sh
#!/bin/bash
export SPARK_MASTER_HOST=`hostname`
cd /opt/spark
./bin/spark-class org.apache.spark.deploy.master.Master --host $SPARK_MASTER_HOST --port 7077 --webui-port 8080
EOF

COPY <<EOF /opt/spark/start-worker.sh
#!/bin/bash
cd /opt/spark
./bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER_URL --webui-port 8081
EOF

RUN chmod +x /opt/spark/start-master.sh /opt/spark/start-worker.sh && \
    chown spark:spark /opt/spark/start-master.sh /opt/spark/start-worker.sh

USER spark

WORKDIR $SPARK_HOME

# Expose ports
EXPOSE 8080 7077 8081 4040

# Default command
CMD ["/bin/bash", "-c", "if [ \"$SPARK_MODE\" = 'master' ]; then ./start-master.sh; else ./start-worker.sh; fi"]

