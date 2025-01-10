#' Extract R code from tagged text
#' 
#' @description Extracts R code contained between <r> tags from a text string
#' 
#' @param text A character string containing R code wrapped in <r> tags
#' @return The extracted R code as a character string, or NULL if no valid code found
#' @examples
#' text <- "Here is some code: <r>mtcars %>% summary()</r>"
#' extract_r_code(text)
#' @export
extract_r_code <- function(text) {
  pattern <- "<r>\\s*([\\s\\S]*?)\\s*</r>"
  matches <- regmatches(text, regexec(pattern, text, perl = TRUE))[[1]]
  if (length(matches) < 2) return(NULL)
  return(trimws(matches[2]))
}

#' Execute R code in a new environment
#' 
#' @description Safely executes R code in an isolated environment and returns results or error message
#' 
#' @param code A character string containing valid R code
#' @return A list with execution results or error message
#' @examples
#' run_r_code("x <- 1:10; mean(x)")
#' run_r_code("this_will_error")
#' @export
run_r_code <- function(code) {
  new_env <- new.env()
  tryCatch({
    result <- eval(parse(text = code), envir = new_env)
    list(
      success = TRUE,
      result = jsonlite::toJSON(result)
    )
  }, error = function(e) {
    list(
      success = FALSE, 
      error = e$message
    )
  })
}
