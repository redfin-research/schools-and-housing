-- Redfin housing cost by school district
select g.district_nces_code
     , quantile(sale_price::numeric, 0.5) as median_sale_price
     , quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
     , count(distinct l.property_id) as total_sales
from __school_shapes g 
	-- contains polygons for school districts with spatial index
join __property_geom p 
	on st_intersects(p.geom, g.polygon) 
	-- contains location geom for each property; 
	-- prefiltered only for condos, townhomes, single-family, or multi-family
	-- listings from the MLS that sold in 2016 for $5,000 or more
join listings l 
	on l.property_id = p.property_id
where g.is_bounding_box is false
and g.district_nces_code is not null
group by 1
having count(distinct l.property_id) >= 5
;