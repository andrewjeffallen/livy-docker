#!/bin/bash

# run_livy.sh - Script to start Apache Livy server

set -e

echo "Starting Apache Livy server..."

# Export required environment variables
export SPARK_HOME=/opt/spark
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export LIVY_HOME=/opt/livy
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# Set Livy configuration directory
export LIVY_CONF_DIR=${LIVY_HOME}/conf

# Set Python path for PySpark
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# Create logs directory if it doesn't exist
mkdir -p ${LIVY_HOME}/logs

# Wait for Spark master to be available
echo "Waiting for Spark master to be available..."
while ! nc -z spark-master 7077; do
    echo "Waiting for Spark master at spark-master:7077..."
    sleep 2
done
echo "Spark master is available!"

# Print environment information
echo "Environment Information:"
echo "SPARK_HOME: $SPARK_HOME"
echo "HADOOP_CONF_DIR: $HADOOP_CONF_DIR"
echo "LIVY_HOME: $LIVY_HOME"
echo "LIVY_CONF_DIR: $LIVY_CONF_DIR"
echo "JAVA_HOME: $JAVA_HOME"
echo "SPARK_MASTER: $SPARK_MASTER"

# Check if Livy configuration exists
if [ ! -f "$LIVY_CONF_DIR/livy.conf" ]; then
    echo "Creating default Livy configuration..."
    cat > "$LIVY_CONF_DIR/livy.conf" << EOL
# Livy server configuration
livy.server.host = 0.0.0.0
livy.server.port = 8998

# Spark configuration
livy.spark.master = ${SPARK_MASTER:-spark://spark-master:7077}
livy.spark.deploy-mode = client

# Session configuration
livy.server.session.timeout = 1h
livy.server.session.state-retain.sec = 600s

# Enable or disable Hive support
livy.repl.enable-hive-context = false

# Recovery configuration (optional)
livy.server.recovery.mode = off

# Impersonation (disabled for simplicity)
livy.impersonation.enabled = false

# Access control (disabled for development)
livy.server.access-control.enabled = false
EOL
fi

# Create spark-blacklist.conf if it doesn't exist
if [ ! -f "$LIVY_CONF_DIR/spark-blacklist.conf" ]; then
    echo "Creating default spark-blacklist.conf..."
    cat > "$LIVY_CONF_DIR/spark-blacklist.conf" << EOL
# Spark configuration options that users are not allowed to override
# Add configuration keys here that should be restricted
# Example:
# spark.master
# spark.app.name
EOL
fi

# Start Livy server
echo "Starting Livy server..."
cd ${LIVY_HOME}

# Start Livy in foreground mode so Docker container stays running
exec ${LIVY_HOME}/bin/livy-server start

