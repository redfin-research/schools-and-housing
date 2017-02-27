#############################################
# School Quality and Housing Affordability by District
# By Taylor Marr
# with the NYTimes
#############################################

rm(list=ls(all.names = TRUE))

# Set Directory
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/GitHub Files District/")

# Load Packages
packagesRequired <- c('stringr',
                      'ggthemes',
                      'tidyverse',
                      'haven')

packagesMissing <- packagesRequired[!(packagesRequired %in% installed.packages())]
for (package in packagesMissing) {
    install.packages(package, repos='http://cran.rstudio.com/')
}
for (package in packagesRequired){
    eval(parse(text=paste0('library(', package, ')')))
}

# View data files
list.files(pattern = '.csv')

# download.file('https://nces.ed.gov/programs/edge/data/GRF15.zip', 'GRF15.zip')
# unzip('GRF15.zip', exdir = './GRF15')
mapping <- haven::read_sas('./GRF15/grf15_lea_cbsa.sas7bdat')

CBSAs <- c('New York-Newark-Jersey City, NY-NJ-PA',
           'Los Angeles-Long Beach-Anaheim, CA',
           'Chicago-Naperville-Elgin, IL-IN-WI',
           'Washington-Arlington-Alexandria, DC-VA-MD-WV',
           'Boston-Cambridge-Newton, MA-NH',
           'San Francisco-Oakland-Hayward, CA',
           'Seattle-Tacoma-Bellevue, WA',
           'Minneapolis-St. Paul-Bloomington, MN-WI',
           'Portland-Vancouver-Hillsboro, OR-WA')


mapping <- filter(mapping, NAME_CBSA15 %in% CBSAs)

mapping_zips <- read_sas('GRF15/grf15_lea_zcta5ce10.sas7bdat')
mapping_zips <- filter(mapping_zips, NAME_CBSA15 %in% CBSAs)

# Join to school data
district_means <- read_csv('district_means_c.csv')

district_means$leaid <- str_pad(as.character(district_means$leaid), 7, 'left', '0')

district_means <- left_join(mapping, district_means, 
                        by = c('LEAID'='leaid'))

district_means_missing <- filter(district_means, is.na(gsmean_pool))

district_means <- district_means[complete.cases(district_means),]

# Pull in housing data
housing_cost <- read_delim("housing_cost_data.csv", delim = ';')

# Pull in Manhattan districts data
nyc <- read_delim('manhattan_data.csv', delim = ';')

nyc <- filter(nyc, price <= 120000000, price_per_sqft <= 10000)

nyc_medians <- nyc %>%
    dplyr::group_by(district_nces_code, polygon_area, initcap, cbsa_title) %>%
    dplyr::summarise(med_price = median(price, na.rm = T),
              med_ppsf = median(price_per_sqft, na.rm = T),
              total_properties = n_distinct(property_id))

# Pull it all together
names(nyc_medians) <- names(housing_cost)

# Remove Manhattan data from housing_cost
housing_cost <- dplyr::filter(housing_cost, !(district_nces_code %in% nyc_medians$district_nces_code))

housing_cost <- rbind(as.data.frame(housing_cost), as.data.frame(nyc_medians))

housing_cost <- housing_cost %>%
    group_by(district_nces_code) %>%
    arrange(desc(total_sales)) %>%
    slice(1) %>%
    ungroup()

# Manually fill in 2 more missing values in NY
housing_cost$median_sale_price[housing_cost$district_nces_code=='3406600'] <- 230000
housing_cost$median_sale_price[housing_cost$district_nces_code=='3416170'] <- 575000

housing_cost$median_sale_price_per_sqft[housing_cost$district_nces_code=='3406600'] <- 125
housing_cost$median_sale_price_per_sqft[housing_cost$district_nces_code=='3416170'] <- 195.45793

write_csv(housing_cost, 'district_level_housing_cost.csv')

# Join to school dataset
combined_data <- left_join(district_means, 
                     select(housing_cost, district_nces_code, 
                            median_sale_price:total_sales), 
                     by = c('LEAID'='district_nces_code'))

# View(combined_data)
glimpse(combined_data)
tail(combined_data)

summary(combined_data)

# Combine with Census data
census_data <- read_csv('census_data_full.csv')

combined_data_all <- left_join(combined_data, 
                               census_data, 
              by = c('LEAID' = 'district_fips'),
              suffix = c('', '_census')) 

glimpse(combined_data_all)

combined_data_all <- combined_data_all %>%
    mutate(pop_density = total_population / LANDAREA) 

# missing data by metro
combined_data_all %>%
    dplyr::group_by(NAME_CBSA15, complete.cases(combined_data_all)) %>%
    dplyr::summarise(n())

write_csv(combined_data_all, 'final_dataset.csv')

tidy_data <- combined_data_all %>%
    select(LEAID, NAME_LEA15, NAME_CBSA15, median_sale_price, median_sale_price_per_sqft, gsmean_pool, mean_commute_time, total_population, percent_under_30, percent_drive_alone, pop_density) %>%
    ungroup() %>%
    group_by(NAME_CBSA15) %>%
    arrange(NAME_CBSA15, desc(total_population)) %>%
    ungroup()

tidy_data %>%
    dplyr::group_by(NAME_CBSA15, complete.cases(tidy_data)) %>%
    dplyr::summarise(n())

write_csv(tidy_data, 'final_dataset_tidy.csv')

save.image()
