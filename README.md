# Laboratorio Vulnerable Automatizado

Entorno academico, listo para ejecutar con un comando, para practicar tecnicas
ofensivas y de DevSecOps en un escenario que imita una arquitectura corporativa
segmentada: una **DMZ** con un proxy reverso mal configurado, una **red interna**
con aplicaciones vulnerables y una **red de datos** aislada con la base de datos.

> **Aviso etico.** Este repositorio contiene vulnerabilidades intencionales.
> Usalo *solo* en una red privada y aislada (tu maquina, una VM o una red
> de laboratorio sin salida a internet). Mas detalles en
> [`docs/ADVERTENCIA.md`](docs/ADVERTENCIA.md).

---

## Que incluye

| Servicio       | Imagen                          | Donde vive                    | Como se accede                   |
|----------------|---------------------------------|-------------------------------|----------------------------------|
| `proxy`        | nginx:1.25-alpine (mal config.) | DMZ (`edge_net` + `app_net`)  | `http://localhost:8080`          |
| `dvwa`         | `vulnerables/web-dvwa`          | Interna (`app_net` + `db_net`)| `http://localhost:8080/dvwa/`    |
| `juice-shop`   | `bkimminich/juice-shop`         | Interna (`app_net`)           | `http://localhost:8080/juice/`   |
| `phpmyadmin`   | `phpmyadmin:5-apache`           | Interna (`app_net` + `db_net`)| `http://localhost:8080/dbadmin/` |
| `mysql`        | `mariadb:10.11`                 | Datos (`db_net`, internal)    | solo via DVWA / phpMyAdmin       |

Diagrama y flujo de red detallado: [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

---

## Inicio rapido

```bash
git clone https://github.com/0xvanguard/Laboratorio-Vulnerable-Automatizado.git
cd Laboratorio-Vulnerable-Automatizado

# Opcion A: usando Make
make up

# Opcion B: con Docker Compose directo
cp .env.example .env
docker compose up -d --build
```

Cuando termine de construir, abre [http://localhost:8080](http://localhost:8080).

Verificacion rapida:

```bash
make health      # consulta los endpoints principales y muestra OK/FAIL
make logs        # tail de logs de todos los contenedores
make ps          # estado de los contenedores
```

Apagar / limpiar:

```bash
make down        # apaga (preserva datos)
make reset       # apaga, borra volumenes y vuelve a levantar limpio
make clean       # apaga + elimina volumenes y redes
make nuke        # clean + borra la imagen del proxy
```

---

## Por que esta segmentado asi

El objetivo es que el escenario se sienta como una empresa real, no como un
"todo en un mismo bridge". Por eso:

- **`edge_net` (DMZ)**: unica red conectada al host. Solo el proxy publica
  puertos. Si una app de detras fuera comprometida, no tiene salida directa.
- **`app_net` (interna)**: declarada con `internal: true`. Las apps no pueden
  iniciar conexiones hacia internet, igual que un segmento corporativo
  detras de un firewall.
- **`db_net` (datos)**: tambien `internal: true`. Solo `dvwa`, `phpmyadmin`
  y `mysql` viven aqui. La base de datos *no* esta accesible ni desde la
  DMZ ni desde el host directamente.

Esto permite ejercicios realistas de **pivoting**, **lateral movement** y
**revision de reglas de red**.

---

## Vulnerabilidades incluidas (resumen)

- **Proxy reverso**: server tokens, autoindex, path traversal por `alias`,
  `stub_status` expuesto, confianza ciega en `X-Forwarded-For`, sin cabeceras
  de seguridad, sin filtros sobre `.git`/`.env`/`*.bak`, gzip sobre respuestas
  con cookies (CRIME-friendly), TRACE/OPTIONS sin filtrar, `client_max_body_size 0`.
- **DVWA**: el catalogo clasico (SQLi, XSS, CSRF, command injection, file upload,
  file inclusion, brute force).
- **Juice Shop**: ~100 retos del Top 10 de OWASP.
- **MariaDB**: usuarios `guest` (sin contrasena), `reporting` (contrasena =
  usuario), `backup` con privilegio `FILE`. Hashes en MD5 sin sal.
- **phpMyAdmin**: publicado en `/dbadmin/` sin ACL, con `PMA_ARBITRARY=1`.

Lista completa, con el ejercicio sugerido para cada una:
[`docs/VULNERABILIDADES.md`](docs/VULNERABILIDADES.md).

---

## Estructura del repositorio

```
.
|-- docker-compose.yml          # composicion principal (3 redes segmentadas)
|-- .env.example                # variables (puertos, contrasenas)
|-- Makefile                    # atajos: up/down/reset/health/logs/ps
|-- proxy/
|   |-- Dockerfile              # imagen del proxy (mal configurado)
|   |-- nginx.conf              # configuracion global
|   |-- conf.d/00-lab.conf      # vhosts + ruteo + misconfigs
|   |-- html/                   # landing + 50x + robots.txt
|   `-- snippets/
|-- db/
|   `-- init/
|       |-- 01-init.sql         # datos sinteticos en BD `corp`
|       `-- 02-weak-users.sql   # usuarios MySQL debiles
|-- scripts/
|   |-- setup.sh                # primera puesta en marcha
|   |-- reset.sh                # arranque limpio
|   `-- health.sh               # verificacion de endpoints
`-- docs/
    |-- ARQUITECTURA.md         # diagrama y modelo de red
    |-- VULNERABILIDADES.md     # catalogo + ejercicios
    `-- ADVERTENCIA.md          # uso responsable
```

---

## Personalizacion

Todos los puertos publicados al host viven en `.env`:

```env
LAB_HTTP_PORT=8080
LAB_DVWA_PORT=8081
LAB_JUICE_PORT=8082
LAB_STATUS_PORT=8088
```

Cambialos si tu host ya tiene esos puertos ocupados y vuelve a levantar:

```bash
make restart
```

---

## Licencia

[MIT](LICENSE). El uso del laboratorio es bajo tu propia responsabilidad
y debe respetar leyes locales y politicas internas.
