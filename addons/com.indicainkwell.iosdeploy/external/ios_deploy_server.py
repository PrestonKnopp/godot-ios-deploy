"""
A server may be helpful as OS.execute does not allow non blocking output.
"""
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from time import sleep


class Handler(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        self._set_headers()
        for i in range(0, 5):
            self.wfile.write("<html><body><h1>hi!</h1></body></html>")
            sleep(1)

    def do_POST(self):
        # Doesn't do anything with posted data
        content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
        post_data = self.rfile.read(content_length) # <--- Gets the data itself
        self._set_headers()
        self.wfile.write("<html><body><h1>POST!</h1></body></html>")

    def do_HEAD(self):
        self._set_headers()


def run(server_class=HTTPServer, handler_class=Handler, port=8124):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print 'Starting httpd...'
    httpd.serve_forever()


if __name__ == "__main__":
    from sys import argv

    if len(argv) == 2:
        run(port=int(argv[1]))
    else:
        run()
