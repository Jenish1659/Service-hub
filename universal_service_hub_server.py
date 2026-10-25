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
CHAT_FILE_PUBLIC = os.path.join(PUBLIC_DIR, "service_hub_chat_messages.json")
CHAT_FILE_TEMP = os.path.join(TEMP_DIR, "service_hub_chat_messages.json")
PRODUCT_FILE_PUBLIC = os.path.join(PUBLIC_DIR, "service_hub_store_products.json")
PRODUCT_FILE_TEMP = os.path.join(TEMP_DIR, "service_hub_store_products.json")
CRED_FILE_PUBLIC = os.path.join(PUBLIC_DIR, "service_hub_credentials.json")
CRED_FILE_TEMP = os.path.join(TEMP_DIR, "service_hub_credentials.json")

_data_lock = threading.RLock()
_flush_event = threading.Event()
_dirty_flags = {
    'verifications': False,
    'bookings': False,
    'chats': False,
    'products': False,
    'credentials': False,
}

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

def _atomic_save_json(data, p1, p2):
    for p in [p1, p2]:
        try:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            tmp_p = f"{p}.tmp_{os.getpid()}_{threading.get_ident()}"
            with open(tmp_p, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
            if os.path.exists(tmp_p):
                os.replace(tmp_p, p)
        except Exception as e:
            log(f"Error saving {p}: {e}")

def _background_flush_loop():
    """Asynchronously flushes memory snapshots to disk without blocking request handlers."""
    while True:
        try:
            _flush_event.wait(timeout=0.25)
            _flush_event.clear()

            verif_copy = None
            book_copy = None
            prod_copy = None
            chat_copy = None
            cred_copy = None

            with _data_lock:
                if _dirty_flags['verifications']:
                    verif_copy = dict(verifications)
                    _dirty_flags['verifications'] = False
                if _dirty_flags['bookings']:
                    book_copy = dict(bookings)
                    _dirty_flags['bookings'] = False
                if _dirty_flags['products']:
                    prod_copy = dict(products)
                    _dirty_flags['products'] = False
                if _dirty_flags['chats']:
                    chat_copy = dict(chats)
                    _dirty_flags['chats'] = False
                if _dirty_flags['credentials']:
                    cred_copy = dict(credentials)
                    _dirty_flags['credentials'] = False

            if verif_copy is not None:
                _atomic_save_json(verif_copy, VERIF_FILE_PUBLIC, VERIF_FILE_TEMP)
            if book_copy is not None:
                _atomic_save_json(book_copy, BOOKING_FILE_PUBLIC, BOOKING_FILE_TEMP)
            if prod_copy is not None:
                _atomic_save_json(prod_copy, PRODUCT_FILE_PUBLIC, PRODUCT_FILE_TEMP)
            if chat_copy is not None:
                _atomic_save_json(chat_copy, CHAT_FILE_PUBLIC, CHAT_FILE_TEMP)
            if cred_copy is not None:
                _atomic_save_json(cred_copy, CRED_FILE_PUBLIC, CRED_FILE_TEMP)
        except Exception as e:
            log(f"Background flush worker error: {e}")
            time.sleep(0.5)

# In-memory stores & file caches
verifications = load_json(VERIF_FILE_PUBLIC) or load_json(VERIF_FILE_TEMP) or {}
bookings = load_json(BOOKING_FILE_PUBLIC) or load_json(BOOKING_FILE_TEMP) or {}
chats = load_json(CHAT_FILE_PUBLIC) or load_json(CHAT_FILE_TEMP) or {}
products = load_json(PRODUCT_FILE_PUBLIC) or load_json(PRODUCT_FILE_TEMP) or {}
credentials = load_json(CRED_FILE_PUBLIC) or load_json(CRED_FILE_TEMP) or {}
_last_verif_mtime = 0
_last_booking_mtime = 0
_last_chat_mtime = 0
_last_product_mtime = 0

def _background_file_sync_loop():
    """Periodically syncs external edits into memory without locking every GET request."""
    global _last_verif_mtime, _last_booking_mtime, _last_chat_mtime, _last_product_mtime
    while True:
        try:
            time.sleep(2.5)
            if os.path.exists(VERIF_FILE_PUBLIC):
                m = os.path.getmtime(VERIF_FILE_PUBLIC)
                if m > _last_verif_mtime:
                    d = load_json(VERIF_FILE_PUBLIC)
                    if d:
                        with _data_lock:
                            verifications.update(d)
                    _last_verif_mtime = m

            if os.path.exists(BOOKING_FILE_PUBLIC):
                m = os.path.getmtime(BOOKING_FILE_PUBLIC)
                if m > _last_booking_mtime:
                    d = load_json(BOOKING_FILE_PUBLIC)
                    if d:
                        with _data_lock:
                            bookings.update(d)
                    _last_booking_mtime = m

            p = PRODUCT_FILE_PUBLIC if os.path.exists(PRODUCT_FILE_PUBLIC) else (PRODUCT_FILE_TEMP if os.path.exists(PRODUCT_FILE_TEMP) else None)
            if p:
                m = os.path.getmtime(p)
                if m > _last_product_mtime:
                    d = load_json(p)
                    if d and isinstance(d, dict):
                        with _data_lock:
                            products.update(d)
                    _last_product_mtime = m

            c = CHAT_FILE_PUBLIC if os.path.exists(CHAT_FILE_PUBLIC) else (CHAT_FILE_TEMP if os.path.exists(CHAT_FILE_TEMP) else None)
            if c:
                m = os.path.getmtime(c)
                if m > _last_chat_mtime:
                    d = load_json(c)
                    if d and isinstance(d, dict):
                        with _data_lock:
                            chats.update(d)
                    _last_chat_mtime = m
        except Exception:
            pass

class ServiceHubHandler(http.server.SimpleHTTPRequestHandler):
    web_dir = None
    timeout = 15

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
        global verifications, bookings, chats, products
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/api/verifications":
            with _data_lock:
                out = list(verifications.values())
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/api/products" or path.startswith("/api/products"):
            with _data_lock:
                out = list(products.values())
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/api/bookings":
            with _data_lock:
                out = list(bookings.values())
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/api/chat" or path.startswith("/api/chat/"):
            q_params = urllib.parse.parse_qs(parsed.query)
            booking_id = q_params.get("booking_id", [None])[0]
            if not booking_id and len(path.split("/")) > 3:
                booking_id = path.split("/")[3]
            
            with _data_lock:
                if booking_id:
                    out = chats.get(str(booking_id), [])
                else:
                    out = chats
            
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return

        if path == "/api/auth/credentials":
            q_params = urllib.parse.parse_qs(parsed.query)
            ident = q_params.get("identifier", [None])[0]
            pwd = None
            if ident:
                clean_ident = ident.lower().strip().replace("@", "").replace("+", "").replace(" ", "")
                clean_digits = "".join(c for c in clean_ident if c.isdigit())
                last10 = clean_digits[-10:] if len(clean_digits) >= 10 else ""
                with _data_lock:
                    pwd = credentials.get(clean_ident) or credentials.get(clean_digits) or (credentials.get(last10) if last10 else None)
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "found": pwd is not None, "password": pwd}).encode("utf-8"))
            return

        if path == "/health":
            with _data_lock:
                v_len = len(verifications)
                b_len = len(bookings)
                p_len = len(products)
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "OK",
                "verifications_count": v_len,
                "bookings_count": b_len,
                "products_count": p_len
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
        global verifications, bookings, chats, products
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        try:
            payload = json.loads(body) if body else {}
        except Exception:
            payload = {}

        if path == "/api/auth/credentials":
            ident = payload.get("identifier") or payload.get("username") or payload.get("phone") or payload.get("email")
            pwd = payload.get("password")
            if ident and pwd:
                clean_ident = str(ident).lower().strip().replace("@", "").replace("+", "").replace(" ", "")
                clean_digits = "".join(c for c in clean_ident if c.isdigit())
                last10 = clean_digits[-10:] if len(clean_digits) >= 10 else ""
                with _data_lock:
                    credentials[clean_ident] = str(pwd)
                    if clean_digits:
                        credentials[clean_digits] = str(pwd)
                    if last10:
                        credentials[last10] = str(pwd)
                    if payload.get("username"):
                        u = str(payload.get("username")).lower().strip().replace("@", "").replace(" ", "")
                        credentials[u] = str(pwd)
                    if payload.get("phone"):
                        p = str(payload.get("phone")).lower().strip().replace("+", "").replace(" ", "")
                        credentials[p] = str(pwd)
                        p_digits = "".join(c for c in p if c.isdigit())
                        if len(p_digits) >= 10:
                            credentials[p_digits[-10:]] = str(pwd)
                    if payload.get("email"):
                        em = str(payload.get("email")).lower().strip().replace(" ", "")
                        credentials[em] = str(pwd)
                        credentials[em.replace("@", "")] = str(pwd)
                    _dirty_flags['credentials'] = True
                    _flush_event.set()
                log(f"[AUTH_SYNC] Credential registered for: {clean_ident}")
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS"}).encode("utf-8"))
            return

        if path == "/api/verifications":
            reg_pwd = payload.get("password")
            if reg_pwd:
                p_digits = "".join(c for c in str(payload.get("phone", "")) if c.isdigit())
                u_clean = str(payload.get("username", "")).lower().strip().replace("@", "").replace(" ", "")
                e_clean = str(payload.get("email", "")).lower().strip().replace(" ", "")
                with _data_lock:
                    if p_digits:
                        credentials[p_digits] = str(reg_pwd)
                        if len(p_digits) >= 10:
                            credentials[p_digits[-10:]] = str(reg_pwd)
                    if u_clean:
                        credentials[u_clean] = str(reg_pwd)
                    if e_clean:
                        credentials[e_clean] = str(reg_pwd)
                        credentials[e_clean.replace("@", "")] = str(reg_pwd)
                    _dirty_flags['credentials'] = True
                    _flush_event.set()
            payload.pop("password", None)
            ver_id = str(payload.get("verification_id") or payload.get("id") or f"SHB-{int(time.time()*1000)}")
            payload["verification_id"] = ver_id
            payload["id"] = payload.get("id") or ver_id
            payload["status"] = payload.get("status") or "PENDING"
            payload["verification_status"] = payload.get("verification_status") or "PENDING"
            payload["received_at"] = time.strftime("%Y-%m-%d %H:%M:%S")

            name = payload.get("name") or payload.get("full_name") or "Unknown"
            phone = payload.get("phone") or ""

            with _data_lock:
                verifications[ver_id] = payload
                _dirty_flags['verifications'] = True
                _flush_event.set()

            log(f"[SYNC_SERVER] Registered partner received: {name} (Phone: {phone}, App ID: {ver_id})")

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "data": payload}).encode("utf-8"))
            return

        if (path.startswith("/api/verifications/") and path.endswith("/approve")) or path == "/api/verifications/approve":
            target_id = payload.get("id") or payload.get("verification_id") or path.split("/")[-2]
            with _data_lock:
                for k, v in verifications.items():
                    if k == target_id or v.get("id") == target_id or v.get("verification_id") == target_id or str(target_id).lower() in str(k).lower():
                        v["status"] = "APPROVED"
                        v["verification_status"] = "VERIFIED"
                        v["approved_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
                        verifications[k] = v
                        log(f"[SYNC_SERVER] Partner APPROVED: {target_id} ({v.get('name')})")
                _dirty_flags['verifications'] = True
                _flush_event.set()

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "message": f"Approved {target_id}"}).encode("utf-8"))
            return

        if (path.startswith("/api/verifications/") and path.endswith("/reject")) or path == "/api/verifications/reject":
            target_id = payload.get("id") or payload.get("verification_id") or path.split("/")[-2]
            with _data_lock:
                for k, v in verifications.items():
                    if k == target_id or v.get("id") == target_id or v.get("verification_id") == target_id or str(target_id).lower() in str(k).lower():
                        v["status"] = "REJECTED"
                        v["verification_status"] = "REJECTED"
                        verifications[k] = v
                        log(f"[SYNC_SERVER] Partner REJECTED: {target_id}")
                _dirty_flags['verifications'] = True
                _flush_event.set()

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "message": f"Rejected {target_id}"}).encode("utf-8"))
            return

        if path == "/api/products" or path.startswith("/api/products"):
            p_id = str(payload.get("id") or payload.get("product_id") or f"PROD_{int(time.time()*1000)}")
            payload["id"] = p_id
            payload["product_id"] = p_id
            if "created_at" not in payload:
                payload["created_at"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            
            with _data_lock:
                products[p_id] = payload
                _dirty_flags['products'] = True
                _flush_event.set()

            log(f"[SYNC_SERVER] Store Product added/updated: {p_id} ({payload.get('name') or payload.get('title')})")

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "data": payload}).encode("utf-8"))
            return

        if path == "/api/bookings":
            b_id = str(payload.get("id") or payload.get("booking_id") or f"AC_{int(time.time()*1000)}")
            payload["id"] = b_id
            payload["booking_id"] = b_id

            with _data_lock:
                bookings[b_id] = payload
                _dirty_flags['bookings'] = True
                _flush_event.set()

            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "data": payload}).encode("utf-8"))
            return

        self.send_response(404)
        self._set_cors()
        self.end_headers()

    def do_DELETE(self):
        global products
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path
        if path.startswith("/api/products/"):
            p_id = path.split("/")[-1]
            with _data_lock:
                if p_id in products:
                    del products[p_id]
                    _dirty_flags['products'] = True
                    _flush_event.set()
                    log(f"[SYNC_SERVER] Store Product deleted: {p_id}")
            self.send_response(200)
            self._set_cors()
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"status": "SUCCESS", "deleted_id": p_id}).encode("utf-8"))
            return

        self.send_response(404)
        self._set_cors()
        self.end_headers()

    def end_headers(self):
        if hasattr(self, 'command') and self.command == 'GET':
            if any(self.path.endswith(ext) for ext in ('.js', '.wasm', '.png', '.jpg', '.jpeg', '.svg', '.ttf', '.woff', '.woff2', '.css', '.ico')):
                self.send_header("Cache-Control", "public, max-age=86400, immutable")
            elif self.path.startswith('/api/'):
                self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self._set_cors()
        super().end_headers()

    def log_message(self, format, *args):
        pass

class ThreadedHTTPServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

def run_server(port, web_dir=None, name="Server"):
    def handler_factory(*args, **kwargs):
        return ServiceHubHandler(*args, directory=web_dir, **kwargs)

    ServiceHubHandler.extensions_map.update({
        ".wasm": "application/wasm",
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".json": "application/json",
    })

    try:
        with ThreadedHTTPServer(("0.0.0.0", port), handler_factory) as httpd:
            log(f"[+] {name} (Multi-Threaded) successfully running on http://0.0.0.0:{port} (dir: {web_dir})")
            httpd.serve_forever()
    except Exception as e:
        log(f"[-] Failed to bind port {port} for {name}: {e}")

if __name__ == "__main__":
    # Start non-blocking background persistence and sync loops
    t_flush = threading.Thread(target=_background_flush_loop, daemon=True)
    t_sync = threading.Thread(target=_background_file_sync_loop, daemon=True)
    t_flush.start()
    t_sync.start()

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
