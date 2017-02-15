with pp as (
	select place_id
	, sum(total_population) as total_population
	from places_population
	group by 1
)
, p2 as (
	select distinct place_id
	, first_value(id2) over(partition by place_id order by total_population desc) as place_fips
	from places_population
), 
principal_city_suburbs as ( --identify suburbs
select pp.place_id
, p2.place_fips
, p.polygon_area
, (case 
	when dense_rank() over (partition by m.cbsa_title order by pp.total_population desc) = 1 
	then 'principal_city' else 'suburb' end) as is_suburb
from places p
join geo_metro m on p.county_id = m.county_id
join pp on pp.place_id = p.place_id
join p2 on pp.place_id = p2.place_id
where cbsa_title in ('San Francisco-Oakland-Hayward, CA', 'New York-Newark-Jersey City, NY-NJ-PA')
)
select p.*, w.walk_score 
from principal_city_suburbs p
left join region_walkscores w on p.place_id = w.region_table_id 
	and w.region_type_id = 6
;