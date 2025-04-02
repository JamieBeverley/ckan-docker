CREATE OR REPLACE FUNCTION xyz_cluster_show(
    z INTEGER,
    x INTEGER,
    y INTEGER
) RETURNS TABLE (
    cluster_id int,
    count int,
    center geometry,
    "text" text
)
LANGUAGE SQL 
AS $$
WITH
    tile_bounds AS (SELECT ST_Transform(ST_TileEnvelope(z, x, y),4326) AS geom),
    groups AS (
        SELECT 
        -- "geometry", "when", "value",
            "_id",
            "geometry",
            -- "when",
            -- "value",
            ST_ClusterDBSCAN(
                "geometry", -- @id. Array of points ordered by id
                0.011,  -- @distance: Hardcoded cluster distance in source esp (todo: change to meters? something more intuitive? should that mapping happen here or parameterized when creating the fn?)
                1    -- Minimum points per cluster
            ) OVER () AS cluster_id
            -- COUNT(*) AS point_count -- Number of points in the cluster (maybe?)
        FROM public."c7c1843c-1043-4aed-8357-0d0086ab76f5", tile_bounds -- @table_name
        WHERE ST_Intersects("geometry", tile_bounds.geom)
    ),
    mvt_data as (
        SELECT
        cluster_id,
        count(cluster_id),
        -- ST_Transform(ST_Centroid(ST_Collect("geometry")), 3857) as center
        ST_Centroid(ST_Collect("geometry")) as center
        -- ST_AsMVTGeom(ST_Centroid(ST_Collect("geometry")), ST_TileEnvelope(z, x, y)) as center
        from groups group by cluster_id
    )
SELECT *, ST_AsText(center) as "text" FROM mvt_data;
STABLE;
$$;

select xyz_cluster_show(0,0,0);
