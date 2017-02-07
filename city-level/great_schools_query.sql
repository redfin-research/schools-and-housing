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
select s.place_id
, city
, s.state_code
, is_suburb
, redfin_metro
, metropolitan_division
, cbsa_title as metropolitan_statistical_area
, count(case when great_schools_rating >= 9 then 1 end) num_top_schools
, (count(
        case when great_schools_rating >= 9 
        then 1 end)::float / 
    count(1)::float) as percent_top_schools
, round(avg(great_schools_rating), 2) as avg_school_rating
, max(great_schools_rating) as best_rating
, (sum(
        case when great_schools_rating >= 9 
        then number_of_students else 0 
        end)::float / 
    nullif(sum(number_of_students)::float, 0)) as percent_students_in_top_schools
, sum(number_of_students) as total_students
from schools s
join geo_metro m on LPAD(fips_county::text, 5, '0') = (LPAD(fips_state_code::text, 2, '0') || LPAD(fips_county_code::text, 3, '0'))
join principal_city_suburbs on principal_city_suburbs.place_id = s.place_id
where institution_type = 'Public'
and elementary = TRUE
and great_schools_rating is not null
and district_nces_code is not null
and cbsa_title in (
	select cbsa_title 
	from geo_metro 
	where total_population is not null 
	and is_metro = TRUE 
	group by cbsa_title 
	order by sum(total_population) desc 
	limit 100
	)
group by s.place_id, city, s.state_code, is_suburb, 
redfin_metro, metropolitan_division, cbsa_title
;
