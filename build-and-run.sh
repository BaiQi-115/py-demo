#!/bin/bash

# Tornado Docker automated build and run script
set -e  # Exit immediately on error

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variable configuration
IMAGE_NAME="tornado-app"
CONTAINER_NAME="tornado-container"
TAG="latest"
PORT="8888"

# Print colored messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show help information
show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build     Build the Docker image"
    echo "  run       Run the Docker container"
    echo "  stop      Stop the Docker container"
    echo "  clean     Clean up the Docker image and container"
    echo "  status    Check the container status"
    echo "  test      Test whether the application is running properly"
    echo "  all       Build and run (default)"
    echo ""
    echo "Examples:"
    echo "  $0 build      # Build the image only"
    echo "  $0 run        # Run the container only"
    echo "  $0 all        # Build and run"
    echo "  $0 test       # Test the application"
}

# Check whether Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "The Docker daemon is not running. Please start Docker"
        exit 1
    fi

    log_success "Docker check passed"
}

# Build the Docker image
build_image_by_pybin() {
    log_info "Based on the Python project, starting to package the binary file"
    cd /app
    pyinstaller --onefile --hidden-import tornado,tornado.ioloop,tornado.web,tornado.escape --name app app.py
    if [[ ! -f "dist/app" ]];then
        log_error "Failed to package the binary file"
    fi
    log_info "Starting to build the Docker image: ${IMAGE_NAME}:${TAG}"
    # Check whether the required files exist
    if [[ ! -f "Dockerfile_pybin" ]]; then
        log_error "Dockerfile_pybin does not exist"
        exit 1
    fi
    # Build the image
    docker build -t ${IMAGE_NAME}:${TAG} -f Dockerfile_pybin .
    
    # Check whether the build succeeded
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_success "Docker image built successfully: ${IMAGE_NAME}:${TAG}"

        # Define the save file name
        local SAVE_FILE="${IMAGE_NAME}-${TAG}.tar"
        log_info "Starting to save the Docker image to a file: ${SAVE_FILE}"
        docker save -o "${SAVE_FILE}" "${IMAGE_NAME}:${TAG}"

        if [[ -f "${SAVE_FILE}" ]]; then
            log_success "Docker image has been saved to ${SAVE_FILE}"
        else
            log_error "Failed to save the Docker image"
            exit 1
        fi
    else
        log_error "Failed to build the Docker image"
        exit 1
    fi
}    

# Build the Docker image
build_image() {
    log_info "Starting to build the Docker image: ${IMAGE_NAME}:${TAG}"

    # Check whether the required files exist
    if [[ ! -f "Dockerfile" ]]; then
        log_error "Dockerfile does not exist"
        exit 1
    fi

    if [[ ! -f "requirements.txt" ]]; then
        log_error "requirements.txt does not exist"
        exit 1
    fi

    if [[ ! -f "app.py" ]]; then
        log_error "app.py does not exist"
        exit 1
    fi

    # Build the image
    docker build -t ${IMAGE_NAME}:${TAG} .

    # Check whether the build succeeded
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_success "Docker image built successfully: ${IMAGE_NAME}:${TAG}"

        # Define the save file name
        local SAVE_FILE="${IMAGE_NAME}-${TAG}.tar"
        log_info "Starting to save the Docker image to a file: ${SAVE_FILE}"
        docker save -o "${SAVE_FILE}" "${IMAGE_NAME}:${TAG}"

        if [[ -f "${SAVE_FILE}" ]]; then
            log_success "Docker image has been saved to ${SAVE_FILE}"
        else
            log_error "Failed to save the Docker image"
            exit 1
        fi
    else
        log_error "Failed to build the Docker image"
        exit 1
    fi
}

# Run the Docker container
run_container() {
    log_info "Checking whether the image exists..."
    if ! docker images | grep -q "${IMAGE_NAME}"; then
        log_warning "The image does not exist. Starting to build..."
        build_image_by_pybin
    fi

    # Check whether the container is already running
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_warning "Container ${CONTAINER_NAME} is already running. Stopping it first"
        stop_container
    fi

    # Check whether the container exists but is stopped
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        log_info "Removing the stopped container ${CONTAINER_NAME}"
        docker rm ${CONTAINER_NAME}
    fi

    log_info "Starting the Docker container: ${CONTAINER_NAME}"
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:8888 \
        -e ENVIRONMENT=production \
        -e HOSTNAME=$(hostname) \
        ${IMAGE_NAME}:${TAG}

    # Wait for the container to start
    log_info "Waiting for the container to start..."
    sleep 5

    # Check the container status
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_success "Container started successfully"
        log_info "The application is running at: http://localhost:${PORT}"
        log_info "Health check: http://localhost:${PORT}/health"
    else
        log_error "Failed to start the container"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# Stop the container
stop_container() {
    log_info "Stopping the container: ${CONTAINER_NAME}"
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        docker stop ${CONTAINER_NAME}
        log_success "Container stopped"
    else
        log_warning "The container is not running"
    fi
}

# Clean up resources
clean_resources() {
    log_info "Starting to clean up resources..."

    # Stop and remove the container
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        log_info "Removing the container: ${CONTAINER_NAME}"
        docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    fi

    # Remove the image
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_info "Removing the image: ${IMAGE_NAME}:${TAG}"
        docker rmi ${IMAGE_NAME}:${TAG} 2>/dev/null || true
    fi

    log_success "Resource cleanup completed"
}

# Check the container status
check_status() {
    log_info "Checking the container status..."

    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_success "The container is running"
        echo "Container information:"
        docker ps | grep "${CONTAINER_NAME}"
        echo ""
        echo "Recent logs:"
        docker logs --tail 10 ${CONTAINER_NAME}
    else
        if docker ps -a | grep -q "${CONTAINER_NAME}"; then
            log_warning "The container is stopped"
            docker ps -a | grep "${CONTAINER_NAME}"
        else
            log_warning "The container does not exist"
        fi
    fi
}

# Test the application
test_app() {
    log_info "Testing the application..."

    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        log_error "The container is not running. Please start the container first"
        exit 1
    fi

    local base_url="http://localhost:${PORT}"

    log_info "Testing the health check endpoint..."
    if curl -s -f "${base_url}/health" > /dev/null; then
        log_success "Health check passed"
    else
        log_error "Health check failed"
        exit 1
    fi

    log_info "Testing the home page endpoint..."
    if curl -s -f "${base_url}/" > /dev/null; then
        log_success "Home page is accessible"
    else
        log_error "Failed to access the home page"
        exit 1
    fi

    log_info "Testing the info endpoint..."
    if curl -s -f "${base_url}/info" > /dev/null; then
        log_success "The info endpoint is working"
    else
        log_error "Failed to access the info endpoint"
        exit 1
    fi

    log_success "All tests passed! The application is running properly"
}

# Main function
main() {
    local command=${1:-"all"}

    case $command in
        "build")
            check_docker
            build_image_by_pybin
            ;;
        "run")
            check_docker
            run_container
            ;;
        "stop")
            check_docker
            stop_container
            ;;
        "clean")
            check_docker
            clean_resources
            ;;
        "status")
            check_docker
            check_status
            ;;
        "test")
            check_docker
            test_app
            ;;
        "all"|"")
            check_docker
            build_image_by_pybin
            run_container
            sleep 3
            test_app
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute the main function
main "$@"
