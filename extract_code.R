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
