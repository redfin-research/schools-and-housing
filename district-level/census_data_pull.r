#############################################
# Pull Census Data by District
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
                      'acs',
                      'haven')

packagesMissing <- packagesRequired[!(packagesRequired %in% installed.packages())]
for (package in packagesMissing) {
    install.packages(package, repos='http://cran.rstudio.com/')
}
for (package in packagesRequired){
    eval(parse(text=paste0('library(', package, ')')))
}

# Read in Census Data
# Need to pull in Unified, Elementary & Secondary separately to have complete picture

    # Pull census data
    states <- data.frame(state_abb = as.character(state.abb), state_name = as.character(state.name), region = as.character(state.region), stringsAsFactors = FALSE)
    
    # Build dataset from census for each state
    census_data <- data.frame()
    state.abb <- c(state.abb, "DC")
    
    for (s in seq_along(state.abb)){
        print(state.abb[s])
        
        # create a geographic set to grab tabular data (acs)
        geo <- geo.make(state=state.abb[s], school.district.unified = "*")
        
        travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                  table.number = "B08303", col.names = "pretty")
        
        # transform into data tables
        travel_times_df <- data.frame(travel_times@geography, 
                                      travel_times@estimate, 
                                      stringsAsFactors = FALSE)
        
        names(travel_times_df) <- c('district_name', 
                                    'state', 
                                    'schooldistrictunified',
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
        

        agg_travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                  table.number = "B08013", col.names = "pretty")
        
        # transform into data tables
        agg_travel_times_df <- data.frame(agg_travel_times@geography, 
                                      agg_travel_times@estimate, 
                                      stringsAsFactors = FALSE)
        
        names(agg_travel_times_df) <- c('district_name', 
                                    'state', 
                                    'schooldistrictunified',
                                    'agg_travel_time',
                                    'agg_travel_time_m',
                                    'agg_travel_time_f')
        
        row.names(agg_travel_times_df) <- 1:nrow(agg_travel_times_df)
        
        travel_times_df <- left_join(travel_times_df, agg_travel_times_df)
        
        travel_times_df <- travel_times_df %>%
            mutate(commute_under_30 = commute_Less_than_5_minutes + commute_5_to_9_minutes + 
                       commute_10_to_14_minutes + commute_15_to_19_minutes + commute_20_to_24_minutes + commute_25_to_29_minutes,
                   commute_greater_than_30 = total_commuters - commute_under_30,
                   percent_under_30 = commute_under_30 / total_commuters,
                   mean_commute_time = agg_travel_time / total_commuters)
        
        # Grab Latest population data
        population <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                table.number = "B01003", col.names = "pretty")
        
        # transform into data tables
        population_df <- data.frame(population@geography, 
                                    population@estimate, 
                                    stringsAsFactors = FALSE)
        
        names(population_df) <- c('district_name', 
                                  'state', 
                                  'schooldistrictunified',
                                  'total_population')
        
        
        row.names(population_df) <- 1:nrow(population_df)
        
        
        population_df <- select(population_df, schooldistrictunified, total_population)
        
        travel_times_df <- full_join(travel_times_df, 
                                     population_df, 
                                     by = "schooldistrictunified")
        
        # Grab commuting data on percent that drive alone
        commute <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                             table.number = "B08301", col.names = "pretty")
        
        # transform into data tables
        commute_df <- data.frame(commute@geography, 
                                 commute@estimate, 
                                 stringsAsFactors = FALSE)
        
        commute_df <- commute_df[,c(3,4,6)]
        
        names(commute_df) <- c('schooldistrictunified',
                               'total_transit',
                               'total_drive_alone')
        
        row.names(commute_df) <- 1:nrow(commute_df)
        
        commute_df <- commute_df %>%
            mutate(percent_drive_alone = total_drive_alone / total_transit) %>%
            select(schooldistrictunified, percent_drive_alone)
        
        travel_times_df <- full_join(travel_times_df, 
                                     commute_df, 
                                     by = "schooldistrictunified")
        
        
        census_data <- rbind(travel_times_df, census_data)
        
    }
    
    # Clean up tables
    rownames(census_data) <- 1:nrow(census_data)
    
    write_csv(census_data, 'census_data.csv')

    # Then pull for elementary schools
    states <- c('AZ', 'CA', 'CT', 'GA', 'IL', 'KY', 'ME', 'MA', 'MI', 'MN', 'MO', 'MT', 'NH', 'NJ', 'NY', 'ND', 'OK', 'OR', 'RI', 'SC', 'TN', 'TX', 'VT', 'VA', 'WI', 'WY')
    
    # Build dataset from census for each state
    census_data_elem <- data.frame()
    
    for (s in seq_along(states)){
        print(states[s])
        
        # create a geographic set to grab tabular data (acs)
        geo <- geo.make(state=states[s], school.district.elementary = "*")
        
        travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                  table.number = "B08303", col.names = "pretty")
        
        # transform into data tables
        travel_times_df <- data.frame(travel_times@geography, 
                                      travel_times@estimate, 
                                      stringsAsFactors = FALSE)
        
        names(travel_times_df) <- c('district_name', 
                                    'state', 
                                    'schooldistrictunified',
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
        
        
        agg_travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                      table.number = "B08013", col.names = "pretty")
        
        # transform into data tables
        agg_travel_times_df <- data.frame(agg_travel_times@geography, 
                                          agg_travel_times@estimate, 
                                          stringsAsFactors = FALSE)
        
        names(agg_travel_times_df) <- c('district_name', 
                                        'state', 
                                        'schooldistrictunified',
                                        'agg_travel_time',
                                        'agg_travel_time_m',
                                        'agg_travel_time_f')
        
        row.names(agg_travel_times_df) <- 1:nrow(agg_travel_times_df)
        
        travel_times_df <- left_join(travel_times_df, agg_travel_times_df)
        
        travel_times_df <- travel_times_df %>%
            mutate(commute_under_30 = commute_Less_than_5_minutes + commute_5_to_9_minutes + 
                       commute_10_to_14_minutes + commute_15_to_19_minutes + commute_20_to_24_minutes + commute_25_to_29_minutes,
                   commute_greater_than_30 = total_commuters - commute_under_30,
                   percent_under_30 = commute_under_30 / total_commuters,
                   mean_commute_time = agg_travel_time / total_commuters)
        
        # Grab Latest population data
        population <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                table.number = "B01003", col.names = "pretty")
        
        # transform into data tables
        population_df <- data.frame(population@geography, 
                                    population@estimate, 
                                    stringsAsFactors = FALSE)
        
        names(population_df) <- c('district_name', 
                                  'state', 
                                  'schooldistrictunified',
                                  'total_population')
        
        
        row.names(population_df) <- 1:nrow(population_df)
        
        
        population_df <- select(population_df, schooldistrictunified, total_population)
        
        travel_times_df <- full_join(travel_times_df, 
                                     population_df, 
                                     by = "schooldistrictunified")
        
        # Grab commuting data on percent that drive alone
        commute <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                             table.number = "B08301", col.names = "pretty")
        
        # transform into data tables
        commute_df <- data.frame(commute@geography, 
                                 commute@estimate, 
                                 stringsAsFactors = FALSE)
        
        commute_df <- commute_df[,c(3,4,6)]
        
        names(commute_df) <- c('schooldistrictunified',
                               'total_transit',
                               'total_drive_alone')
        
        row.names(commute_df) <- 1:nrow(commute_df)
        
        commute_df <- commute_df %>%
            mutate(percent_drive_alone = total_drive_alone / total_transit) %>%
            select(schooldistrictunified, percent_drive_alone)
        
        travel_times_df <- full_join(travel_times_df, 
                                     commute_df, 
                                     by = "schooldistrictunified")
        
        
        census_data_elem <- rbind(travel_times_df, census_data_elem)
    }
    
    # Clean up tables
    rownames(census_data_elem) <- 1:nrow(census_data_elem)
    
    write_csv(census_data_elem, 'census_data_elem.csv')        

