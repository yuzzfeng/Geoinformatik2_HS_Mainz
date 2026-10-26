#!/bin/sh
set -eu

PW="${PGPASSWORD:-postgres}"

echo "[gdal-import] Start importing /data/*.geojson ..."
echo "[gdal-import] Contents of /data:"
if ! ls -lah /data; then
  echo "[gdal-import] ERROR: Cannot read /data. Check Docker file sharing and host folder permissions. For cloud-synced folders, try a fully downloaded local copy outside the cloud folder." >&2
  exit 1
fi

FOUND=false
for f in /data/*.geojson; do
  if [ ! -e "$f" ]; then
    echo "[gdal-import] Pattern /data/*.geojson did not match any files"
    continue
  fi
  if [ ! -r "$f" ]; then
    echo "[gdal-import] ERROR: Cannot read $f." >&2
    exit 1
  fi
  FOUND=true
  name=$(basename "$f")
  name=${name%.*}
  echo "[gdal-import] Importing $f -> table $name"
  ogr2ogr -f PostgreSQL \
    PG:"host=db port=5432 dbname=postgres user=postgres password=${PW}" \
    "$f" -nln "$name" -lco GEOMETRY_NAME=geom -t_srs EPSG:4326 -overwrite
done

if [ "$FOUND" = false ]; then
  echo "[gdal-import] No GeoJSON files found under /data."
else
  echo "[gdal-import] Done."
fi
