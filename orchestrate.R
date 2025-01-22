source("libraries.R")

run_orchestrator <- function(input, max_tokens = 100000) {

  # List all files in template directory
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
  file.copy(files, suggested_names$directory_name)
  
  file.rename(
    from = paste0(suggested_names$directory_name, "/template.Rmd"),
    to = paste0(suggested_names$directory_name,"/", suggested_names$report_file_name, ".Rmd")
  )
  
  # Initialize message history with user input
  messages_ <- list(
    list(
      role = "user",
      content = paste0("Here is the user request: ", input, "\n", "Please note the directory and new template have already been made for you here, directory:", suggested_names$directory_name, "\n",
      "Report file: ", suggested_names$report_file_name,".Rmd", "\n", "Please interact with only these files, you may title the report as: ", suggested_names$report_title)
    )
  )
  
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
      
      rmarkdown::render(paste0(suggested_names$directory_name,"/",suggested_names$report_file_name,".Rmd"),
                        output_format = "html_document",
                        output_dir = "output-reports")
      
      break
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
