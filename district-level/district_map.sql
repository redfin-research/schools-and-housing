create table __school_districts_temp as (
select distinct s.district_nces_code
, initcap(s.district_name) as district_name
, m.cbsa_title
from __school_district_shapes s
join counties c on st_intersects(s.polygon, c.polygon_data)
join geo_metro m on m.county_id = c.county_id
and m.cbsa_title in (
'New York-Newark-Jersey City, NY-NJ-PA',
'Los Angeles-Long Beach-Anaheim, CA',
'Chicago-Naperville-Elgin, IL-IN-WI',
'Washington-Arlington-Alexandria, DC-VA-MD-WV',
'Boston-Cambridge-Newton, MA-NH',
'San Francisco-Oakland-Hayward, CA',
'Seattle-Tacoma-Bellevue, WA',
'Minneapolis-St. Paul-Bloomington, MN-WI',
'Portland-Vancouver-Hillsboro, OR-WA'
)
);

st_intersects(ST_Transform(ST_SetSRID(ST_MakePoint(p.longitude, p.latitude), 4326), 4326), g.polygon)


ALTER TABLE __redfin_est 
ADD COLUMN geom geometry;

UPDATE __redfin_est 
SET geom = ST_AsEWKT(ST_SetSRID(ST_MakePoint(longitude, latitude)::geometry, 4326));

create index __redfin_est_geom_gix on __redfin_est using gist(geom);

