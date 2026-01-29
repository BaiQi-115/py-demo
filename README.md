[TOC]

# 项目结构
```
tornado-app/
├── app.py
├── requirements.txt
├── Dockerfile
├── build-and-run.sh
└── README.md
```

## 1. Python Tornado 测试代码 (app.py) 
```
......省略
```

## 2. 依赖文件 (requirements.txt)
```
tornado==6.5.1
```

## 3. Dockerfile
```
......省略
```

## 4. 自动构建和运行脚本 (build-and-run.sh)
```
......省略
```

## 5. 使用说明

### 快速开始
1. 给脚本执行权限：
```
chmod +x build-and-run.sh
```

2. 一键构建和运行：
```
./build-and-run.sh all
```

3. 测试应用：
```
./build-and-run.sh test
```

### 单独命令
```
# 只构建镜像
./build-and-run.sh build

# 只运行容器
./build-and-run.sh run

# 停止容器
./build-and-run.sh stop

# 检查状态
./build-and-run.sh status

# 清理资源
./build-and-run.sh clean
```

### 手动测试 API
```
# 健康检查
curl http://localhost:8888/health

# 首页
curl http://localhost:8888/

# 服务器信息
curl http://localhost:8888/info

# 测试 POST 请求
curl -X POST -H "Content-Type: application/json" -d '{"message": "Hello Tornado"}' http://localhost:8888/echo
```

## 6. 验证运行
运行成功后，您应该看到类似以下的输出：
```
🚀 Tornado 服务器启动在 0.0.0.0:8888
📝 可用端点:
   GET  /        - 首页
   GET  /health  - 健康检查
   GET  /info    - 服务器信息
   POST /echo    - 回显消息
```

## 总结
这个完整的解决方案提供了：
✅ 功能完整的 Tornado Web 服务器
✅ 优化的 Dockerfile
✅ 智能的自动化构建脚本
✅ 健康检查和监控
✅ 错误处理和日志
✅ 易于使用的命令行界面
