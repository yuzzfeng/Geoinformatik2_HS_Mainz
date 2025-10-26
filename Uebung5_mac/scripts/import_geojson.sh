#!/bin/sh
set -eu

PW="${PGPASSWORD:-postgres}"

echo "[gdal-import] Start importing /data/*.geojson ..."
echo "[gdal-import] Contents of /data:"
ls -lah /data || echo "[gdal-import] Cannot list /data"

FOUND=false
for f in /data/*.geojson; do
  if [ ! -e "$f" ]; then
    echo "[gdal-import] Pattern /data/*.geojson did not match any files"
    continue
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
