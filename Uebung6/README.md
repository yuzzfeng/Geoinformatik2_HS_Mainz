Geoinformatik 2 – Web-GIS
# Übung 6 · Eigene Vector Tiles ohne Server
Prof. Dr. Yu Feng

In dieser Übung erzeugt ihr aus Gebäudedaten von OpenStreetMap euren **eigenen Vector-Tile-Layer**, veröffentlicht ihn kostenlos auf **GitHub Pages** und nutzt ihn in einer Webkarte (MapLibre GL JS) und in **QGIS**. Ihr braucht dafür keinen Kartenserver, keine Datenbank und kein Hosting.

## Lernziele

Nach dieser Übung könnt ihr

- den Unterschied zwischen Raster Tiles und Vector Tiles erklären,
- das Kachelschema (`zoom/x/y`) beschreiben,
- **PMTiles** (eine Datei) und **XYZ** (Ordner `z/x/y.pbf`) vergleichen,
- mit **tippecanoe** (in Docker) Vector Tiles aus GeoJSON erzeugen und die Parameter bewusst wählen,
- Vector Tiles statisch auf GitHub Pages veröffentlichen,
- sie in **MapLibre** und **QGIS** einbinden und gestalten.

## Die Idee in einem Satz

> Daten → **tippecanoe** → Kacheln (PMTiles / XYZ) → **GitHub Pages** → Webkarte und QGIS

Die Kacheln werden **einmal vorab berechnet** und liegen danach als statische Dateien im Netz. Es läuft kein Server-Programm. Bei PMTiles holt der Browser per HTTP-Range-Request nur die Bytes, die er für den aktuellen Kartenausschnitt braucht.

## Material

| Pfad | Inhalt |
|---|---|
| `data/buildings.geojson` | OSM-Gebäude, Mainzer Innenstadt (ca. 3 × 3 km, 6411 Gebäude, alle OSM-Tags) |
| `data/population.geojson` | Zensus-2022-Bevölkerung, 100-m-Gitter (Vergleichsebene) |
| `tools/Dockerfile` | Baut das Docker-Image mit tippecanoe |
| `index.html` | Webkarte mit PMTiles/XYZ-Umschalter, Hover, Beschriftung und 3D |
| `qgis/test_simple.json` | Stil für QGIS (Farben nach Etagenzahl bzw. Einwohnerzahl) |
| `tiles/`, `tiles_xyz/` | Fertige Musterkacheln zum Vergleichen |

