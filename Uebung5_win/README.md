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
- **WFS-Layer**: `uebung:points` (Interaktive Punkte aus PostGIS: Mainz, Wiesbaden, Frankfurt)
- **Datenbank-Test**: `places`-Tabelle (Beijing, Shanghai) für Verbindungsprüfung

---

## Schritt 1 · Projektstruktur verstehen

```
Uebung5_win/
├─ docker-compose.yml          # Orchestrierung aller Services
├─ db/
│   ├─ Dockerfile               # PostGIS mit Init-Skripten
│   └─ initdb/
│       ├─ 01_init.sql          # Erstellt 'places'-Tabelle
│       └─ 10_postgis.sh        # Platzhalter für PostGIS-Initialisierung
├─ geodata/                     # Zu publizierende Geodaten
│   ├─ mainz.tif                # GeoTIFF (wird als WMS publiziert)
│   └─ points.geojson           # Vektordaten (werden in PostGIS importiert)
├─ geoserver_init/
│   ├─ Dockerfile               # Image für GeoServer-Konfiguration
│   ├─ init_geoserver.sh        # REST-API-Skript: Workspace, Datastore, Layer
│   └─ verify_mainz.py          # Prüft Mainz und ein echtes WMS-Bild
├─ scripts/
│   ├─ Dockerfile               # GDAL-Image mit eingebettetem Import-Skript
│   └─ import_geojson.sh        # ogr2ogr: GeoJSON → PostGIS
└─ web/
    ├─ app.py                   # Flask-App mit /api/places und WMS/WFS-Seite
    └─ templates/index.html     # Leaflet-Karte mit WMS + WFS Overlay
```

---

## Vor dem Start

- Docker Desktop muss laufen; unter Windows Linux-Container verwenden.
- Die separat bereitgestellte `mainz.tif` nach `geodata/mainz.tif` kopieren.
  Bei Cloud-Synchronisation müssen alle Dateien vollständig lokal verfügbar sein.
- Docker Desktop muss auf den Übungsordner zugreifen dürfen: **Settings → Resources → File sharing**.
  Bei `Operation not permitted` zuerst diese Freigabe prüfen.
- Übung 4 und die jeweils andere Übung-5-Version vorher stoppen (`docker compose stop`
  im jeweiligen Verzeichnis). Die Projekte verwenden dieselben Host-Ports.
- Ports: Webseite `5001`, GeoServer `8080`, PostGIS `5432`. Der Container verwendet intern
  weiterhin Flask-Port `5000`; Host-Port `5001` vermeidet den üblichen AirPlay-Konflikt.
- Für den ersten Image-Download sowie Leaflet und die OSM-Grundkarte ist Internet nötig.

## Schritt 2 · Container starten

```bash
# In Uebung5_win/ Verzeichnis
cd Uebung5_win/

# ⚠️ Nur bei Problemen: Alles löschen und von vorne beginnen (inkl. Datenbank-Daten!)
# docker compose down -v --remove-orphans

# Alle Images bauen
docker compose build

# Services starten
docker compose up -d

# Status prüfen (Init- und Import-Container enden erfolgreich mit Exit 0)
docker compose ps -a
```

**Wichtig:** Der erste Start kann mehrere Minuten dauern. `gdal-import` und `geoserver-init` müssen mit `Exited (0)` enden. Erst danach startet die Webseite. Details: `docker compose logs gdal-import geoserver-init`.

---

## Schritt 3 · Funktionen testen

### 1. Flask-Webseite
**URL:** http://localhost:5001/

**Erwartung:**
- Oben: Tabelle mit `places`-Daten (Beijing, Shanghai) → Datenbankverbindung OK ✅
- Unten: Interaktive Karte mit:
  - OpenStreetMap Basiskarte
  - WMS-Layer: `uebung:mainz` (GeoTIFF-Hintergrund)
  - WFS-Layer: `uebung:points` (klickbare Punkte: Mainz, Wiesbaden, Frankfurt)

### 2. GeoServer Admin-Panel
**URL:** http://localhost:8080/geoserver/
**Login:** `admin` / `geoserver`

