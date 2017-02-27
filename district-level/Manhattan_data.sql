--Manhattan Data pulls
select g.district_nces_code
	 , g.polygon_area
	 , initcap(g.district_name)
	 , 'New York-Newark-Jersey City, NY-NJ-PA'::text as cbsa_title
     , coalesce(l.sale_price, l.list_price, l.original_price)::numeric as price
     , (coalesce(l.sale_price, l.list_price, l.original_price)::numeric / 
     		coalesce(nullif(l.approx_sq_ft::numeric, 0), nullif(p.total_sq_ft::numeric, 0), nullif(p.sq_ft_finished::numeric, 0))) as price_per_sqft
     , l.property_id
from school_district_shapes g 
	-- contains polygons for school districts with spatial index
join properties p 
	on st_intersects(ST_Transform(ST_SetSRID(ST_MakePoint(p.longitude, p.latitude), 4326), 4326), g.polygon)
join listings l 
	on l.property_id = p.property_id
where g.is_bounding_box is false
and g.district_nces_code in (
	'3600077',
	'3600083',
	'3600081',
	'3600078',
	'3600079',
	'3600076',
	'3615720',
	'3620580'
	)
and l.property_type_id in (3,4,6,13)
and coalesce(l.listing_date::date, l.listing_added_date::date) >= '2014-01-01'::date
and coalesce(l.sale_price, l.list_price, l.original_price) > 100000
;