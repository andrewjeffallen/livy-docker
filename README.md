# Apache Livy & Spark Cluster with Docker

This project sets up a complete Apache Spark cluster with Livy REST API server using Docker containers. It includes JupyterLab for interactive development and demonstrates distributed computing with the Titanic dataset.

## Architecture

The cluster consists of four main services:
- **Spark Master** - Manages the cluster and hosts Livy server
- **Spark Worker** - Executes Spark jobs
- **JupyterLab** - Interactive notebook environment
- **Livy Server** - REST API for submitting Spark jobs

## Prerequisites

- Docker installed and running
- Docker Compose
- Python 3.7+ (for the client script)

## Quick Start

### 1. Build Docker Images

```bash
# Make the build script executable
chmod +x build.sh

# Build all Docker images
./build.sh
```

This will create four Docker images:
- `mk-spark-base` - Base image with Spark and Java
- `mk-spark-master` - Master node with Livy server
- `mk-spark-worker` - Worker node
- `mk-jupyter` - JupyterLab with PySpark

### 2. Start the Cluster

```bash
# Start all services in detached mode
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Verify Services

Once all containers are running, verify the services:

| Service | URL | Description |
|---------|-----|-------------|
| Spark Master UI | http://localhost:8080 | Monitor cluster status |
| Spark Worker UI | http://localhost:8081 | Monitor worker status |
| Livy Server | http://localhost:8998 | REST API endpoint |
| JupyterLab | http://localhost:8888 | Interactive notebooks |

### 4. Run the Titanic Analysis

```bash
# Install Python dependencies
pip install -r requirements.txt

# Run the analysis
python titanic_data.py
```

## Services Overview

### Spark Master (Port 8080, 7077, 8998)
- Hosts the Spark master process
- Runs Livy server for REST API access
- Manages job distribution to workers
- Web UI available at http://localhost:8080

### Spark Worker (Port 8081)
- Executes Spark tasks assigned by master
- Configurable cores and memory
- Web UI available at http://localhost:8081

### Livy Server (Port 8998)
- Provides REST API for Spark job submission
- Supports PySpark, Scala, and R
- Session management for interactive computing
- API documentation at http://localhost:8998/ui

### JupyterLab (Port 8888)
- Interactive notebook environment
- Pre-configured with PySpark
- Shared workspace with Spark cluster
- Access at http://localhost:8888

## Usage Examples

### Using Livy REST API Directly

```bash
# Create a new PySpark session
curl -X POST \
  http://localhost:8998/sessions \
  -H 'Content-Type: application/json' \
  -d '{"kind": "pyspark"}'

# Submit code to session
curl -X POST \
  http://localhost:8998/sessions/0/statements \
  -H 'Content-Type: application/json' \
  -d '{"code": "spark.range(10).count()"}'

# Get session status
curl http://localhost:8998/sessions/0/state
```

### Using Python Client (pylivy)

```python
from livy import LivySession, SessionKind

with LivySession.create("http://localhost:8998", kind=SessionKind.PYSPARK) as session:
    # Run PySpark code
    session.run("df = spark.range(10)")
    session.run("print(f'Count: {df.count()}')")
    
    # Read results as Pandas DataFrame
    session.run("result = spark.range(10).toPandas()")
    local_df = session.read("result")
    print(local_df)
```

### Using JupyterLab

1. Open http://localhost:8888 in your browser
2. Create a new notebook
3. Use PySpark directly:

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("JupyterExample") \
    .master("spark://spark-master:7077") \
    .getOrCreate()

# Your Spark code here
df = spark.range(100)
print(f"Count: {df.count()}")
```

## File Structure

```
├── base.Dockerfile          # Base image with Spark and Java
├── master.Dockerfile        # Master node with Livy
├── worker.Dockerfile        # Worker node
├── jupyter.Dockerfile       # JupyterLab image
├── docker-compose.yml       # Service orchestration
├── entryfile.sh            # Master node startup script
├── build.sh               # Build all images
├── titanic_data.py        # Titanic analysis example
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## Scaling Workers

To add more workers, edit `docker-compose.yml`:

```yaml
  spark-worker-2:
    image: mk-spark-worker
    container_name: mk-spark-worker-2
    hostname: spark-worker-2
    depends_on:
      - spark-master
    ports:
      - 8082:8081
    volumes:
      - shared-workspace:/opt/workspace
    networks:
      - spark-network
    environment:
      - SPARK_WORKER_CORES=2
      - SPARK_WORKER_MEMORY=1g
      - SPARK_MASTER_HOST=spark-master
      - SPARK_MASTER_PORT=7077
```

## Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker status
docker --version
docker-compose --version

# View container logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

**Port conflicts:**
```bash
# Check what's using ports
netstat -tulpn | grep :8080
netstat -tulpn | grep :8998

# Modify ports in docker-compose.yml if needed
```

**Livy connection errors:**
```bash
# Verify Livy is running
curl http://localhost:8998/sessions

# Check firewall settings
# Ensure ports 8998, 8080, 8081, 7077 are accessible
```

### Logs and Debugging

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f spark-master
docker-compose logs -f spark-worker-1

# Execute commands inside containers
docker exec -it mk-spark-master bash
docker exec -it mk-spark-worker-1 bash
```

## Stopping the Cluster

```bash
# Stop all services
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images
docker rmi mk-spark-master mk-spark-worker mk-jupyter mk-spark-base
```

## Performance Tuning

### Worker Resources
Edit environment variables in `docker-compose.yml`:

```yaml
environment:
  - SPARK_WORKER_CORES=4
  - SPARK_WORKER_MEMORY=2g
```

### Spark Configuration
Modify Spark settings in your application:

```python
spark = SparkSession.builder \
    .appName("MyApp") \
    .master("spark://spark-master:7077") \
    .config("spark.executor.memory", "1g") \
    .config("spark.executor.cores", "2") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Apache Livy Documentation](https://livy.incubator.apache.org/)
- [Docker Documentation](https://docs.docker.com/)
- [JupyterLab Documentation](https://jupyterlab.readthedocs.io/)

