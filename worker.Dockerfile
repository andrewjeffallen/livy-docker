FROM mk-spark-base

ENV APP=/app
ENV JAVA_HOME=/usr
ENV SPARK_HOME=/usr/bin/spark-2.4.7-bin-hadoop2.7
ENV PATH=$SPARK_HOME:$PATH:/bin:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
ENV PYSPARK_PYTHON=/usr/bin/python
ENV PYTHONPATH=$SPARK_HOME/python:$PYTHONPATH

EXPOSE 8081 7077 8998 8888

WORKDIR ${APP}

CMD /usr/bin/spark-2.4.7-bin-hadoop2.7/bin/spark-class org.apache.spark.deploy.worker.Worker spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT} >> /tmp/logs/spark-worker.out

