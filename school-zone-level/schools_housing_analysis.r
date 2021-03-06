#############################################
# School Quality and Housing Affordability by Zone
# By Taylor Marr
# with the NYTimes
#############################################

rm(list=ls(all.names = TRUE))

# Set Directory
setwd("~/Google Drive/PRTeam Analysis/Misc/2017-02 Misc/New York Times School Viz/GitHub Files School Zone/")

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

hist(great_schools_ratings$great_schools_rating, 10)

great_schools_ratings %>%
          dplyr::group_by(district_nces_code, district_name) %>%
          dplyr::summarise(n_schools = n_distinct(nces_code)) %>%
          arrange(desc(n_schools))

# Top 10 metros for top schools
great_schools_ratings %>%
    dplyr::group_by(redfin_metro) %>%
    dplyr::summarise(n_schools = n_distinct(nces_code),
                    n_top_schools = n_distinct(nces_code[school_quality=='top_school']),
                    percent_top_schools = n_top_schools / n_schools) %>%
    dplyr::filter(n_top_schools >= 5) %>%
    dplyr::arrange(desc(percent_top_schools))
    
# Top 10 metros for poor schools
great_schools_ratings %>%
    dplyr::group_by(redfin_metro) %>%
    dplyr::summarise(n_schools = n_distinct(nces_code),
              n_poor_schools = n_distinct(nces_code[school_quality=='poor_school']),
              percent_poor_schools = n_poor_schools / n_schools) %>%
    dplyr::filter(n_poor_schools >= 5) %>%
    dplyr::arrange(desc(percent_poor_schools))


housing_cost <- read_delim("housing_cost_data.csv", delim = ';')

glimpse(housing_cost)
summary(housing_cost)

filter(housing_cost, total_sales==max(total_sales))

# removed bad data
# View(filter(housing_cost, median_sale_price_per_sqft>=5000))
housing_cost$median_sale_price_per_sqft[housing_cost$median_sale_price_per_sqft >= 5000 & !is.na(housing_cost$median_sale_price_per_sqft)] <- NA

hist(housing_cost$median_sale_price, 30)
hist(housing_cost$median_sale_price_per_sqft, 30)

housing_cost_controlled <- read_delim("housing_cost_controlled_data.csv", delim = ';')

glimpse(housing_cost_controlled)
summary(housing_cost_controlled)

housing_cost_controlled$median_sale_price_per_sqft[housing_cost_controlled$median_sale_price_per_sqft >= 5000 & !is.na(housing_cost_controlled$median_sale_price_per_sqft)] <- NA

hist(housing_cost_controlled$median_sale_price, 30)
hist(housing_cost_controlled$num_bedrooms, 30)
hist(housing_cost_controlled$median_sale_price_per_sqft, 30)

ttl_sales <- sum(housing_cost_controlled$total_sales)

housing_cost_controlled %>% 
    dplyr::group_by(property_type) %>% 
    dplyr::summarise(sales = sum(total_sales), 
              as_pct = scales::percent(sales/ttl_sales)) %>% 
    dplyr::arrange(desc(sales))

# Pull it all together
full_dataset <- merge(great_schools_ratings, 
                      select(
                        housing_cost
                        , -school_name
                        , -district_nces_code
                        , -district_name
                        , -cbsa_title), 
                      by.x = "nces_code", 
                      by.y = "school_nces_code",
                      all.x = T)

glimpse(full_dataset)

write_csv(full_dataset, "combined_school_zone_data.csv")

# Plot the data
(graphic <- ggplot(full_dataset, 
                   aes(great_schools_rating, median_sale_price_per_sqft)) +
    geom_smooth(se = F, show.legend = F, color = '#008FD5') +
    geom_jitter(alpha = 0.6, show.legend = F, width = 0.25, size = 0.8,
                aes(size = number_of_students, color = '#008FD5')) +
    scale_y_log10(labels=scales::dollar) +
    ggtitle("Housing Affordability and Quality of Schools",
            subtitle = "Each circle is a school zone, sized by number of students") +
    theme_fivethirtyeight() +
    theme(axis.title = element_text(size = rel(.8)),
          plot.caption = element_text(size = rel(.8))) +
    labs(x="School Rating", 
        y="Median Home Price per sqft", 
        caption = "Data Source: GreatSchools; Redfin") +
    scale_color_fivethirtyeight())

ggsave('housing_affordability_school_quality_graphic.png')

(graphic_overall <- full_dataset %>%
        dplyr::group_by(great_schools_rating) %>%
        dplyr::summarise(price_per_sqft = mean(median_sale_price_per_sqft, na.rm = T)) %>%
        ggplot(., 
                   aes(great_schools_rating, price_per_sqft)) +
        geom_bar(stat = "identity", show.legend = F, aes(fill = '#008FD5')) +
        scale_y_continuous(labels=scales::dollar) +
        scale_x_continuous(breaks=c(1:10), labels = as.character(c(1:10))) +
        ggtitle("Housing Cost and Quality of Schools",
                subtitle = "Average Home Price per sqft by Great School Rating") +
        theme_fivethirtyeight() +
        theme(plot.caption = element_text(size = rel(.8))) +
        labs(x="", y="", caption = "Data Source: GreatSchools; Redfin") +
        scale_fill_fivethirtyeight())

ggsave('overall_housing_cost_vs_school_quality_graphic.png')

# Should repull data directly from SQL to avoid an average of medians
metro_premium_data <- full_dataset %>%
    dplyr::group_by(redfin_metro, school_quality) %>%
    dplyr::summarise(price_per_sqft = mean(median_sale_price_per_sqft, na.rm = T)) %>%
    dplyr::arrange(redfin_metro, price_per_sqft) %>%
    dplyr::mutate(price_per_sqft_diff = price_per_sqft - first(price_per_sqft))

# 20 most expensive only
metros <- metro_premium_data %>% 
    dplyr::group_by(redfin_metro) %>%
    dplyr::filter(school_quality=='top_school') %>%
    dplyr::arrange(desc(price_per_sqft)) %>%
    dplyr::ungroup() %>%
    dplyr::slice(1:20)

# Slight update of data from this post:
# https://www.redfin.com/blog/2013/09/paying-more-for-a-house-with-a-top-public-school-its-elementary.html
(metro_premiums <- ggplot(filter(metro_premium_data, redfin_metro %in% metros$redfin_metro), 
               aes(redfin_metro, price_per_sqft)) +
        geom_point(size=3, alpha = 0.8, show.legend = T, aes(col = school_quality)) +
        coord_flip() +
        scale_y_continuous(labels=scales::dollar) +
        scale_x_discrete(limits = rev(metros$redfin_metro)) +
        ggtitle("Housing Cost Premium for Quality of Schools",
                subtitle = "Average Home Price per sqft by Great School Rating") +
        theme_fivethirtyeight() +
        theme(plot.caption = element_text(size = rel(.8))) +
        labs(x="", y="", caption = "Data Source: GreatSchools; Redfin", col="") +
        scale_color_economist(limits=c("poor_school", "average_school", "top_school"),
                                    labels=c("Poor School", "Average School", "Top School")))

ggsave('overall_housing_cost_premium_by_metro_graphic.png')