Voraussetzungen: ein GitHub-Account, [Docker Desktop](https://www.docker.com/products/docker-desktop/), Git, QGIS (ab 3.x mit Vector-Tiles-Unterstützung).

## Ablauf

### Schritt 1 · Konzept
Lest kurz nach (oder besprecht in der Übung): Was ist der Unterschied zwischen Raster- und Vector Tiles? Welche Vorteile hat es, dass Geometrie und Attribute erst im Client gezeichnet werden?

### Schritt 2 · Repository anlegen
1. Legt auf GitHub ein **öffentliches** Repository an, z. B. `vector-tiles-mainz`.
2. Kopiert die Übungsdateien hinein (oder forkt das Vorlage-Repository).
3. Klont das Repository auf euren Rechner.

> Arbeitet in einem **lokalen** Ordner (z. B. `~/Documents`). Docker kann Cloud-Ordner (OneDrive, SeaDrive, iCloud) oft nicht einbinden und meldet „Mounts denied“.

### Schritt 3 · Kacheln mit Docker erzeugen
Öffnet ein Terminal im Hauptverzeichnis des Repositorys (`Geoinformatik2_HS_Mainz`). Baut zuerst einmal das tippecanoe-Image:

```bash
docker build -t tippecanoe-uebung6 Uebung6/tools
```

Gebäude als PMTiles erzeugen:

```bash
mkdir -p Uebung6/tiles
docker run --rm -v "$PWD/Uebung6":/work -w /work tippecanoe-uebung6 \
  tippecanoe \
  -o tiles/buildings.pmtiles -l buildings \
  -Z13 -z16 --no-feature-limit --no-tile-size-limit --force \
  data/buildings.geojson
```

Dasselbe geht für XYZ-Kacheln (unkomprimiert, weil GitHub Pages `.pbf` nicht gzip-komprimiert ausliefert):

```bash
mkdir -p Uebung6/tiles_xyz
docker run --rm -v "$PWD/Uebung6":/work -w /work tippecanoe-uebung6 \
  tippecanoe \
  -e tiles_xyz/buildings -l buildings \
  -Z13 -z16 --no-feature-limit --no-tile-size-limit \
  --no-tile-compression --force data/buildings.geojson
```

Die Bevölkerungsebene wird nur lokal erzeugt und bleibt wegen der `.gitignore` von GitHub Pages ausgeschlossen. Kopiert den gesamten Block im Hauptverzeichnis des Repositorys, um PMTiles und XYZ-Kacheln zu erzeugen:

```bash
mkdir -p Uebung6/tiles Uebung6/tiles_xyz
docker run --rm -v "$PWD/Uebung6":/work -w /work tippecanoe-uebung6 \
  tippecanoe \
  -o tiles/population.pmtiles -l population \
  -Z8 -z15 --no-tile-size-limit --coalesce-densest-as-needed --force \
  data/population.geojson
docker run --rm -v "$PWD/Uebung6":/work -w /work tippecanoe-uebung6 \
  tippecanoe \
  -e tiles_xyz/population -l population \
  -Z8 -z15 --no-tile-size-limit --coalesce-densest-as-needed \
  --no-tile-compression --force data/population.geojson
```

Kein Docker? Alternativ tippecanoe lokal installieren (`brew install tippecanoe` auf macOS, WSL unter Windows) und dieselben tippecanoe-Optionen direkt ausführen.

### Schritt 4 · Veröffentlichen
1. Speichert eure Änderungen in VS Code.
2. Öffnet links **Quellcodeverwaltung** (Symbol mit Verzweigungen). Prüft die angezeigten geänderten Dateien.
3. Klickt neben den Dateien, die ihr veröffentlichen möchtet, auf **+**. Fügt `index.html` und die erzeugten Gebäude-Kacheln hinzu. Fügt keine lokalen Bevölkerungsdaten oder Bevölkerungskacheln hinzu.
4. Gebt oben eine Commit-Nachricht ein, z. B. `Vector Tiles Mainz`, und klickt auf **Commit**.
5. Klickt anschließend auf **Änderungen synchronisieren** (oder **Push**), um den Commit zu GitHub hochzuladen.

Verwendet nicht **Alle Änderungen stagen**, wenn darunter lokale Bevölkerungsdaten angezeigt werden. Die Bevölkerungsebene ist nur für die lokale Übung gedacht; `index.html` erkennt online fehlende Bevölkerungskacheln und blendet diese Ebene aus.

Aktiviert in GitHub unter **Settings → Pages** die Quelle `main` / `(root)`. Nach ein bis zwei Minuten erreicht ihr:

- Webkarte: `https://<user>.github.io/<repo>/`
- PMTiles: `https://<user>.github.io/<repo>/tiles/buildings.pmtiles`
- XYZ: `https://<user>.github.io/<repo>/tiles_xyz/buildings/{z}/{x}/{y}.pbf`
- POI-XYZ: `https://<user>.github.io/<repo>/tiles_xyz/poi/{z}/{x}/{y}.pbf`

### Schritt 5 · Webkarte
Öffnet `index.html` in VS Code mit **Live Server** (**Go Live**). PMTiles benötigen HTTP-Range-Requests und funktionieren nicht, wenn ihr die HTML-Datei direkt als `file://` öffnet. Probiert danach aus:

- Umschalter **PMTiles / XYZ** (beide liefern dieselbe Karte),
- Schaltet Bevölkerung und Gebäude mit den runden Layer-Kästchen unabhängig ein oder aus,
- schaltet die Beschriftung und 3D-Darstellung der jeweiligen Ebene mit den quadratischen Kästchen ein oder aus,
- sobald eine 3D-Darstellung aktiv ist, erscheint nur noch die Beschriftung dieses 3D-Layers; die beiden 3D-Darstellungen schließen sich gegenseitig aus,
- **3D-Säulen** zeigen Einwohnerzahlen (Einwohner × 0,1 m); **3D-Gebäude** zeigen Etagen (Etagen × 3 m),
- **Hover** über eine Bevölkerungszelle zeigt Einwohnerzahl und Dichte; Hover über ein Gebäude zeigt dessen OSM-Tags und die geschätzte Höhe,
- bei Gebäuden ohne Etagenangabe wird für die 3D-Höhe eine Etage angenommen.

Die Seite findet eure Kacheln relativ zum eigenen Pfad, sie funktioniert also lokal und auf GitHub Pages ohne Änderung. Wenn ihr eigene Layer-Namen oder Zoom-Bereiche verwendet habt, passt sie in `index.html` im Block `EBENEN` an.

### Schritt 6 · QGIS
1. **Layer → Layer hinzufügen → Vector-Tiles-Layer → Neu → Neue generische Verbindung**.
2. Typ XYZ, Min. Zoom 13, Max. Zoom 16, URL:

   | Version | URL |
   |---|---|
   | **Online** (GitHub Pages) | `https://<user>.github.io/<repo>/tiles_xyz/buildings/{z}/{x}/{y}.pbf` |
   | **Lokal** (VS Code Live Server) | `http://127.0.0.1:5500/tiles_xyz/buildings/{z}/{x}/{y}.pbf` |

   Die Bevölkerungsebene (`tiles_xyz/population/{z}/{x}/{y}.pbf`, Zoom 8–15) gibt es nur lokal.

   Für die lokale Vorschau der Webkarte öffnet `index.html` in VS Code mit **Live Server** (Rechtsklick → **Open with Live Server**). Ein zusätzlicher Webserver-Container ist nicht nötig.
3. Layer hinzufügen und auf Zoom 13 oder größer zoomen.
4. Stil laden: Layer-Eigenschaften → **Symbolisierung → Stil → Aus Datei laden** → `qgis/test_simple.json`. Alternativ den Stil manuell bauen (Farbe nach `building:levels`).

Hinweis: Feldnamen mit Doppelpunkt schreibt ihr in QGIS in Anführungszeichen, z. B. `"building:levels"`.

## Aufgabe · POIs als Vector Tiles veröffentlichen
Verwendet eure POI-GeoJSON-Datei aus der vorherigen Übung. Kopiert sie im VS Code Explorer nach `Uebung6/data/poi.geojson`. Wählt eine überschaubare Region und entfernt nicht benötigte Attribute. Erzeugt XYZ-Kacheln mit Zoom 10–14; `--drop-densest-as-needed` reduziert die Punktzahl in besonders dichten Kacheln.

Führt den Befehl im Hauptverzeichnis des Repositorys aus:

```bash
mkdir -p Uebung6/tiles_xyz/poi
docker run --rm -v "$PWD/Uebung6":/work -w /work tippecanoe-uebung6 \
  tippecanoe -e tiles_xyz/poi -l poi \
  -Z10 -z14 --drop-densest-as-needed \
  --no-tile-compression --force data/poi.geojson
```

Prüft im VS Code Explorer die Größe von `Uebung6/tiles_xyz/poi` (Rechtsklick → **Reveal in Finder** / **Im Datei-Explorer anzeigen** → **Informationen** / **Eigenschaften**). Ziel: **höchstens 5 MB**. Ist das Kachelset größer, verkleinert die Region, senkt die maximale Zoomstufe oder reduziert die Features/Attribute und erzeugt die Kacheln erneut. Veröffentlicht nur die Kacheln, nicht `data/poi.geojson`.

Fügt `tiles_xyz/poi/` in der VS Code Quellcodeverwaltung zum Commit hinzu und pusht die Änderungen zu GitHub. Fügt keine POI-Quelldatei hinzu. Nach der Veröffentlichung lautet die URL: `https://<user>.github.io/<repo>/tiles_xyz/poi/{z}/{x}/{y}.pbf`. Fügt den Layer in QGIS als XYZ-Verbindung mit Zoomstufen 10–14 hinzu.

## Abgabe

Zeigt eurem Dozenten euren veröffentlichten POI-Vector-Layer in QGIS.

## Häufige Probleme

| Problem | Lösung |
|---|---|
| `Mounts denied` bei Docker | Projekt in einen lokalen Ordner verschieben |
| Karte bleibt leer, PMTiles | Seite mit VS Code Live Server oder über GitHub Pages öffnen, nicht per Doppelklick (`file://`); PMTiles benötigt HTTP-Range-Requests |
| Alte Version im Browser | Hart neu laden (Strg/Cmd + Shift + R) |
| Seite 404 auf GitHub | Pages aktiviert? Branch `main`, Ordner `/ (root)`? |
| Gebäude fehlen bei kleinem Zoom | Kacheln beginnen bei Zoom 13, einfach weiter hineinzoomen |
| Beschriftung fehlt | Schrift kommt von `demotiles.maplibre.org`, Internetzugang nötig |
| QGIS zeigt keine Änderung des Stils | Stil ohne Filter verwenden (`qgis/test_simple.json`), Layer neu laden |

## Datenquellen und Lizenz

- Gebäude: © OpenStreetMap-Mitwirkende, [ODbL](https://www.openstreetmap.org/copyright)
- Bevölkerung: Zensus 2022, © Statistische Ämter des Bundes und der Länder
- Software: [tippecanoe](https://github.com/felt/tippecanoe), [PMTiles](https://github.com/protomaps/PMTiles), [MapLibre GL JS](https://maplibre.org/)
