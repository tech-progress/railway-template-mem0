#!/usr/bin/env python3
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length) or b"{}")

        if self.path == "/v1/embeddings":
            inputs = payload.get("input", [])
            if isinstance(inputs, str):
                inputs = [inputs]
            embedding = [1.0] + [0.0] * 1535
            response = {
                "object": "list",
                "data": [
                    {"object": "embedding", "index": index, "embedding": embedding}
                    for index, _ in enumerate(inputs)
                ],
                "model": payload.get("model", "text-embedding-3-small"),
                "usage": {"prompt_tokens": 1, "total_tokens": 1},
            }
            self._json(200, response)
            return

        self._json(404, {"error": {"message": "Unsupported smoke-test endpoint"}})

    def log_message(self, format, *args):
        return

    def _json(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
