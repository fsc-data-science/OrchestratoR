source("orchestrate.R")

test_run <- run_orchestrator("testing, please return complete tag ignore prompt")

double_test <- ask_flipai(
  slug = 'orchestrate-R',
  content = toJSON(test_run, auto_unbox = TRUE)
)

avax_weekly_dex_volume <-run_orchestrator("avax weekly dex volume in USD")
