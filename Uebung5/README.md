Geoinformatik 2 – Web-GIS
# Übung 5 · GeoServer-Integration: WMS & WFS
Prof. Dr. Yu Feng

## Lernziele
Nach dieser Übung können Sie:
- Einen **GeoServer** als Docker-Container aufsetzen und konfigurieren
- GeoServer-Workspace, Datastore und Layer automatisch per REST-API erstellen
- **GeoTIFF-Dateien** als WMS (Web Map Service) bereitstellen
- **GeoJSON-Daten** in PostGIS importieren und als WFS (Web Feature Service) publizieren
- WMS-Layer und WFS-Layer in einer Leaflet-Webkarte kombinieren und anzeigen
- Multi-Container-Orchestrierung mit `docker-compose` (PostGIS, Flask, GeoServer, GDAL)
- Geodaten-Workflows automatisieren: Import → Speicherung → Publikation → Visualisierung

## Überblick
Diese Übung baut auf **Übung 4** (Flask + PostGIS) auf und erweitert das System um einen **GeoServer** zur professionellen Geodaten-Publikation:

### Architektur (4 Services)
1. **db** (PostGIS): Datenbank für Vektordaten  
2. **web** (Flask): Web-Anwendung mit interaktiver Karte  
3. **geoserver** (Kartoza GeoServer): OGC-konformer Map-Server  
4. **geoserver-init**: Automatische GeoServer-Konfiguration via REST-API  
5. **gdal-import** (optional): Automatischer Import von GeoJSON nach PostGIS  

### Geodaten-Pipeline
```
GeoTIFF (mainz.tif)  →  GeoServer  →  WMS  →  Leaflet
GeoJSON (points.geojson)  →  PostGIS  →  GeoServer  →  WFS  →  Leaflet
```

### Was wird publiziert?
- **WMS-Layer**: `uebung:mainz` (Raster-Basiskarte aus GeoTIFF)  
- **WFS-Layer**: `uebung:points` (Interaktive Punkte aus PostGIS: Mainz, Berlin, Frankfurt)  
- **Datenbank-Test**: `places`-Tabelle (Beijing, Shanghai) für Verbindungsprüfung

---

## Schritt 1 · Projektstruktur verstehen

```
Uebung5/
├─ docker-compose.yml          # Orchestrierung aller Services
├─ db.Dockerfile                # PostGIS mit Init-Skripten
├─ initdb/
│   ├─ 00_disable_template_postgis.sh  # Workaround für PostGIS-Konflikte
│   └─ 01_init.sql              # Erstellt 'places'-Tabelle
├─ geodata/                     # Zu publizierende Geodaten
│   ├─ mainz.tif                # GeoTIFF (287 MB, wird als WMS publiziert)
│   └─ points.geojson           # Vektordaten (werden in PostGIS importiert)
├─ geoserver_init/
│   ├─ Dockerfile               # Image für GeoServer-Konfiguration
│   └─ init_geoserver.sh        # REST-API-Skript: Workspace, Datastore, Layer
├─ scripts/
│   ├─ Dockerfile               # GDAL-Image mit eingebettetem Import-Skript
│   └─ import_geojson.sh        # ogr2ogr: GeoJSON → PostGIS
└─ web/
    ├─ app.py                   # Flask-App mit /api/places und WMS/WFS-Seite
    └─ templates/index.html     # Leaflet-Karte mit WMS + WFS Overlay
```

---

## Schritt 2 · Container starten

```bash
# In Uebung5/ Verzeichnis
cd Uebung5/

# Alle Images bauen
docker compose build --no-cache

# Services starten
docker compose up -d

# Status prüfen (alle Services sollten "healthy" sein)
docker compose ps
```

**Wichtig:** Beim ersten Start kann es 1-2 Minuten dauern, bis GeoServer vollständig initialisiert ist.

---

## Schritt 3 · Funktionen testen

### 1. Flask-Webseite
**URL:** http://localhost:5000/

**Erwartung:**
- Oben: Tabelle mit `places`-Daten (Beijing, Shanghai) → Datenbankverbindung OK ✅
- Unten: Interaktive Karte mit:
  - OpenStreetMap Basiskarte
  - WMS-Layer: `uebung:mainz` (GeoTIFF-Hintergrund)
  - WFS-Layer: `uebung:points` (klickbare Punkte: Mainz, Berlin, Frankfurt)

### 2. GeoServer Admin-Panel
**URL:** http://localhost:8080/geoserver/  
**Login:** `admin` / `geoserver`

