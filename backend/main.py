"""
main.py - Village Land Mapping API
FastAPI backend with PostGIS spatial queries

Endpoints:
  POST /api/fields           - Naya khet register karo
  GET  /api/fields           - Saare khet dekho
  GET  /api/fields/{id}      - Ek khet ki detail dekho
  GET  /api/fields/nearby    - Aas-paas ke khet dekho
  GET  /api/fields/containing - Kya main kisi khet pe khada hoon?
  POST /api/fields/import-geojson - GeoJSON se khet import karo
  DELETE /api/fields/{id}    - Khet delete karo
  GET  /api/gmaps/plot-info  - Google Maps location se plot info lo
"""

import os
import json
from typing import Optional, List
from datetime import datetime

from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel, Field
import shapely.geometry as sg
from shapely.ops import transform
import pyproj

from database import Field as FieldModel, get_db, create_tables, ensure_database_exists

# ─────────────────────── App Setup ───────────────────────
app = FastAPI(
    title="🌾 Village Land Mapping API",
    description="Apne gaon ke khetton ki GPS boundary map karo, area-dimension jaano",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Allow all origins so Flutter app can connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────── Constants ───────────────────────
BIGHA_SQM = 2529.3    # 1 bigha = 2529.3 sqm (UP/Bihar standard)
ACRE_SQM = 4046.86    # 1 acre = 4046.86 sqm
GMAPS_API_KEY = os.getenv("GMAPS_API_KEY", "")

# ─────────────────────── Pydantic Schemas ───────────────────────
class CreateFieldRequest(BaseModel):
    name: str = Field(..., description="Khet ka naam (Field name)")
    owner_name: str = Field(..., description="Malik ka naam (Owner name)")
    khasra_number: Optional[str] = Field(None, description="Khasra/Survey number")
    coordinates: List[List[float]] = Field(
        ...,
        description="GPS coordinates [[lon1,lat1],[lon2,lat2],...,[lon1,lat1]] - first and last must be same to close the polygon"
    )

class FieldResponse(BaseModel):
    id: int
    name: str
    owner_name: str
    khasra_number: Optional[str]
    area_sqm: Optional[float]
    area_bigha: Optional[float]
    area_acre: Optional[float]
    perimeter_m: Optional[float]
    boundary_geojson: Optional[dict]
    created_at: Optional[datetime]

    class Config:
        from_attributes = True

class NearbyFieldResponse(BaseModel):
    id: int
    name: str
    owner_name: str
    khasra_number: Optional[str]
    area_bigha: Optional[float]
    area_sqm: Optional[float]
    distance_m: float

class ContainingResponse(BaseModel):
    found: bool
    message: str
    field: Optional[FieldResponse] = None

# ─────────────────────── Helper Functions ───────────────────────
def calculate_area_and_perimeter(coordinates: List[List[float]]):
    """
    Shapely aur PyProj se area (sqm) aur perimeter (meters) calculate karo.
    WGS84 lat/lon se UTM projection mein convert karke accurate calculation.
    """
    # Close the polygon if not closed
    coords = coordinates[:]
    if coords[0] != coords[-1]:
        coords.append(coords[0])

    polygon_wgs84 = sg.Polygon(coords)

    # Find UTM zone based on centroid longitude
    centroid = polygon_wgs84.centroid
    utm_zone = int((centroid.x + 180) / 6) + 1
    hemisphere = "north" if centroid.y >= 0 else "south"

    wgs84 = pyproj.CRS("EPSG:4326")
    utm = pyproj.CRS(f"+proj=utm +zone={utm_zone} +{hemisphere} +ellps=WGS84")

    project = pyproj.Transformer.from_crs(wgs84, utm, always_xy=True).transform
    polygon_utm = transform(project, polygon_wgs84)

    area_sqm = polygon_utm.area
    perimeter_m = polygon_utm.length

    return area_sqm, perimeter_m


def coordinates_to_wkt(coordinates: List[List[float]]) -> str:
    """Convert [[lon,lat],...] list to WKT POLYGON string."""
    coords = coordinates[:]
    if coords[0] != coords[-1]:
        coords.append(coords[0])
    coord_str = ", ".join(f"{lon} {lat}" for lon, lat in coords)
    return f"POLYGON(({coord_str}))"


def field_to_response(field: FieldModel, db: Session) -> dict:
    """Convert DB model to response dict with GeoJSON boundary."""
    # Get boundary as GeoJSON from PostGIS
    geojson_str = db.execute(
        text("SELECT ST_AsGeoJSON(boundary) FROM fields WHERE id = :id"),
        {"id": field.id}
    ).scalar()
    boundary_geojson = json.loads(geojson_str) if geojson_str else None

    return {
        "id": field.id,
        "name": field.name,
        "owner_name": field.owner_name,
        "khasra_number": field.khasra_number,
        "area_sqm": round(field.area_sqm, 2) if field.area_sqm else None,
        "area_bigha": round(field.area_bigha, 4) if field.area_bigha else None,
        "area_acre": round(field.area_acre, 4) if field.area_acre else None,
        "perimeter_m": round(field.perimeter_m, 2) if field.perimeter_m else None,
        "boundary_geojson": boundary_geojson,
        "created_at": field.created_at,
    }


# ─────────────────────── Startup ───────────────────────
@app.on_event("startup")
def on_startup():
    ensure_database_exists()
    create_tables()
    print("🌾 Village Land Mapping API is ready!")
    print("📖 API Docs: http://localhost:8000/docs")


# ─────────────────────── Routes ───────────────────────
@app.get("/", tags=["Info"])
def root():
    return {
        "message": "🌾 Village Land Mapping API - Zameen Naksha",
        "docs": "http://localhost:8000/docs",
        "status": "running"
    }


@app.post("/api/fields", tags=["Fields"])
def create_field(body: CreateFieldRequest, db: Session = Depends(get_db)):
    """
    Naya khet register karo.
    GPS coordinates ki list do, baaki sab auto-calculate hoga:
    - Area in Bigha, Acre, Square Meters
    - Perimeter in meters
    """
    if len(body.coordinates) < 3:
        raise HTTPException(status_code=400, detail="Kam se kam 3 GPS points chahiye polygon banane ke liye.")

    wkt = coordinates_to_wkt(body.coordinates)
    area_sqm, perimeter_m = calculate_area_and_perimeter(body.coordinates)

    field = FieldModel(
        name=body.name,
        owner_name=body.owner_name,
        khasra_number=body.khasra_number,
        boundary=f"SRID=4326;{wkt}",
        area_sqm=area_sqm,
        area_bigha=area_sqm / BIGHA_SQM,
        area_acre=area_sqm / ACRE_SQM,
        perimeter_m=perimeter_m,
    )
    db.add(field)
    db.commit()
    db.refresh(field)

    return {"success": True, "field": field_to_response(field, db)}


@app.get("/api/fields", tags=["Fields"])
def list_fields(db: Session = Depends(get_db)):
    """Gaon ke saare registered khetton ki list dekho."""
    fields = db.query(FieldModel).order_by(FieldModel.created_at.desc()).all()
    return [field_to_response(f, db) for f in fields]


@app.get("/api/fields/nearby", tags=["Fields"])
def get_nearby_fields(
    lat: float = Query(..., description="Aapki latitude"),
    lon: float = Query(..., description="Aapki longitude"),
    radius_m: float = Query(1000.0, description="Kitni door tak dhundhe (meters mein)"),
    db: Session = Depends(get_db)
):
    """
    Aapki current location ke aas-paas ke saare khet dikhao.
    ST_DWithin use karke PostGIS se spatial query karte hain.
    """
    results = db.execute(
        text("""
            SELECT f.id, f.name, f.owner_name, f.khasra_number, f.area_bigha, f.area_sqm,
                   ST_Distance(
                       f.boundary::geography,
                       ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
                   ) as distance_m
            FROM fields f
            WHERE ST_DWithin(
                f.boundary::geography,
                ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
                :radius_m
            )
            ORDER BY distance_m ASC
        """),
        {"lat": lat, "lon": lon, "radius_m": radius_m}
    ).fetchall()

    return [
        {
            "id": r.id,
            "name": r.name,
            "owner_name": r.owner_name,
            "khasra_number": r.khasra_number,
            "area_bigha": round(r.area_bigha, 4) if r.area_bigha else None,
            "area_sqm": round(r.area_sqm, 2) if r.area_sqm else None,
            "distance_m": round(r.distance_m, 1),
        }
        for r in results
    ]


@app.get("/api/fields/containing", tags=["Fields"])
def get_field_at_location(
    lat: float = Query(..., description="Aapki latitude"),
    lon: float = Query(..., description="Aapki longitude"),
    db: Session = Depends(get_db)
):
    """
    Check karo: kya main abhi kisi registered khet pe khada hoon?
    ST_Contains PostGIS function use hota hai.
    """
    result = db.execute(
        text("""
            SELECT id FROM fields
            WHERE ST_Contains(
                boundary,
                ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)
            )
            LIMIT 1
        """),
        {"lat": lat, "lon": lon}
    ).fetchone()

    if not result:
        return {"found": False, "message": "Aap abhi kisi registered khet par khade nahi hain.", "field": None}

    field = db.query(FieldModel).filter(FieldModel.id == result.id).first()
    return {
        "found": True,
        "message": f"Aap '{field.name}' khet par khade hain!",
        "field": field_to_response(field, db)
    }


@app.get("/api/fields/{field_id}", tags=["Fields"])
def get_field(field_id: int, db: Session = Depends(get_db)):
    """Ek specific khet ki poori detail dekho."""
    field = db.query(FieldModel).filter(FieldModel.id == field_id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Yeh khet nahi mila.")
    return field_to_response(field, db)


@app.delete("/api/fields/{field_id}", tags=["Fields"])
def delete_field(field_id: int, db: Session = Depends(get_db)):
    """Ek khet ka record delete karo."""
    field = db.query(FieldModel).filter(FieldModel.id == field_id).first()
    if not field:
        raise HTTPException(status_code=404, detail="Yeh khet nahi mila.")
    db.delete(field)
    db.commit()
    return {"success": True, "message": f"'{field.name}' successfully delete ho gaya."}


@app.post("/api/fields/import-geojson", tags=["Fields"])
def import_geojson(geojson: dict, db: Session = Depends(get_db)):
    """
    GeoJSON Feature ya FeatureCollection se khet import karo.
    Bhu-Naksha ya Google Earth exported KML/GeoJSON files se directly import kar sakte ho.
    """
    imported = []

    def process_feature(feature: dict):
        geom = feature.get("geometry", {})
        props = feature.get("properties", {}) or {}

        if geom.get("type") != "Polygon":
            return None

        coords_raw = geom.get("coordinates", [[]])
        coordinates = coords_raw[0]  # Outer ring

        name = props.get("name") or props.get("Name") or props.get("FIELD_NAME") or "Imported Field"
        owner = props.get("owner") or props.get("OWNER") or props.get("owner_name") or "Unknown"
        khasra = props.get("khasra") or props.get("KHASRA") or props.get("khasra_number")

        wkt = coordinates_to_wkt(coordinates)
        area_sqm, perimeter_m = calculate_area_and_perimeter(coordinates)

        field = FieldModel(
            name=name,
            owner_name=owner,
            khasra_number=khasra,
            boundary=f"SRID=4326;{wkt}",
            area_sqm=area_sqm,
            area_bigha=area_sqm / BIGHA_SQM,
            area_acre=area_sqm / ACRE_SQM,
            perimeter_m=perimeter_m,
        )
        db.add(field)
        db.commit()
        db.refresh(field)
        return field_to_response(field, db)

    if geojson.get("type") == "FeatureCollection":
        for feature in geojson.get("features", []):
            result = process_feature(feature)
            if result:
                imported.append(result)
    elif geojson.get("type") == "Feature":
        result = process_feature(geojson)
        if result:
            imported.append(result)
    else:
        raise HTTPException(status_code=400, detail="Valid GeoJSON Feature ya FeatureCollection chahiye.")

    return {"success": True, "imported_count": len(imported), "fields": imported}


@app.get("/api/gmaps/plot-info", tags=["Google Maps"])
def gmaps_plot_info(
    lat: float = Query(..., description="Google Maps se li gayi latitude"),
    lon: float = Query(..., description="Google Maps se li gayi longitude"),
    db: Session = Depends(get_db)
):
    """
    Google Maps link se lat/lon lekar:
    1. Is location par koi registered khet hai kya (ST_Contains)
    2. 200m ke andar kaunse khet hain (ST_DWithin)
    3. Agar GMAPS_API_KEY set hai to address bhi return karo
    Returns location info and nearby registered plots.
    """
    import urllib.request

    response = {
        "queried_location": {"lat": lat, "lon": lon},
        "address": None,
        "standing_on": None,
        "nearby_fields": []
    }

    # Geocoding (only if API key is set)
    if GMAPS_API_KEY:
        try:
            url = (
                f"https://maps.googleapis.com/maps/api/geocode/json"
                f"?latlng={lat},{lon}&key={GMAPS_API_KEY}"
            )
            with urllib.request.urlopen(url, timeout=5) as r:
                data = json.loads(r.read())
            if data.get("results"):
                response["address"] = data["results"][0].get("formatted_address")
        except Exception:
            pass

    # Check if standing on a field
    on_field = db.execute(
        text("""
            SELECT id, name, owner_name, area_bigha FROM fields
            WHERE ST_Contains(boundary, ST_SetSRID(ST_MakePoint(:lon, :lat), 4326))
            LIMIT 1
        """),
        {"lat": lat, "lon": lon}
    ).fetchone()

    if on_field:
        response["standing_on"] = {
            "id": on_field.id,
            "name": on_field.name,
            "owner_name": on_field.owner_name,
            "area_bigha": round(on_field.area_bigha, 4) if on_field.area_bigha else None,
        }

    # Nearby within 200m
    nearby = db.execute(
        text("""
            SELECT f.id, f.name, f.owner_name, f.area_bigha,
                   ST_Distance(f.boundary::geography,
                       ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography) as distance_m
            FROM fields f
            WHERE ST_DWithin(
                f.boundary::geography,
                ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
                200
            )
            ORDER BY distance_m ASC
        """),
        {"lat": lat, "lon": lon}
    ).fetchall()

    response["nearby_fields"] = [
        {
            "id": r.id,
            "name": r.name,
            "owner_name": r.owner_name,
            "area_bigha": round(r.area_bigha, 4) if r.area_bigha else None,
            "distance_m": round(r.distance_m, 1),
        }
        for r in nearby
    ]

    return response
