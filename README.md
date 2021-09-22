# foss4g-workshop
Repository for From your data to vector tiles in your web&amp;mobile app workshop at FOSS4G 2021, Buenos Aires

# Block 0 - prerequisites

- Docker, docker-compose
- QGIS
- IDE
- CloudShell



## Block 1 - import OSM data

Add - layers/bicycle/bicycle.yaml into openmaptiles.yaml

unzip bicycle.zip into layers/

## Block 2

### Spatial analysis in QGIS

#### Add PostGIS connection to QGIS.

Go to Browser/PostGIS/New Connection…
- Name: osm_buenos_aires
- Host: localhost
- Port: 5432
- Database: openmaptiles
- User: openmaptiles
- Password: openmaptiles

Check you can see added bicycle table. Go to Browser/PostGIS/osm_buenos_aires/public/osm_bicycle_linestring and
double-click on it. Bicycle paths should be added to map canvas.

#### Add basemap for context via MapTiler plugin

1. Go to Plugins/Manage and Install plugins.../All and search for `MapTiler`
2. Right-click on MapTiler in Browser and add API key `XorxtpkRV4o7B7Ssqzg6`
3. Add Streets map


#### Add GeoJSON to QGIS

1. Download GeoJSON from https://dev.maptiler.download/foss4g/bicicleterias/bicicleterias-de-la-ciudad.geojson
2. Add GeoJSON to QGIS (drag and drop) 
3. Reproject data from WGS84 (EPSG:4326) to Pseudo-Mercator (EPSG:3857).
   1. Go to Processing toolbox/Vector general/Reproject layer
   2. Choose Input layer: `bicicleterias-de-la-ciudad bicicleterias_WGS [EPSG:4326]`
   3. Choose Target CRS: `EPSG:3857 - WGS 84/Pseudo-Mercator`
   4. Choose `[Create temporary layer]`
   5. Run

#### Add new attribute field
1. Open attribute table
2. Toggle editing
3. Add New field
   1. Name: distance
   2. Type: Integer
4. Save edits

#### Distance analysis
Go to Processing toolbox/GRASS/vector/v.distance 
 - from: Reprojected
 - to: osm_bicycle_linestring
 - upload: dist
 - column for upload: distance
 - Save to temporary file Nearest

#### Export 
Right-click on Nearest/Make Permanent
 - Format: GeoJSON
 - File name: openmaptiles/data/bike_shops_w_distance.geojson

### Import GeoJSON to PostGIS
Processed GeoJSON available for download at: https://dev.maptiler.download/foss4g/bike_shops_w_distance/bike_shops_w_distance.geojson

Use `import-data` docker image to import the processed GeoJSON `bike_shops_w_distance.geojson into` 
PostGIS table `ba_bike_shops`.

```
cd openmaptiles
docker-compose run --rm -v $PWD:/omt import-data /bin/sh
ogr2ogr --version
ogr2ogr -f "PostgreSQL" PG:"dbname=openmaptiles" data/bike_shops_w_distance.geojson -nln ba_bike_shops
```

You should be able to see the table `ba_bike_shops` in QGIS now.

### Import Shapefile to PostGIS
1. Download zip file from https://dev.maptiler.download/foss4g/estaciones/estaciones-de-bicicletas-zip.zip
2. Extract zip file into openmaptiles/data
3. Import shapefile to PostGIS
```
cd openmaptiles
docker-compose run --rm -v $PWD:/omt import-data /bin/sh
ogr2ogr -f "PostgreSQL" PG:"dbname=openmaptiles" /omt/data/estaciones-de-bicicletas-zip/estaciones_de_bicicletas_WGS84.shp -nln ba_bike_sharing_stations -s_srs EPSG:4326 -t_srs EPSG:3857
```

### Spatial analysis in PostGIS
#### Add new table column
Either in QGIS/Database/DB Manager... or in psql console
Add column `distance` with integer type.
```
cd openmaptiles
make psql
\d ba_bike_sharing_stations
ALTER TABLE ba_bike_sharing_stations ADD COLUMN distance INTEGER;
\d ba_bike_sharing_stations
```

#### Distance analysis
Either in QGIS/Database/DB Manager... or in psql console
```
cd openmaptiles
make psql
UPDATE ba_bike_sharing_stations AS b SET distance=(SELECT ST_Distance(b.wkb_geometry, c.geometry) FROM osm_bicycle_linestring AS c ORDER BY b.wkb_geometry <-> c.geometry LIMIT 1);
```
