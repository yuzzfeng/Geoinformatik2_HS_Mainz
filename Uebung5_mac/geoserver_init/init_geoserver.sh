#!/bin/sh
set -euo pipefail

GEOSERVER_URL=${GEOSERVER_URL:-http://geoserver:8080/geoserver}
ADMIN_USER=${GEOSERVER_ADMIN_USER:-admin}
ADMIN_PASS=${GEOSERVER_ADMIN_PASSWORD:-geoserver}

# Wait for GeoServer REST to be ready (polling)
echo "Waiting for GeoServer REST to be ready..."
for i in $(seq 1 60); do
  if curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/about/version.json" >/dev/null; then
    echo "GeoServer is ready."
    break
  fi
  sleep 2
done

echo "Creating workspace 'uebung'..."
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d '<workspace><name>uebung</name></workspace>' \
  -X POST "$GEOSERVER_URL/rest/workspaces" || true

# Create PostGIS datastore pointing to 'db' service
cat > /tmp/pg_ds.xml <<EOF
<dataStore>
  <name>pg_places</name>
  <enabled>true</enabled>
  <connectionParameters>
    <entry key="host">db</entry>
    <entry key="port">5432</entry>
    <entry key="database">postgres</entry>
    <entry key="user">postgres</entry>
    <entry key="passwd">postgres</entry>
    <entry key="dbtype">postgis</entry>
    <entry key="schema">public</entry>
  </connectionParameters>
</dataStore>
EOF

echo "Creating PostGIS datastore..."
curl -sf -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/pg_ds.xml \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores"

# Publish 'places' layer from PostGIS as WFS/WMS
cat > /tmp/featuretype.json <<EOF
{
  "featureType": {
    "name": "places",
    "nativeName": "places",
    "srs": "EPSG:4326"
  }
}
EOF

echo "Publishing PostGIS layer 'places'..."
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
  -d @/tmp/featuretype.json \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_places/featuretypes"

# If a 'points' table exists in PostGIS (e.g., imported from GeoJSON), publish it too
cat > /tmp/points_ft.json <<EOF
{
  "featureType": {
    "name": "points",
    "nativeName": "points",
    "srs": "EPSG:4326"
  }
}
EOF
echo "Attempting to publish PostGIS layer 'points' (if table exists)..."
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
  -d @/tmp/points_ft.json \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_places/featuretypes" || true

# Auto-publish all GeoTIFFs (*.tif, *.tiff) as WMS, using filename as store/layer name
for f in /data/*.tif /data/*.tiff; do
  [ -e "$f" ] || continue
  name=$(basename "$f")
  name=${name%.*}
  echo "Publishing GeoTIFF '$name' from $f..."
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: text/plain" \
    -d "file://$f" \
    -X PUT "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores/$name/external.geotiff?configure=all" || true
done

# Auto-publish all GeoJSONs (*.geojson) as WFS, using filename as store/layer name
for f in /data/*.geojson; do
  [ -e "$f" ] || continue
  name=$(basename "$f")
  name=${name%.*}
  echo "Creating GeoJSON datastore '$name' from $f..."
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
    -d '{"dataStore": {"name": "'"$name"'", "type": "GeoJSON", "enabled": true, "connectionParameters": {"url": "file:'"$f"'"}}}' \
    -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores" || true

  cat > /tmp/${name}_ft.json <<EOFJSON
{
  "featureType": {
    "name": "${name}",
    "nativeName": "${name}",
    "srs": "EPSG:4326"
  }
}
EOFJSON
  echo "Publishing GeoJSON layer '${name}'..."
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
    -d @/tmp/${name}_ft.json \
    -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/${name}/featuretypes" || true
done

echo "GeoServer initialization done."
