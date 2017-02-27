select s.district_nces_code
, s.polygon_area
, initcap(s.district_name) as district_name
, m.cbsa_title
, quantile(l.sale_price::numeric, 0.5) as median_sale_price
, quantile((l.sale_price::numeric / coalesce(nullif(l.approx_sq_ft, 0), nullif(prop.sq_ft_finished, 0))), 0.5) as median_sale_price_per_sqft
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
join properties prop on prop.property_id = l.property_id
where s.district_nces_code is not null
and s.district_nces_code::numeric in (3400004,3400870,3401860,3401980,3402550,3402610,3403060,3403930,3404170,3404200,3404770,3405250,3405550,3406090,3406630,3406720,3406960,3407440,3407680,3408060,3408130,3409810,3409900,3409930,3410350,3410530,3410680,3410860,3411010,3411310,3412150,3412660,3413470,3414100,3414250,3414610,3415240,3415720,3415750,3415900,3415960,3417190,3417880)
and l.property_type_id in (3,4,6,13)
and l.sale_price is not null
group by 1,2,3,4
;