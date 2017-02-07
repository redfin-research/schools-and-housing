-- Redfin housing cost by school district
select g.school_nces_code
     , quantile(sale_price::numeric, 0.5) as median_sale_price
     , quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
     , count(distinct l.property_id) as total_sales
from __school_shapes g 
	-- contains polygons for school zones with a spatial index
	join schools s on g.school_nces_code=s.nces_code
join __property_geom p 
	on st_intersects(p.geom, g.polygon) 
	-- contains location geom for each property; 
	-- prefiltered only for condos, townhomes, single-family, or multi-family
	-- listings from the MLS that sold in 2016 for $5,000 or more
join listings l 
	on l.property_id = p.property_id
where g.is_bounding_box is false
and g.school_nces_code is not null
and s.institution_type = 'Public'
and s.elementary = TRUE
and s.great_schools_rating is not null
and s.nces_code is not null
and l.sale_price is not null
and l.property_type_id = 6 -- single-family residences only
and l.num_bedrooms = 2
and l.approx_sq_ft between 1000 and 2000
group by 1
having count(distinct l.property_id) >= 5
;