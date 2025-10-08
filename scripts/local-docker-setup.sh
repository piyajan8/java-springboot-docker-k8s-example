#!/bin/bash

# Local Docker Development Setup Script
# This script helps set up the local development environment using Docker Compose

set -e

echo "🚀 Setting up local Docker development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create logs directory if it doesn't exist
mkdir -p logs

print_status "Building and starting the application with Docker Compose..."

# Build and start the services
docker-compose up --build -d

print_status "Waiting for the application to start..."

# Wait for the application to be healthy
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f http://localhost:8080/actuator/health > /dev/null 2>&1; then
        print_status "Application is healthy and ready!"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        print_error "Application failed to start within expected time"
        print_warning "Check logs with: docker-compose logs app"
        exit 1
    fi
    
    echo "Attempt $attempt/$max_attempts - waiting for application..."
    sleep 5
    ((attempt++))
done

print_status "Local development environment is ready!"
echo ""
echo "📋 Available endpoints:"
echo "   Application: http://localhost:8080"
echo "   Health Check: http://localhost:8080/actuator/health"
echo "   Metrics: http://localhost:8080/actuator/metrics"
echo "   Info: http://localhost:8080/actuator/info"
echo "   All Actuator Endpoints: http://localhost:8080/actuator"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose logs -f app"
echo "   Stop services: docker-compose down"
echo "   Restart app: docker-compose restart app"
echo "   Rebuild and restart: docker-compose up --build -d"
echo ""
print_status "Setup complete! Happy coding! 🎉"