
#' Create an Analysis Set as JSON
#'
#' Creates a structured JSON file containing an analysis set with a heading,
#' optional bullet points, SQL queries, and analysis code chunks. The set is
#' saved to a specified directory with metadata.
#'
#' @param directory Character string. Path to the directory where the set should
#'   be saved. Will be created if it doesn't exist.
#' @param setname Character string. Name of the set file (without .json extension)
#'   that will be created in the directory.
#' @param heading Character string. The main heading (H2) text for this analysis
#'   set.
#' @param bullets Character vector, optional. Bullet points to be included in the
#'   set.
#' @param sql_chunk List, optional. Contains SQL query information with components:
#'   \describe{
#'     \item{object_name}{Name of the object where query results will be stored}
#'     \item{query}{SQL query string}
#'   }
#' @param analysis_chunks List of lists, optional. Each inner list contains:
#'   \describe{
#'     \item{object_name}{Name of the object where analysis results will be stored}
#'     \item{code}{R code string for the analysis}
#'   }
#'
#' @return Character string containing the filepath where the JSON was saved.
#'
#' @examples
#' \dontrun{
#' # Create a basic set with just a heading
#' create_set(
#'   directory = "analysis/dex",
#'   setname = "basic_set",
#'   heading = "Basic Analysis"
#' )
#'
#' # Create a complete set with all components
#' create_set(
#'   directory = "analysis/dex",
#'   setname = "weekly_volume",
#'   heading = "Weekly Volume",
#'   bullets = c(
#'     "Analysis of DEX volume trends",
#'     "Shows week-over-week changes"
#'   ),
#'   sql_chunk = list(
#'     object_name = "weekly_vol",
#'     query = "SELECT date_trunc('week', block_timestamp) as week_"
#'   ),
#'   analysis_chunks = list(
#'     list(
#'       object_name = "weekly_summary",
#'       code = "weekly_vol %>% summarize(mean = mean(volume))"
#'     ),
#'     list(
#'       object_name = "weekly_plot",
#'       code = "plot_ly() %>% add_trace(data = weekly_vol...)"
#'     )
#'   )
#' )
#' }
#'
#' @importFrom jsonlite write_json
#'
#' @export
create_set <- function(
    directory,
    setname,
    heading,
    bullets = NULL,
    sql_chunk = NULL,
    analysis_chunks = NULL
) {
  # Input validation
  if (!is.character(directory) || !is.character(setname) || !is.character(heading)) {
    stop("directory, setname, and heading must be character strings")
  }
  
  # Create directory if it doesn't exist
  if (!dir.exists(directory)) {
    dir.create(directory)
  }
  
  # Construct the set structure
  set <- list(
    sets = list(
      list(
        heading = heading,
        bullets = bullets,
        sql_chunk = if (!is.null(sql_chunk)) {
          list(
            object_name = sql_chunk$object_name,
            query = sql_chunk$query
          )
        } else NULL,
        analysis_chunks = if (!is.null(analysis_chunks)) {
          lapply(analysis_chunks, function(chunk) {
            list(
              object_name = chunk$object_name,
              code = chunk$code
            )
          })
        } else NULL
      )
    ),
    metadata = list(
      title = heading,
      date = format(Sys.time(), "%Y-%m-%d"),
      directory = directory
    )
  )
  
  # Create filepath
  filepath <- file.path(directory, paste0(setname, ".json"))
  
  # Write JSON to file with pretty formatting
  write_json(set, filepath, pretty = TRUE, auto_unbox = TRUE)
  
  # Return the filepath for reference
  return(filepath)
}