# app.R

system(shQuote(paste0(getwd(), "/update.sh")), ignore.stdout = TRUE, ignore.stderr = TRUE)

library(tidyverse)
library(plotly)
library(htmlwidgets)
library(shiny)

# required_packages <-
#   c("tidyverse",
#     "plotly",
#     "htmlwidgets",
#     "shiny")
# 
# check_installed <- suppressWarnings(unlist(lapply(required_packages, require, character.only = TRUE)))
# needed_packages <- required_packages[check_installed == FALSE]
# install.packages(needed_packages)
# lapply(required_packages, require, character.only = TRUE)

data_list <- mapply(
  FUN = function(x) {
    data_func <- read.csv(file = paste0(getwd(), "/data/", x), skip = 3)
    return(data_func)
  }, 
  list.files("data/"),
  SIMPLIFY = FALSE
)
data_all <- bind_rows(data_list)

# Code for testing...

# plot_data <- data_all[, c("Date", "Hour", "Market.Demand")] %>%
#   pivot_wider(names_from = Date, values_from = Market.Demand) %>%
#   select(-Hour) %>% as.matrix()

# Runs a Shiny R app to interactively view Ontario market data by range

ui <- fluidPage(
  
  titlePanel("Ontario Hourly Demand for Electricity"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,

      p(span("Generate interactive plots of electricity demand in Ontario.", style = "color:blue")),
      
      radioButtons(inputId = "showhelp",
                   label = span("Display help text", style = "color:blue"),
                   choices = list("Yes" = TRUE, "No" = FALSE),
                   selected = TRUE
      ),
      
      selectInput(inputId = "uservar",
                  label = "Demand type",
                  choices = list("Market Demand" = "Market.Demand",
                                 "Ontario Demand" = "Ontario.Demand"),
                  selected = "Market Demand",
                  # choices = list("Market.Demand", "Ontario.Demand")
                  # choices = list("Sepal.Length", "Petal.Length")
                  ),
      
      conditionalPanel(
        condition = "input.showhelp == 'TRUE'",
        p(span(em("Market Demand"), " is the total demand for electricity in Ontario's electricity market.", style = "color:grey")),
        p(span(em("Ontario Demand"), " is the demand for electricity from Ontario alone.", style = "color:grey"))
      ),
      
      dateRangeInput(inputId = "dates", 
                     label = "Date range",
                     min = data_all[1, "Date"],
                     start = data_all[nrow(data_all)-365*24*2, "Date"],
                     max = data_all[nrow(data_all), "Date"],
                     end = data_all[nrow(data_all), "Date"]),
      
      conditionalPanel(
        condition = "input.showhelp == 'TRUE'",
        p(span("Data available from ", em(data_all[1, "Date"]), " to ", em(data_all[nrow(data_all), "Date"], .noWS = "after"), ".", .noWS = "after", style = "color:grey"))
      ),
      
      radioButtons(inputId = "autozaxis",
                   label = "Autoscale height",
                   choices = list("Yes" = TRUE, "No" = FALSE),
                   selected = TRUE
                   ),
      
      conditionalPanel(
        condition = "input.showhelp == 'TRUE'",
        p(span("Turn off autoscaling to facilitate comparisons across date ranges.", style = "color:grey"))
      ),
      
      conditionalPanel(
        condition = "input.autozaxis == 'FALSE'",
        sliderInput(inputId = "zaxislimits",
                    label = "Specify height limits",
                    min = 0, max = round(max(data_all[,3:4])+1000, -3),
                    value = c(0, round(max(data_all[,3:4]), -3)),
                    step = 1000),
        conditionalPanel(
          condition = "input.showhelp == 'TRUE'",
          p(span("Values below are with respect to the specified date range.", style = "color:grey"))
        ),
        tableOutput(outputId = "zaxistable")
      ),
      
      conditionalPanel(
        condition = "input.showhelp == 'TRUE'",
        hr(style = "border-top: 1px dotted #808080;"),
        p(a("Source", href = "http://reports.ieso.ca/public/Demand/")),
        p(span(em("Data are published by the Independent Electricity System Operator (IESO) of Ontario."), style = "color:grey")),
        p(span(em("Built by"), "Nathan K. Chan", em(" in ", strong("R"), "and", strong("Shiny", .noWS = "after"), ". Visit the project on Github ", a("here", href = "https://nathankchan.github.io/ontario-electricity-demand-viz/", .noWS = "after"), "."), style = "color:grey"))
      )
      
      # ,
      
      # Couldn't get rotation to work... see below.
      
      # radioButtons(inputId = "autorotate",
      #              label = "Rotate plot",
      #              choices = list("Yes" = TRUE, "No" = FALSE),
      #              selected = TRUE
      # )
      # ,

      # conditionalPanel(
      #   condition = "input.autorotate == 'TRUE'",
      #   numericInput(inputId = "rotatespeed",
      #                label = "Rotation speed",
      #                min = 0, max = 4,
      #                value = 1,
      #                step = 0.5)
      # )
      
      
      
    ),
    
    mainPanel(
      width = 9,
      tabsetPanel(
        tabPanel(
          title = "Interactive 3D Plot", 
          plotlyOutput(
            outputId = "display3dplot",
            width = "auto",
            height = "800px"))
        ,
        tabPanel(
          title = "Line Chart", 
          plotlyOutput(
            outputId = "displayline",
            width = "auto",
            height = "800px"))
        ,
        tabPanel(
          title = "Heat Map", 
          plotlyOutput(
            outputId = "displayheat",
            width = "auto",
            height = "800px"))
        # tabPanel(
        #   title = "Rotating Plot", 
        #   plotlyOutput(
        #     outputId = "rotateplot",
        #     width = "auto",
        #     height = "800px"))
      )
    )
    
  )
)


