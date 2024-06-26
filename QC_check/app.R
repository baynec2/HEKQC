#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(ggplot2)
library(ggVennDiagram)
library(DBI)
library(plotly)


ggplot2::theme_set(theme_minimal())

# Define UI for application that draws a histogram
ui <- dashboardPage(
  # skin = "midnight",
  dashboardHeader(title = "HEK Quality Control"),
  dashboardSidebar(
    sidebarMenu(
      # Making the tabs
      menuItem("Metrics", tabName = "Metrics",
               icon = icon("magnifying-glass-chart")),
      menuItem("Chromatograms",
               tabName = "Chromatograms", icon = icon("chart-simple")),
      menuItem("Shared Proteins", tabName = "shared_proteins", icon = icon("share"
      ))
     
    ),
    dateRangeInput(
      "date_range",
      "date_range",
      start = (Sys.Date()-14),
      end = NULL,
      min = NULL,
      max = NULL,
      format = "yyyy-mm-dd",
      startview = "year",
      weekstart = 0,
      language = "en",
      separator = " to ",
      width = NULL,
      autoclose = TRUE
    ),
    actionButton("new_data", "add_new_data")
  ),
  dashboardBody(
   tabItems(
    tabItem(tabName = "Metrics",
            h1("HEK QC Metrics"),
            fluidRow(
              box(title = "Filesize",
                  plotlyOutput("filesize_plot")
                  ),
            box(title = "Protein IDs",
                plotlyOutput("protein_plot"))
              ),
              box(title = "Peptide IDs",
                  plotlyOutput("peptide_plot")),
            box(title = "Percent Coverage",
                plotlyOutput("protein_coverage_plot")),
            box(title = "Filesize Protein Correlation",
                plotlyOutput("correlation_plot"))
            )
    ,
    ### Comparison between E. faecalis and E. faecium ###
    tabItem(tabName = "Chromatograms",
            fluidPage(
              box(title = "HEK Chrmoatograms",
                  plotOutput("chromatogram_plot",
                             width = "100%",height = "1000px"))
            )
    ),
    tabItem(tabName = "shared_proteins",
            fluidPage(
              box(title = "Overlap Plot",
                  plotOutput('overlap_plot',brush = "plot_brush"))
)
)
)
)
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  ###Loading in all the data###
  
  #function to perform sql query
  sql_query = function(min_date, max_date, table){
   query = paste0("SELECT * FROM ", table,
                  " WHERE date(Date) >= ", paste0("\"",min_date,"\""),
                  " AND date(Date) <= ",  paste0("\"",max_date,"\""))
    
    #query = paste0("SELECT * FROM ", table)
    ## Connect to database ### 
    db = dbConnect(RSQLite::SQLite(), "../hek.db")
    res = dbGetQuery(db, query) 
    dbDisconnect(db)
    return(res)
  }
  
  
  
  ### Loading data ###
  protein = reactive({
    sql_query(input$date_range[[1]],input$date_range[[2]],"protein")
  })
  peptide = reactive({
    sql_query(input$date_range[[1]],input$date_range[[2]],"peptide")
  })
  chromatogram = reactive({
    sql_query(input$date_range[[1]],input$date_range[[2]],"chromatogram")
  })
  filesize = reactive({
    sql_query(input$date_range[[1]],input$date_range[[2]],"filesize")
  })
  

  ### Metrics Tab ###
    output$filesize_plot <- renderPlotly({
      
      filesize_plot = filesize() %>% 
        ggplot(aes(as.Date(Date),Filesize_mb))+
        geom_point(aes(text = Filename))+
        geom_line()+
        xlab("Date")+
        ylab("File Size (MB)")
      
      plotly::ggplotly(filesize_plot)

    })
    
    output$protein_plot <- renderPlotly({
      
      protein_sum = protein() %>%
        dplyr::group_by(Filename,Date) %>%
        dplyr::summarise(n = n())
      
      
      protein_plot = protein_sum %>% 
        ggplot(aes(as.Date(Date),n))+
        geom_point(aes(text = Filename))+
        geom_line()+
        xlab("Date")+
        ylab("n Proteins")
      
      plotly::ggplotly(protein_plot)
      
    })
    
    output$peptide_plot <- renderPlotly({
      
      peptide_sum = peptide() %>%
        dplyr::group_by(Filename,Date) %>%
        dplyr::summarise(n = n())
      
      peptide_plot = peptide_sum %>% 
        ggplot(aes(as.Date(Date),n))+
        geom_point(aes(text = Filename))+
        geom_line()+
        xlab("Date")+
        ylab("n Peptides")
      
      plotly::ggplotly(peptide_plot)
      
    })
    
    
    output$protein_coverage_plot <- renderPlotly({
      
      protein_coverage_plot = protein() %>% 
        ggplot(aes(`Coverage`,color = Filename, text = Date)) +
        geom_density()+
        xlab("Protein Coverage")+
        theme(legend.position = "none")
      
      plotly::ggplotly(protein_coverage_plot)
      
    })
    
    
    output$correlation_plot <- renderPlotly({
      
      all = inner_join(protein_sum,
                       filesize(),
                       by = c("Filename","Date"))
      
      lm = lm(n ~ Filesize_mb,data = all)
        
      sum = summary(lm)

      coorelation_plot = all %>% 
        ggplot(aes(n,Filesize_mb)) +
        geom_point(aes(text = Filename))+
        geom_smooth(method = "lm")+
        xlab("N Protein ID")+
        ylab("Filesize")+
        annotate("text", x = 4000,y =400,
                 label = paste0("R2 = ",round(sum$r.squared,2)))
  
      
      plotly::ggplotly(coorelation_plot)
      
    })
    
    
  ### Chromatogram Tab ###  
    
    
    output$chromatogram_plot <- renderPlot({
      
      chromatogram_plot = chromatogram() %>%  
        ggplot(aes(RT,tic))+
        geom_line()+
        facet_wrap(~ Date+ Filename,nrow = length(unique(chromatogram()$Filename)))
      
      chromatogram_plot
      
    }
      )


## Shared Protein Tab

output$overlap_plot <- renderPlot({
  
  listp = list()
  
  for( i in unique(protein()$Filename)){
    
    filter = protein() %>% 
      dplyr::filter(Filename == i) %>% 
      pull(`Protein ID`)
    
    listp[[i]] = filter
    
  }
  
  upset_plot = ggVennDiagram::ggVennDiagram(x = listp)
  
  upset_plot
  
})


## Adding new data ###

#observeEvent(input$new_data, {
 # system2("sh ../hek_lf.sh")
  
  
#})

}



# Run the application 
shinyApp(ui = ui, server = server)
