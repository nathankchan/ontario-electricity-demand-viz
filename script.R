# script.R

# Usage: Rscript script.R [filename]

# Produces a 3D surface plot of electricity market demand given a specially formatted .csv file
# [filename] should be the path to the .csv file from IESO containing hourly demand data

source(file = "functions.R")

required_packages <-
  c("tidyverse",
    "plotly",
    "htmlwidgets",
    "shiny")

suppressMessages(using(required_packages))

args <- commandArgs(trailingOnly = TRUE)
filename <- args[1]
mydata <- read.csv(file = filename, skip = 3)
fileyear <- substr(mydata$Date[1], 1, 4)
plot_title <- paste0("<b>", fileyear, " Ontario Hourly Market Demand</b>")
filename_out <- paste0("plots/", fileyear, "_Ontario_Hourly_Market_Demand.html")

plot_data <- mydata[, c("Date", "Hour", "Market.Demand")] %>% 
  pivot_wider(names_from = Date, values_from = Market.Demand) %>%
  select(-Hour) %>% as.matrix()

xindex <- which(substr(colnames(plot_data), 9, 12) == "01")
xlabels_df <- cbind.data.frame(
  xindex = xindex,
  xlabels = colnames(plot_data)[xindex] %>% as.Date() %>% format(., "%b")
)

plot_xaxis <- list(
  title = "Date",
  ticketmode = "array",
  ticktext = xlabels_df$xlabels,
  tickvals = xlabels_df$xindex,
  range = c(1, ncol(plot_data)))

plot_yaxis <- list(
  title = "Hour",
  ticketmode = "array",
  ticktext = c("0400h", "0800h", "1200h", "1600h", "2000h", "2400h"),
  tickvals = c(4, 8, 12, 16, 20, 24)
)

plot_zaxis <- list(
  title = "Market Demand (MW)"
)

myplot <-
  plot_ly(z = ~ plot_data,
          lighting = list(ambient = 0.9)) %>%
  add_surface(
    showscale = FALSE,
    contours = list(
      z = list(
        show = TRUE,
        usecolormap = TRUE,
        highlightcolor = "#ff0000",
        project = list(z = F)
      )
    )
  ) %>%
  layout(title = plot_title,
         scene = list(
           xaxis = plot_xaxis,
           yaxis = plot_yaxis,
           zaxis = plot_zaxis,
           scale = list(title = list(text = "Market Demand (MW)")),
           camera = list(
             eye = list(x = 1.5,
                        y = -1.5,
                        z = 0.75)
           ))
         )

saveWidget(myplot, filename_out)
unlink(paste0("plots/", fileyear, "_Ontario_Hourly_Market_Demand_files"), recursive = T)

message(paste0("Plot of ", fileyear, " data saved to ", filename_out))
