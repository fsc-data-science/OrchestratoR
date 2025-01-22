#' Combine Multiple Analysis Sets and Append to Template
#'
#' Takes a list of JSON filepaths, formats each set, combines them, and appends
#' the result to a template Rmd file.
#'
#' @param json_files Character vector of file paths to JSON set files
#' @param template_file Character string path to the template Rmd file
#' @param output_file Character string path for the output Rmd file
#'
#' @return Invisibly returns the path to the created output file
#'
#' @importFrom jsonlite fromJSON
#'
#' @examples
#' \dontrun{
#' combine_sets(
#'   json_files = c(
#'     "markdown_manipulation_test/example_query.json",
#'     "markdown_manipulation_test/data_quality.json"
#'   ),
#'   template_file = "templates/analysis_template.Rmd",
#'   output_file = "output/combined_analysis.Rmd"
#' )
#' }
#'
#' @export
write_sets <- function(json_files, template_file, output_file) {
  # Input validation
  if (!all(file.exists(json_files))) {
    stop("One or more JSON files do not exist")
  }
  if (!file.exists(template_file)) {
    stop("Template file does not exist")
  }
  
  # Read template file
  template_lines <- readLines(template_file, warn = FALSE)
  
  # Process each JSON file
  all_sets <- character(0)
  
  for (json_file in json_files) {
    # Read and format each set
    set_data <- fromJSON(json_file)
    formatted_set <- format_set(set_data)
    
    # Add to combined sets
    all_sets <- c(all_sets, formatted_set)
  }
  
  # Find insertion point in template (assuming there's a marker)
  insert_marker <- "<!-- INSERT_ANALYSIS -->"
  insert_pos <- which(template_lines == insert_marker)
  
  if (length(insert_pos) == 0) {
    # If no marker found, append to end
    output_lines <- c(template_lines, all_sets)
  } else {
    # Insert at marker position
    output_lines <- c(
      template_lines[1:(insert_pos - 1)],
      all_sets,
      template_lines[(insert_pos + 1):length(template_lines)]
    )
  }
  
  # Create output directory if it doesn't exist
  output_dir <- dirname(output_file)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Write output file
  writeLines(output_lines, output_file)
  
  invisible(output_file)
}
