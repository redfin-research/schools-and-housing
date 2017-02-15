
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
geo <- geo.make(state="*", place = "*")

travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                          table.number = "B08303", col.names = "pretty")

# transform into data tables
travel_times_df <- data.frame(travel_times@geography, 
                              travel_times@estimate, 
                              stringsAsFactors = FALSE)

names(travel_times_df) <- c('place', 
                            'state_fips', 
                            'place_fips', 
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

travel_times_df <- travel_times_df %>%
    mutate(fips = str_c(str_pad(state_fips, 2, "left", "0"), str_pad(place_fips, 5, "left", "0")),
           commute_under_30 = commute_Less_than_5_minutes + commute_5_to_9_minutes + 
               commute_10_to_14_minutes + commute_15_to_19_minutes + commute_20_to_24_minutes + commute_25_to_29_minutes,
           commute_greater_than_30 = total_commuters - commute_under_30,
           percent_under_30 = commute_under_30 / total_commuters)

glimpse(travel_times_df)

# Grab Latest population data
population <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                          table.number = "B01003", col.names = "pretty")

# transform into data tables
population_df <- data.frame(population@geography, 
                            population@estimate, 
                              stringsAsFactors = FALSE)

names(population_df) <- c('place', 
                            'state_fips', 
                            'place_fips', 
                            'total_population')



population_df <- population_df %>%
    mutate(fips = str_c(str_pad(state_fips, 2, "left", "0"), str_pad(place_fips, 5, "left", "0"))) %>%
    select(fips, total_population)

glimpse(population_df)

# combine these two data frames
travel_times_df <- merge(travel_times_df, population_df, by = "fips")
glimpse(travel_times_df)

# Grab Latest population data
commute <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                        table.number = "B08301", col.names = "pretty")

# transform into data tables
commute_df <- data.frame(commute@geography, 
                            commute@estimate, 
                            stringsAsFactors = FALSE)

commute_df <- commute_df[,c(1:4,6)]

names(commute_df) <- c('place', 
                          'state_fips', 
                          'place_fips', 
                          'total_transit',
                          'total_drive_alone')


commute_df <- commute_df %>%
    mutate(fips = str_c(str_pad(state_fips, 2, "left", "0"), str_pad(place_fips, 5, "left", "0")),
           percent_drive_alone = total_drive_alone / total_transit) %>%
    select(fips, percent_drive_alone)

glimpse(commute_df)
glimpse(travel_times_df)

travel_times_df <- merge(travel_times_df, commute_df)

fips_codes <- read_csv('./preferences_layer/ny_sf_mapping.csv')
glimpse(fips_codes)
fips_codes$place_fips <- str_pad(fips_codes$place_fips, 7, "left", "0")

combined_data <- merge(fips_codes, select(travel_times_df, -place_fips), by.x="place_fips", by.y="fips")

glimpse(combined_data)

combined_data <- combined_data %>% 
    mutate(pop_density = total_population / polygon_area) %>%
    arrange(desc(pop_density)) %>%
    select(place_fips, percent_under_30, percent_drive_alone, total_population, pop_density, walk_score, polygon_area)

glimpse(full_dataset)

all_data_sf_ny <- merge(combined_data, full_dataset, by = "place_fips")


write_csv(all_data_sf_ny, './preferences_layer/all_data_ny_sf.csv')

