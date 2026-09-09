#!/usr/bin/env python3
"""
Tornado Web Server Example
"""

import tornado.ioloop
import tornado.web
import tornado.escape
import os
import json
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MainHandler(tornado.web.RequestHandler):
    """Main page handler"""

    def get(self):
        """Handle GET requests"""
        response = {
            "message": "Welcome to the Tornado Web Server!",
            "timestamp": datetime.now().isoformat(),
            "status": "success",
            "endpoints": {
                "/": "Home page",
                "/health": "Health check",
                "/info": "Server information",
                "/echo": "Echo message (POST)"
            }
        }
        self.write(response)

class HealthHandler(tornado.web.RequestHandler):
    """Health check handler"""

    def get(self):
        health_status = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "service": "tornado-web-server",
            "version": "1.0.0"
        }
        self.write(health_status)

class InfoHandler(tornado.web.RequestHandler):
    """Server information handler"""

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
    """Echo handler - for testing POST requests"""

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
            self.write({"error": "Invalid JSON data"})

    def get(self):
        self.write({"message": "Please send JSON data to this endpoint using the POST method"})

def make_app():
    """Create the Tornado application"""
    return tornado.web.Application([
        (r"/", MainHandler),
        (r"/health", HealthHandler),
        (r"/info", InfoHandler),
        (r"/echo", EchoHandler),
    ])

if __name__ == "__main__":
    # Get the port, default is 8888
    port = int(os.environ.get("PORT", 8888))
    host = os.environ.get("HOST", "0.0.0.0")

    # Create the application
    app = make_app()

    # Start the server
    app.listen(port, address=host)

    logger.info(f"🚀 Tornado server started on {host}:{port}")
    logger.info("📝 Available endpoints:")
    logger.info("   GET  /        - Home page")
    logger.info("   GET  /health  - Health check")
    logger.info("   GET  /info    - Server information")
    logger.info("   POST /echo    - Echo message")
    logger.info("⏹️  Press Ctrl+C to stop the server")

    try:
        tornado.ioloop.IOLoop.current().start()
    except KeyboardInterrupt:
        logger.info("👋 Server is shutting down...")
