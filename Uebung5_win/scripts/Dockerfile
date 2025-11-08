FROM ghcr.io/osgeo/gdal:alpine-small-latest

# Kopiere Import-Skript und setze ausführbare Rechte
# Konvertiere auch mögliche CRLF zu LF, um /bin/sh Parsing-Fehler zu vermeiden
COPY --chmod=0755 import_geojson.sh /app/import_geojson.sh
RUN sed -i 's/\r$//' /app/import_geojson.sh || true

ENTRYPOINT ["/bin/sh", "/app/import_geojson.sh"]