**Prüfen Sie:**
- **Layer Preview** → `uebung:mainz` (WMS) und `uebung:points` (WFS)
- **Workspaces** → Workspace `uebung` existiert
- **Stores** → PostGIS-Datastore `pg_data` verbunden (bei älteren Installationen `pg_places`)

### 3. WMS GetCapabilities
**URL:** http://localhost:8080/geoserver/uebung/wms?service=WMS&request=GetCapabilities

**Erwartung:** XML mit `<Layer><Name>mainz</Name></Layer>`

### 4. WFS GetFeature (GeoJSON)
**URL:** http://localhost:8080/geoserver/uebung/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=uebung:points&outputFormat=application/json

**Erwartung:** GeoJSON mit 3 Features (Mainz, Wiesbaden, Frankfurt)

---

## Schritt 4 · Wie funktioniert die Automation?

### GeoServer-Initialisierung (`geoserver-init`)
Das `init_geoserver.sh`-Skript läuft einmalig nach GeoServer-Start und führt automatisch aus:

1. **Workspace erstellen:** `uebung`
2. **PostGIS-Datastore erstellen:** `pg_data` (bestehendes `pg_places` wird weiterverwendet) (Verbindung zu `db:5432/postgres`)
3. **Layer publizieren:**
   - Alle Tabellen mit Geometriespalten im Schema `public`, z.B. `places`, `points`, `cafes`
4. **GeoTIFF auto-publizieren:** Alle `*.tif` in `/data/` (z.B. `mainz.tif`) werden als WMS CoverageStore angelegt

**REST-API Beispiel (Workspace):**
```bash
curl -u admin:geoserver -H "Content-type: application/xml" \
  -d '<workspace><name>uebung</name></workspace>' \
  -X POST http://localhost:8080/geoserver/rest/workspaces
```

### GeoJSON-Import (`gdal-import`)
Das Skript importiert alle `*.geojson` aus `/data`. Dateinamen bestimmen die Tabellennamen.
Bei erneutem Import werden vorhandene Tabellen durch die Dateiinhalte ersetzt (`-overwrite`).
Das folgende Beispiel zeigt den Import innerhalb des Import-Containers:

```bash
ogr2ogr -f PostgreSQL \
  PG:"host=db user=postgres password=postgres dbname=postgres" \
  /data/points.geojson \
  -nln points -lco GEOMETRY_NAME=geom -t_srs EPSG:4326 -overwrite
```

---

## Schritt 5 · Troubleshooting

### Problem: GeoServer zeigt Layer nicht an
**Lösung:**
```bash
# GeoServer-Logs prüfen
docker compose logs geoserver

# Init-Skript nochmal ausführen
docker compose run --rm --no-deps geoserver-init
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
docker compose run --rm --no-deps geoserver-init
```

---

## Erwartete Webseite

<p align="center">
  <img src="assets/Uebung5_output.png" alt="Übung 5 Output" width="100%">
</p>

---

## Deine Aufgaben

1. **Neues Raster aus GeoPortal RLP herunterladen, konvertieren und publizieren:**
   - Öffnen Sie den INSPIRE-Download-Link des GeoPortal RLP (Beispiel):
     https://www.geoportal.rlp.de/mapbender/plugins/mb_downloadFeedClient.php?url=https%3A%2F%2Fwww.geoportal.rlp.de%2Fmapbender%2Fphp%2Fmod_inspireDownloadFeed.php%3Fid%3D2b009ae4-aa3e-ff21-870b-49846d9561b2%26type%3DSERVICE%26generateFrom%3Dremotelist
   - Laden Sie eine benachbarte Rasterkachel herunter. ZIP-Archive zuerst entpacken; Raster bei Bedarf mit GDAL/QGIS als GeoTIFF (`.tif`) exportieren. Eine GML-Datei ist nicht automatisch ein Raster und kann nicht pauschal in GeoTIFF umgewandelt werden.
   - Speichern Sie die GeoTIFF-Datei in `geodata/` und publizieren Sie sie:
     ```bash
     docker compose run --rm --no-deps geoserver-init
     ```

     Ein Neustart von GeoServer allein veröffentlicht keine neuen Dateien.
   - Prüfen: Layer-Preview in GeoServer sollte einen neuen WMS-Layer (z.B. `uebung:<dateiname>`) anzeigen.
   - **Leaflet:** Seite neu laden, den automatisch erkannten WMS-Layer im Kartenmenü aktivieren und zum Datenbereich navigieren.

