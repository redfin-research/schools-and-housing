select s.district_nces_code
, s.polygon_area
, initcap(s.district_name) as district_name
, m.cbsa_title
, quantile(pt.sale_price::numeric, 0.5) as median_sale_price
, quantile((pt.sale_price::numeric / coalesce(nullif(p.sq_ft_finished, 0))), 0.5) as median_sale_price_per_sqft
, count(distinct pt.property_id) as total_sales
from __school_district_shapes s
join __school_districts_temp m on m.district_nces_code = s.district_nces_code
join properties p
	on st_intersects(ST_AsEWKT(ST_SetSRID(ST_MakePoint(p.longitude, p.latitude)::geometry, 4326))::geometry, s.polygon) 
join property_transactions pt 
	on p.property_id = pt.property_id
where s.district_nces_code is not null
and s.district_nces_code::numeric in (2500542,2501680,2502850,1800750,1802880,1802910,1803870,1804170,1804560,1804590,1804620,1805280,1805460,1807920,1809000,1809150,1809180,1809420,1809690,1811700,1811970,1813200,1809360,1810470,1811430,2700379,3406600,3416170,3418030,4108700)
and p.property_type_id in (3,4,6,13)
and pt.sale_price is not null
and pt.sale_price >= 5000
and pt.sale_date >= '2014-01-01'
and pt.sale_date <= '2017-01-01'
group by 1,2,3,4
;