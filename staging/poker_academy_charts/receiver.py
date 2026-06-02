import http.server, socketserver, json, os, re

PORT = 8799
BASE = os.path.dirname(os.path.abspath(__file__))
FILES = os.path.join(BASE, "files")
os.makedirs(FILES, exist_ok=True)

def safe(name):
    name = re.sub(r'[^A-Za-z0-9._-]+', '_', name or 'chart')
    return name[:180]

class H(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
    def do_OPTIONS(self):
        self.send_response(204); self._cors(); self.end_headers()
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(n)
        fn = safe(self.headers.get("X-Filename", "chart")) + ".json"
        with open(os.path.join(FILES, fn), "wb") as f:
            f.write(data)
        self.send_response(200); self._cors()
        self.send_header("Content-Type", "text/plain"); self.end_headers()
        self.wfile.write(("OK %s %d" % (fn, len(data))).encode())
    def log_message(self, *a): pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("127.0.0.1", PORT), H) as httpd:
    httpd.serve_forever()
