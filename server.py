from http.server import HTTPServer, BaseHTTPRequestHandler

# Define a custom request handler that supports the POST method
class CustomRequestHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')

        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

        # You can process the POST data here and send a response
        response_data = "Received POST data: " + post_data
        self.wfile.write(response_data.encode('utf-8'))

# Define the server address and port
server_address = ('', 80)  # Empty string means listen on all available interfaces

# Create the HTTP server with the custom request handler
httpd = HTTPServer(server_address, CustomRequestHandler)

# Start the server
print("Server listening on port 80...")
httpd.serve_forever()