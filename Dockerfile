FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

# Copy proto file, server, and client scripts
COPY helloworld.proto .
COPY grpc_server.py .
COPY grpc_client.py .

# Compile the proto file
RUN python -m grpc_tools.protoc -I. --python_out=. --grpc_python_out=. helloworld.proto

# Default to running the server
CMD ["python", "grpc_server.py"]
