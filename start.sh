#!/bin/bash

# Comprehensive startup script for Apache Livy & Spark Cluster

echo "🚀 Apache Livy & Spark Cluster Startup Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed and running
check_docker() {
    print_status "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Docker is installed and running"
}

# Check if Docker Compose is installed
check_docker_compose() {
    print_status "Checking Docker Compose installation..."
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_success "Docker Compose is installed"
}

# Build Docker images
build_images() {
    print_status "Building Docker images..."
    
    # Make build script executable
    chmod +x build.sh
    
    # Run build script
    if ./build.sh; then
        print_success "All Docker images built successfully"
    else
        print_error "Failed to build Docker images"
        exit 1
    fi
}

# Start the cluster
start_cluster() {
    print_status "Starting Spark cluster..."
    
    # Start services in detached mode
    if docker-compose up -d; then
        print_success "Cluster started successfully"
    else
        print_error "Failed to start cluster"
        exit 1
    fi
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    services=(
        "http://localhost:8080:Spark Master"
        "http://localhost:8081:Spark Worker" 
        "http://localhost:8998:Livy Server"
        "http://localhost:8888:JupyterLab"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r url name <<< "$service"
        print_status "Checking $name..."
        
        # Wait up to 60 seconds for each service
        timeout=60
        elapsed=0
        
        while [ $elapsed -lt $timeout ]; do
            if curl -s "$url" > /dev/null 2>&1; then
                print_success "$name is ready"
                break
            fi
            
            sleep 2
            elapsed=$((elapsed + 2))
            
            if [ $elapsed -ge $timeout ]; then
                print_warning "$name is not responding after ${timeout}s"
            fi
        done
    done
}

# Display service URLs
display_urls() {
    echo ""
    echo "🌐 Service URLs:"
    echo "==============="
    echo "📊 Spark Master UI:  http://localhost:8080"
    echo "👷 Spark Worker UI:  http://localhost:8081"
    echo "🔌 Livy Server API:  http://localhost:8998"
    echo "📓 JupyterLab:       http://localhost:8888"
    echo ""
}

# Check service status
check_status() {
    print_status "Checking service status..."
    docker-compose ps
}

# Setup Python environment
setup_python() {
    print_status "Setting up Python environment..."
    
    if command -v python3 &> /dev/null; then
        print_status "Python 3 found, installing dependencies..."
        
        if pip3 install -r requirements.txt; then
            print_success "Python dependencies installed"
        else
            print_warning "Failed to install Python dependencies. You may need to install them manually."
        fi
    else
        print_warning "Python 3 not found. Please install Python 3 to run the client scripts."
    fi
}

# Run example analysis
run_example() {
    if [ -f "titanic_data.py" ]; then
        echo ""
        read -p "Would you like to run the Titanic analysis example? [y/N]: " run_analysis
        
        if [[ $run_analysis =~ ^[Yy]$ ]]; then
            print_status "Running Titanic analysis..."
            
            if python3 titanic_data.py; then
                print_success "Analysis completed successfully!"
            else
                print_error "Analysis failed. Check the logs above."
            fi
        fi
    fi
}

# Main execution
main() {
    echo ""
    
    # Check prerequisites
    check_docker
    check_docker_compose
    
    # Check if images already exist
    if docker images | grep -q "mk-spark-base"; then
        print_status "Docker images already exist"
        read -p "Would you like to rebuild them? [y/N]: " rebuild
        
        if [[ $rebuild =~ ^[Yy]$ ]]; then
            build_images
        fi
    else
        build_images
    fi
    
    # Check if cluster is already running
    if docker-compose ps | grep -q "Up"; then
        print_warning "Some services are already running"
        read -p "Would you like to restart the cluster? [y/N]: " restart
        
        if [[ $restart =~ ^[Yy]$ ]]; then
            print_status "Stopping existing cluster..."
            docker-compose down
            start_cluster
        fi
    else
        start_cluster
    fi
    
    # Wait for services and check status
    wait_for_services
    check_status
    display_urls
    
    # Setup Python environment
    setup_python
    
    # Optionally run example
    run_example
    
    echo ""
    print_success "Spark cluster is ready! 🎉"
    echo ""
    echo "💡 Quick commands:"
    echo "  - View logs:           docker-compose logs -f"
    echo "  - Stop cluster:        docker-compose down"
    echo "  - Restart cluster:     docker-compose restart"
    echo "  - Run Titanic example: python3 titanic_data.py"
    echo ""
}

# Handle script interruption
trap 'print_warning "Script interrupted by user"; exit 1' INT

# Run main function
main

