-- etldoc: layer_cycleway_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_cycleway_poi |<z12_> z12+|" ] ;
DROP FUNCTION IF EXISTS layer_cycleway_poi(geometry,integer);
CREATE OR REPLACE FUNCTION layer_cycleway_poi(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                name      text,
                geometry  geometry,
                class     text,
                hours     text,
                distance  integer
            )
AS
$$
SELECT name,
       geometry,
       class,
       hours,
       distance
FROM (
       -- etldoc: ba_bike_shops -> layer_cycleway_poi:z12_
       SELECT nombre as name,
              wkb_geometry as geometry,
              'bike-shop' AS class,
              horario_de AS hours,
              distance
       FROM ba_bike_shops
       WHERE zoom_level >= 12

       UNION ALL

       -- etldoc: ba_bike_sharing_stations -> layer_cycleway_poi:z12_
       SELECT nombre as name,
              wkb_geometry as geometry,
              'bike-sharing' AS class,
              horario AS hours,
              distance
       FROM ba_bike_sharing_stations
       WHERE zoom_level >= 12
       ) zooms
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
