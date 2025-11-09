# Geodaten für GeoServer

Legen Sie hier Ihre eigenen Daten ab – sie werden automatisch veröffentlicht:
- Beliebige `*.tif`/`*.tiff` (GeoTIFF) → WMS (als Layer `uebung:<Dateiname>`)
- Beliebige `*.geojson` → WFS (als Layer `uebung:<Dateiname>`, SRS=EPSG:4326)

Hinweise:
- Dateien werden read-only in den GeoServer-Container gemountet (`/data`).
- Achten Sie auf das Koordinatenbezugssystem. Für Vektor (WFS) wird EPSG:4326 erwartet.
- Große Raster (> 200 MB) können initial langsamer sein. Bei Bedarf können Sie vorab mit `gdal_translate` Pyramiden und Kompression (z. B. LZW/DEFLATE) anwenden.
