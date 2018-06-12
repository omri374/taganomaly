library(shiny)
library(dplyr)
library(shinyBS)
server <- function(input,output, session) {
  INTERACTIONS <- c('like','assumedLike','love','wow','haha','sad','angry')
  SHARES <- c('retweet','share')
  library(DT) 
  library(ggplot2) 
  
  getDataset <- reactive({
    groupid = input$groupid
    dataset <- read.csv(paste0('../fashionista/exploratory/data/',groupid,'/',groupid,'-12H.csv'),stringsAsFactors = F)
    dataset$date <- as.POSIXct(dataset$date,tz = 'UTC')
    twelve_hours <- data.frame(date = seq.POSIXt(min(dataset$date), max(dataset$date), by="12 h"))
    full_df <- full_join(dataset,twelve_hours) %>% mutate_each(funs(ifelse(is.na(.),0,.)))%>% arrange(date)
    full_df$date <- as.POSIXct(full_df$date,tz='UTC',origin = "1970-01-01")
    full_df$sampleId <- 1:nrow(full_df)
    full_df
  })
  
  getCategoryDataset <- reactive({
    cate <- input$category
    if(is.null(cate)) return(NULL)
    
    dataset <- getDataset() %>% filter(category == cate)
    dataset
  })
  
  output$slider <- renderUI({
    dataset <- getCategoryDataset()
    if(is.null(dataset)) return(NULL)
    dataset <- dataset %>% arrange(date)
    
    mini = as.POSIXct(min(dataset$date),origin = '1970-01-01',tz = 'UTC')
    maxi = as.POSIXct(max(dataset$date),origin = '1970-01-01',tz = 'UTC')
    
    #mini = dataset[1,'start']
    threeMonthsAgo <- maxi - 60*60*24*90 # last 3 months
    minValueToShow <- as.POSIXct(ifelse(threeMonthsAgo > mini,threeMonthsAgo,mini),origin = '1970-01-01',tz = 'UTC')
    s <- sliderInput("slider","Time range",min = mini,max = maxi,value = c(minValueToShow,maxi),step = 1)
    s
  })
  
  getTimeFilteredCategoryDataset <- reactive({
    dataset <- getCategoryDataset()
    if(is.null(dataset)) return(NULL)
    if(is.null(input$slider)) return(NULL)
    
    dataset %>% filter(date >= input$slider[1], date <= input$slider[2])
  })
  
  getTimeFilteredDataset <- reactive({
    dataset <- getDataset()
    if(is.null(dataset)) return(NULL)
    if(is.null(input$slider)) return(NULL)
    
    dataset %>% filter(date >= input$slider[1], date <= input$slider[2])
  })
  
  
  selectedPoints <- reactive({
    user_brush <- input$user_brush
    brushedPoints(getTimeFilteredCategoryDataset(), user_brush, xvar = "date", yvar = "itemWeightSum")
  })
  
  getRawData <- reactive({
    groupid <- input$groupid
    cate <- input$category
    
    raw <- read.csv(paste0('../fashionista/exploratory/data/',groupid,'/',groupid,'-raw.csv'),stringsAsFactors = F)
    raw$date <- as.POSIXct(raw$date_hour_res,tz = 'UTC',format = '%Y-%m-%d %H:%M')
    raw <- raw %>% filter(category == cate)
    
    raw
  })
  
  getRawDataForSample <- reactive({
    lastclicked <- input$summaryTable_rows_selected
    if(is.null(lastclicked)) return(NULL)
    
    raw <- getRawData()
    selected <- selectedPoints()
    if(is.null(selected)) return(NULL)
    
    sampleDate <- selected[lastclicked,'date']
    
    #get only this window
    
    
    raw <- raw %>% filter(date >= sampleDate & date < sampleDate + 12*60*60)
    
    
    if(!is.null(raw$parent)){
      
      #count interactions
      interactions <- raw %>% 
        filter(content %in% INTERACTIONS) %>%
        group_by(parent) %>% summarize(interaction_count = n())
      raw <- raw %>% left_join(interactions,by=c('id'='parent'))
      
      #count shares
      shares <- raw %>% filter(content %in% SHARES) %>%
        group_by(parent) %>% summarize(share_count = n())
      raw <- raw %>% left_join(shares,by=c('id'='parent'))
      
      raw <- raw %>% filter(!(content %in% c(INTERACTIONS,SHARES)))  %>% select(date,category,content,share_count,interaction_count)
    } else{
      raw <- raw %>% select(date,category,content)
    }
    
    
    raw
    
  })
  
  
  
  output$category <- renderUI({
    dataset <- getDataset()
    if(is.null(dataset)){
      return(NULL)
    }
    selectInput("category", "Choose category:", as.list(unique(dataset$category)),selected = unique(dataset$category)[1],multiple = F) 
  })
  
  output$plot <- renderPlot({
    categoryDataset <- getTimeFilteredCategoryDataset()
    if(is.null(categoryDataset)) return(NULL)
    ggplot(categoryDataset, aes(date, itemWeightSum)) +
      geom_point(size = 3) +
      geom_line() + 
      #geom_smooth(method = lm, formula = formula, fullrange = TRUE, color = "gray50") +
      #geom_point(data = exclude, fill = NA, color = "black", size = 3, alpha = 0.25) +
      scale_y_continuous(labels = scales::comma) + 
      scale_x_datetime(date_breaks = '1 day') + 
      #coord_cartesian(xlim = range(data[[xvar]]), ylim = range(data[[yvar]])) +
      theme(axis.text.x = element_text(angle = 90, hjust = 1))
  })
  
  output$allplot <- renderPlot({
    
    dataset <- getTimeFilteredDataset()
    categoryDataset <- getTimeFilteredCategoryDataset()
    minDate = min(categoryDataset$date)
    maxDate = min(categoryDataset$date)
    categories <- table(dataset$category)
    categories <- categories[categories > input$minPerCategory]
    
    dataset <- dataset %>% filter(category %in% names(categories))
    
    if(nrow(dataset) == 0) return(NULL)
    
    dataset %>%
      ggplot(aes(date, itemWeightSum)) +
      #geom_point(color = "#2c3e50", alpha = 0.5) +
      geom_point(stat="identity") +
      facet_grid(category ~. , scales = 'free') +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      scale_y_continuous(labels = scales::comma) + scale_x_datetime(date_breaks = '1 day')#,limits = c(minDate,maxDate))
    
  }, height = 600)
  
  
  
  output$summaryTable <- DT::renderDataTable(expr = {DT::datatable(selectedPoints())})
  
  data_to_display<-eventReactive(input$summaryTable_rows_selected,ignoreNULL=TRUE,
                                 getRawDataForSample()
  )
  
  output$rawtable<-DT::renderDataTable(data_to_display(),options = list(
    pageLength = 25))
  
  
  output$mydownload <- downloadHandler(
    filename = paste0(input$groupid,'-',input$category,'-labels.csv'),
    content = function(filename) {write.csv(selectedPoints(), filename)}
  )
}

ui <- fluidPage(
  h1('Taganomaly - Anomaly detection labeling tool'),
  h2('Tag events on a time series for different categories (multiple time series)'),
  
  fluidRow(
    column(3,
           textInput('groupid','groupid',value = 'corona')
    ),
    column(3,
           uiOutput("category")
    ),
    column(3,
           uiOutput('slider')
    )
  ),
  
  h5('Instructions: select groupid and category, then select points on plot. Once you decide that these are actual anomalies, save the resulting table to csv and continue to the next category.'),
  
  h2('events per 12 hours:'),
  
  plotOutput("plot", brush = "user_brush"),
  h2('Selected points:'),
  dataTableOutput("summaryTable"),
  
  downloadButton(outputId = "mydownload", label = "Download labels set"),
  h2('Inspect raw data:'),
  dataTableOutput("rawtable"),
  
  h2('Inspect all other categories:'),
  numericInput('minPerCategory','Minimum samples for being a major category',min = 0,value = 100),
  bsCollapse(id = "collapseExample", open = "Panel 1",
             #bsCollapsePanel("Panel 1", "Category time series plot",,
             bsCollapsePanel("All major categories", "",plotOutput("allplot")
             ))
  
)

shinyApp(ui = ui, server = server)