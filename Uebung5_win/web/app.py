from flask import Flask, render_template, jsonify, abort
from sqlalchemy import create_engine, text
from sqlalchemy.exc import ProgrammingError
import json
import os

app = Flask(__name__)

# Datenbank-URL aus Umgebungsvariable lesen (db = Container-Name als Host)
DB_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/postgres")
engine = create_engine(DB_URL, pool_pre_ping=True)

@app.get("/")
def home():
    # Rendert /templates/index.html
    return render_template("index.html")

@app.get("/api/health")
def health():
    return jsonify({"ok": True})

@app.get("/api/places")
def places():
    with engine.connect() as conn:
        rows = conn.execute(text("""
            SELECT id, name, ST_AsGeoJSON(geom) AS geom
            FROM places ORDER BY id
        """)).mappings().all()      # rows: list[RowMapping]
    data = [{"id": r["id"], "name": r["name"], "geom": r["geom"]} for r in rows]
    return jsonify(data)

def _detect_geom_column(conn, table_name: str) -> str | None:
    # Prefer explicit names, then fallback to geometry_columns
    for candidate in ("geom", "wkb_geometry"):
        q = text("""
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='public' AND table_name=:t AND column_name=:c
            LIMIT 1
        """)
        if conn.execute(q, {"t": table_name, "c": candidate}).scalar() == 1:
            return candidate
    # Fallback via geometry_columns view
    try:
        gc = conn.execute(text("""
            SELECT f_geometry_column FROM geometry_columns
            WHERE f_table_schema='public' AND f_table_name=:t LIMIT 1
        """), {"t": table_name}).scalar()
        if gc:
            return gc
    except ProgrammingError:
        pass
    return None

@app.get("/api/table/<table_name>")
def api_table(table_name: str):
    # Return GeoJSON FeatureCollection for a given table in public schema
    with engine.connect() as conn:
        geom_col = _detect_geom_column(conn, table_name)
        if not geom_col:
            abort(404, description=f"No geometry column found for table '{table_name}'")

        # Build a dynamic SELECT: all props except geometry, plus geojson geometry
        # Fetch column list
        cols = conn.execute(text("""
            SELECT column_name FROM information_schema.columns
            WHERE table_schema='public' AND table_name=:t
        """), {"t": table_name}).scalars().all()
        prop_cols = [c for c in cols if c != geom_col]
        props_sql = ", ".join([f'"{c}"' for c in prop_cols]) or ""
        select_sql = f"SELECT {props_sql + (', ' if props_sql else '')} ST_AsGeoJSON(\"{geom_col}\") AS __geojson FROM \"{table_name}\""

        rows = conn.execute(text(select_sql)).mappings().all()

    features = []
    for r in rows:
        geom_json = r.get("__geojson")
        try:
            geometry = json.loads(geom_json) if geom_json else None
        except Exception:
            geometry = None
        properties = {k: v for k, v in r.items() if k != "__geojson"}
        features.append({
            "type": "Feature",
            "geometry": geometry,
            "properties": properties,
        })
    return jsonify({"type": "FeatureCollection", "features": features})

@app.get("/api/points")
def api_points():
    # Convenience alias for the common imported table 'points'
    return api_table("points")

if __name__ == "__main__":
    # Direkt mit Python starten (ohne flask CLI)
    app.run(host="0.0.0.0", port=5000)
