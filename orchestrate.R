run_orchestrator <- function(input, max_tokens = 100000) {
  browser()
  # Create persistent function environment that inherits from global
  function_env <- new.env(parent = globalenv())
  
  # Initialize message history with user input
  messages_ <- list(
    list(
      role = "user",
      content = input
    )
  )
  
  # Note this is Orchestrator token budget, it does not include budgets for 
  # any agents called which are not tracked here. 
  total_tokens <- 0
  
  # Define custom run_r_code that uses persistent environment
  local_run_r_code <- function(code) {
    tryCatch({
      result <- eval(parse(text = code), envir = function_env)
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
      messages = messages_
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
  return(messages)
}
