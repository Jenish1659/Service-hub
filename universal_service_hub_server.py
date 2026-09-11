import http.server
import socketserver
import threading
import json
import os
import sys
import time
import tempfile
import urllib.parse

PUBLIC_DIR = r"C:\Users\Public\ServiceHub"
TEMP_DIR = tempfile.gettempdir()
os.makedirs(PUBLIC_DIR, exist_ok=True)

LOG_FILE = os.path.join(PUBLIC_DIR, "server.log")
VERIF_FILE_PUBLIC = os.path.join(PUBLIC_DIR, "service_hub_partner_verifications.json")
VERIF_FILE_TEMP = os.path.join(TEMP_DIR, "service_hub_partner_verifications.json")
BOOKING_FILE_PUBLIC = os.path.join(PUBLIC_DIR, "service_hub_live_bookings.json")
BOOKING_FILE_TEMP = os.path.join(TEMP_DIR, "service_hub_live_bookings.json")

lock = threading.Lock()

def log(msg):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{ts}] {msg}"
    print(formatted)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except:
        pass

def load_json(p):
    if os.path.exists(p):
        try:
            with open(p, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_json(data, p1, p2):
    for p in [p1, p2]:
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            log(f"Error saving {p}: {e}")

# In-memory stores
verifications = load_json(VERIF_FILE_PUBLIC) or load_json(VERIF_FILE_TEMP) or {}
bookings = load_json(BOOKING_FILE_PUBLIC) or load_json(BOOKING_FILE_TEMP) or {}

class ServiceHubHandler(http.server.SimpleHTTPRequestHandler):
    web_dir = None

    def __init__(self, *args, directory=None, **kwargs):
        self.web_dir = directory
        super().__init__(*args, directory=directory, **kwargs)

    def _set_cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Cross-Origin-Opener-Policy", "same-origin-allow-popups")
        self.send_header("Cross-Origin-Embedder-Policy", "credentialless")

    def do_OPTIONS(self):
        self.send_response(200)
        self._set_cors()
        self.end_headers()

    def do_GET(self):
        global verifications, bookings
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/api/verifications":
            with lock:
                file_data = load_json(VERIF_FILE_PUBLIC)
                if file_data:
                    verifications.update(file_data)
                out = list(verifications.values())
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/api/bookings":
            with lock:
                file_data = load_json(BOOKING_FILE_PUBLIC)
                if file_data:
                    bookings.update(file_data)
                out = list(bookings.values())
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/health":
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "OK",
                "verifications_count": len(verifications),
                "bookings_count": len(bookings)
            }).encode("utf-8"))
            return

        # Serve static web directory if provided
        if self.web_dir:
            file_path = os.path.join(self.web_dir, path.lstrip("/"))
            if not os.path.exists(file_path) and not path.startswith("/assets") and not path.endswith((".js", ".wasm", ".json", ".png", ".jpg", ".ttf", ".css", ".html")):
                # SPA Fallback to index.html
                self.path = "/index.html"
            return super().do_GET()

        self.send_response(404)
        self._set_cors()
        self.end_headers()

    def do_POST(self):
        global verifications, bookings
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        try:
            payload = json.loads(body) if body else {}
        except Exception as e:
            payload = {}

        if path == "/api/verifications":
            with lock:
                payload.pop("password", None)
                ver_id = str(payload.get("verification_id") or payload.get("id") or f"SHB-{int(time.time()*1000)}")
                payload["verification_id"] = ver_id
                payload["id"] = payload.get("id") or ver_id
                payload["status"] = payload.get("status") or "PENDING"
                payload["verification_status"] = payload.get("verification_status") or "PENDING"
                payload["received_at"] = time.strftime("%Y-%m-%d %H:%M:%S")

                name = payload.get("name") or payload.get("full_name") or "Unknown"
                phone = payload.get("phone") or ""

                verifications[ver_id] = payload
                save_json(verifications, VERIF_FILE_PUBLIC, VERIF_FILE_TEMP)
                log(f"[SYNC_SERVER] Registered partner received: {name} (Phone: {phone}, App ID: {ver_id})")

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "data": payload}).encode("utf-8"))
            return

        if (path.startswith("/api/verifications/") and path.endswith("/approve")) or path == "/api/verifications/approve":
            with lock:
                target_id = payload.get("id") or payload.get("verification_id") or path.split("/")[-2]
                for k, v in verifications.items():
                    if k == target_id or v.get("id") == target_id or v.get("verification_id") == target_id or str(target_id).lower() in str(k).lower():
                        v["status"] = "APPROVED"
                        v["verification_status"] = "VERIFIED"
                        v["approved_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                        verifications[k] = v
                        log(f"[SYNC_SERVER] Partner APPROVED: {target_id} ({v.get('name')})")
                save_json(verifications, VERIF_FILE_PUBLIC, VERIF_FILE_TEMP)

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "message": f"Approved {target_id}"}).encode("utf-8"))
            return

        if (path.startswith("/api/verifications/") and path.endswith("/reject")) or path == "/api/verifications/reject":
            with lock:
                target_id = payload.get("id") or payload.get("verification_id") or path.split("/")[-2]
                for k, v in verifications.items():
                    if k == target_id or v.get("id") == target_id or v.get("verification_id") == target_id or str(target_id).lower() in str(k).lower():
                        v["status"] = "REJECTED"
                        v["verification_status"] = "REJECTED"
                        verifications[k] = v
                        log(f"[SYNC_SERVER] Partner REJECTED: {target_id}")
                save_json(verifications, VERIF_FILE_PUBLIC, VERIF_FILE_TEMP)

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "message": f"Rejected {target_id}"}).encode("utf-8"))
            return

        if path == "/api/bookings":
            with lock:
                b_id = str(payload.get("id") or payload.get("booking_id") or f"AC_{int(time.time()*1000)}")
                payload["id"] = b_id
                payload["booking_id"] = b_id
                bookings[b_id] = payload
                save_json(bookings, BOOKING_FILE_PUBLIC, BOOKING_FILE_TEMP)

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "data": payload}).encode("utf-8"))
            return

        self.send_response(404)
        self._set_cors()
        self.end_headers()

    def end_headers(self):
        self._set_cors()
        super().end_headers()

    def log_message(self, format, *args):
        pass

def run_server(port, web_dir=None, name="Server"):
    def handler_factory(*args, **kwargs):
        return ServiceHubHandler(*args, directory=web_dir, **kwargs)

    ServiceHubHandler.extensions_map.update({
        ".wasm": "application/wasm",
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".json": "application/json",
    })

    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("0.0.0.0", port), handler_factory) as httpd:
            log(f"[+] {name} successfully running on http://0.0.0.0:{port} (dir: {web_dir})")
            httpd.serve_forever()
    except Exception as e:
        log(f"[-] Failed to bind port {port} for {name}: {e}")

if __name__ == "__main__":
    admin_web = r"d:\Service hub\admin_app\build\web"
    partner_web = r"d:\Service hub\partner_app\build\web"

    t_api = threading.Thread(target=run_server, args=(8088, None, "Sync Bridge API"), daemon=True)
    t_admin = threading.Thread(target=run_server, args=(8083, admin_web, "Admin Web App"), daemon=True)
    t_partner = threading.Thread(target=run_server, args=(8084, partner_web, "Partner Web App"), daemon=True)

    t_api.start()
    t_admin.start()
    t_partner.start()

    log("[*] ServiceHub Triple-Port Engine Active (8088, 8083, 8084)")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log("[*] Shutting down servers...")
