import argparse
import random
import datetime
from ckanapi import RemoteCKAN
from shapely.geometry import Point, LineString, Polygon
from typing import Literal
import os
import subprocess

CKAN_URL = "http://localhost:5000"
API_KEY = os.environ['CKAN_API_KEY']
ORG_NAME = "test-org"
PACKAGE_NAME = "test-spatial-package"

GEOMETRY_TYPES = {"Point", "LineString", "Polygon"}

TORONTO_BOUNDS = {
    "minx": -79.6393,
    "maxx": -79.1169,
    "miny": 43.5804,
    "maxy": 43.8554
}

def random_point() -> Point:
    return Point(
        random.uniform(TORONTO_BOUNDS["minx"], TORONTO_BOUNDS["maxx"]),
        random.uniform(TORONTO_BOUNDS["miny"], TORONTO_BOUNDS["maxy"])
    )

def random_geometry(geometry_type: Literal["Point", "LineString", "Polygon"]):
    if geometry_type == "Point":
        return random_point()
    elif geometry_type == "LineString":
        return LineString([random_point() for _ in range(3)])
    elif geometry_type == "Polygon":
        points = [random_point() for _ in range(5)]
        return Polygon(points + [points[0]])  # Close the polygon

def create_org() -> None:
    ckan = RemoteCKAN(CKAN_URL, apikey=API_KEY)
    org = {
        "name": ORG_NAME,
        "title": "Test Organization"
    }
    ckan.action.organization_create(**org)
    print(f"Created organization: {ORG_NAME}")

def create_package() -> None:
    ckan = RemoteCKAN(CKAN_URL, apikey=API_KEY)
    package = {
        "name": PACKAGE_NAME,
        "title": "Test Spatial Package",
        "private": False,
        "owner_org": ORG_NAME,
        "url": f"{CKAN_URL}/dataset/test-spatial-package",
    }
    ckan.action.package_create(**package)
    print(f"Created package: {PACKAGE_NAME}")

def create_spatial_resource(
        geometry_type: Literal["Point", "LineString", "Polygon"],
        name:str,
        rows: int = 1000,
    ) -> None:
    if geometry_type not in GEOMETRY_TYPES:
        raise ValueError(f"Invalid geometry type. Must be one of {GEOMETRY_TYPES}")
    
    ckan = RemoteCKAN(CKAN_URL, apikey=API_KEY)
    
    resource = ckan.action.resource_create(
        package_id=PACKAGE_NAME,
        name=f"{name} ({geometry_type})",
        format="GeoJSON",
        url=f"{CKAN_URL}/{PACKAGE_NAME}/{geometry_type}/{name}",
    )
    
    resource_id = resource["id"]
    geometry_col_name = "geometry"
    fields = [
        {"id": "when", "type": "timestamp"},
        {"id": "value", "type": "float"},
        {"id": geometry_col_name, "type": f"geometry({geometry_type}, 4326)"}
    ]
    
    data = [
        {
            "when": (datetime.datetime.utcnow() - datetime.timedelta(days=random.randint(0, 365))).isoformat(),
            "value": random.uniform(0, 100),
            geometry_col_name: random_geometry(geometry_type).wkt
        }
        for _ in range(rows)
    ]
    
    ckan.action.datastore_create(
        resource_id=resource_id,
        fields=fields,
        records=data,
        force=True
    )
    create_spatial_index("public", resource_id, geometry_col_name)
    print(f"Created spatial resource with {rows} rows of {geometry_type} data.")


def create_spatial_index(schema:str, table:str, column:str):
    create_index_cmd = (
        "CREATE INDEX geom_idx "
        f"ON {schema}.\"{table}\" "
        f"USING GIST (\"{column}\");"
    )
    here = os.path.dirname(__file__)
    psql_datastore_write = os.path.join(here, "psql-datastore-write")
    subprocess.check_output(
        [
            psql_datastore_write,
            "-c",
            create_index_cmd
        ], stderr=subprocess.STDOUT
    )

def create_non_spatial_resource(name:str, rows: int = 1000) -> None:
    ckan = RemoteCKAN(CKAN_URL, apikey=API_KEY)
    
    resource = ckan.action.resource_create(
        package_id=PACKAGE_NAME,
        name=f'{name} (non-spatial)',
        url=f"{CKAN_URL}/{PACKAGE_NAME}/non-spatial/{name}",
    )
    
    resource_id = resource["id"]
    fields = [
        # {"id": "when", "type": "timestamp"},
        {"id": "value", "type": "numeric"},
    ]
    
    data = [
        {
            # "when": (datetime.datetime.utcnow() - datetime.timedelta(days=random.randint(0, 365))).isoformat(" "),
            "value": random.uniform(0, 100),
        }
        for _ in range(rows)
    ]
    
    ckan.action.datastore_create(
        resource_id=resource_id,
        fields=fields,
        records=data,
        force=True
    )
    print(f"Created non-spatial resource with {rows} rows of data.")

def purge() -> None:
    ckan = RemoteCKAN(CKAN_URL, apikey=API_KEY)
    try:
        package = ckan.action.package_show(id=PACKAGE_NAME)
    except Exception:
        print(f"Package {PACKAGE_NAME} not found.")
        return
    
    for resource in package.get("resources", []):
        ckan.action.resource_delete(id=resource["id"])
        ckan.action.datastore_delete(resource_id=resource["id"], force=True)
    
    ckan.action.package_delete(id=PACKAGE_NAME)
    print(f"Purged package {PACKAGE_NAME} and associated resources.")
    
    try:
        ckan.action.organization_delete(id=ORG_NAME)
        print(f"Purged organization {ORG_NAME}.")
    except Exception:
        print(f"Organization {ORG_NAME} not found.")

def main() -> None:
    parser = argparse.ArgumentParser(description="CKAN Spatial CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)
    
    subparsers.add_parser("create-org", help="Create a test CKAN organization")
    subparsers.add_parser("create-package", help="Create a test CKAN package")
    
    spatial_parser = subparsers.add_parser("create-spatial-resource", help="Create a spatial datastore resource")
    spatial_parser.add_argument("geometry_type", choices=GEOMETRY_TYPES, help="Type of geospatial data")
    spatial_parser.add_argument("name", help="resource name")
    spatial_parser.add_argument("--rows", type=int, default=1000, help="Number of rows to generate")

    non_spatial_parser = subparsers.add_parser("create-non-spatial-resource", help="Create a tabular datastore resource")
    non_spatial_parser.add_argument("name", help="resource name")
    non_spatial_parser.add_argument("--rows", type=int, default=1000, help="Number of rows to generate")

    subparsers.add_parser("purge", help="Hard-delete the package, resources, and organization")
    
    args = parser.parse_args()
    
    if args.command == "create-org":
        create_org()
    elif args.command == "create-package":
        create_package()
    elif args.command == "create-spatial-resource":
        create_spatial_resource(args.geometry_type, args.name, args.rows)
    elif args.command == "create-non-spatial-resource":
        create_non_spatial_resource(args.name, args.rows)
    elif args.command == "purge":
        purge()

if __name__ == "__main__":
    main()
