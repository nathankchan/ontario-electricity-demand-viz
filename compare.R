# compare.R

# Usage: Rscript compare.R [year]

# Produces 2x2 interactive surface plots to facilitate comparison between years
# [year] is a mandatory argument that provies the first year for comparison

source(file = "functions.R")

required_packages <-
  c("tidyverse",
    "plotly",
    "htmlwidgets")

suppressMessages(using(required_packages))

args <- commandArgs(trailingOnly = TRUE)
check_year <- as.character(args[1])

filenames <- list.files("data/") %>% substr(., 12, 15)
if (any(which(filenames == check_year))) {
  start_year <- which(filenames == check_year)
  if (start_year > length(filenames) - 3) {
    check_year <- filenames[length(filenames) - 3]
    start_year <- length(filenames) - 3
    # message("Year provided is within last 4 years. Comparison plot will show last 4 years.")
  } 
} else {
  stop(paste0("No data are available for ", start_year))
}

end_year <- start_year + 3

filename <- paste0("data/", list.files("data/"))
filename <- filename[start_year:end_year]

# Yes, copying and pasting code is bad practice. However, it looks like plotly
# requires data objects to exist in memory before plotting (i.e., plots do not
# save a copy of the data). To this end, we need to explicitly load plot data to
# memory.

plot_data1 <- read.csv(file = filename[1], skip = 3)
plot_year1 <- substr(plot_data1$Date[1], 1, 4)
plot_data1 <- plot_data1[, c("Date", "Hour", "Market.Demand")] %>% 
  pivot_wider(names_from = Date, values_from = Market.Demand) %>%
  select(-Hour) %>% as.matrix()

plot_data2 <- read.csv(file = filename[2], skip = 3)
plot_year2 <- substr(plot_data2$Date[1], 1, 4)
plot_data2 <- plot_data2[, c("Date", "Hour", "Market.Demand")] %>% 
  pivot_wider(names_from = Date, values_from = Market.Demand) %>%
  select(-Hour) %>% as.matrix()

plot_data3 <- read.csv(file = filename[3], skip = 3)
plot_year3 <- substr(plot_data3$Date[1], 1, 4)
plot_data3 <- plot_data3[, c("Date", "Hour", "Market.Demand")] %>% 
  pivot_wider(names_from = Date, values_from = Market.Demand) %>%
  select(-Hour) %>% as.matrix()

plot_data4 <- read.csv(file = filename[4], skip = 3)
plot_year4 <- substr(plot_data4$Date[1], 1, 4)
plot_data4 <- plot_data4[, c("Date", "Hour", "Market.Demand")] %>% 
  pivot_wider(names_from = Date, values_from = Market.Demand) %>%
  select(-Hour) %>% as.matrix()

plot_cols <- list(
  colnames(plot_data1),
  colnames(plot_data2),
  colnames(plot_data3),
  colnames(plot_data4)
)
xmax <- which.max(lapply(plot_cols, length))
xindex <- which(substr(plot_cols[[xmax]], 9, 12) == "01")
xlabels_df <- cbind.data.frame(xindex = xindex,
                               xlabels = plot_cols[[xmax]][xindex] %>% as.Date() %>% format(., "%b"))

plot_xaxis <- list(
  title = "Date",
  ticketmode = "array",
  ticktext = xlabels_df$xlabels,
  tickvals = xlabels_df$xindex,
  range = c(1, ncol(plot_data1))
)

plot_yaxis <- list(
  title = "Hour",
  ticketmode = "array",
  ticktext = c("0400h", "0800h", "1200h", "1600h", "2000h", "2400h"),
  tickvals = c(4, 8, 12, 16, 20, 24)
)

# plot_scene <- list(
#   xaxis = plot_xaxis,
#   yaxis = plot_yaxis,
#   zaxis = plot_zaxis,
#   camera = list(eye = list(
#     x = 1.5,
#     y = -1.5,
#     z = 0.75
#   )),
#   aspectmode = "cube"
# )

plot_demand <- function(plot_data, scenenumber) {
  myplot <-
    plot_ly(z = ~ plot_data,
            scene = scenenumber,
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
    ) 
  
  return(myplot)
}


plot1 <- plot_demand(plot_data1, "scene1") 
plot2 <- plot_demand(plot_data2, "scene2")
plot3 <- plot_demand(plot_data3, "scene3")
plot4 <- plot_demand(plot_data4, "scene4")

plot_title <- paste0("<br><b>Ontario Hourly Electricity Market Demand</b><br><b><i>", plot_year1, " to ", plot_year4, "</b></i>")

plot_all <- suppressWarnings(subplot(plot1, plot2, plot3, plot4) %>%
  layout(
    title = plot_title,
    scene = list(
      annotations = list(x = 0.25, y = 1, text = plot_year1,
                         xref = "paper", yref = "paper", xanchor = "center", yanchor = "bottom", showarrow = FALSE),
      xaxis = plot_xaxis,
      yaxis = plot_yaxis,
      zaxis = list(title = paste0("<b>", plot_year1, "</b> Market Demand (MW)")),
      camera = list(eye = list(
        x = 1.5,
        y = -1.5,
        z = 0.75
      )),
      aspectmode = "cube",
      domain = list(x = c(0, 0.5), y = c(0.5, 1))
    ),
    scene2 = list(
      xaxis = plot_xaxis,
      yaxis = plot_yaxis,
      zaxis = list(title = paste0("<b>", plot_year2, "</b> Market Demand (MW)")),
      camera = list(eye = list(
        x = 1.5,
        y = -1.5,
        z = 0.75
      )),
      aspectmode = "cube",
      domain = list(x = c(0.5, 1), y = c(0.5, 1))
    ),
    scene3 = list(
      xaxis = plot_xaxis,
      yaxis = plot_yaxis,
      zaxis = list(title = paste0("<b>", plot_year3, "</b> Market Demand (MW)")),
      camera = list(eye = list(
        x = 1.5,
        y = -1.5,
        z = 0.75
      )),
      aspectmode = "cube",
      domain = list(x = c(0, 0.5), y = c(0, 0.5))
    ),
    scene4 = list(
      xaxis = plot_xaxis,
      yaxis = plot_yaxis,
      zaxis = list(title = paste0("<b>", plot_year4, "</b> Market Demand (MW)")),
      camera = list(eye = list(
        x = 1.5,
        y = -1.5,
        z = 0.75
      )),
      aspectmode = "cube",
      domain = list(x = c(0.5, 1), y = c(0, 0.5))
    )
  ))

filename_out <- paste0("plots/", plot_year1, "_to_", plot_year4, "_Ontario_Hourly_Market_Demand_Comparison")
saveWidget(plot_all, paste0(filename_out, ".html"))
unlink(paste0(filename_out, "_files"), recursive = T)
message("Plot of ", plot_year1, " to ", plot_year4, " data saved to ", filename_out)
