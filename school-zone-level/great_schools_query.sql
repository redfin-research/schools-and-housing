-- Pull Data from Great Schools Data tables
with pp as (
	select place_id
	, sum(total_population) as total_population
	from places_population
	group by 1
),
principal_city_suburbs as ( --identify suburbs
	select pp.place_id
	, p.display_name
	, s.state_code
	, (case 
		when dense_rank() over (partition by m.cbsa_title order by pp.total_population desc) = 1 
		then 'principal_city' else 'suburb' end) as is_suburb
	from places p
	join geo_metro m on p.county_id = m.county_id
	join pp on pp.place_id = p.place_id
	join counties c on c.county_id = p.county_id
	join states s on s.state_id = c.state_id
)
select nces_code
, name
, zipcode
, s.city
, s.state_code
, COALESCE(s.place_id, p.place_id) as place_id
, COALESCE(is_suburb, 'suburb'::text) as is_suburb
, district_nces_code
, district_name
, redfin_metro
, metropolitan_division
, cbsa_title as metropolitan_statistical_area
, (CASE WHEN great_schools_rating <= 3 THEN 'poor_school' 
	WHEN great_schools_rating between 4 and 7 THEN 'average_school'
 	WHEN great_schools_rating >= 8 THEN 'top_school' 
	END) as school_quality
, great_schools_rating
, number_of_students
from schools s
left join principal_city_suburbs p on s.city = (case when p.display_name = 'Washington, DC' then 'Washington' else p.display_name end) 
	and s.state_code = p.state_code
join geo_metro m on LPAD(fips_county::text, 5, '0') = (LPAD(fips_state_code::text, 2, '0') || LPAD(fips_county_code::text, 3, '0'))
where institution_type = 'Public'
and elementary = TRUE
and great_schools_rating is not null
and nces_code is not null
and cbsa_title in (
	select cbsa_title 
	from geo_metro 
	where total_population is not null 
	and is_metro = TRUE 
	group by cbsa_title 
	order by sum(total_population) desc 
	limit 100
	)
;