server <- function(input, output, session) {
  
  plot_3dinput <- reactive({

    start_date <- which(data_all$Date %in% as.character(input$dates[1]))[1]
    end_date <- which(data_all$Date %in% as.character(input$dates[2])) %>% .[length(.)]

    out <- data_all[start_date:end_date, c("Date", "Hour", input$uservar)] %>%
      pivot_wider(names_from = Date, values_from = all_of(input$uservar)) %>%
      select(-Hour) %>% as.matrix()

  })
  
  plot_lineinput <- reactive({
    
    start_date <- which(data_all$Date %in% as.character(input$dates[1]))[1]
    end_date <- which(data_all$Date %in% as.character(input$dates[2])) %>% .[length(.)]
    
    out <- data_all[start_date:end_date, c("Date", "Hour", input$uservar)]
    
    out <- cbind.data.frame(
      DateTime = as.POSIXct(out$Date) + out$Hour * 60 * 60,
      Demand = out[[input$uservar]]
    )
    
  })
  
  plot_heatinput <- reactive({
    
    start_date <- which(data_all$Date %in% as.character(input$dates[1]))[1]
    end_date <- which(data_all$Date %in% as.character(input$dates[2])) %>% .[length(.)]
    
    out <- data_all[start_date:end_date, c("Date", "Hour", input$uservar)]
    colnames(out)[3] <- "Demand"
    
    return(out)
    
  })
  
  output$zaxistable <- renderTable({
    
    start_date <- which(data_all$Date %in% as.character(input$dates[1]))[1]
    end_date <- which(data_all$Date %in% as.character(input$dates[2])) %>% .[length(.)]
    
    minmax <- data_all[start_date:end_date, input$uservar]
    minmax <- cbind.data.frame(
      Minimum = min(minmax), 
      Maximum = max(minmax))
    
    out <- minmax
    
  }, width = "100%", align = "c")
  
  # The problem with the rotating plot is that the `onRender()` javascript chunk
  # that enables rotation is "applied"/"appended" every time the figure is
  # updated. Consequently, the figure speeds up and spins faster with each
  # update as javascript chunks are appended. This bug appears to be the
  # consequence of an interaction between `Plotly.update()` and a loop created
  # by `requestAnimationFrame()` in the javascript. Cancelling the loop by
  # sending a message from R to javascript didn't seem to work... (neither did
  # `cancelAnimationFrame()`).
  
  # output$rotateplot <- renderPlotly({
  #   
  #   plot_data <- plot_input()
  #   
  #   if (ncol(plot_data) > 365) {
  #     xindex <- which(substr(colnames(plot_data), 9, 12) == "01")
  #     xindex <- xindex[seq(from = 1, to = length(xindex), by = floor(length(xindex)/12))]
  #   } else if (ncol(plot_data) > 12) {
  #     xindex <- seq(from = 1, to = ncol(plot_data), by = floor(ncol(plot_data)/12))
  #   } else {
  #     xindex <- seq_len(ncol(plot_data))
  #   }
  #   
  #   xlabels_df <- cbind.data.frame(
  #     xindex = xindex,
  #     xlabels = colnames(plot_data)[xindex] %>% as.Date() %>% format(., "%y-%b-%d (%a)")
  #   )
  #   
  #   
  #   plot_xaxis <- list(
  #     title = "",
  #     tickmode = "array",
  #     ticktext = xlabels_df$xlabels,
  #     tickvals = xlabels_df$xindex,
  #     range = c(1, ncol(plot_data)))
  #   
  #   plot_yaxis <- list(
  #     title = "",
  #     tickmode = "array",
  #     ticktext = c("0400h", "0800h", "1200h", "1600h", "2000h", "2400h"),
  #     tickvals = c(4, 8, 12, 16, 20, 24)
  #   )
  #   
  #   plot_zaxis <- list(
  #     title = "Demand (MW)"
  #   )
  #   
  #   if (input$autozaxis == FALSE) {
  #     plot_zaxis$range <- c(input$zaxislimits[1], input$zaxislimits[2])
  #   }
  #   
  #   plot_out <- plot_ly(z = ~ plot_data,
  #                       lighting = list(ambient = 0.9)) %>%
  #     add_surface(
  #       showscale = TRUE,
  #       colorbar = list(title = list(text = "Demand (MW)")),
  #       contours = list(
  #         z = list(
  #           show = FALSE,
  #           usecolormap = TRUE,
  #           highlightcolor = "#ff0000",
  #           project = list(z = F)
  #         )
  #       )
  #     ) %>%
  #     layout(
  #       # legend = list(text = "Demand (MW)"),
  #       scene = list(
  #         xaxis = plot_xaxis,
  #         yaxis = plot_yaxis,
  #         zaxis = plot_zaxis,
  #         scale = list(title = list(text = "Demand (MW)")),
  #         camera = list(
  #           eye = list(x = 1.5,
  #                      y = -1.5,
  #                      z = 0.75)
  #         ),
  #         aspectmode = "manual",
  #         aspectratio = list(
  #           x = 2,
  #           y = 1,
  #           z = 1
  #         ))
  #     ) %>%
  #     onRender("
  #     function(el, x, data){
  #       var id = el.getAttribute('id');
  #       var gd = document.getElementById(id);
  #       var pause = !data
  #       
  #       attach(Plotly.update(id));
  #       
  #       
  #     
  #       function attach() {
  #         run();
  #     
  #         function run() {
  #           if (!pause) {
  #             rotate('scene', Math.PI / 720);
  #             requestId = requestAnimationFrame(run);
  #           }
  #         }
  #     
  #         function rotate(id, angle) {
  #           var eye0 = gd.layout[id].camera.eye
  #           var rtz = xyz2rtz(eye0);
  #           rtz.t += angle;
  #     
  #           var eye1 = rtz2xyz(rtz);
  #           // if (!pause) {
  #             Plotly.relayout(gd, id + '.camera.eye', eye1);
  #           // }
  #           
  #         }
  #     
  #         function xyz2rtz(xyz) {
  #           return {
  #             r: Math.sqrt(xyz.x * xyz.x + xyz.y * xyz.y),
  #             t: Math.atan2(xyz.y, xyz.x),
  #             z: xyz.z
  #           };
  #         }
  #     
  #         function rtz2xyz(rtz) {
  #           return {
  #             x: rtz.r * Math.cos(rtz.t),
  #             y: rtz.r * Math.sin(rtz.t),
  #             z: rtz.z
  #           };
  #         }
  #       };
  #     }
  #   ", data = input$autorotate)
  #   
  #   return(plot_out)
  #   
  # })
  
  output$display3dplot <- renderPlotly({

    plot_data <- plot_3dinput()
    
    if (ncol(plot_data) > 365) {
      xindex <- which(substr(colnames(plot_data), 9, 12) == "01")
      xindex <- xindex[seq(from = 1, to = length(xindex), by = floor(length(xindex)/12))]
    } else if (ncol(plot_data) > 12) {
      xindex <- seq(from = 1, to = ncol(plot_data), by = floor(ncol(plot_data)/12))
    } else {
      xindex <- seq_len(ncol(plot_data))
    }
    
    xlabels_df <- cbind.data.frame(
      xindex = xindex,
      xlabels = colnames(plot_data)[xindex] %>% as.Date() %>% format(., "%y-%b-%d")
    )
    
    
    plot_xaxis <- list(
      title = "",
      tickmode = "array",
      ticktext = xlabels_df$xlabels,
      tickvals = xlabels_df$xindex,
      range = c(1, ncol(plot_data)))
    
    plot_yaxis <- list(
      title = "",
      tickmode = "array",
      ticktext = c("0400h", "0800h", "1200h", "1600h", "2000h", "2400h"),
      tickvals = c(4, 8, 12, 16, 20, 24)
    )
    
    plot_zaxis <- list(
      title = "Demand (MW)"
    )
    
    if (input$autozaxis == FALSE) {
      plot_zaxis$range <- c(input$zaxislimits[1], input$zaxislimits[2])
    }
    
    plot_out <- plot_ly(z = ~ plot_data,
            lighting = list(ambient = 0.9)) %>%
      add_surface(
        showscale = TRUE,
        colorbar = list(title = list(text = "Demand (MW)")),
        contours = list(
          z = list(
            show = FALSE,
            usecolormap = TRUE,
            highlightcolor = "#ff0000",
            project = list(z = F)
          )
        )
      ) %>%
      layout(
        title = list(text = paste0(
          "<br>Hourly Demand<br>(",
          input$dates[1] %>% as.Date() %>% format(., "%Y-%b-%d"),
          " to ",
          input$dates[2] %>% as.Date() %>% format(., "%Y-%b-%d"),
          ")"
        )),
        # legend = list(text = "Demand (MW)"),
        scene = list(
               xaxis = plot_xaxis,
               yaxis = plot_yaxis,
               zaxis = plot_zaxis,
               scale = list(title = list(text = "Demand (MW)")),
               camera = list(
                 eye = list(x = 1.5,
                            y = -1.5,
                            z = 0.75)
               ),
               aspectmode = "manual",
               aspectratio = list(
                 x = 2,
                 y = 1,
                 z = 1
               ))
      ) 
    
    return(plot_out)
    
  })
  
  output$displayline <- renderPlotly({
    
    plot_data <- plot_lineinput()
    
    plot_out <- ggplot(
      data = plot_data,
      aes(x = DateTime, y = Demand)
      ) + 
      geom_line(size = 0.1, color = "blue") +
      # geom_smooth(method = "loess", formula = y ~ x, span = 0.1) +
      labs(
        x = "Date", 
        y = "Demand (MW)",
        title = paste0(
          "Hourly Demand (",
          input$dates[1] %>% as.Date() %>% format(., "%Y-%b-%d"),
          " to ",
          input$dates[2] %>% as.Date() %>% format(., "%Y-%b-%d"),
          ")"
        )) +
      theme_light()
    
    if (input$autozaxis == FALSE) {
      plot_out <- plot_out + ylim(input$zaxislimits)
    }
    
    return(ggplotly(plot_out))
    
  })
  
  output$displayheat <- renderPlotly({
    
    plot_data <- plot_heatinput()
    
    plot_out <- ggplot(
      data = plot_data,
      aes(x = as.Date(Date), y = Hour)
    ) + 
      geom_tile(aes(fill = Demand)) +
      scale_y_continuous(n.breaks = 13,
                         limits = c(1,24)) +
      labs(
        x = "Date", 
        y = "Hour",
        fill = "Demand (MW)",
        title = paste0(
          "Hourly Demand (",
          input$dates[1] %>% as.Date() %>% format(., "%Y-%b-%d"),
          " to ",
          input$dates[2] %>% as.Date() %>% format(., "%Y-%b-%d"),
          ")"
        )) 
    
    if (input$autozaxis == FALSE) {
      plot_out <- plot_out + 
        scale_fill_viridis_c(limits = input$zaxislimits) +
        theme_light() 
    } else {
      plot_out <- plot_out + 
        scale_fill_viridis_c() +
        theme_light() 
    }
    
    return(ggplotly(plot_out))
    
  })
  
}


shinyApp(ui, server)
