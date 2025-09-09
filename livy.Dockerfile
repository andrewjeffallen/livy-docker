FROM openjdk:11-jdk-slim

# Set environment variables
ENV SPARK_VERSION=3.4.1
ENV HADOOP_VERSION=3
ENV LIVY_VERSION=0.8.0
ENV SPARK_HOME=/opt/spark
ENV LIVY_HOME=/opt/livy
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV PATH=$PATH:$SPARK_HOME/bin:$LIVY_HOME/bin:$HADOOP_HOME/bin
ENV PYSPARK_PYTHON=python3

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget python3 python3-pip python3-dev build-essential procps && \
    pip3 install --no-cache-dir py4j && \
    rm -rf /var/lib/apt/lists/*

# Create livy user
RUN groupadd -r livy && useradd -r -g livy livy

# Download and install Spark
RUN wget -q "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    tar xzf "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /opt/ && \
    rm "spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "$SPARK_HOME"

# Download and install Hadoop (minimal for configuration)
RUN wget -q "https://archive.apache.org/dist/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz" && \
    tar xzf "hadoop-3.3.4.tar.gz" -C /opt/ && \
    rm "hadoop-3.3.4.tar.gz" && \
    mv "/opt/hadoop-3.3.4" "$HADOOP_HOME" && \
    mkdir -p $HADOOP_CONF_DIR

# Download and install Livy
RUN wget -q "https://archive.apache.org/dist/incubator/livy/${LIVY_VERSION}-incubating/apache-livy-${LIVY_VERSION}-incubating-bin.zip" && \
    apt-get update && apt-get install -y unzip && \
    unzip "apache-livy-${LIVY_VERSION}-incubating-bin.zip" -d /opt/ && \
    rm "apache-livy-${LIVY_VERSION}-incubating-bin.zip" && \
    mv "/opt/apache-livy-${LIVY_VERSION}-incubating-bin" "$LIVY_HOME" && \
    apt-get remove -y unzip && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p $LIVY_HOME/logs && \
    mkdir -p $LIVY_HOME/conf && \
    chown -R livy:livy $LIVY_HOME && \
    chown -R livy:livy $SPARK_HOME && \
    chown -R livy:livy $HADOOP_HOME

# Create default Livy configuration
RUN echo "livy.server.host = 0.0.0.0" > $LIVY_HOME/conf/livy.conf && \
    echo "livy.server.port = 8998" >> $LIVY_HOME/conf/livy.conf && \
    echo "livy.spark.master = spark://spark-master:7077" >> $LIVY_HOME/conf/livy.conf && \
    echo "livy.spark.deploy-mode = client" >> $LIVY_HOME/conf/livy.conf && \
    echo "livy.repl.enable-hive-context = false" >> $LIVY_HOME/conf/livy.conf

# Create spark-blacklist.conf (empty for now, can be customized)
RUN touch $LIVY_HOME/conf/spark-blacklist.conf

# Create basic log4j.properties
COPY <<EOF $LIVY_HOME/conf/log4j.properties
log4j.rootCategory=INFO, console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

# Set the default spark-shell log level to WARN. When running the spark-shell, the
# log level for this class is used to overwrite the root logger's log level, so that
# the user can have different defaults for the shell and regular Spark apps.
log4j.logger.org.apache.spark.repl.Main=WARN

# Settings to quiet third party logs that are too verbose
log4j.logger.org.spark_project.jetty=WARN
log4j.logger.org.spark_project.jetty.util.component.AbstractLifeCycle=ERROR
log4j.logger.org.apache.spark.repl.SparkIMain$exprTyper=INFO
log4j.logger.org.apache.spark.repl.SparkILoop$SparkILoopInterpreter=INFO
log4j.logger.org.apache.parquet=ERROR
log4j.logger.parquet=ERROR

# SPARK-9183: Settings to avoid annoying messages when looking up nonexistent UDFs in SparkSQL with Hive support
log4j.logger.org.apache.hadoop.hive.metastore.RetryingHMSHandler=FATAL
log4j.logger.org.apache.hadoop.hive.ql.exec.FunctionRegistry=ERROR
EOF

RUN chown -R livy:livy $LIVY_HOME/conf

USER livy

WORKDIR $LIVY_HOME

# Expose Livy port
EXPOSE 8998

# Default command
CMD ["/opt/livy/bin/livy-server", "start"]

