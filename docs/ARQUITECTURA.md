# Arquitectura del Laboratorio

## Vision general

El laboratorio simula tres zonas de red de un entorno corporativo:

```
                     +---------------------+
                     |       Host (TU)     |
                     +----------+----------+
                                | publica solo el proxy
                                v
                     +---------------------+
   edge_net (DMZ) -->|  proxy (Nginx mal   |
                     |    configurado)     |
                     +----+----------------+
                          |  conecta tambien a app_net
                          v
       +------------------+--------------------+
       |                  |                    |
   +---+----+      +------+------+      +------+-------+
   |  dvwa  |      | juice-shop  |      | phpmyadmin   |
   +---+----+      +-------------+      +------+-------+
       |                                       |
       |        db_net (internal: true)        |
       +------------------+--------------------+
                          v
                    +-----+------+
                    |   mysql    |
                    +------------+
```

## Redes

| Red        | CIDR             | `internal` | Quien vive aqui                          | Quien la atraviesa |
|------------|------------------|------------|------------------------------------------|--------------------|
| `edge_net` | `172.28.10.0/24` | no         | `proxy`                                  | unica conectada al host |
| `app_net`  | `172.28.20.0/24` | si         | `proxy`, `dvwa`, `juice-shop`, `phpmyadmin` | solo el proxy puede entrar |
| `db_net`   | `172.28.30.0/24` | si         | `dvwa`, `phpmyadmin`, `mysql`            | la BD no es accesible desde edge ni host |

`internal: true` evita que los contenedores en esa red puedan iniciar conexiones
salientes a internet a traves del gateway de Docker. Esto es lo que hace que
`app_net` y `db_net` se comporten como segmentos detras de un firewall.

## Flujos validos

- Host -> `edge_net` -> `proxy` (puertos 8080/8081/8082/8088).
- `proxy` -> `app_net` -> `dvwa` / `juice-shop` / `phpmyadmin`.
- `dvwa` -> `db_net` -> `mysql`.
- `phpmyadmin` -> `db_net` -> `mysql`.

## Flujos imposibles (por diseno)

- Host -> `mysql` directo (no hay puerto publicado y `db_net` es interna).
- Host -> `dvwa` directo (`app_net` es interna; el unico camino es via `proxy`).
- `juice-shop` -> internet (no tiene salida; `app_net` es interna).
- `juice-shop` -> `mysql` (no esta conectada a `db_net`).

## Por que el proxy esta en la DMZ y *tambien* en `app_net`

Es la posicion clasica de un balanceador o reverse proxy corporativo:
expone solo lo que necesita hacia fuera y conoce las apps internas para
poder reenviarles trafico. Esa doble pertenencia (`edge_net` + `app_net`)
es realista, y es justo lo que hace que sus errores de configuracion sean
tan peligrosos.

## Puertos publicados al host

| Puerto host | Destino interno     | Proposito                                |
|-------------|---------------------|------------------------------------------|
| 8080        | `proxy:80`          | Landing + ruteo (`/dvwa/`, `/juice/`, `/dbadmin/`, ...) |
| 8081        | `proxy:81`          | Atajo a DVWA (sin prefijo)               |
| 8082        | `proxy:82`          | Atajo a Juice Shop                       |
| 8088        | `proxy:8088`        | Endpoint `stub_status` aislado           |

Estos valores viven en `.env` y se pueden cambiar sin tocar el compose.

## Healthchecks

- `proxy` expone `/health` (200 OK) consumido por el HEALTHCHECK del contenedor.
- `mysql` usa `healthcheck.sh --connect --innodb_initialized` (incluido en la
  imagen oficial de MariaDB).
- `dvwa` y `phpmyadmin` declaran `depends_on: mysql.healthy` para no arrancar
  contra una BD a medias.

## Volumenes

- `mysql_data` (named volume) preserva los datos de MariaDB entre `make down`
  y `make up`. Se borra con `make clean` o `make reset`.
- Los SQL de `db/init/` se montan como `:ro` y solo se ejecutan la primera vez
  que se crea el volumen.
