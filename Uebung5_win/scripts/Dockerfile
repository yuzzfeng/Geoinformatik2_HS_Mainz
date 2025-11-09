FROM ghcr.io/osgeo/gdal:alpine-small-latest

# Kopiere das Import-Skript in das Image
COPY import_geojson.sh /app/import_geojson.sh

# Setze ausführbare Rechte und normalisiere CRLF für Windows-Kompatibilität
RUN chmod +x /app/import_geojson.sh && sed -i 's/\r$//' /app/import_geojson.sh

ENTRYPOINT ["/bin/sh", "/app/import_geojson.sh"]
