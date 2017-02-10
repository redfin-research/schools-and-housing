-- Redfin housing cost by school zone
select g.school_nces_code
	 , g.school_name
	 , g.district_nces_code
	 , s.district_name
	 , m.cbsa_title
	 , pt.name as property_type
	 , l.num_bedrooms
	 , avg(nullif(l.approx_sq_ft, 0)) as average_sqft
     , quantile(sale_price::numeric, 0.5) as median_sale_price
     , quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
     , count(distinct l.property_id) as total_sales
from __school_shapes g 
	-- contains polygons for school zones with a spatial index
join schools s 
	on g.school_nces_code = s.nces_code
join __property_geom p 
	on st_intersects(p.geom, g.polygon) 
	-- contains location geom for each property; 
	-- prefiltered only for condos, townhomes, single-family, or multi-family
	-- listings from the MLS that sold in 2016 for $5,000 or more
join listings l 
	on l.property_id = p.property_id
join property_types pt 
	on pt.property_type_id = l.property_type_id
join geo_metro m 
	on l.county_id = m.county_id
where g.is_bounding_box is false
and g.school_nces_code is not null
and s.institution_type = 'Public'
and s.elementary = TRUE
and s.great_schools_rating is not null
and s.nces_code is not null
and l.sale_price is not null
and m.cbsa_title in (
	select cbsa_title 
	from geo_metro 
	where total_population is not null 
	and is_metro = TRUE 
	group by cbsa_title 
	order by sum(total_population) desc 
	limit 100
	)
group by 1, 2, 3, 4, 5, 6, 7
;