2. **OSM-Datenpunkte (z.B. Café, Restaurant) herunterladen, als GeoJSON konvertieren und publizieren:**
   - Nutzen Sie Overpass Turbo (https://overpass-turbo.eu/) oder eine andere OSM-API, um relevante POIs (z.B. Café, Restaurant) für Ihre Region als GeoJSON zu exportieren.
   - Speichern Sie die GeoJSON-Datei in `geodata/` und publizieren Sie sie als WFS-Layer:
     Führen Sie zuerst den Import und danach die Veröffentlichung aus (macOS und Windows):

     ```bash
     docker compose run --rm gdal-import
     docker compose run --rm --no-deps geoserver-init
     ```

     Das Initialisierungsskript veröffentlicht automatisch alle Tabellen mit Geometriespalten
     im Schema `public`, z.B. `cafes` und `restaurants`. Bereits veröffentlichte Layer werden
     übersprungen. Neue Installationen verwenden den Datastore `pg_data`; ein vorhandener
     Datastore `pg_places` aus der älteren Windows-Version wird weiterverwendet.
   - Prüfen: Layer-Preview in GeoServer sollte einen neuen WFS-Layer (z.B. `uebung:cafes` oder `uebung:restaurants`) anzeigen.
   - **Leaflet:** Seite neu laden und den automatisch erkannten WFS-Layer im Kartenmenü aktivieren. Passen Sie anschließend die Markerfarbe oder Popup-Darstellung im HTML an.

## Übung 4–6 – Abgabe

- Machen Sie einen Screenshot Ihrer Ergebnisse.

- Laden Sie den Screenshot in Ihr GitHub-Repository hoch.

- Geben Sie in OLAT unter
Geoinformatik 2 (aktueller Kurs) → Übungsabgabe → Uebung 4–6 – Link
den Link zu Ihrem Repository ab.

---

👉 **Mit dieser Übung lernen Sie:**
- Professionelle Geodaten-Publikation mit OGC-Standards (WMS/WFS)
- Automatisierung von GIS-Workflows mit Docker + GeoServer
- Integration von Raster (GeoTIFF) und Vektor (GeoJSON/PostGIS) in einer Webkarte

## Mainz-Layer prüfen

Die separat bereitgestellte Datei muss vor dem Start unter `geodata/mainz.tif` liegen.
`geoserver-init` wartet auf den GeoJSON-Import und prüft anschließend, ob `uebung:mainz`
aktiviert ist und eine WMS-GetMap-Anfrage über den Rasterbereich ein PNG liefert.
Erst nach erfolgreicher Prüfung startet `web`. Bei Fehlern endet die Initialisierung
mit einem Fehlercode; die Logs enthalten die Ursache.

```bash
docker compose logs geoserver-init
docker compose ps -a
```

Nach einer Korrektur die Initialisierung erneut ausführen und danach die Webseite starten:

```bash
docker compose up -d --build
```

Nur die Prüfung erneut ausführen (ohne Layer zu verändern):

```bash
docker compose run --rm --no-deps --entrypoint python3 geoserver-init /app/verify_mainz.py
```

Erwartete Meldung: `Verified: uebung:mainz is enabled and WMS GetMap returns a PNG.`
Diese Prüfung bestätigt die technische Ausgabe; die sichtbare Kartendarstellung
wird anschließend im Browser kontrolliert.

## Änderungen an der Webseite

HTML-Dateien werden beim Build ins Image kopiert. Nach Änderungen:

```bash
docker compose up -d --build --no-deps web
```

Danach die Browserseite neu laden. Die Karte startet immer im Raum Mainz;
zusätzliche Layer verändern den Kartenausschnitt nicht automatisch.
Für neue Datendateien einfache Namen verwenden, z.B. `cafes.geojson` oder `raster_west.tif`
(Kleinbuchstaben, Ziffern, Unterstrich; mit einem Buchstaben beginnen).