# TP Integrador ARQWEB 2026 — Despliegue de todos-express-sqlite

Trabajo Práctico Integrador de la materia **Electiva III — Arquitectura Web** (FP-UNA, 2.º Semestre 2026).

Despliegue, conectividad y verificación experimental de una aplicación web de código abierto sobre una máquina virtual GNU/Linux.

---

## Equipo

- Jazmin Figueredo
- Fernando Servian
- Samyr Galeano

**Docente:** Rodrigo Benitez

---

## Aplicación desplegada

| Dato | Valor |
|---|---|
| Nombre | todos-express-sqlite |
| Repositorio origen | https://github.com/jaredhanson/todos-express-sqlite |
| Commit utilizado | `a489bf23de555bb5fdfe95c40a34bd22711e51fe` |
| Lenguaje | JavaScript (Node.js v22.23.2) |
| Framework | Express 4.16.4 |
| Base de datos | SQLite (embebida) |
| Servidor web / proxy | Nginx 1.28.3 |

---

## Infraestructura

| Elemento | Valor |
|---|---|
| Virtualizador | VirtualBox |
| Sistema operativo | Ubuntu Server 24.04.4 LTS |
| Hostname | tp-electiva-vm |
| Usuario | admin1 |
| Red NAT | enp0s3 — 10.0.2.15/24 (salida a Internet) |
| Red Host-only | enp0s8 — 192.168.56.101/24 (acceso desde anfitrión) |
| Nombre local | equipo.arqweb.test (definido en hosts del anfitrión) |

---

## Arquitectura (as built)

```
Cliente / Navegador (Windows)
        │
        │ HTTPS :443 (TLS 1.3)  |  HTTP :80 → 301 → HTTPS
        ▼
    Nginx 1.28.3 (192.168.56.101)
    + cabeceras de seguridad (HSTS, X-Frame-Options, etc.)
        │
        │ proxy inverso
        ▼
    Node.js / Express (127.0.0.1:3000)
    todos.service (systemd)
        │
        ▼
    SQLite (archivo local)
```

---

## Cómo levantar el servicio

```bash
# 1. Clonar la aplicación
git clone https://github.com/jaredhanson/todos-express-sqlite.git /home/admin1/todos-express-sqlite
cd /home/admin1/todos-express-sqlite

# 2. Instalar Node.js y dependencias
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
npm install

# 3. Instalar el servicio systemd
sudo cp entrega-2/todos.service /etc/systemd/system/todos.service
sudo systemctl daemon-reload
sudo systemctl enable --now todos

# 4. Configurar Nginx (versión final con TLS y headers de seguridad)
sudo cp entrega-4/nginx-todos-final.conf /etc/nginx/sites-available/todos
sudo ln -s /etc/nginx/sites-available/todos /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# 5. Firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

El certificado TLS autofirmado se genera con:

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/arqweb.key \
  -out /etc/ssl/certs/arqweb.crt \
  -subj "/CN=equipo.arqweb.test" \
  -addext "subjectAltName=DNS:equipo.arqweb.test"
```

En el anfitrión (Windows), agregar al archivo hosts:
```
192.168.56.101   equipo.arqweb.test
```

---

## Puertos en uso

| Puerto | Proceso | Interfaz | Función |
|---|---|---|---|
| 22 | sshd | todas | Administración remota SSH |
| 80 | nginx | todas | HTTP (redirige a HTTPS) |
| 443 | nginx | todas | HTTPS (punto de entrada principal) |
| 3000 | node | 127.0.0.1 | Backend (no expuesto a la red) |

---

## Estructura del repositorio

```
.
├── README.md
├── informe/
│   └── TP-Integrador-ARQWEB.pdf     # Informe técnico completo
├── entrega-1/
│   └── comandos.sh                   # Configuración VM y línea base
├── entrega-2/
│   ├── comandos.sh                   # Instalación app + Nginx HTTP
│   ├── todos.service                 # Servicio systemd
│   └── nginx-todos.conf              # Config Nginx (HTTP)
├── entrega-3/
│   ├── comandos.sh                   # TLS, DNS, mediciones
│   ├── nginx-todos-tls.conf          # Config Nginx (HTTPS)
│   ├── curl-format.txt               # Formato de mediciones
│   └── logs/
│       ├── mediciones.txt            # 10 mediciones de tiempos
│       └── certificado.txt           # Análisis del certificado
└── entrega-4/
    ├── comandos.sh                   # Seguridad y resiliencia
    ├── nginx-todos-final.conf        # Config Nginx final (headers seguridad)
    ├── bin-www.diff                  # Corrección puerto 3000
    └── logs/
        ├── ab-concurrencia.txt       # Prueba de carga
        ├── caida-recuperacion.txt    # Simulación de falla
        └── reinicio-smoke-test.txt   # Reinicio de VM
```

---

## Matriz de pruebas P01–P12

| ID | Dimensión | Resultado |
|---|---|---|
| P01 | Direccionamiento | ✅ Interfaces NAT y host-only documentadas |
| P02 | Conectividad | ✅ Ping y ARP verificados |
| P03 | Puertos | ✅ Solo 22/80/443 abiertos, backend en loopback |
| P04 | Nombre | ✅ Resolución local verificada |
| P05 | HTTP | ✅ Métodos, estados y cabeceras verificados |
| P06 | Proxy | ✅ Backend no expuesto, proxy funcional |
| P07 | TLS | ✅ Handshake, certificado y protocolo analizados |
| P08 | Rendimiento | ✅ 10 mediciones con tabla estadística |
| P09 | Caché | ✅ ETag y 304 Not Modified demostrados |
| P10 | Seguridad | ✅ Firewall, headers y 2 hallazgos corregidos |
| P11 | Resiliencia | ✅ Caída, recuperación y reinicio probados |
| P12 | Recursos | ✅ Concurrencia con ab y monitoreo de recursos |

---

## Hallazgos de seguridad y correcciones

| Hallazgo | Estado |
|---|---|
| Node.js escuchaba en `*:3000` (todas las interfaces) | ✅ Corregido → `127.0.0.1:3000` |
| Ausencia de cabeceras de seguridad HTTP | ✅ Corregido → HSTS, X-Frame-Options, etc. |
| `X-Powered-By: Express` expuesto | ⚠️ Riesgo residual aceptado |
| Certificado autofirmado | ⚠️ Aceptado (entorno de laboratorio) |

---

## Nota de seguridad

Este repositorio **no contiene secretos**. La clave privada del certificado TLS (`arqweb.key`) no está versionada. Los datos utilizados en la aplicación son ficticios.

---

## Etiqueta

Entrega final marcada con el tag `fase-4`.