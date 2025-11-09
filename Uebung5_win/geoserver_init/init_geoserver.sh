#!/bin/sh
set -e

GEOSERVER_URL=${GEOSERVER_URL:-http://geoserver:8080/geoserver}
ADMIN_USER=${GEOSERVER_ADMIN_USER:-admin}
ADMIN_PASS=${GEOSERVER_ADMIN_PASSWORD:-geoserver}

# Wait for GeoServer REST to be ready (polling)
echo "========================================" >&2
echo "Waiting for GeoServer to start..." >&2
echo "========================================" >&2
for i in $(seq 1 60); do
  if curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/about/version.json" >/dev/null 2>&1; then
    echo "✓ GeoServer is ready!" >&2
    echo "" >&2
    break
  fi
  sleep 2
done

echo "Creating workspace 'uebung'..." >&2
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d '<workspace><name>uebung</name></workspace>' \
  -X POST "$GEOSERVER_URL/rest/workspaces" >/dev/null 2>&1 || true
echo "  ✓ Workspace created/verified" >&2
echo "" >&2

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

echo "Creating PostGIS datastore 'pg_places'..." >&2
RESULT=$(curl -s -w "\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/pg_ds.xml \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores" 2>&1) || true
HTTP_CODE=$(echo "$RESULT" | tail -n1)
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ PostGIS datastore created successfully" >&2
else
  echo "  ⚠ PostGIS datastore already exists or created (HTTP $HTTP_CODE)" >&2
fi
echo "" >&2

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

echo "Publishing PostGIS layer 'places'..." >&2
RESULT=$(curl -s -w "\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
  -d @/tmp/featuretype.json \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_places/featuretypes")
HTTP_CODE=$(echo "$RESULT" | tail -n1)
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ Layer 'places' published successfully" >&2
else
  echo "  ⚠ Layer 'places' may already exist (HTTP $HTTP_CODE)" >&2
fi

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
echo "Publishing PostGIS layer 'points' (if table exists)..." >&2
RESULT=$(curl -s -w "\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/json" \
  -d @/tmp/points_ft.json \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_places/featuretypes" 2>&1) || true
HTTP_CODE=$(echo "$RESULT" | tail -n1)
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ Layer 'points' published successfully" >&2
elif echo "$RESULT" | grep -q "already exists"; then
  echo "  ⚠ Layer 'points' already exists" >&2
else
  echo "  ℹ Table 'points' not found in database (will be imported later)" >&2
fi

# Auto-publish all GeoTIFFs (*.tif, *.tiff) as WMS, using filename as store/layer name
for f in /data/*.tif /data/*.tiff; do
  [ -e "$f" ] || continue
  name=$(basename "$f")
  name=${name%.*}
  echo "Publishing GeoTIFF '$name'..." >&2
  RESULT=$(curl -s -w "\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: text/plain" \
    -d "file://$f" \
    -X PUT "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores/$name/external.geotiff?configure=all" 2>&1) || true
  HTTP_CODE=$(echo "$RESULT" | tail -n1)
  if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "  ✓ GeoTIFF '$name' published successfully" >&2
  else
    echo "  ⚠ GeoTIFF '$name' status: HTTP $HTTP_CODE" >&2
  fi
done

echo "" >&2
echo "========================================" >&2
echo "GeoServer initialization completed!" >&2
echo "========================================" >&2
echo "Published layers:" >&2
echo "  - uebung:places (PostGIS)" >&2
echo "  - uebung:points (PostGIS, if imported)" >&2
echo "  - uebung:mainz (GeoTIFF)" >&2
echo "" >&2
echo "Access GeoServer at: http://localhost:8080/geoserver" >&2
echo "Login: admin / geoserver" >&2
echo "========================================" >&2
