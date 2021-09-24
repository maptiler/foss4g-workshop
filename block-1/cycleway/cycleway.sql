-- Generalized spatila data for zooms 8 to zoom 12
-- etldoc: osm_cycleway_merge_linestring -> osm_cycleway_merge_linestring_gen_z8_z12
DROP MATERIALIZED VIEW IF EXISTS osm_cycleway_merge_linestring_gen_z8_z12 CASCADE;
CREATE MATERIALIZED VIEW osm_cycleway_merge_linestring_gen_z8_z12 AS
(
SELECT osm_id, 
       ST_Simplify(geometry, ZRes(10)) AS geometry,
       member_name,
       network,
       surface
FROM osm_cycleway_merge_linestring
);

CREATE INDEX IF NOT EXISTS osm_cycleway_merge_linestring_gen_z8_z12_gix
    ON osm_cycleway_merge_linestring_gen_z8_z12 USING gist (geometry);


-- etldoc: layer_cycleway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_cycleway |<z8_> z8-z12 |<z13> z13 |<z14> z14+|" ] ;
DROP FUNCTION IF EXISTS layer_cycleway(geometry,integer);
CREATE OR REPLACE FUNCTION layer_cycleway(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                osm_id    bigint,
                geometry  geometry,
                name      text,
                network   text,
                surface   text
            )
AS
$$
SELECT osm_id,
       geometry,
       name,
       network,
       surface
FROM (
       -- etldoc: osm_cycleway_merge_linestring_gen_z8_z12 -> layer_cycleway:z8_
       SELECT osm_id,
              geometry,
              member_name AS name,
              network,
              surface
       FROM osm_cycleway_merge_linestring_gen_z8_z12
       WHERE zoom_level BETWEEN 8 AND 12
       
       UNION ALL
       -- etldoc: osm_cycleway_merge_linestring -> layer_cycleway:z13
       SELECT osm_id,
              geometry,
              member_name AS name,
              network,
              surface
       FROM osm_cycleway_merge_linestring
       WHERE zoom_level = 13
       
       UNION ALL
       -- etldoc: osm_cycleway_union_linestring -> layer_cycleway:z14
       SELECT osm_id,
              geometry,
              member_name AS name,
              network,
              surface
       FROM osm_cycleway_union_linestring
       WHERE zoom_level >= 14
       
       ) zooms
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
