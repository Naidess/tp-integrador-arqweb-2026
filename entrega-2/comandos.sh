#!/bin/bash
# ============================================
# Entrega 2 — Instalacion y publicacion HTTP
# TP Integrador ARQWEB 2026
# App: todos-express-sqlite
# ============================================

# --- Clonado del repositorio ---
git clone https://github.com/jaredhanson/todos-express-sqlite.git /home/admin1/todos-express-sqlite
cd /home/admin1/todos-express-sqlite
pwd
git rev-parse HEAD

# --- Instalacion de Node.js ---
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v    # v22.23.2
npm -v     # 10.9.8

# --- Instalacion de dependencias ---
npm install
npm list --depth=0
# Nota: 17 vulnerabilidades reportadas (6 low, 1 moderate, 8 high, 2 critical)

# --- Variables de entorno (P05) ---
grep -R "process\.env" -n . --exclude-dir=node_modules
# Variable: PORT (por defecto 3000)

# --- Primera ejecucion de prueba ---
npm start
# En otra terminal:
curl http://127.0.0.1:3000

# --- Servicio systemd ---
sudo cp todos.service /etc/systemd/system/todos.service
sudo systemctl daemon-reload
sudo systemctl enable todos
sudo systemctl start todos
sudo systemctl status todos

# --- Verificacion del proceso (P03) ---
systemctl show -p MainPID todos
ps -o user,pid,cmd -p $(systemctl show -p MainPID --value todos)

# --- Logs del servicio ---
sudo journalctl -u todos --no-pager

# --- Puertos y procesos (P03) ---
ss -lntup | grep -E ':22|:53|:80|:3000'

# --- Instalacion y configuracion de Nginx ---
sudo apt install -y nginx
sudo cp nginx-todos.conf /etc/nginx/sites-available/todos
sudo ln -s /etc/nginx/sites-available/todos /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 80/tcp

# --- Verificacion del proxy (P06) ---
curl -I http://127.0.0.1
curl http://127.0.0.1

# --- Acceso desde el anfitrion (P05) ---
# Desde Windows: curl.exe http://192.168.56.101
# Nombre local en hosts de Windows: 192.168.56.101 equipo.arqweb.test
# Desde Windows: curl.exe -v http://equipo.arqweb.test/
# Desde Windows: curl.exe -I http://equipo.arqweb.test/
# Desde Windows: curl.exe -X OPTIONS -i http://equipo.arqweb.test/