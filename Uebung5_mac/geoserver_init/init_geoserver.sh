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
# Check if workspace already exists
if ! curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/workspaces/uebung.json" >/dev/null 2>&1; then
  curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
    -d '<workspace><name>uebung</name></workspace>' \
    -X POST "$GEOSERVER_URL/rest/workspaces"
  echo "Workspace 'uebung' created."
else
  echo "Workspace 'uebung' already exists."
fi

# Create or update PostGIS datastore
cat > /tmp/pg_ds.xml <<EOF
<dataStore>
  <name>pg_data</name>
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

echo "Creating/Updating PostGIS datastore 'pg_data'..."
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/pg_ds.xml \
  -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores" 2>/dev/null || \
curl -s -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
  -d @/tmp/pg_ds.xml \
  -X PUT "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_data"

# Get list of all tables from PostGIS (auto-publishes as WMS + WFS)
echo "Querying PostGIS for available tables..."
TABLES=$(PGPASSWORD=postgres psql -h db -U postgres -d postgres -t -A -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name NOT IN ('spatial_ref_sys', 'geography_columns', 'geometry_columns', 'raster_columns', 'raster_overviews') ORDER BY table_name;" 2>/dev/null)

if [ -z "$TABLES" ]; then
  echo "⚠️  No tables found in PostGIS or database query failed."
  echo "Please check: 1) Database is running, 2) Tables exist, 3) psql is available"
  exit 1
fi

echo "Found user tables: $TABLES"

# Publish each table as feature type (GeoServer auto-enables both WMS + WFS)
echo "Publishing PostGIS tables..."
echo "$TABLES" | while read table_name; do
  [ -z "$table_name" ] && continue
  
  if ! curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_data/featuretypes/${table_name}.json" >/dev/null 2>&1; then
    echo "Publishing table '${table_name}'..."
    
    # Create feature type - GeoServer will auto-calculate bounds and enable both WMS/WFS
    cat > /tmp/featuretype_${table_name}.xml <<EOFFT
<featureType>
  <name>${table_name}</name>
  <nativeName>${table_name}</nativeName>
  <srs>EPSG:4326</srs>
  <enabled>true</enabled>
</featureType>
EOFFT
    
    RESPONSE=$(curl -s -w "\\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
      -d @/tmp/featuretype_${table_name}.xml \
      -X POST "$GEOSERVER_URL/rest/workspaces/uebung/datastores/pg_data/featuretypes" 2>&1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    
    if [ "$HTTP_CODE" = "201" ]; then
      echo "  ✓ Layer '${table_name}' published (WMS + WFS)."
    else
      echo "  ✗ Failed to publish '${table_name}' (HTTP $HTTP_CODE)"
      echo "$RESPONSE" | head -n -1
    fi
  else
    echo "Layer '${table_name}' already exists, skipping."
  fi
done

# Auto-publish all GeoTIFFs as WMS raster layers
echo "\\n--- Publishing GeoTIFF Raster Images ---"

# Find all TIF files using find command directly
if [ -d "/data" ]; then
  find /data -maxdepth 1 \( -name "*.tif" -o -name "*.tiff" -o -name "*.TIF" -o -name "*.TIFF" \) -type f | while read filepath; do
    [ -z "$filepath" ] && continue
    
    filename=$(basename "$filepath")
    name=$(echo "$filename" | sed 's/\.[^.]*$//')
    
    echo "Publishing GeoTIFF '$name' from '$filepath' as WMS..."
    
    # Create coverage store for this GeoTIFF if it doesn't exist
    if ! curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores/${name}.json" >/dev/null 2>&1; then
      cat > /tmp/coverage_store_${name}.xml <<EOFCS
<coverageStore>
  <name>${name}</name>
  <enabled>true</enabled>
  <workspace>
    <name>uebung</name>
  </workspace>
  <type>GeoTIFF</type>
  <url>file://${filepath}</url>
</coverageStore>
EOFCS
      
      RESPONSE=$(curl -s -w "\\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
        -d @/tmp/coverage_store_${name}.xml \
        -X POST "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores" 2>&1)
      HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
      
      if [ "$HTTP_CODE" = "201" ]; then
        echo "  ✓ Coverage store '${name}' created."
      else
        echo "  ✗ Failed to create coverage store '${name}' (HTTP $HTTP_CODE)"
        echo "$RESPONSE" | head -n -1
        continue
      fi
    else
      echo "  Coverage store '${name}' already exists."
    fi
    
    # Wait for store to be fully initialized
    sleep 2
    
    # Create coverage (layer) for this GeoTIFF if it doesn't exist
    if ! curl -sf -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores/${name}/coverages/${name}.json" >/dev/null 2>&1; then
      cat > /tmp/coverage_${name}.xml <<EOFCOV
<coverage>
  <name>${name}</name>
  <enabled>true</enabled>
</coverage>
EOFCOV
      
      RESPONSE=$(curl -s -w "\\n%{http_code}" -u "$ADMIN_USER:$ADMIN_PASS" -H "Content-type: application/xml" \
        -d @/tmp/coverage_${name}.xml \
        -X POST "$GEOSERVER_URL/rest/workspaces/uebung/coveragestores/${name}/coverages" 2>&1)
      HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
      
      if [ "$HTTP_CODE" = "201" ]; then
        echo "  ✓ WMS layer '${name}' created from GeoTIFF."
      else
        echo "  ✗ Failed to create WMS layer '${name}' (HTTP $HTTP_CODE)"
        echo "$RESPONSE" | head -n -1
      fi
    else
      echo "  WMS layer '${name}' already exists."
    fi
  done
else
  echo "  /data directory not found, skipping GeoTIFF publishing."
fi

# Verify configuration was persisted
echo "\\nVerifying published layers..."
sleep 2

LAYER_COUNT=$(curl -s -u "$ADMIN_USER:$ADMIN_PASS" "$GEOSERVER_URL/rest/layers.json" 2>/dev/null | grep -o '"name"' | wc -l || echo "0")
echo "Total layers published: $LAYER_COUNT"

echo "\\n✓ GeoServer initialization complete."
