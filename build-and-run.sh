#!/bin/bash

# Tornado Docker 自动构建和运行脚本
set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 变量配置
IMAGE_NAME="tornado-app"
CONTAINER_NAME="tornado-container"
TAG="latest"
PORT="8888"

# 打印带颜色的信息
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

# 显示帮助信息
show_help() {
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  build     构建 Docker 镜像"
    echo "  run       运行 Docker 容器"
    echo "  stop      停止 Docker 容器"
    echo "  clean     清理 Docker 镜像和容器"
    echo "  status    检查容器状态"
    echo "  test      测试应用是否正常运行"
    echo "  all       构建并运行（默认）"
    echo ""
    echo "示例:"
    echo "  $0 build      # 只构建镜像"
    echo "  $0 run        # 只运行容器"
    echo "  $0 all        # 构建并运行"
    echo "  $0 test       # 测试应用"
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装 Docker"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker 守护进程未运行，请启动 Docker"
        exit 1
    fi

    log_success "Docker 检查通过"
}

# 构建 Docker 镜像
build_image_by_pybin() {
    log_info "基于python项目，开始打包二进制文件"
    cd /app
    pyinstaller --onefile --hidden-import tornado,tornado.ioloop,tornado.web,tornado.escape --name app app.py
    if [[ ! -f "dist/app" ]];then
        log_error "打包二进制文件失败"
    fi
    log_info "开始构建 Docker 镜像: ${IMAGE_NAME}:${TAG}"
    # 检查必要文件是否存在
    if [[ ! -f "Dockerfile_pybin" ]]; then
        log_error "Dockerfile_pybin 不存在"
        exit 1
    fi
    # 构建镜像
    docker build -t ${IMAGE_NAME}:${TAG} -f Dockerfile_pybin .
    
    # 检查构建是否成功
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_success "Docker 镜像构建成功: ${IMAGE_NAME}:${TAG}"

        # 定义保存文件名
        local SAVE_FILE="${IMAGE_NAME}-${TAG}.tar"
        log_info "开始打包 Docker 镜像到文件: ${SAVE_FILE}"
        docker save -o "${SAVE_FILE}" "${IMAGE_NAME}:${TAG}"

        if [[ -f "${SAVE_FILE}" ]]; then
            log_success "Docker 镜像已成功打包到 ${SAVE_FILE}"
        else
            log_error "Docker 镜像打包失败"
            exit 1
        fi
    else
        log_error "Docker 镜像构建失败"
        exit 1
    fi
}    

# 构建 Docker 镜像
build_image() {
    log_info "开始构建 Docker 镜像: ${IMAGE_NAME}:${TAG}"

    # 检查必要文件是否存在
    if [[ ! -f "Dockerfile" ]]; then
        log_error "Dockerfile 不存在"
        exit 1
    fi

    if [[ ! -f "requirements.txt" ]]; then
        log_error "requirements.txt 不存在"
        exit 1
    fi

    if [[ ! -f "app.py" ]]; then
        log_error "app.py 不存在"
        exit 1
    fi

    # 构建镜像
    docker build -t ${IMAGE_NAME}:${TAG} .

    # 检查构建是否成功
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_success "Docker 镜像构建成功: ${IMAGE_NAME}:${TAG}"

        # 定义保存文件名
        local SAVE_FILE="${IMAGE_NAME}-${TAG}.tar"
        log_info "开始打包 Docker 镜像到文件: ${SAVE_FILE}"
        docker save -o "${SAVE_FILE}" "${IMAGE_NAME}:${TAG}"

        if [[ -f "${SAVE_FILE}" ]]; then
            log_success "Docker 镜像已成功打包到 ${SAVE_FILE}"
        else
            log_error "Docker 镜像打包失败"
            exit 1
        fi
    else
        log_error "Docker 镜像构建失败"
        exit 1
    fi
}

# 运行 Docker 容器
run_container() {
    log_info "检查镜像是否存在..."
    if ! docker images | grep -q "${IMAGE_NAME}"; then
        log_warning "镜像不存在，开始构建..."
        build_image_by_pybin
    fi

    # 检查容器是否已经在运行
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_warning "容器 ${CONTAINER_NAME} 已经在运行，先停止它"
        stop_container
    fi

    # 检查容器是否存在但已停止
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        log_info "删除已停止的容器 ${CONTAINER_NAME}"
        docker rm ${CONTAINER_NAME}
    fi

    log_info "启动 Docker 容器: ${CONTAINER_NAME}"
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:8888 \
        -e ENVIRONMENT=production \
        -e HOSTNAME=$(hostname) \
        ${IMAGE_NAME}:${TAG}

    # 等待容器启动
    log_info "等待容器启动..."
    sleep 5

    # 检查容器状态
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_success "容器启动成功"
        log_info "应用运行在: http://localhost:${PORT}"
        log_info "健康检查: http://localhost:${PORT}/health"
    else
        log_error "容器启动失败"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
}

# 停止容器
stop_container() {
    log_info "停止容器: ${CONTAINER_NAME}"
    if docker ps | grep -q "${CONTAINER_NAME}"; then
        docker stop ${CONTAINER_NAME}
        log_success "容器已停止"
    else
        log_warning "容器未在运行"
    fi
}

# 清理资源
clean_resources() {
    log_info "开始清理资源..."

    # 停止并删除容器
    if docker ps -a | grep -q "${CONTAINER_NAME}"; then
        log_info "删除容器: ${CONTAINER_NAME}"
        docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    fi

    # 删除镜像
    if docker images | grep -q "${IMAGE_NAME}"; then
        log_info "删除镜像: ${IMAGE_NAME}:${TAG}"
        docker rmi ${IMAGE_NAME}:${TAG} 2>/dev/null || true
    fi

    log_success "资源清理完成"
}

# 检查容器状态
check_status() {
    log_info "检查容器状态..."

    if docker ps | grep -q "${CONTAINER_NAME}"; then
        log_success "容器正在运行"
        echo "容器信息:"
        docker ps | grep "${CONTAINER_NAME}"
        echo ""
        echo "最近日志:"
        docker logs --tail 10 ${CONTAINER_NAME}
    else
        if docker ps -a | grep -q "${CONTAINER_NAME}"; then
            log_warning "容器已停止"
            docker ps -a | grep "${CONTAINER_NAME}"
        else
            log_warning "容器不存在"
        fi
    fi
}

# 测试应用
test_app() {
    log_info "测试应用..."

    if ! docker ps | grep -q "${CONTAINER_NAME}"; then
        log_error "容器未运行，请先启动容器"
        exit 1
    fi

    local base_url="http://localhost:${PORT}"

    log_info "测试健康检查端点..."
    if curl -s -f "${base_url}/health" > /dev/null; then
        log_success "健康检查通过"
    else
        log_error "健康检查失败"
        exit 1
    fi

    log_info "测试首页端点..."
    if curl -s -f "${base_url}/" > /dev/null; then
        log_success "首页访问正常"
    else
        log_error "首页访问失败"
        exit 1
    fi

    log_info "测试信息端点..."
    if curl -s -f "${base_url}/info" > /dev/null; then
        log_success "信息端点正常"
    else
        log_error "信息端点访问失败"
        exit 1
    fi

    log_success "所有测试通过！应用运行正常"
}

# 主函数
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
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
