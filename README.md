# GRPC-NGINX-EXAMPLE

이 프로젝트는 Docker Compose를 사용하여 Nginx 리버스 프록시를 통한 gRPC 통신을 설정하는 기본 예제를 보여줍니다. 이 프로젝트에는 gRPC 서버, gRPC 클라이언트, 그리고 gRPC 요청을 라우팅하도록 구성된 Nginx 리버스 프록시가 포함되어 있습니다.

## 프로젝트 구조

```
GRPC-NGINX-EXAMPLE/
├── nginx/
│   └── nginx.conf              # Nginx 설정 파일
├── docker-compose.yml          # Docker Compose 구성 파일
├── Dockerfile                  # gRPC 서버를 빌드하기 위한 Dockerfile
├── grpc_client.py              # gRPC 클라이언트 Python 스크립트
├── grpc_server.py              # gRPC 서버 Python 스크립트
├── helloworld.proto            # Protocol Buffers 정의 파일
└── requirements.txt            # Python 의존성
```

## 작동 방식

1. `grpc_server.py`는 간단한 gRPC 서비스를 구현하며 인사 메시지로 응답합니다.
2. `grpc_client.py`는 Nginx 리버스 프록시를 통해 서비스에 연결하고 요청을 전달합니다.
3. Nginx는 HTTP/2를 처리하며 gRPC 백엔드로 요청을 전달하는 리버스 프록시로 동작합니다.
4. Docker Compose는 gRPC 서버, 클라이언트, Nginx 프록시의 배포를 조정합니다.

## 설정 및 사용법

### 사전 준비

- Docker 및 Docker Compose가 시스템에 설치되어 있어야 합니다.

### 실행 단계

1. 이 저장소를 클론합니다:

   ```bash
   git clone https://github.com/lms990108/grpc-nginx-example
   cd GRPC-NGINX-EXAMPLE
   ```

2. Docker 컨테이너를 빌드하고 실행합니다:

   ```bash
   docker-compose up --build
   ```

3. gRPC 클라이언트는 Nginx를 통해 서버에 연결하며, 로그에서 다음과 같은 응답을 확인할 수 있습니다:
   ```
   gRPC Response: Hello, Docker Compose!
   ```

### 정리

컨테이너를 중지하고 제거하려면 다음을 실행하세요:

```bash
docker-compose down
```

## 주요 구성 요소

### gRPC 서버 (`grpc_server.py`)

간단한 Python으로 구현된 gRPC 서버:

```python
import grpc
from concurrent import futures
import time
import helloworld_pb2
import helloworld_pb2_grpc

class Greeter(helloworld_pb2_grpc.GreeterServicer):
    def SayHello(self, request, context):
        return helloworld_pb2.HelloReply(message=f"Hello, {request.name}!")

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    helloworld_pb2_grpc.add_GreeterServicer_to_server(Greeter(), server)
    server.add_insecure_port('[::]:50051')
    print("gRPC server is running on port 50051")
    server.start()
    try:
        while True:
            time.sleep(86400)
    except KeyboardInterrupt:
        server.stop(0)

if __name__ == "__main__":
    serve()
```

### gRPC 클라이언트 (`grpc_client.py`)

Nginx를 통해 서버에 연결하는 Python 클라이언트:

```python
import grpc
import helloworld_pb2
import helloworld_pb2_grpc

def run():
    with grpc.insecure_channel('nginx:8080') as channel:  # Nginx를 경유
        stub = helloworld_pb2_grpc.GreeterStub(channel)
        response = stub.SayHello(helloworld_pb2.HelloRequest(name='Docker Compose'))
        print(f"gRPC Response: {response.message}")

if __name__ == "__main__":
    run()
```

### Nginx 설정 (`nginx.conf`)

gRPC 트래픽을 서버로 전달하도록 구성됨:

```nginx
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    upstream grpc_backend {
        server grpc_server:50051; # gRPC 서버 컨테이너와 포트
    }

    server {
        listen 8080 http2; # HTTP/2를 명시적으로 활성화

        location / {
            grpc_pass grpc://grpc_backend;
            error_page 502 = /error502grpc;
        }

        location = /error502grpc {
            internal;
            default_type application/grpc;
            add_header grpc-status 14;
            add_header content-length 0;
            return 204;
        }
    }
}
```

### Docker Compose 설정 (`docker-compose.yml`)

Docker Compose로 모든 서비스를 실행하는 설정:

```yaml
version: "3.8"

services:
  grpc_server:
    build:
      context: .
      dockerfile: Dockerfile
    command: ["python", "grpc_server.py"]
    ports:
      - "50051:50051"

  grpc_client:
    build:
      context: .
      dockerfile: Dockerfile
    command: ["python", "grpc_client.py"]
    depends_on:
      - grpc_server
      - nginx

  nginx:
    image: nginx:latest
    ports:
      - "8080:8080"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - grpc_server
```

## 의존성

- **gRPC for Python**
- **Nginx** (HTTP/2 지원)
- **Docker Compose**

Python 의존성은 `requirements.txt`에 나열되어 있습니다:

```
grpcio==1.68.1
grpcio-tools==1.68.1
```

다음 명령어로 설치할 수 있습니다:

```bash
pip install -r requirements.txt
```
