import socket

# Define the target IP and port
target_ip = '3.85.151.24'  # Change this to the target IP address
target_port = 80  # Change this to the target port

# Define the HTTP request data
http_request = """POST /path/to/resource HTTP/1.1
Host: {0}:{1}
Content-Type: application/x-www-form-urlencoded
Content-Length: 15

Content:"DROP DATABASE"
""".format(target_ip, target_port)

try:
    # Create a socket object
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Connect to the target IP and port
    s.connect((target_ip, target_port))

    # Send the HTTP POST request
    s.send(http_request.encode())

    # Receive and print the server's response
    response = s.recv(4096)
    print(response.decode())

    # Close the socket
    s.close()

except Exception as e:
    print("Error:", e)
