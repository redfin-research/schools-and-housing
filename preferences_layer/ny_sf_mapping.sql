--Grab Walk score data by zip code
select zip_code, z.polygon_area, cbsa_title, w.walk_score
from zip_codes z
join geo_metro m on z.county_id = m.county_id
join region_view v on v.display_name = z.zip_code
left join region_walkscores w on v.table_id = w.region_table_id and w.region_type_id = 2
where cbsa_title in (
	'San Francisco-Oakland-Hayward, CA', 
	'New York-Newark-Jersey City, NY-NJ-PA'
);