glimpse(census_data)
glimpse(census_data_elem)

census_data <- rbind(census_data, census_data_elem)


    # Then pull for elementary schools
    states <- c('AZ', 'CA', 'CT', 'GA', 'IL', 'KY', 'ME', 'MA', 'MN', 'MT', 'NH', 'NJ', 'NY', 'OK', 'OR', 'RI', 'SC', 'TN', 'TX', 'VT', 'WI')
    
    # Build dataset from census for each state
    census_data_sec <- data.frame()
    
    for (s in seq_along(states)){
        print(states[s])
        
        # create a geographic set to grab tabular data (acs)
        geo <- geo.make(state=states[s], school.district.secondary = "*")
        
        travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                  table.number = "B08303", col.names = "pretty")
        
        # transform into data tables
        travel_times_df <- data.frame(travel_times@geography, 
                                      travel_times@estimate, 
                                      stringsAsFactors = FALSE)
        
        names(travel_times_df) <- c('district_name', 
                                    'state', 
                                    'schooldistrictunified',
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
        
        
        agg_travel_times <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                      table.number = "B08013", col.names = "pretty")
        
        # transform into data tables
        agg_travel_times_df <- data.frame(agg_travel_times@geography, 
                                          agg_travel_times@estimate, 
                                          stringsAsFactors = FALSE)
        
        names(agg_travel_times_df) <- c('district_name', 
                                        'state', 
                                        'schooldistrictunified',
                                        'agg_travel_time',
                                        'agg_travel_time_m',
                                        'agg_travel_time_f')
        
        row.names(agg_travel_times_df) <- 1:nrow(agg_travel_times_df)
        
        travel_times_df <- left_join(travel_times_df, agg_travel_times_df)
        
        travel_times_df <- travel_times_df %>%
            mutate(commute_under_30 = commute_Less_than_5_minutes + commute_5_to_9_minutes + 
                       commute_10_to_14_minutes + commute_15_to_19_minutes + commute_20_to_24_minutes + commute_25_to_29_minutes,
                   commute_greater_than_30 = total_commuters - commute_under_30,
                   percent_under_30 = commute_under_30 / total_commuters,
                   mean_commute_time = agg_travel_time / total_commuters)
        
        # Grab Latest population data
        population <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                                table.number = "B01003", col.names = "pretty")
        
        # transform into data tables
        population_df <- data.frame(population@geography, 
                                    population@estimate, 
                                    stringsAsFactors = FALSE)
        
        names(population_df) <- c('district_name', 
                                  'state', 
                                  'schooldistrictunified',
                                  'total_population')
        
        
        row.names(population_df) <- 1:nrow(population_df)
        
        
        population_df <- select(population_df, schooldistrictunified, total_population)
        
        travel_times_df <- full_join(travel_times_df, 
                                     population_df, 
                                     by = "schooldistrictunified")
        
        # Grab commuting data on percent that drive alone
        commute <- acs.fetch(endyear = 2015, span = 5, geography = geo,
                             table.number = "B08301", col.names = "pretty")
        
        # transform into data tables
        commute_df <- data.frame(commute@geography, 
                                 commute@estimate, 
                                 stringsAsFactors = FALSE)
        
        commute_df <- commute_df[,c(3,4,6)]
        
        names(commute_df) <- c('schooldistrictunified',
                               'total_transit',
                               'total_drive_alone')
        
        row.names(commute_df) <- 1:nrow(commute_df)
        
        commute_df <- commute_df %>%
            mutate(percent_drive_alone = total_drive_alone / total_transit) %>%
            select(schooldistrictunified, percent_drive_alone)
        
        travel_times_df <- full_join(travel_times_df, 
                                     commute_df, 
                                     by = "schooldistrictunified")
        
        
        census_data_sec <- rbind(travel_times_df, census_data_sec)
    }
    
    # Clean up tables
    rownames(census_data_sec) <- 1:nrow(census_data_sec)
    
    write_csv(census_data_sec, 'census_data_sec.csv')        

glimpse(census_data)
glimpse(census_data_sec)

census_data <- rbind(census_data, census_data_sec)

census_data <- census_data %>%
    mutate_each_(funs("as.character"), "state") %>%
    mutate(district_fips = str_c(str_pad(state, 2, side = "left", pad = "0"),
                                 str_pad(schooldistrictunified, 5, side = "left", pad = "0"))) %>%
    select(district_fips, everything()) %>%
    arrange(desc(total_population))

# De-dupe
census_data <- unique(census_data)


census_data <- census_data %>%
    select(district_fips, district_name, percent_under_30, 
           total_population, percent_drive_alone, mean_commute_time)
glimpse(census_data)

census_data <- census_data %>%
    group_by(district_fips) %>%
    arrange(district_fips, desc(total_population)) %>%
    slice(1)

write_csv(census_data, 'census_data_full.csv')
