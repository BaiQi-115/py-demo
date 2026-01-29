#!/usr/bin/env python3
"""
Tornado Web Server 示例
"""

import tornado.ioloop
import tornado.web
import tornado.escape
import os
import json
from datetime import datetime
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MainHandler(tornado.web.RequestHandler):
    """主页面处理器"""

    def get(self):
        """处理 GET 请求"""
        response = {
            "message": "欢迎使用 Tornado Web 服务器!",
            "timestamp": datetime.now().isoformat(),
            "status": "success",
            "endpoints": {
                "/": "首页",
                "/health": "健康检查",
                "/info": "服务器信息",
                "/echo": "回显消息 (POST)"
            }
        }
        self.write(response)

class HealthHandler(tornado.web.RequestHandler):
    """健康检查处理器"""

    def get(self):
        health_status = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "service": "tornado-web-server",
            "version": "1.0.0"
        }
        self.write(health_status)

class InfoHandler(tornado.web.RequestHandler):
    """服务器信息处理器"""

    def get(self):
        info = {
            "server": "Tornado Web Server",
            "version": "6.3.3",
            "python_version": os.environ.get('PYTHON_VERSION', 'Unknown'),
            "hostname": os.environ.get('HOSTNAME', 'localhost'),
            "environment": os.environ.get('ENVIRONMENT', 'development'),
            "timestamp": datetime.now().isoformat()
        }
        self.write(info)

class EchoHandler(tornado.web.RequestHandler):
    """回显处理器 - 测试 POST 请求"""

    def post(self):
        try:
            data = tornado.escape.json_decode(self.request.body)
            echo_response = {
                "echo": data,
                "received_at": datetime.now().isoformat(),
                "method": self.request.method,
                "headers": dict(self.request.headers)
            }
            self.write(echo_response)
        except json.JSONDecodeError:
            self.set_status(400)
            self.write({"error": "无效的 JSON 数据"})

    def get(self):
        self.write({"message": "请使用 POST 方法发送 JSON 数据到此端点"})

def make_app():
    """创建 Tornado 应用"""
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/health", HealthHandler),
        (r"/info", InfoHandler),
        (r"/echo", EchoHandler),
    ])

if __name__ == "__main__":
    # 获取端口，默认为 8888
    port = int(os.environ.get("PORT", 8888))
    host = os.environ.get("HOST", "0.0.0.0")

    # 创建应用
    app = make_app()

    # 启动服务器
    app.listen(port, address=host)

    logger.info(f"🚀 Tornado 服务器启动在 {host}:{port}")
    logger.info("📝 可用端点:")
    logger.info("   GET  /        - 首页")
    logger.info("   GET  /health  - 健康检查")
    logger.info("   GET  /info    - 服务器信息")
    logger.info("   POST /echo    - 回显消息")
    logger.info("⏹️  按 Ctrl+C 停止服务器")

    try:
        tornado.ioloop.IOLoop.current().start()
    except KeyboardInterrupt:
        logger.info("👋 服务器正在关闭...")