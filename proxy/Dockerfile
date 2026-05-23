# =============================================================================
# Proxy reverso Nginx INTENCIONALMENTE mal configurado para el laboratorio.
# =============================================================================
#
# Nota didactica:
# - Se fija una version "vieja" pero soportada para que las herramientas de
#   reconocimiento (nikto, nmap http-enum, whatweb) detecten banner.
# - server_tokens on; en la configuracion expone la version (ver nginx.conf).
# - Se incluye stub_status, autoindex y rutas vulnerables a path traversal.
# =============================================================================

FROM nginx:1.25-alpine

LABEL org.opencontainers.image.title="lab-vulnerable-proxy" \
      org.opencontainers.image.description="Proxy reverso intencionalmente mal configurado (uso academico)" \
      lab.role="edge-proxy" \
      lab.misconfigured="true"

# Herramientas para healthcheck y debugging desde el contenedor
RUN apk add --no-cache wget curl

# Limpieza de la configuracion por defecto
RUN rm -f /etc/nginx/conf.d/default.conf

# Configuracion principal (con misconfigs documentadas)
COPY nginx.conf            /etc/nginx/nginx.conf
COPY conf.d/               /etc/nginx/conf.d/
COPY snippets/             /etc/nginx/snippets/
COPY html/                 /usr/share/nginx/html/

# Directorio "publico" con autoindex habilitado a proposito
RUN mkdir -p /usr/share/nginx/html/static \
 && echo "credentials backup - DO NOT COMMIT" > /usr/share/nginx/html/static/backup.txt \
 && echo "DB_USER=dvwa"                       >> /usr/share/nginx/html/static/backup.txt \
 && echo "DB_PASSWORD=p@ssw0rd"               >> /usr/share/nginx/html/static/backup.txt \
 && echo "ADMIN_TOKEN=lab-demo-token-1234"    >> /usr/share/nginx/html/static/backup.txt

# Verifica que la configuracion arranca (no implica que sea segura :)
RUN nginx -t

EXPOSE 80 81 82 8088

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
