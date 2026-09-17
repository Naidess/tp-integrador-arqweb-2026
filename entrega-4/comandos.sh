#!/bin/bash
# ============================================
# Entrega 4 — Resiliencia, seguridad y cierre
# TP Integrador ARQWEB 2026
# App: todos-express-sqlite
# ============================================

# --- Firewall y superficie expuesta (P10) ---
sudo ufw status verbose
ss -lntup

# --- HALLAZGO 1: Node.js escuchaba en *:3000 (todas las interfaces) ---
# Correccion en bin/www: server.listen(port) -> server.listen(port, process.env.HOST || '0.0.0.0')
sudo sed -i "s/server\.listen(port);/server.listen(port, process.env.HOST || '0.0.0.0');/" \
  /home/admin1/todos-express-sqlite/bin/www
grep "server.listen" /home/admin1/todos-express-sqlite/bin/www
# HOST=127.0.0.1 ya definido en todos.service
sudo systemctl restart todos
ss -lntup | grep 3000        # ahora escucha en 127.0.0.1:3000

# --- HALLAZGO 2: cabeceras de seguridad ausentes (P10) ---
# Se agregan en el bloque server 443 de Nginx (ver nginx-todos-final.conf)
sudo cp nginx-todos-final.conf /etc/nginx/sites-available/todos
sudo nginx -t
sudo systemctl reload nginx
# Verificacion antes/despues desde Windows:
# curl.exe -kI https://equipo.arqweb.test/

# --- Pruebas funcionales y de error (P11) ---
# Desde Windows PowerShell:
# curl.exe -kI https://equipo.arqweb.test/                    # 200 OK
# curl.exe -kI https://equipo.arqweb.test/ruta-que-no-existe  # 404
# curl.exe -kI -X DELETE https://equipo.arqweb.test/          # 404 (Express, ruta no definida)

# --- Caida y recuperacion del backend (P11) ---
sudo systemctl stop todos
sudo systemctl status todos
# Desde Windows: curl.exe -kI https://equipo.arqweb.test/     # 502 Bad Gateway
sudo journalctl -u todos --no-pager | tail -20
sudo systemctl start todos
sudo systemctl status todos
# Desde Windows: curl.exe -kI https://equipo.arqweb.test/     # 200 OK (recuperado)

# --- Reinicio completo de la VM y smoke test (P11) ---
sudo reboot
# Tras reiniciar y reconectar por SSH:
sudo systemctl status todos
sudo systemctl status nginx
sudo ufw status
# Desde Windows: curl.exe -kI https://equipo.arqweb.test/     # 200 OK

# --- Prueba de concurrencia moderada (P12) ---
sudo apt install apache2-utils -y
# Se usa la IP porque el nombre no resuelve desde la VM
ab -n 200 -c 10 https://192.168.56.101/

# --- Observacion de recursos durante la prueba (P12) ---
top -bn1 | head -20
free -h
df -h
sudo journalctl -u todos --no-pager | tail -30