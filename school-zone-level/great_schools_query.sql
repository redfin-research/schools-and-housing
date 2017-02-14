-- Pull Data from Great Schools Data tables
with principal_city_suburbs as ( --identify suburbs
	select p.place_id
	, (case 
		when dense_rank() over (partition by m.cbsa_title order by pp.total_population desc) = 1 
		then 'principal_city' else 'suburb' end) as is_suburb
	from places p
	join geo_metro m on p.county_id = m.county_id
	join places_population pp on pp.place_id = p.place_id
)
select nces_code
, name
, schools.city
, schools.state_code
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
from schools
left join principal_city_suburbs p on schools.place_id = p.place_id
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