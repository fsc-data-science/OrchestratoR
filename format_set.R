#' Convert Analysis Set List to RMarkdown
#'
#' Converts an R list containing an analysis set into RMarkdown formatted strings.
#' The function handles headings, bullet points, SQL chunks, and analysis chunks.
#'
#' @param set List. An R list containing both 'sets' and 'metadata' components.
#'   The 'sets' component contains the analysis set structure with heading,
#'   bullets (optional), sql_chunk (optional), and analysis_chunks (optional).
#'
#' @return Character vector containing RMarkdown formatted strings.
#'
#' @details The function expects a list with a nested structure containing both
#' 'sets' and 'metadata' components. The 'sets' component should contain
#' heading, bullets (optional), sql_chunk (optional), and analysis_chunks (optional).
#'
#' @examples
#' \dontrun{
#' # Example set structure
#' example_set <- list(
#'   sets = list(
#'     heading = "Example Query",
#'     bullets = c("First bullet", "Second bullet"),
#'     sql_chunk = list(
#'       object_name = "example_query",
#'       query = "SELECT * FROM table"
#'     ),
#'     analysis_chunks = list(
#'       list(
#'         object_name = "example_plot",
#'         code = "plot_ly(data = example_query)"
#'       )
#'     )
#'   ),
#'   metadata = list(
#'     title = "Example Query",
#'     date = "2025-01-22",
#'     directory = "analysis/dex"
#'   )
#' )
#' 
#' # Convert to RMarkdown
#' rmd_lines <- format_set(example_set)
#' }
#'
#' @export
format_set <- function(set) {
  # Input validation
  if (!is.list(set) || is.null(set$sets)) {
    stop("Input must be a list containing 'sets' component")
  }
  
  # Extract the set contents from the nested structure
  set_ <- set$sets  # Take the sets obj
  
  if (is.null(set_$heading)) {
    stop("The set must contain at least a 'heading' element")
  }
  
  # Initialize empty vector for RMarkdown lines
  rmd_lines <- character(0)
  
  # Add heading
  rmd_lines <- c(rmd_lines,
                 "",
                 paste0("## ", set_$heading))
  
  # Add bullets if they exist
  if (!is.null(set_$bullets)) {
    # Add each bullet on a new line
    bullet_lines <- unlist(
      lapply(set_$bullets, 
             function(x){
           paste0("* ", x, "\n")
       })
      )
    
    rmd_lines <- c(rmd_lines,
                   "",
                   bullet_lines)
  }
  
  # Add SQL chunk if it exists
  if (!is.null(set_$sql_chunk$object_name)) {
    rmd_lines <- c(rmd_lines,
                   "",
                   "```{r}",
                   paste0(set_$sql_chunk$object_name, " = submitSnowflake({"),
                   "\"",
                   set_$sql_chunk$query,
                   "\"",
                   "})",
                   paste0("colnames(",set_$sql_chunk$object_name,") <- tolower(colnames(", set_$sql_chunk$object_name,"))"),
                   "```")
  }
  
  # Add analysis chunks if they exist
  if (!is.null(set_$analysis_chunks)) {
    for (chunk in set_$analysis_chunks) {
      rmd_lines <- c(rmd_lines,
                     "",
                     "```{r}",
                     chunk$code,
                     "```")
    }
  }
  
  # Add final blank line
  rmd_lines <- c(rmd_lines, "")
  
  return(rmd_lines)
}

#' @rdname format_set
#' @export
print.rmd_lines <- function(x, ...) {
  cat(paste(x, collapse = "\n"))
}