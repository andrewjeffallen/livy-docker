#!/bin/bash

# Builds Docker images for Spark cluster with Livy

echo "Building Spark base image..."
docker build \
  -f base.Dockerfile \
  -t mk-spark-base .

echo "Building Spark master image (includes Livy)..."
docker build \
  -f master.Dockerfile \
  -t mk-spark-master .

echo "Building Spark worker image..."
docker build \
  -f worker.Dockerfile \
  -t mk-spark-worker .

echo "Building Jupyter image..."
docker build \
  -f jupyter.Dockerfile \
  -t mk-jupyter .

echo "All images built successfully!"
echo ""
echo "To start the cluster, run:"
echo "  docker-compose up -d"
echo ""
echo "Services will be available at:"
echo "  Spark Master UI: http://localhost:8080"
echo "  Spark Worker UI: http://localhost:8081"
echo "  Livy Server: http://localhost:8998"
echo "  JupyterLab: http://localhost:8888"

