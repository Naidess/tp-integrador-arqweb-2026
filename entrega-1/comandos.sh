#!/bin/bash
# ============================================
# Entrega 1 — Evaluación, selección y línea base
# TP Integrador ARQWEB 2026
# App: todos-express-sqlite
# ============================================

# --- Configuracion base de la VM ---
sudo apt update && sudo apt upgrade -y
sudo hostnamectl set-hostname tp-electiva-vm
sudo timedatectl set-timezone America/Asuncion
timedatectl

# --- Firewall (solo SSH en esta fase) ---
sudo ufw allow 22/tcp
sudo ufw enable
sudo ufw status verbose

# --- Linea base: red y direccionamiento (P01) ---
ip addr
ip route
resolvectl status
hostnamectl

# --- Puertos en escucha (P03) ---
ss -lntup

# --- Conectividad: salida a Internet ---
ping -c4 8.8.8.8
curl -I https://example.com

# --- Conectividad anfitrion <-> VM (P02) ---
# Desde Windows PowerShell (no desde la VM):
# ping 192.168.56.101

# --- Clonado de la aplicacion y registro del commit ---
sudo apt install git -y
git clone https://github.com/jaredhanson/todos-express-sqlite.git /home/admin1/todos-express-sqlite
cd /home/admin1/todos-express-sqlite
pwd
git rev-parse HEAD
# Commit registrado: a489bf23de555bb5fdfe95c40a34bd22711e51fe