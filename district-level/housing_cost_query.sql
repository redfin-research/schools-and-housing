select s.district_nces_code
, s.polygon_area
, initcap(s.district_name) as district_name
, m.cbsa_title
, quantile(l.sale_price::numeric, 0.5) as median_sale_price
, quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
, count(distinct l.property_id) as total_sales
from __school_district_shapes s
join __school_districts_temp m on m.district_nces_code = s.district_nces_code
join __property_geom p 
	on st_intersects(p.geom, s.polygon) 
	-- contains location geom for each property; 
	-- prefiltered only for condos, townhomes, single-family, or multi-family
	-- listings from the MLS that sold in 2014, 15, & 16 for $5,000 or more
join listings l 
	on l.property_id = p.property_id
where s.district_nces_code is not null
and l.property_type_id in (3,4,6,13)
and l.sale_price is not null
group by 1,2,3,4
;