Geoinformatik 2 – Web-GIS
# Übung 3 · Webkarte mit APIs and SDKs
Prof. Dr. Yu Feng

## Lernziele
Nach dieser Übung können Sie:
- mit **Folium** (Leaflet in Python) eine interaktive Karte erzeugen,
- **Punkte**, **Linien** und **Flächen (GeoJSON/Polygon)** visualisieren,
- Popups/Tooltips und LayerControl nutzen,
- andere Webkarten in die eigene Webseite einbinden

## Aufgabe 1 - Webkarte mit Folium/Python
- Colab Notebook https://drive.google.com/file/d/1Tt8KefdDQxWbimkvMBNkVWvVIC6xYv4D/view?usp=sharing



## Aufgabe 2 - Webkarten in eigene Webseite einbinden

Wenn Sie die mit Folium erzeugten HTML-Dateien (z. B. `maps/map_1_basiskarte.html`) auf einer eigenen Seite einbinden möchten, verwenden Sie ein `<iframe>`:

- Auf GitHub Pages lautet die URL typischerweise:  
  `https://<IhrGitHubName>.github.io/Geoinformatik2_HS_Mainz/Uebung3/maps/map_1_basiskarte.html`
- Alternativ können Sie die HTML-Datei auf jeden beliebigen Webspace hochladen und den Pfad entsprechend anpassen.


## Aufgabe 3 - Deutschland 3D-Gebäude mit Cesium einbinden

Hier gibt es einen 3D‑Gebäudelayer für ganz Deutschland. Bitte binden Sie ihn mit **Cesium** in Ihre eigene Webseite ein.

- Info/Quelle: https://basemap.de/produkte-und-dienste/3d/


## Aufgabe 4 - Erweiterte Webvisualisierung mit weiteren APIs

Nutzen Sie zusätzlich zu Leaflet/Cesium weitere Bibliotheken, die wir im Kurs besprochen haben, um anspruchsvollere Visualisierungen zu erstellen. Beispiele:

- Kepler.gl
  - Interaktive Explorationskarten ohne Programmierung
  - Vorgehen: Karte in Kepler.gl erstellen → Export → "Export Map" → "HTML" → die exportierte HTML in dieses Repo legen (z. B. `Uebung3/assets/kepler_map.html`) und per `<iframe>` einbinden.
  - Links: https://kepler.gl/

- Three.js
  - Für eigene 3D-Visualisierungen (Extrusionen, Partikel, Animationen)
  - Typische Wege: GeoJSON einlesen → in Three.js-Geometrie konvertieren → Materialien/Beleuchtung/Kamera konfigurieren
  - Startpunkte: https://threejs.org/ (Docs, Beispiele)

## Beispiel-Output

- https://yuzzfeng.github.io/Geoinformatik2_HS_Mainz/Uebung3/ 

## Erwartete Karten

<table>
  <tr>
    <td>
      <a target="_blank" rel="noopener" href="https://nbviewer.org/github/yuzzfeng/Geoinformatik2_HS_Mainz/blob/main/Uebung3/maps/map_1_basiskarte.html">
        <img src="previews/map_1.png" alt="Basiskarte" width="100%">
      </a>
      <p align="center"><em>1) Basiskarte</em></p>
    </td>
    <td>
      <a target="_blank" rel="noopener" href="https://nbviewer.org/github/yuzzfeng/Geoinformatik2_HS_Mainz/blob/main/Uebung3/maps/map_2_punkte.html">
        <img src="previews/map_2.png" alt="Punkte (Marker)" width="100%">
      </a>
      <p align="center"><em>2) Punkte (Marker)</em></p>
    </td>
  </tr>
  <tr>
    <td>
      <a target="_blank" rel="noopener" href="https://nbviewer.org/github/yuzzfeng/Geoinformatik2_HS_Mainz/blob/main/Uebung3/maps/map_3_reiseroute.html">
        <img src="previews/map_3.png" alt="Reiseroute (Polyline)" width="100%">
      </a>
      <p align="center"><em>3) Reiseroute (Polyline)</em></p>
    </td>
    <td>
      <a target="_blank" rel="noopener" href="https://nbviewer.org/github/yuzzfeng/Geoinformatik2_HS_Mainz/blob/main/Uebung3/maps/map_4_flaechen_online.html">
        <img src="previews/map_4.png" alt="Flächen (GeoJSON)" width="100%">
      </a>
      <p align="center"><em>4) Flächen (GeoJSON)</em></p>
    </td>
  </tr>
  <tr>
    <td>
      <a target="_blank" rel="noopener" href="https://nbviewer.org/github/yuzzfeng/Geoinformatik2_HS_Mainz/blob/main/Uebung3/maps/map_5_3d.html">
        <img src="previews/map_5.png" alt="Reiseroute (Polyline)" width="100%">
      </a>
      <p align="center"><em>5) 3D Stadt</em></p>
    </td>
  </tr>
</table>