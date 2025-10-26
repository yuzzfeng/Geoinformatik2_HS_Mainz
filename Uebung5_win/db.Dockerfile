# Uebung4/db.Dockerfile
FROM postgis/postgis:16-3.4

# Als root Verzeichnis und Berechtigungen vorbereiten
# USER root
RUN mkdir -p /docker-entrypoint-initdb.d \
 && chown -R postgres:postgres /docker-entrypoint-initdb.d \
 && chmod 755 /docker-entrypoint-initdb.d

# Skripte kopieren und Besitzer direkt auf postgres setzen
COPY --chown=postgres:postgres initdb/*.sql /docker-entrypoint-initdb.d/
COPY --chown=postgres:postgres initdb/*.sh  /docker-entrypoint-initdb.d/

# Windows -> Unix 行尾转换，避免 /bin/bash^M 错误；并设置权限
RUN set -eux; \
        for f in /docker-entrypoint-initdb.d/*.sh; do \
            [ -f "$f" ] || continue; \
            sed -i 's/\r$//' "$f" || true; \
        done; \
        chmod 755 /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true; \
        chmod 644 /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true

# Zurück zu postgres (vom offiziellen Entrypoint erwarteter Benutzer)
USER postgres
