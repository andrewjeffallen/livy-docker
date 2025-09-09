FROM debian:stretch

# System packages
RUN apt-get clean && apt-get update -y && \
   apt-get install -y python3 python3-pip curl wget unzip procps openjdk-8-jdk && \
   ln -s /usr/bin/python3 /usr/bin/python && \
   rm -rf /var/lib/apt/lists/*

# Install Spark
RUN curl https://apache.mirrors.tworzy.net/spark/spark-2.4.7/spark-2.4.7-bin-hadoop2.7.tgz -o spark.tgz && \
   tar -xf spark.tgz && \
   mv spark-2.4.7-bin-hadoop2.7 /usr/bin/ && \
   mkdir /usr/bin/spark-2.4.7-bin-hadoop2.7/logs && \
   rm spark.tgz

# Prepare dirs
RUN mkdir -p /tmp/logs/ && chmod a+w /tmp/logs/ && mkdir /app && chmod a+rwx /app && mkdir /data && chmod a+rwx /data

ENV JAVA_HOME=/usr
ENV SPARK_HOME=/usr/bin/spark-2.4.7-bin-hadoop2.7
ENV PATH=$SPARK_HOME:$PATH:/bin:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON=/usr/bin/python
ENV PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH
ENV APP=/app
ENV SHARED_WORKSPACE=/opt/workspace

RUN mkdir -p ${SHARED_WORKSPACE}
VOLUME ${SHARED_WORKSPACE}

