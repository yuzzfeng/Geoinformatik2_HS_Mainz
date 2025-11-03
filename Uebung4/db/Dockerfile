# Uebung4/db/Dockerfile
FROM postgis/postgis:16-3.4

# Als root Verzeichnis und Berechtigungen vorbereiten
USER root
RUN mkdir -p /docker-entrypoint-initdb.d \
 && chown -R postgres:postgres /docker-entrypoint-initdb.d \
 && chmod 755 /docker-entrypoint-initdb.d

# Skripte kopieren und Besitzer direkt auf postgres setzen
COPY --chown=postgres:postgres initdb/*.sql /docker-entrypoint-initdb.d/
COPY --chown=postgres:postgres initdb/*.sh  /docker-entrypoint-initdb.d/

# Angemessene Berechtigungen setzen (.sh ausführbar, .sql lesbar)
RUN set -eux; \
    chmod 755 /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true; \
    chmod 644 /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true

# Zurück zu postgres (vom offiziellen Entrypoint erwarteter Benutzer)
USER postgres
