# functions.R

using <- function(...) {
  libs <- unlist(list(...))
  req <- suppressWarnings(unlist(lapply(libs, require, character.only = TRUE)))
  need <- libs[req == FALSE]
  n <- length(need)
  
  if (n > 0) {
    libsmsg <-
      if (n > 2) {
        paste(paste(need[1:(n - 1)], collapse = ", "), ",", sep = "")
      } else
        need[1]
    
    if (n > 1) {
      libsmsg <- paste(libsmsg, " and ", need[n], sep = "")
    }
    
    libsmsg <-
      paste(
        "The following packages could not be found: ",
        libsmsg,
        "\n\r\n\rInstall missing packages?",
        collapse = ""
      )
    
    # Checks if R is in interactive mode. If yes, then prompt user for
    # interactive response. If no, prompt user for input from stdin.
    if (interactive()) {
      if (!(askYesNo(libsmsg, default = FALSE) %in% c(NA, FALSE))) {
        install.packages(need)
        lapply(need, require, character.only = TRUE)
      } else {
        stop("required packages were not installed or loaded")
      }
      
    } else {
      cat(libsmsg, "(yes/No/cancel) ")
      response <- readLines("stdin", n = 1)
      input <- pmatch(tolower(response), c("yes", "no", "cancel"))
      
      if (!nchar(response) | input %in% c(2, 3)) {
        stop("required packages were not installed or loaded")
      } else if (is.na(input)) {
        stop("Unrecognized response ", dQuote(response))
      } else {
        install.packages(need)
        lapply(need, require, character.only = TRUE)
      }
    }
    
  }
  
  return(invisible(NULL))
}


