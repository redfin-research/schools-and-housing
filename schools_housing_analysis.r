#############################################
# School Quality and Housing Affordability
# By Taylor Marr
# with the NYTimes
#############################################

rm(list=ls(all.names = TRUE))

# Set Directory
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/GitHub Files District/")

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

print(great_schools_ratings %>%
          group_by(metropolitan_statistical_area) %>%
          summarise(districts = n_distinct(district_nces_code)) %>%
          arrange(desc(districts)), n = 100)
    
housing_cost <- read_csv("housing_cost_data.csv")

glimpse(housing_cost)
summary(housing_cost)

hist(housing_cost$median_sale_price, 30)
hist(housing_cost$median_sale_price_per_sqft, 30)

housing_cost_controlled <- read_csv("housing_cost_controlled_data.csv")

glimpse(housing_cost_controlled)
summary(housing_cost_controlled)

hist(housing_cost_controlled$median_sale_price, 30)
hist(housing_cost_controlled$median_sale_price_per_sqft, 30)

# Pull it all together
full_dataset <- merge(great_schools_ratings, housing_cost_controlled, by = "district_nces_code")

glimpse(full_dataset)

# Plot the data
(graphic <- ggplot(full_dataset, 
                   aes(avg_school_rating, median_sale_price)) +
    geom_smooth(method = 'glm', se = F, show.legend = F, color = '#008FD5') +
    geom_jitter(alpha = 0.6, show.legend = F, width = 0.2,
                aes(size = total_students, color = '#008FD5')) +
    scale_y_log10(breaks = c(25000, 50000, 100000, 200000, 400000, 800000, 1600000), 
                  labels = c('$25k', '$50k', '$100k', '$200k', '$400k', '$800k', '$1.6m')) +
    ggtitle("Housing Affordability and Quality of Schools",
            subtitle = "Each circle is a school district, sized by number of students") +
    theme_fivethirtyeight() +
    theme(axis.title = element_text(size = rel(.8)),
          plot.caption = element_text(size = rel(.8))) +
    labs(x="Average School Rating", 
        y="Median Home Sale Price", 
        caption = "Source: GreatSchools; Redfin") +
    scale_color_fivethirtyeight())

ggsave('housing_affordability_school_quality_graphic.png')

