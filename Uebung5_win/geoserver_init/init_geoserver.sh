#!/bin/sh
# POSIX sh in curlimages/curl may be BusyBox ash; keep it minimal (no 'set' flags)

GEOSERVER_URL=${GEOSERVER_URL:-http://geoserver:8080/geoserver}
ADMIN_USER=${GEOSERVER_ADMIN_USER:-admin}
ADMIN_PASS=${GEOSERVER_ADMIN_PASSWORD:-geoserver}

# Wait for GeoServer REST to be ready (polling) without relying on 'seq'
echo "Waiting for GeoServer REST to be ready..."
i=0
while true; do
  if curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/about/version.json" >/dev/null; then
    echo "GeoServer is ready."
    break
  fi
  i=$(expr "$i" + 1)
  [ "$i" -ge 60 ] && break
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
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores" || true

# Publish 'places' layer from PostGIS as WFS/WMS (use XML so GeoServer infers attributes)
cat > /tmp/places_ft.xml <<EOF
<featureType>
  <name>places</name>
  <nativeName>places</nativeName>
  <srs>EPSG:4326</srs>
</featureType>
EOF

echo "Publishing PostGIS layer 'places'..."
curl -sf -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/places_ft.xml \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_places/featuretypes" || true

# If a 'points' table exists in PostGIS (e.g., imported from GeoJSON), publish it too (XML payload)
cat > /tmp/points_ft.xml <<EOF
<featureType>
  <name>points</name>
  <nativeName>points</nativeName>
  <srs>EPSG:4326</srs>
</featureType>
EOF
echo "Attempting to publish PostGIS layer 'points' (if table exists)..."
curl -sf -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/points_ft.xml \
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
# Auto-publish GeoJSONs if GeoJSON store is available; otherwise, skip with a warning
GEOJSON_AVAILABLE=1
for f in /data/*.geojson; do
  [ -e "$f" ] || continue
  [ "$GEOJSON_AVAILABLE" -eq 0 ] && { echo "GeoJSON store not available; skipping remaining GeoJSONs."; break; }
  name=$(basename "$f")
  name=${name%.*}
  echo "Creating GeoJSON datastore '$name' from $f..."

  # Attempt to create datastore and capture status + response
  code=$(curl -s -o /tmp/resp_ds.txt -w "%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
    -d '{"dataStore": {"name": "'"$name"'", "type": "GeoJSON", "enabled": true, "connectionParameters": {"url": "file:'"$f"'"}}}' \
    -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores") || code=000

  if [ "$code" -ge 400 ]; then
    if grep -q "Failed to find the datastore factory" /tmp/resp_ds.txt 2>/dev/null; then
      echo "GeoServer GeoJSON store plugin not installed; skipping GeoJSON publishing."
      GEOJSON_AVAILABLE=0
      continue
    else
      echo "Warning: Failed to create GeoJSON datastore '$name' (HTTP $code)." 
      continue
    fi
  fi

  # Create feature type via XML (lets GeoServer infer attributes)
  cat > /tmp/${name}_ft.xml <<EOFJSON
<featureType>
  <name>${name}</name>
  <nativeName>${name}</nativeName>
  <srs>EPSG:4326</srs>
</featureType>
EOFJSON
  echo "Publishing GeoJSON layer '${name}'..."
  curl -sf -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
    -d @/tmp/${name}_ft.xml \
    -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/${name}/featuretypes" || true
done

echo "GeoServer initialization done."
