-- -- Hard-coded things (not ideal): id (column), distance (int, meters?), table_name

-- CREATE OR REPLACE FUNCTION xyz_cluster(
--     z INTEGER,
--     x INTEGER,
--     y INTEGER
-- ) RETURNS BYTEA 
-- LANGUAGE SQL 
-- AS $$
-- WITH tile_bounds AS (
--     SELECT ST_TileEnvelope(z, x, y) AS geom
-- ),
-- clustered_points AS (
--     -- Select points inside the tile and cluster them
--     SELECT 
--         unnest(ST_ClusterDBSCAN(
--             ARRAY_AGG(geometry ORDER BY _id)::GEOMETRY[], -- @id. Array of points ordered by id
--             500.0,  -- @distance: Hardcoded cluster distance in meters
--             1    -- Minimum points per cluster
--         )) AS geom,
--         COUNT(*) AS point_count, -- Number of points in the cluster
--         MIN(id) AS cluster_id -- Representative ID
--     FROM public."d4628c3f-4b5a-445d-827e-ff7d4f447114", tile_bounds -- @table_name
--     WHERE ST_Intersects(geom, tile_bounds.geom) -- Only include points in the tile
-- ),
-- mvt_data AS (
--     -- Convert clustered points into MVT format
--     SELECT 
--         cluster_id, 
--         point_count, 
--         ST_AsMVTGeom(geom, (SELECT geom FROM tile_bounds), 4096, 64, true) AS geom
--     FROM clustered_points
-- )
-- SELECT ST_AsMVT(mvt_data, 'clusters')
-- FROM mvt_data;
-- $$;

-- Hard-coded things (not ideal): id (column), distance (int, meters?), table_name

CREATE OR REPLACE FUNCTION xyz_cluster(
    z INTEGER,
    x INTEGER,
    y INTEGER
) RETURNS BYTEA 
LANGUAGE SQL 
AS $$
WITH tile_bounds AS (
    SELECT ST_TileEnvelope(z, x, y) AS geom
),
clustered_points AS (
    SELECT 
        -- "geometry", "when", "value",
        ST_ClusterDBSCAN(
            "geometry", -- @id. Array of points ordered by id
            0.011,  -- @distance: Hardcoded cluster distance in source esp (todo: change to meters? something more intuitive? should that mapping happen here or parameterized when creating the fn?)
            1    -- Minimum points per cluster
        ) OVER () AS cluster_id,
        COUNT(*) AS point_count -- Number of points in the cluster (maybe?)
    FROM public."d4628c3f-4b5a-445d-827e-ff7d4f447114", tile_bounds -- @table_name
    WHERE ST_Intersects(geom, tile_bounds.geom) -- Only include points in the tile
),
mvt_data AS (
    -- Convert clustered points into MVT format
    SELECT 
        cluster_id, 
        -- point_count, 
        ST_AsMVTGeom(geom, (SELECT geom FROM tile_bounds), 4096, 64, true) AS geom
    FROM clustered_points
)
SELECT ST_AsMVT(mvt_data, 'clusters')
FROM mvt_data;
$$;
