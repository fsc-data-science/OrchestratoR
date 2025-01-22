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
                       messages = NULL, 
                       content = NULL) {
  # Input validation
  if (is.null(messages) && is.null(content)) {
    stop("Either messages or content must be provided")
  }
  if (!is.null(messages) && !is.null(content)) {
    stop("Only one of messages or content should be provided")
  }
  
  # Prepare the request body
  if (is.null(messages)) {
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
  } else {
    # Use messages parameter directly
    body <- list(
      slug = slug,
      messages = messages
    )
  }
  
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

