"""Verify that Mainz is enabled and GeoServer can render it as a PNG."""
import base64
import json
import os
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

base = os.getenv("GEOSERVER_URL", "http://geoserver:8080/geoserver").rstrip("/")
credentials = "{}:{}".format(os.getenv("GEOSERVER_ADMIN_USER", "admin"),
                             os.getenv("GEOSERVER_ADMIN_PASSWORD", "geoserver"))
auth = "Basic " + base64.b64encode(credentials.encode()).decode()


def get(path):
    request = Request(base + path, headers={"Authorization": auth})
    with urlopen(request, timeout=30) as response:
        return response.read()


def verify():
    layer = json.loads(get("/rest/layers/uebung:mainz.json"))["layer"]
    if layer.get("enabled") is False:
        raise ValueError("uebung:mainz is disabled")
    coverage = json.loads(get(
        "/rest/workspaces/uebung/coveragestores/mainz/coverages/mainz.json"
    ))["coverage"]
    if coverage.get("enabled") is False:
        raise ValueError("Mainz coverage is disabled")
    bounds = coverage["latLonBoundingBox"]
    bbox = [float(bounds[key]) for key in ("minx", "miny", "maxx", "maxy")]
    if not (bbox[0] < bbox[2] and bbox[1] < bbox[3]):
        raise ValueError("Mainz has invalid geographic bounds")
    query = urlencode({"service": "WMS", "version": "1.1.1",
                       "request": "GetMap", "layers": "uebung:mainz",
                       "styles": "", "srs": "EPSG:4326",
                       "bbox": ",".join(map(str, bbox)), "width": 256,
                       "height": 256, "format": "image/png"})
    rendered = get("/uebung/wms?" + query)
    # GeoServer may return an XML exception with HTTP 200.
    if not rendered.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("WMS returned no PNG: " + rendered[:400].decode(errors="replace"))


if __name__ == "__main__":
    for attempt in range(1, 6):
        try:
            verify()
            print("Verified: uebung:mainz is enabled and WMS GetMap returns a PNG.")
            break
        except (HTTPError, URLError, TimeoutError, ValueError, KeyError) as error:
            print(f"Mainz verification {attempt}/5 failed: {error}", file=sys.stderr)
            if attempt == 5:
                sys.exit(1)
            time.sleep(3)
