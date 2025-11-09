# Uebung5_win/db/Dockerfile
FROM postgis/postgis:16-3.4

# Als root Verzeichnis und Berechtigungen vorbereiten
RUN mkdir -p /docker-entrypoint-initdb.d \
 && chown -R postgres:postgres /docker-entrypoint-initdb.d \
 && chmod 755 /docker-entrypoint-initdb.d

# Init-Skripte kopieren
COPY --chown=postgres:postgres initdb/*.sql /docker-entrypoint-initdb.d/
COPY --chown=postgres:postgres initdb/*.sh  /docker-entrypoint-initdb.d/

# Windows -> Unix Zeilenenden konvertieren, um /bin/bash^M Fehler zu vermeiden; Berechtigungen setzen
RUN set -eux; \
        for f in /docker-entrypoint-initdb.d/*.sh; do \
            [ -f "$f" ] || continue; \
            sed -i 's/\r$//' "$f" || true; \
        done; \
        chmod 755 /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true; \
        chmod 644 /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true

# Zurück zu postgres (vom offiziellen Entrypoint erwarteter Benutzer)
USER postgres
