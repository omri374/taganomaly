# taganomaly
Anomaly detection labeling tool, specifically for multiple time series (one time series per category)


## Requirements
- R (3.4.0 or above)
### Used packages: 
- shiny
- dplyr
- gridExtra
- shinyDashboard
- DT
- ggplot2


packages should be installed upon start if missing (see [global.R])

## How to run:
This tool uses the [shiny framework](https://shiny.rstudio.com/) for visualizing events.
In order to run it, you need to have [R](https://mran.microsoft.com/download) and preferably [Rstudio](https://www.rstudio.com/products/rstudio/download/).
Once you have everything installed, open the project on R studio and click "Run App", or call runApp() from the console.

## Instructions
1. Import time series CSV file. Assumed structure:
- date ("%Y-%m-%d %H:%M:%S")
- category
- value

2. (Optional) Import raw data time series CSV file.

If the original time series is an aggreation over time windows, this time series is the raw values themselves. This way we could dive deeper into an anomalous value and see what it is comprised of.
Assumed structure:
- date ("%Y-%m-%d %H:%M:%S")
- category
- value

2. Select category (if exists)

3. Select time range on slider

4.Select points on plot that look anomalous.
Optional (1): click on one time range on the table below the plot to see raw data on this time range
Optional (2): Open the "All Categories" tab to see how other time series behave on the same time range.
5. Once you decide that these are actual anomalies, save the resulting table to csv by clicking on "Download labels set" and continue to the next category.