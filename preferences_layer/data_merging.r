
rm(list=ls())

# Set Directory
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/")
source("./GitHub Files School Zone/schools_housing_analysis.r")
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/")
# Load Packages
packagesRequired <- c('stringr',
                      'tidyverse',
                      'lubridate',
                      'acs')

packagesMissing <- packagesRequired[!(packagesRequired %in% installed.packages())]
for (package in packagesMissing) {
    install.packages(package, repos='http://cran.rstudio.com/')
}

for (package in packagesRequired){
    eval(parse(text=paste0('library(', package, ')')))
}

# Pull population density and average commute times for each city
geo <- geo.make(zip.code = "*")

travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                          table.number = "B08303", col.names = "pretty")

# transform into data tables
travel_times_df <- data.frame(travel_times@geography, 
                              travel_times@estimate, 
                              stringsAsFactors = FALSE)

names(travel_times_df) <- c('zip_name', 
                            'zip_codes', 
                            'total_commuters',
                            'commute_Less_than_5_minutes',
                            'commute_5_to_9_minutes',
                            'commute_10_to_14_minutes',
                            'commute_15_to_19_minutes',
                            'commute_20_to_24_minutes',
                            'commute_25_to_29_minutes',
                            'commute_30_to_34_minutes',
                            'commute_35_to_39_minutes',
                            'commute_40_to_44_minutes',
                            'commute_45_to_59_minutes',
                            'commute_60_to_89_minutes',
                            'commute_90_or_more_minutes')

row.names(travel_times_df) <- 1:nrow(travel_times_df)

travel_times_df <- travel_times_df %>%
    mutate(commute_under_30 = commute_Less_than_5_minutes + commute_5_to_9_minutes + 
               commute_10_to_14_minutes + commute_15_to_19_minutes + commute_20_to_24_minutes + commute_25_to_29_minutes,
           commute_greater_than_30 = total_commuters - commute_under_30,
           percent_under_30 = commute_under_30 / total_commuters) %>%
    select(-zip_name)

glimpse(travel_times_df)

# Grab Latest population data
population <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                          table.number = "B01003", col.names = "pretty")

# transform into data tables
population_df <- data.frame(population@geography, 
                            population@estimate, 
                              stringsAsFactors = FALSE)

names(population_df) <- c('zip_name', 
                            'zip_codes', 
                            'total_population')


row.names(population_df) <- 1:nrow(population_df)


glimpse(population_df)

# combine these two data frames
travel_times_df <- merge(travel_times_df, select(population_df, -zip_name), by = "zip_codes")
glimpse(travel_times_df)

# Grab commuting data on percent that drive alone
commute <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                        table.number = "B08301", col.names = "pretty")

# transform into data tables
commute_df <- data.frame(commute@geography, 
                            commute@estimate, 
                            stringsAsFactors = FALSE)

commute_df <- commute_df[,c(2,3,5)]

names(commute_df) <- c('zip_codes', 
                          'total_transit',
                          'total_drive_alone')

row.names(commute_df) <- 1:nrow(commute_df)

commute_df <- commute_df %>%
    mutate(percent_drive_alone = total_drive_alone / total_transit) %>%
    select(zip_codes, percent_drive_alone)

glimpse(commute_df)
glimpse(travel_times_df)

travel_times_df <- merge(travel_times_df, commute_df)

zip_codes <- read_csv('./preferences_layer/ny_sf_mapping.csv')
glimpse(zip_codes)

combined_data <- merge(zip_codes, travel_times_df, 
                       by.x="zip_code", by.y="zip_codes")

glimpse(combined_data)

combined_data <- combined_data %>% 
    mutate(pop_density = total_population / polygon_area) %>%
    arrange(desc(pop_density)) %>%
    select(percent_under_30, percent_drive_alone, total_population, pop_density, walk_score, polygon_area)

# rename zip_code to zipcode for join
names(combined_data) <- c('zipcode', names(combined_data[,2:ncol(combined_data)]))

# full_dataset is the final dataset from the school_zone script
glimpse(full_dataset)

full_dataset_ny_sf <- filter(full_dataset, 
       metropolitan_statistical_area %in% 
           c('San Francisco-Oakland-Hayward, CA', 'New York-Newark-Jersey City, NY-NJ-PA'))

glimpse(full_dataset_ny_sf)

all_data_sf_ny <- right_join(combined_data, full_dataset_ny_sf, by = 'zipcode')

filter(all_data_sf_ny, is.na(total_population))

write_csv(all_data_sf_ny, './preferences_layer/all_data_ny_sf.csv')

# in case we need to map each zip to a place_fips
# zip_fips_mapping <- read_csv('http://www2.census.gov/geo/docs/maps-data/data/rel/zcta_place_rel_10.txt')
