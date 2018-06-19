### This function return anomalizes based on Twitter's module found in https://github.com/twitter/AnomalyDetection
find_anomalies_twitter <- function(categoryDataset){
  
  ## Install AnomalyDetection if not instaled
  if(!require(AnomalyDetection)) install.packages('AnomalyDetection')
  library(AnomalyDetection)
  library(dplyr)
  
  categoryDataset <- categoryDataset %>% select(date, value)
  res <- AnomalyDetectionTs(categoryDataset, threshold='p95', direction='pos', plot=TRUE, title='Anomalies found using Twitter\'s anomaly detection.')
  res
}