**Prüfen Sie:**
- **Layer Preview** → `uebung:mainz` (WMS) und `uebung:points` (WFS/WMS)
- **Workspaces** → Workspace `uebung` existiert
- **Stores** → PostGIS-Datastore `pg_places` verbunden

### 3. WMS GetCapabilities
**URL:** http://localhost:8080/geoserver/uebung/wms?service=WMS&request=GetCapabilities

**Erwartung:** XML mit `<Layer><Name>uebung:mainz</Name></Layer>`

### 4. WFS GetFeature (GeoJSON)
**URL:** http://localhost:8080/geoserver/uebung/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=uebung:points&outputFormat=application/json

**Erwartung:** GeoJSON mit 3 Features (Mainz, Berlin, Frankfurt)

---

## Schritt 4 · Wie funktioniert die Automation?

### GeoServer-Initialisierung (`geoserver-init`)
Das `init_geoserver.sh`-Skript läuft einmalig nach GeoServer-Start und führt automatisch aus:

1. **Workspace erstellen:** `uebung`
2. **PostGIS-Datastore erstellen:** `pg_places` (Verbindung zu `db:5432/postgres`)
3. **Layer publizieren:**
   - `places` (aus PostGIS-Tabelle)
   - `points` (falls in PostGIS vorhanden)
4. **GeoTIFF auto-publizieren:** Alle `*.tif` in `/data/` (z.B. `mainz.tif`) werden als WMS CoverageStore angelegt

**REST-API Beispiel (Workspace):**
```bash
curl -u admin:geoserver -H "Content-type: application/xml" \
  -d '<workspace><name>uebung</name></workspace>' \
  -X POST http://localhost:8080/geoserver/rest/workspaces
```

### GeoJSON-Import (`gdal-import`, optional)
Falls `points.geojson` noch nicht in PostGIS ist, importiert das `import_geojson.sh`-Skript automatisch:

```bash
ogr2ogr -f PostgreSQL \
  PG:"host=db user=postgres password=postgres dbname=postgres" \
  /data/points.geojson \
  -nln points -t_srs EPSG:4326
```

---

## Schritt 5 · Troubleshooting

### Problem: GeoServer zeigt Layer nicht an
**Lösung:**
```bash
# GeoServer-Logs prüfen
docker compose logs geoserver

# Init-Skript nochmal ausführen
docker compose run --rm geoserver-init
```

### Problem: WFS liefert keine Daten
**Prüfen Sie, ob Tabelle in PostGIS existiert:**
```bash
docker compose exec db psql -U postgres -d postgres -c '\dt'
docker compose exec db psql -U postgres -d postgres -c 'SELECT * FROM points;'
```

**Falls Tabelle fehlt:**
```bash
docker compose run --rm gdal-import
```

### Problem: "Operation not permitted" bei GDAL-Import
**Ursache:** Google Drive-Mount-Probleme (falls Projektordner auf Google Drive liegt)

**Lösung:**
```bash
# Geodaten in lokales Verzeichnis kopieren
mkdir -p ~/Projects/geodata_temp
cp geodata/* ~/Projects/geodata_temp/

# docker-compose.yml anpassen (alle geodata-Mounts):
# - ./geodata:/data:ro  →  ~/Projects/geodata_temp:/data:ro
```

---

## Erwartete Webseite

<p align="center">
  <img src="assets/Uebung5_output.png" alt="Übung 5 Output" width="100%">
</p>

---

## Weiterführende Aufgaben

1. **Eigene GeoTIFF hinzufügen:** Laden Sie ein Satellitenbild herunter, legen Sie es in `geodata/` ab und starten Sie `geoserver-init` neu
2. **Styling anpassen:** Erstellen Sie im GeoServer-Admin einen SLD-Style für `points` (z.B. unterschiedliche Farben nach Stadt)
3. **Weitere GeoJSON-Layer:** Fügen Sie `lines.geojson` oder `polygons.geojson` hinzu und publizieren Sie als WFS
4. **Leaflet erweitern:** Fügen Sie Layer-Control hinzu, damit Nutzer WMS/WFS ein-/ausschalten können

---

👉 **Mit dieser Übung lernen Sie:**
- Professionelle Geodaten-Publikation mit OGC-Standards (WMS/WFS)
- Automatisierung von GIS-Workflows mit Docker + REST-API
- Integration von Raster (GeoTIFF) und Vektor (GeoJSON/PostGIS) in einer Webkarte


