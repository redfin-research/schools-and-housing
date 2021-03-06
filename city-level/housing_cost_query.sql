-- Redfin housing cost by city in 2016
select pm.table_id as place_id
     , quantile(sale_price::numeric, 0.5) as median_sale_price
     , quantile((l.sale_price::numeric / nullif(l.approx_sq_ft, 0)), 0.5) as median_sale_price_per_sqft
     , count(distinct l.property_id) as total_sales
from listings l 
join property_region_map pm on pm.property_id = l.property_id 
	and pm.region_type_id = 6
where l.property_type_id in (3,4,6,13) 
and l.listing_type_id = 1
and l.sale_price >= 5000
and date_trunc('year', l.sale_date) = '2016-01-01'
group by 1
having count(distinct l.property_id) >= 5
;