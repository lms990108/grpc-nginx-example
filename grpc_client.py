import grpc
import helloworld_pb2
import helloworld_pb2_grpc

def run():
    with grpc.insecure_channel('nginx:8080') as channel:  # Nginx 경유
        stub = helloworld_pb2_grpc.GreeterStub(channel)
        response = stub.SayHello(helloworld_pb2.HelloRequest(name='Docker Compose'))
        print(f"gRPC Response: {response.message}")

if __name__ == "__main__":
    run()
