#############################################
# School Quality and Housing Affordability
# By Taylor Marr
# with the NYTimes
#############################################

rm(list=ls(all.names = TRUE))

# Set Directory
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/GitHub Files City/")

# Load Packages
packagesRequired <- c('stringr',
                      'ggthemes',
                      'tidyverse')

packagesMissing <- packagesRequired[!(packagesRequired %in% installed.packages())]
for (package in packagesMissing) {
    install.packages(package, repos='http://cran.rstudio.com/')
}
for (package in packagesRequired){
    eval(parse(text=paste0('library(', package, ')')))
}

# View data files
list.files(pattern = '.csv')

# Full GreatSchools Ratings Methodology here:
# http://www.greatschools.org/gk/wp-content/uploads/2016/07/GreatSchools_Ratings_Methodology_Report.pdf
great_schools_ratings <- read_csv("great_schools_data.csv")

glimpse(great_schools_ratings)

summary(great_schools_ratings)

hist(great_schools_ratings$avg_school_rating, 10)

# Number of cities by metro
great_schools_ratings %>%
          group_by(metropolitan_statistical_area) %>%
          summarise(cities = n_distinct(place_id)) %>%
          arrange(desc(cities))


# Controls for single-family 2 bedroom residences between 1k and 2k sqft sold in 2016
housing_cost_controlled <- read_csv("housing_cost_controlled_data.csv")

glimpse(housing_cost_controlled)
summary(housing_cost_controlled)

hist(housing_cost_controlled$median_sale_price, 30)
hist(housing_cost_controlled$median_sale_price_per_sqft, 30)

# Pull it all together
full_dataset <- merge(great_schools_ratings, housing_cost_controlled, by = "place_id")

glimpse(full_dataset)

# Calcluate differences between principal city and suburbs
full_dataset <- full_dataset %>%
    dplyr::group_by(metropolitan_statistical_area) %>%
    dplyr::arrange(metropolitan_statistical_area, is_suburb) %>%
    dplyr::mutate(median_sale_price_diff = median_sale_price - first(median_sale_price),
                  median_sale_price_pct_diff = median_sale_price_diff 
                    / first(median_sale_price) * 100,
                  median_ppsf_diff = median_sale_price_per_sqft - 
                        first(median_sale_price_per_sqft),
                  median_sale_price_pct_diff = median_sale_price_per_sqft 
                    / first(median_sale_price_per_sqft) * 100,
                  avg_rating_diff = avg_school_rating - first(avg_school_rating),
                  best_rating_diff = best_rating - first(best_rating))

# Plot the data
(gs_graphic <- ggplot(great_schools_ratings, 
                      aes(avg_school_rating, percent_students_in_top_schools)) +
        geom_jitter(alpha = 0.6, show.legend = F, width = 0.2,
                    aes(size = total_students, color = '#008FD5')) +
        ggtitle("Quality of Schools",
                subtitle = "Each circle is a city, sized by number of students") +
        theme_fivethirtyeight() +
        scale_y_continuous(labels=scales::percent) +
        theme(axis.title = element_text(size = rel(.8)),
              plot.caption = element_text(size = rel(.8))) +
        labs(x="Average School Rating", 
             y="Percentage of Students in a Top School", 
             caption = "Source: GreatSchools") +
        scale_color_fivethirtyeight())

ggsave('school_quality_graphic.png')

(city_suburb_graphic <- ggplot(filter(full_dataset, is_suburb == 'suburb'), 
                   aes(avg_rating_diff, median_ppsf_diff, color = '#008FD5')) +
        geom_smooth(method = 'glm', se = F, show.legend = F) +
        geom_jitter(alpha = 0.6, show.legend = F, width = 0.1,
                    aes(size = total_students)) +
        scale_y_continuous(labels = scales::dollar) +
        ggtitle("Cheaper Housing and Better Schools",
                subtitle = "Each circle is a suburb, sized by number of students") +
        theme_fivethirtyeight() +
        theme(axis.title = element_text(size = rel(.8)),
              plot.caption = element_text(size = rel(.8))) +
        labs(x="Difference in Average School Rating", 
             y="Difference in Home Price per sqft", 
             caption = "Source: GreatSchools; Redfin") +
        scale_color_fivethirtyeight())

ggsave('suburban_affordability_vs_school_quality.png')

(graphic <- ggplot(full_dataset, 
                   aes(avg_school_rating, median_sale_price, color = '#008FD5')) +
    geom_smooth(method = 'loess', se = F, show.legend = F) +
    geom_jitter(alpha = 0.6, show.legend = F, width = 0.2,
                aes(size = total_students)) +
    scale_y_log10(breaks = c(25000, 50000, 100000, 200000, 400000, 800000, 1600000),
                  labels = c('$25k', '$50k', '$100k', '$200k', '$400k', '$800k', '$1.6m')) +
    ggtitle("Housing Affordability and Quality of Schools",
            subtitle = "Each circle is a city, sized by number of students") +
    theme_fivethirtyeight() +
    theme(axis.title = element_text(size = rel(.8)),
          plot.caption = element_text(size = rel(.8))) +
    labs(x="Average School Rating", 
        y="Median Home Sale Price", 
        caption = "Source: GreatSchools; Redfin") +
    scale_color_fivethirtyeight())

ggsave('housing_affordability_school_quality_graphic.png')

