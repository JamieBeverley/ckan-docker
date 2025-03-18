CREATE OR REPLACE FUNCTION cluster_base(
    z INTEGER,
    x INTEGER,
    y INTEGER,
    table_name TEXT
) RETURNS BYTEA 
LANGUAGE SQL 
AS $$
WITH
    tile_bounds AS (SELECT ST_Transform(ST_TileEnvelope(z, x, y), 4326) AS geom),
    -- geoms AS
    groups AS (
        SELECT 
        -- "geometry", "when", "value",
            "_id",
            "geometry",
            -- "when",
            -- "value",
            ST_ClusterDBSCAN(
                "geometry", -- @id. Array of points ordered by id
                50 * (2 * pi() * 6378137) / (256 * power(2, z)),
                -- (0.1 * (2 * pi() * 6378137) / power(3, z*2)), -- Adjust `1000` as needed
                -- 1/z,  -- @distance: Hardcoded cluster distance in source esp (todo: change to meters? something more intuitive? should that mapping happen here or parameterized when creating the fn?)
                1    -- Minimum points per cluster
            ) OVER () AS cluster_id
            -- COUNT(*) AS point_count -- Number of points in the cluster (maybe?)
        FROM public."d4628c3f-4b5a-445d-827e-ff7d4f447114", tile_bounds -- @table_name
        WHERE ST_Intersects("geometry", tile_bounds.geom)
    ),
    mvt_data as (
        SELECT
        cluster_id,
        count(cluster_id),
        -- ST_Transform(ST_Centroid(ST_Collect("geometry")), 4326) as center
        -- ST_AsMVTGeom(ST_Centroid(ST_Collect("geometry")), ST_Transform(ST_TileEnvelope(0, 0, 0),4326)) as center
        ST_AsMVTGeom(ST_Transform(ST_Centroid(ST_Collect("geometry")), 3857), ST_TileEnvelope(z, x, y)) as center
        from groups group by cluster_id
    )
SELECT ST_AsMVT(mvt_data, 'default') FROM mvt_data;
$$;


CREATE OR REPLACE FUNCTION xyz_cluster(
    z INTEGER,
    x INTEGER,
    y INTEGER
) RETURNS BYTEA 
LANGUAGE SQL 
AS $$
WITH
    tile_bounds AS (SELECT ST_Transform(ST_TileEnvelope(z, x, y), 4326) AS geom),
    -- geoms AS
    groups AS (
        SELECT 
        -- "geometry", "when", "value",
            "_id",
            "geometry",
            -- "when",
            -- "value",
            ST_ClusterDBSCAN(
                "geometry", -- @id. Array of points ordered by id
                50 * (2 * pi() * 6378137) / (256 * power(2, z)),
                -- (0.1 * (2 * pi() * 6378137) / power(3, z*2)), -- Adjust `1000` as needed
                -- 1/z,  -- @distance: Hardcoded cluster distance in source esp (todo: change to meters? something more intuitive? should that mapping happen here or parameterized when creating the fn?)
                1    -- Minimum points per cluster
            ) OVER () AS cluster_id
            -- COUNT(*) AS point_count -- Number of points in the cluster (maybe?)
        FROM public."d4628c3f-4b5a-445d-827e-ff7d4f447114", tile_bounds -- @table_name
        WHERE ST_Intersects("geometry", tile_bounds.geom)
    ),
    mvt_data as (
        SELECT
        cluster_id,
        count(cluster_id),
        -- ST_Transform(ST_Centroid(ST_Collect("geometry")), 4326) as center
        -- ST_AsMVTGeom(ST_Centroid(ST_Collect("geometry")), ST_Transform(ST_TileEnvelope(0, 0, 0),4326)) as center
        ST_AsMVTGeom(ST_Transform(ST_Centroid(ST_Collect("geometry")), 3857), ST_TileEnvelope(z, x, y)) as center
        from groups group by cluster_id
    )
SELECT ST_AsMVT(mvt_data, 'default') FROM mvt_data;
$$;

CREATE OR REPLACE FUNCTION dummy(
    z INTEGER,
    x INTEGER,
    y INTEGER
) RETURNS BYTEA 
LANGUAGE SQL 
AS $$
WITH
    mvt_data AS (SELECT ST_AsMVTGeom(ST_Transform(ST_Point(-79,43,4326),3857), ST_TileEnvelope(z, x, y)) AS geom)
SELECT ST_AsMVT(mvt_data, 'default') from mvt_data
$$;


CREATE OR REPLACE VIEW resource_z_15 AS
WITH
    grouped AS (
        SELECT 
            "_id",
            "geometry",
            ST_ClusterDBSCAN(
                "geometry", -- @id. Array of points ordered by id
                0.011,
                1    -- Minimum points per cluster
            ) OVER () AS cluster_id
        FROM public."d4628c3f-4b5a-445d-827e-ff7d4f447114"
    ),
    mvt_data as (
        SELECT
        cluster_id,
        count(cluster_id),
        -- ST_Transform(ST_Centroid(ST_Collect("geometry")), 4326) as center
        -- ST_AsMVTGeom(ST_Centroid(ST_Collect("geometry")), ST_Transform(ST_TileEnvelope(0, 0, 0),4326)) as center
        -- ST_AsMVTGeom(ST_Transform(ST_Centroid(ST_Collect("geometry")), 3857), ST_TileEnvelope(z, x, y)) as geometry
        ST_Centroid(ST_Collect("geometry"))::geometry('Point', 4326) as center
        from grouped group by cluster_id
    )
    -- SELECT ST_AsMVT(mvt_data, 'default') FROM mvt_data
    SELECT *, ST_AsText(center) as "text" FROM mvt_data;