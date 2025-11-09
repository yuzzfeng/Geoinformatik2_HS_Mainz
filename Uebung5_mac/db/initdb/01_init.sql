CREATE EXTENSION IF NOT EXISTS postgis;
DROP TABLE IF EXISTS places;
CREATE TABLE places (
  id SERIAL PRIMARY KEY,
  name TEXT,
  geom GEOMETRY(Point, 4326)
);

INSERT INTO places (name, geom) VALUES
 ('Beijing', ST_SetSRID(ST_MakePoint(116.4074,39.9042),4326)),
 ('Shanghai', ST_SetSRID(ST_MakePoint(121.4737,31.2304),4326));
