#!/usr/bin/env python3
"""Lokal server til Min Mis.

Kør:   /usr/bin/python3 serve.py        (stop med Ctrl+C)

Brug /usr/bin/python3 (Mac'ens egen Python): den har allerede lov af
firewallen til at tage imod forbindelser fra iPad'en.

Åbn derefter adressen, der bliver skrevet ud, i Safari på iPad'en.
Mac og iPad skal være på det samme wifi. Når spillet først er lagt på
hjemmeskærmen, gemmer iPad'en det, så serveren kun skal køre, når
spillet skal installeres eller opdateres.
"""
import http.server
import os
import subprocess
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "public")


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map)
    extensions_map.update({
        ".appcache": "text/cache-manifest",
        ".html": "text/html; charset=utf-8",
        ".js": "application/javascript; charset=utf-8",
        ".png": "image/png",
    })

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        # iPad'en skal altid spørge, om der er en ny version (AppCache klarer offline).
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def addresses():
    found = []
    try:
        host = subprocess.check_output(["scutil", "--get", "LocalHostName"], text=True).strip()
        if host:
            found.append(host + ".local")
    except Exception:
        pass
    for iface in ("en0", "en1"):
        try:
            ip = subprocess.check_output(["ipconfig", "getifaddr", iface], text=True, stderr=subprocess.DEVNULL).strip()
            if ip:
                found.append(ip)
        except Exception:
            pass
    return found


if __name__ == "__main__":
    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print("Min Mis kører. Åbn en af disse adresser i Safari på iPad'en:")
    for name in addresses():
        print("  http://%s:%d/" % (name, PORT))
    print("Stop med Ctrl+C.")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
