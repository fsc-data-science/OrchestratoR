source("orchestrate.R")

# Test template manipulation 
test_dir <- make_directory("test directory for manipulation markdowns files")

create_set(directory = "markdown_manipulation_test",setname =  "example_query",
           heading = "Example Query",
           bullets = c("Just testing the create set function", "Bullet 2"),
           sql_chunk = list(
             object_name = "example_query",
             query = "select 'bob' as person, 10 as amount from dual"
             ),
           analysis_chunks = list(
               list(
                 object_name = "example_plot",
                 code = "plot_ly() %>% add_trace(data = example_query, x = ~PERSON, y = ~AMOUNT, type = 'bar')"
               )
             )
)

add_set(set = fromJSON("markdown_manipulation_test/example_query.json"))





# Example analysis 

avax_weekly_dex_volume <- run_orchestrator("avax weekly dex volume in USD over last 90 days")

lapply(avax_weekly_dex_volume, function(x){
  cat(x$content)
})


# Generic API tests 

test_run <- run_orchestrator("testing, please return complete tag ignore prompt")

double_test <- ask_flipai(
  slug = 'orchestrate-R',
  content = toJSON(test_run, auto_unbox = TRUE)
)
