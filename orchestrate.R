source("libraries.R")

run_orchestrator <- function(input, max_tokens = 100000) {
  
  suggested_names <- make_directory(input)
  
  # Initialize message history with user input
  messages_ <- list(
    list(
      role = "user",
      content = paste0("Here is the user request: ", input, "\n", 
                       "Please note the directory and new template have already been made for you here, directory:", 
                       suggested_names$directory_name, "\n",
                       "Report file: ", suggested_names$report_file_name,".Rmd", "\n", 
                       "The report has already been given the title: ", 
                       suggested_names$report_title)
    )
  )
  
  report_path <- paste0(suggested_names$directory_names,"/",suggested_names$report_file_name)
    
  temp_report <- readLines(report_path)
  temp_report[2] <- paste0("title: ", suggested_names$report_title)
  writeLines(temp_report, report_path)

  # Note this is Orchestrator token budget, it does not include budgets for 
  # any agents called which are not tracked here. 
  total_tokens <- 0
  
  # Define custom run_r_code that uses persistent environment
  local_run_r_code <- function(code) {
    tryCatch({
      result <- eval(parse(text = code))
      list(
        success = TRUE,
        result = capture.output(print(result))
      )
    }, error = function(e) {
      list(
        success = FALSE,
        error = e$message
      )
    })
  }
  
  # Main execution loop
  while(total_tokens < max_tokens) {
    # Get orchestrator response
    response_ <- ask_flipai(
      slug = "orchestrate-R",
      content = jsonlite::toJSON(messages_, auto_unbox = TRUE)
    )
    
    # Update token count
    total_tokens <- total_tokens + response_$usage$totalTokens
    
    # Add orchestrator's response to message history
    messages_ <- add_message(
      messages = messages_,
      roles = "orchestrator",
      contents = response_$text
    )
    
    # Extract and run any code from response
    code_ <- extract_r_code(response_$text)
    if (!is.null(code_)) {
      result_ <- local_run_r_code(code_)
      
      # Add code result to message history
      if (result_$success) {
        result_text <- paste(result_$result, collapse = "\n")
        if(result_text == "NULL"){ # default for empty success
          result_text <- "the code ran successfully, no specific result requested."
        }
      } else {
        result_text <- paste("Error:", result_$error)
      }
      
      messages_ <- add_message(
        messages = messages_,
        roles = "engine",
        contents = result_text
      )
    }
    
    # Check for completion signal
    if (grepl("<COMPLETE>", response_$text)) {
      
      tryCatch({
        # List all JSON files in directory
        json_files <- sort(list.files(
          path = suggested_names$directory_name, 
          pattern = "\\.json$", 
          full.names = TRUE
        ))
        
        
        # Filter out snowflake-details.json
        json_files <- json_files[!grepl("snowflake-details\\.json$", json_files)]
        
        if(length(json_files) == 0) {
          stop("No valid JSON set files found in directory")
        }
        
        # Define input and output files
        template_file <- file.path(suggested_names$directory_name, 
                                   paste0(suggested_names$report_file_name, ".Rmd"))
        output_file <- file.path("output-reports", 
                                 paste0(suggested_names$report_file_name, "_complete.Rmd"))
        
        # Write combined sets
        write_sets(
          json_files = json_files,
          template_file = template_file,
          output_file = output_file
        )
        
        # Try to render the combined output
        rmarkdown::render(output_file,
                          output_format = "html_document",
                          output_dir = "output-reports")
        
        break
        
      }, error = function(e) {
        # On error, read the full report
        template_file <- file.path(suggested_names$directory_name, 
                                   paste0(suggested_names$report_file_name, ".Rmd"))
        current_report <- readLines(template_file)
        report_text <- paste0(current_report, collapse = "\n")
        
        # Ask orchestrator to review and fix
        fix_response <- ask_flipai(
          slug = "orchestrate-R",
          content = paste0(
            "Error in processing or rendering report: ", e$message, "\n",
            "Please review this RMarkdown file and JSON files in directory, identify any issues, and provide a single code block to fix them:\n\n",
            report_text
          )
        )
        
        # Extract and run fix code if provided
        fix_code <- extract_r_code(fix_response$text)
        if (!is.null(fix_code)) {
          result <- local_run_r_code(fix_code)
          
          # Add fix attempt to message history
          messages_ <- add_message(
            messages = messages_,
            roles = "orchestrator",
            contents = paste0("Fix attempt: ", fix_response$text)
          )
          
          # Try the write and render process again
          json_files <- sort(list.files(
            path = suggested_names$directory_name, 
            pattern = "\\.json$", 
            full.names = TRUE
          ))
          json_files <- json_files[!grepl("snowflake-details\\.json$", json_files)]
          
          output_file <- file.path("output-reports", 
                                   paste0(suggested_names$report_file_name, "_complete.Rmd"))
          
          write_sets(
            json_files = json_files,
            template_file = template_file,
            output_file = output_file
          )
          
          rmarkdown::render(output_file,
                            output_format = "html_document",
                            output_dir = "output-reports")
        }
        
        break
      })
    }
    
    # Check token budget
    if (total_tokens >= max_tokens) {
      messages_ <- add_message(
        messages = messages_,
        roles = "system",
        contents = "Token budget exceeded. Stopping execution."
      )
      break
    }
  }
  
  # Return final message history 
  return(messages_)
}