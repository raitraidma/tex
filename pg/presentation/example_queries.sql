---------------
-- PgRouting --
---------------

-- DIJKSTRA example
CREATE SCHEMA IF NOT EXISTS pggraph_dijkstra_test;

CREATE TABLE IF NOT EXISTS pggraph_dijkstra_test.graph (
  id BIGINT
, source BIGINT
, target BIGINT
, cost DOUBLE PRECISION
);

INSERT INTO pggraph_dijkstra_test.graph (id, source, target, cost) VALUES
(1, 1, 2, 4),
(2, 1, 3, 2),
(3, 2, 3, 5),
(4, 2, 4, 10),
(5, 3, 5, 3),
(6, 5, 4, 4),
(7, 4, 6, 11);

SELECT * FROM pgr_dijkstra('SELECT id, source, target, cost FROM pggraph_dijkstra_test.graph', 1, 6, FALSE);

SELECT * FROM pgr_dijkstra('SELECT id, source, target, cost FROM pggraph_dijkstra_test.graph', 6, 1, TRUE);

SELECT * FROM pgr_dijkstra('SELECT id, source, target, cost FROM pggraph_dijkstra_test.graph', 6, 1, FALSE);

-------------
-- PgGraph --
-------------

-- MST example

CREATE SCHEMA IF NOT EXISTS pggraph_mst_test;

CREATE TABLE IF NOT EXISTS pggraph_mst_test.graph (
  id BIGINT
, source BIGINT
, target BIGINT
, cost DOUBLE PRECISION
);

INSERT INTO pggraph_mst_test.graph (id, source, target, cost) VALUES
(1, 1, 5, 1),
(2, 1, 2, 3),
(3, 2, 5, 4),
(4, 2, 3, 5),
(5, 3, 5, 6),
(6, 3, 4, 2),
(7, 4, 5, 7);

SELECT * FROM pggraph.kruskal('SELECT id, source, target, cost FROM pggraph_mst_test.graph');

---------------
-- PlPythonu --
---------------

CREATE OR REPLACE FUNCTION f_google_api_key() RETURNS varchar AS
$$
  SELECT 'AIzaSyBb_020z-CcUJ2x6pqOObqOi_WFgl3F-rU'::varchar;
$$
LANGUAGE sql
  SECURITY DEFINER
  SET search_path=public, pg_temp;


CREATE OR REPLACE FUNCTION f_geocode_lng_lat(IN s_address TEXT, s_api_key VARCHAR)
  RETURNS text ARRAY[2] AS
$$
from geopy.geocoders import GoogleV3
try:
  geolocator = GoogleV3(api_key=s_api_key)
  location = geolocator.geocode(s_address)
  lat, lng = location.latitude, location.longitude
except:
  lat, lng = 0, 0
return lng, lat
$$
LANGUAGE 'plpythonu'
  SECURITY DEFINER
  SET search_path=public, pg_temp;


CREATE OR REPLACE FUNCTION f_geocode_address(IN d_latitude DOUBLE PRECISION, IN d_longitude DOUBLE PRECISION, s_api_key VARCHAR)
  RETURNS text AS
$$
from geopy.geocoders import GoogleV3
try:
  geolocator = GoogleV3(api_key=s_api_key)
  location = geolocator.reverse(str(d_latitude) + ", " + str(d_longitude))
  address = location[0].address
except:
  address = ''
return address
$$
LANGUAGE 'plpythonu'
  SECURITY DEFINER
  SET search_path=public, pg_temp;


CREATE OR REPLACE FUNCTION f_http_get(s_url TEXT)
  RETURNS text AS
$$
import urllib2
try:
  result = urllib2.urlopen(s_url).read()
except:
  result = ''
return result
$$
LANGUAGE 'plpythonu'
  SECURITY DEFINER
  SET search_path=public, pg_temp;

-- Example queries:

SELECT f_http_get('http://www.neti.ee');
SELECT f_geocode_lng_lat('Järvevana tee 9, Tallinn', f_google_api_key());
SELECT f_geocode_address(59.4031513, 24.7343579, f_google_api_key());
