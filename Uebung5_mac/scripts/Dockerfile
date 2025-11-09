FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

# Kopiere das Import-Skript in das Image
COPY import_geojson.sh /app/import_geojson.sh

# Setze ausführbare Rechte
RUN chmod +x /app/import_geojson.sh

ENTRYPOINT ["/bin/sh", "/app/import_geojson.sh"]
