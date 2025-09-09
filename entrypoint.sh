#!/bin/bash

echo "Starting Spark Master..."

# Start Spark Master in background
$SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master \
    --host $SPARK_MASTER_HOST \
    --port $SPARK_MASTER_PORT \
    --webui-port 8080 >> /tmp/logs/spark-master.out &

# Wait for Spark Master to start
sleep 10

echo "Starting Livy Server..."

# Configure Livy
export LIVY_HOME=/usr/bin/apache-livy-0.7.0-incubating-bin

# Create Livy configuration if it doesn't exist
if [ ! -f $LIVY_HOME/conf/livy.conf ]; then
    mkdir -p $LIVY_HOME/conf
    cat > $LIVY_HOME/conf/livy.conf << EOF
livy.spark.master = spark://$SPARK_MASTER_HOST:$SPARK_MASTER_PORT
livy.spark.deploy-mode = client
livy.repl.enableHiveContext = false
livy.server.host = 0.0.0.0
livy.server.port = 8998
EOF
fi

# Start Livy Server
$LIVY_HOME/bin/livy-server >> /tmp/logs/livy.out &

echo "Services started. Keeping container alive..."

# Keep container running
tail -f /dev/null

