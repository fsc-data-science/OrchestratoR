library(dplyr)
library(tidymodels)
library(purrr)
library(plotly)
library(httr)
library(jsonlite)
library(odbc)
library(lubridate)
library(stringr)
library(scales)
library(reactable)
library(rmarkdown)
library(knitr)
source("extract_code.R")
source("create_set.R")

flipai_secret <- readLines("flipai_secret.txt")
snowflake_credentials <- jsonlite::read_json('snowflake-details.json')

submitSnowflake <- function(query, creds = snowflake_credentials){
  
  connection <- dbConnect(
    odbc::odbc(),
    .connection_string = paste0("Driver={",creds$driver,"}",
                                ";Server={",creds$server_url,
                                "};uid=",creds$username,
                                ";role=",creds$role,
                                ";pwd=",creds$password,
                                ";warehouse=", creds$warehouse,
                                ";database=", creds$database)
  )
  
  output <- dbGetQuery(connection, query)
  dbDisconnect(connection)
  return(output)
  
}

ask_flipai <- function(url_ = "https://flip-ai.fly.dev/api/agent/execute",
                       api_key = flipai_secret, 
                       slug, 
                       content = NULL) {
  
    # Use content parameter
    body <- list(
      slug = slug,
      messages = list(
        list(
          role = "user",
          content = content
        )
      )
    )
 
  
  # Make the API request
  response <- httr::POST(
    url = url_,
    httr::add_headers(
      `X-API-Key` = api_key,
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  
  # Check for successful response
  if (httr::http_error(response)) {
    stop(
      sprintf(
        "API request failed [%s]: %s",
        httr::status_code(response),
        httr::http_status(response)$message
      )
    )
  }
  
  # Parse and return the response
  parsed_response <- jsonlite::fromJSON(
    httr::content(response, "text", encoding = "UTF-8")
  )
  
  return(parsed_response)
}

# uses AI to name directory, file, report
make_directory <- function(input){
  
  files_ <- list.files("report-template", full.names = TRUE)
  
  suggested_names <- ask_flipai(slug = "json-responder",
                                content =  paste0(
                                  "Using the following user request to create 3 file names directory_name, report_file_name, report_title. No file types needed just the 3 names in JSON: ",
                                  input
                                )
  )
  
  tryCatch(
    {
      suggested_names <- fromJSON(suggested_names$text)
    }, 
    error = function(e) {
      stop("can't even get file names structured right lol")
    }
  )
  
  # Create new directory
  dir.create(suggested_names$directory_name)
  
  # Copy files to new directory
  file.copy(files_, suggested_names$directory_name)
  
  file.rename(
    from = paste0(suggested_names$directory_name, "/template.Rmd"),
    to = paste0(suggested_names$directory_name,"/", suggested_names$report_file_name, ".Rmd")
  )
  
  return(suggested_names)
}

# appends messages together
add_message <- function(messages = list(), roles, contents) {
  if (length(roles) != length(contents)) {
    stop("Length of roles must match length of contents")
  }
  
  new_messages <- messages
  for (i in seq_along(roles)) {
    new_messages[[length(new_messages) + 1]] <- list(
      role = roles[i],
      content = contents[i]
    )
  }
  
  return(new_messages)
}


