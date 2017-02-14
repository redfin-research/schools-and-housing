-- Redfin housing cost by school district
select g.district_nces_code
	 , s.district_name
	 , pt.name as property_type
	 , l.num_bedrooms
	 , avg(nullif(l.approx_sq_ft, 0)) as average_sqft
     , quantile(sale_price::numeric, 0.5) as median_sale_price
     , quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
     , count(distinct l.property_id) as total_sales
from __school_shapes g 
	-- contains polygons for school districts with spatial index
join schools s 
	on g.school_nces_code = s.nces_code
join __property_geom p 
	on st_intersects(p.geom, g.polygon) 
	-- contains location geom for each property; 
	-- prefiltered only for condos, townhomes, single-family, or multi-family
	-- listings from the MLS that sold in 2014, 15, & 16 for $5,000 or more
join listings l 
	on l.property_id = p.property_id
join property_types pt 
	on pt.property_type_id = l.property_type_id
join geo_metro m 
	on l.county_id = m.county_id
where g.is_bounding_box is false
and g.district_nces_code is not null
and l.sale_price is not null
and l.property_type_id in (3,4,6,13)
and s.institution_type = 'Public'
and s.elementary = TRUE
and m.cbsa_title in (
	select cbsa_title 
	from geo_metro 
	where total_population is not null 
	and is_metro = TRUE 
	group by cbsa_title 
	order by sum(total_population) desc 
	limit 100
	)
group by 1, 2, 3, 4
;