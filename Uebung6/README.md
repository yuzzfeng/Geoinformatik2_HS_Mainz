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
| `compose.yaml` | Docker Compose-Konfiguration für tippecanoe und lokalen Webserver |
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

### Schritt 3 · Kacheln mit Docker Compose erzeugen
Öffnet ein Terminal im Ordner des geklonten Repositories. Das tippecanoe-Image wird beim ersten Mal gebaut und kann danach wiederverwendet werden:

```bash
docker compose build tippecanoe
```

PMTiles für die Gebäude erzeugen:

```bash
docker compose run --rm tippecanoe \
  -o tiles/buildings.pmtiles -l buildings \
  -Z13 -z16 --no-feature-limit --no-tile-size-limit --force \
  data/buildings.geojson
```

Danach dieselben Daten als XYZ-Ordner (unkomprimiert, weil GitHub Pages `.pbf` nicht gzip-komprimiert ausliefert):

```bash
mkdir -p tiles_xyz
docker compose run --rm tippecanoe \
  -e tiles_xyz/buildings -l buildings \
  -Z13 -z16 --no-feature-limit --no-tile-size-limit \
  --no-tile-compression --force data/buildings.geojson
```

Erzeugt die Bevölkerungsebene lokal entsprechend mit `-l population`, `-Z8 -z15` und `--coalesce-densest-as-needed`. Beispiel für PMTiles:

```bash
docker compose run --rm tippecanoe \
  -o tiles/population.pmtiles -l population \
  -Z8 -z15 --no-tile-size-limit --coalesce-densest-as-needed --force \
  data/population.geojson
```

Kein Docker? Alternativ tippecanoe lokal installieren (`brew install tippecanoe` auf macOS, WSL unter Windows) und dieselben tippecanoe-Optionen direkt ausführen.

### Schritt 4 · Parameter untersuchen
Erzeugt die Gebäude-Kacheln ein zweites Mal, aber mit `--drop-densest-as-needed` statt `--no-feature-limit --no-tile-size-limit`, unter anderem Namen (z. B. `buildings_test.pmtiles`).

Beantwortet:
1. Wie groß sind die beiden Dateien?
2. Wie viele Gebäude sind bei Zoom 13 in der Karte sichtbar? Vergleicht beide Varianten.
3. Warum sind Vector Tiles **verlustbehaftet**? Was passiert mit Objekten, wenn eine Kachel zu groß wird?
4. Welche Wahl von `-Z` und `-z` ist für Gebäude sinnvoll, welche für ein Gitter mit 100-m-Zellen?

### Schritt 5 · Veröffentlichen
```bash
git add .
git commit -m "Vector Tiles Mainz"
git push
```
Die `.gitignore` schließt die Bevölkerungsebene aus: Sie bleibt **lokal**, online gibt es nur die Gebäude. `index.html` erkennt das selbst und zeigt lokal beide Ebenen, online nur „Gebäude“.

Aktiviert in GitHub unter **Settings → Pages** die Quelle `main` / `(root)`. Nach ein bis zwei Minuten erreicht ihr:

- Webkarte: `https://<user>.github.io/<repo>/`
- PMTiles: `https://<user>.github.io/<repo>/tiles/buildings.pmtiles`
- XYZ: `https://<user>.github.io/<repo>/tiles_xyz/buildings/{z}/{x}/{y}.pbf`

### Schritt 6 · Webkarte
Öffnet eure Seite und probiert aus:

- Umschalter **PMTiles / XYZ** (beide liefern dieselbe Karte),
- **Hover** über Gebäude: alle OSM-Tags erscheinen,
- **Beschriftung** (ab Zoom 17): Hausnummer oder Name, direkt aus den Kachel-Attributen,
- **3D-Gebäude**: Höhe = Etagen × 3 m, aus denselben Kacheln.

Die Seite findet eure Kacheln relativ zum eigenen Pfad, sie funktioniert also lokal und auf GitHub Pages ohne Änderung. Wenn ihr eigene Layer-Namen oder Zoom-Bereiche verwendet habt, passt sie in `index.html` im Block `EBENEN` an.

### Schritt 7 · QGIS
1. **Layer → Layer hinzufügen → Vector-Tiles-Layer → Neu → Neue generische Verbindung**.
2. Typ XYZ, Min. Zoom 13, Max. Zoom 16, URL:

   | Version | URL |
   |---|---|
   | **Online** (GitHub Pages) | `https://<user>.github.io/<repo>/tiles_xyz/buildings/{z}/{x}/{y}.pbf` |
   | **Lokal** (nginx auf Port 8080) | `http://localhost:8080/tiles_xyz/buildings/{z}/{x}/{y}.pbf` |

   Die Bevölkerungsebene (`tiles_xyz/population/{z}/{x}/{y}.pbf`, Zoom 8–15) gibt es nur lokal.

   Lokalen Webserver mit Docker Compose starten (im Projektordner):
   ```bash
   docker compose up -d web
   ```
   Die Dateien sind dann unter `http://localhost:8080/` erreichbar. Zum Stoppen: `docker compose down`.
3. Layer hinzufügen und auf Zoom 13 oder größer zoomen.
4. Stil laden: Layer-Eigenschaften → **Symbolisierung → Stil → Aus Datei laden** → `qgis/test_simple.json`. Alternativ den Stil manuell bauen (Farbe nach `building:levels`).

Hinweis: Feldnamen mit Doppelpunkt schreibt ihr in QGIS in Anführungszeichen, z. B. `"building:levels"`.

## Abgabe

- Link zu eurem GitHub-Repository und zur Webkarte,
- Screenshot der Webkarte (3D oder Beschriftung),
- Screenshot aus QGIS mit eingefärbten Gebäuden,
- kurze Antworten zu den Fragen aus Schritt 4.

## Häufige Probleme

| Problem | Lösung |
|---|---|
| `Mounts denied` bei Docker | Projekt in einen lokalen Ordner verschieben |
| Karte bleibt leer, PMTiles | Seite über `http(s)://` öffnen, nicht per Doppelklick (`file://`); lokal z. B. mit nginx, denn `python -m http.server` unterstützt keine Range-Requests |
| Alte Version im Browser | Hart neu laden (Strg/Cmd + Shift + R) |
| Seite 404 auf GitHub | Pages aktiviert? Branch `main`, Ordner `/ (root)`? |
| Gebäude fehlen bei kleinem Zoom | Kacheln beginnen bei Zoom 13, einfach weiter hineinzoomen |
| Beschriftung fehlt | Schrift kommt von `demotiles.maplibre.org`, Internetzugang nötig |
| QGIS zeigt keine Änderung des Stils | Stil ohne Filter verwenden (`qgis/test_simple.json`), Layer neu laden |

## Datenquellen und Lizenz

- Gebäude: © OpenStreetMap-Mitwirkende, [ODbL](https://www.openstreetmap.org/copyright)
- Bevölkerung: Zensus 2022, © Statistische Ämter des Bundes und der Länder
- Software: [tippecanoe](https://github.com/felt/tippecanoe), [PMTiles](https://github.com/protomaps/PMTiles), [MapLibre GL JS](https://maplibre.org/)
