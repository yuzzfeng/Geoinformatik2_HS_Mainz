from flask import Flask, render_template, jsonify
from sqlalchemy import create_engine, text
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

if __name__ == "__main__":
    # Direkt mit Python starten (ohne flask CLI)
    app.run(host="0.0.0.0", port=5000)
