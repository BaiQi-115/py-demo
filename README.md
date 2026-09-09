[TOC]

# Project Structure
```
tornado-app/
├── app.py
├── requirements.txt
├── Dockerfile
├── build-and-run.sh
└── README.md
```

## 1. Python Tornado Test Code (app.py) 
```
......omitted
```

## 2. Dependencies File (requirements.txt)
```
tornado==6.5.1
```

## 3. Dockerfile
```
......omitted
```

## 4. Automated Build and Run Script (build-and-run.sh)
```
......omitted
```

## 5. Usage Instructions

### Quick Start
1. Grant execute permission to the script:
```
chmod +x build-and-run.sh
```

2. Build and run with one command:
```
./build-and-run.sh all
```

3. Test the application:
```
./build-and-run.sh test
```

### Individual Commands
```
# Build the image only
./build-and-run.sh build

# Run the container only
./build-and-run.sh run

# Stop the container
./build-and-run.sh stop

# Check status
./build-and-run.sh status

# Clean up resources
./build-and-run.sh clean
```

### Manually Test the API
```
# Health check
curl http://localhost:8888/health

# Home page
curl http://localhost:8888/

# Server information
curl http://localhost:8888/info

# Test a POST request
curl -X POST -H "Content-Type: application/json" -d '{"message": "Hello Tornado"}' http://localhost:8888/echo
```

## 6. Verify the Run
After a successful run, you should see output similar to the following:
```
🚀 Tornado server started on 0.0.0.0:8888
📝 Available endpoints:
   GET  /        - Home page
   GET  /health  - Health check
   GET  /info    - Server information
   POST /echo    - Echo message
```

## Summary
This complete solution provides:
✅ A fully functional Tornado Web server
✅ An optimized Dockerfile
✅ A smart automated build script
✅ Health checks and monitoring
✅ Error handling and logging
✅ An easy-to-use command-line interface
