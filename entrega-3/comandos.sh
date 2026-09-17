#!/bin/bash
# ============================================
# Entrega 3 — DNS local, TLS, HTTP y medicion
# TP Integrador ARQWEB 2026
# App: todos-express-sqlite
# ============================================

# --- Resolucion del nombre local (P04) ---
# En la VM (el nombre NO resuelve, es lo esperado):
resolvectl query equipo.arqweb.test    # devuelve "not found"
hostname -I
resolvectl query google.com
# Desde Windows PowerShell:
# ping equipo.arqweb.test
# curl.exe --resolve equipo.arqweb.test:80:192.168.56.101 http://equipo.arqweb.test/

# --- Generacion del certificado autofirmado (P07) ---
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/arqweb.key \
  -out /etc/ssl/certs/arqweb.crt \
  -subj "/CN=equipo.arqweb.test" \
  -addext "subjectAltName=DNS:equipo.arqweb.test"
sudo ls -la /etc/ssl/private/arqweb.key
ls -la /etc/ssl/certs/arqweb.crt

# --- Configuracion HTTPS en Nginx (ver nginx-todos-tls.conf) ---
sudo cp nginx-todos-tls.conf /etc/nginx/sites-available/todos
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 443/tcp
sudo ufw status verbose

# --- Analisis del certificado (P07) ---
# Se usa 127.0.0.1 porque el nombre no resuelve desde la VM
echo | openssl s_client -connect 127.0.0.1:443 \
  -servername equipo.arqweb.test 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates -ext subjectAltName -fingerprint

openssl s_client -connect 127.0.0.1:443 -servername equipo.arqweb.test

# --- Verificacion redireccion HTTP->HTTPS (P05/P07) ---
# Desde Windows PowerShell:
# curl.exe -v http://equipo.arqweb.test/       # 301 Moved Permanently
# curl.exe -kv https://equipo.arqweb.test/     # 200 OK sobre TLS
# curl.exe -kI https://equipo.arqweb.test/

# --- Medicion de tiempos: 10 ejecuciones (P08) ---
# Desde Windows PowerShell (para medir todas las fases reales):
# for ($i=1; $i -le 10; $i++) {
#   Write-Host "=== Run $i ==="
#   curl.exe -k -w "@curl-format.txt" -o NUL -s https://equipo.arqweb.test/
# }

# --- Cache (P09) ---
curl -kI https://127.0.0.1/css/base.css
# Segunda peticion con el ETag (incluir prefijo W/):
curl -kI https://127.0.0.1/css/base.css \
  -H 'If-None-Match: W/"71a-1a09ba0e06e"'    # devuelve 304 Not Modified

# --- Comparacion backend vs proxy (P06) ---
curl -v http://127.0.0.1:3000/               # 200 OK desde la VM
# Desde Windows: curl.exe http://192.168.56.101:3000/   # falla (backend no expuesto)

# --- Captura de red (P07/P02) ---
sudo tcpdump -i enp0s8 -w /home/admin1/f3-e14-captura.pcap
# Descargar al anfitrion con scp y analizar en Wireshark
# Filtros: arp | tcp.flags.syn==1 | tls