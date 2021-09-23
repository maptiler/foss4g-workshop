-- remove duplicities
-- etldoc: osm_cycleway_linestring -> osm_cycleway_union_linestring
DROP MATERIALIZED VIEW IF EXISTS osm_cycleway_union_linestring CASCADE;
CREATE MATERIALIZED VIEW osm_cycleway_union_linestring AS
(

SELECT osm_id,
       (ST_Dump(ST_LineMerge(ST_Collect(geometry)))).geom AS geometry,
       member_name,
       network,
       surface
FROM osm_cycleway_linestring
GROUP BY osm_id,network, member_name, surface

);

CREATE INDEX IF NOT EXISTS osm_cycleway_union_linestring_gix
    ON osm_cycleway_union_linestring USING gist (geometry);

-- merge together by name and surface
-- etldoc: osm_cycleway_union_linestring -> osm_cycleway_merge_linestring
DROP MATERIALIZED VIEW IF EXISTS osm_cycleway_merge_linestring CASCADE;
CREATE MATERIALIZED VIEW osm_cycleway_merge_linestring AS
(
SELECT NULL::bigint AS osm_id, 
       ST_LineMerge(ST_Collect(geometry)) AS geometry,
       member_name,
       network,
       surface
FROM osm_cycleway_union_linestring
GROUP BY network, member_name, surface
);

CREATE INDEX IF NOT EXISTS osm_cycleway_merge_linestring_gix
    ON osm_cycleway_merge_linestring USING gist (geometry);
