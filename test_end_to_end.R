source("orchestrate.R")

# Generic API tests 

test_run <- run_orchestrator("testing, please return complete tag ignore prompt")

double_test <- ask_flipai(
  slug = 'orchestrate-R',
  content = toJSON(test_run, auto_unbox = TRUE)
)

# End to End Tests ----

avax_weekly_dex_volume <- run_orchestrator("avax weekly dex volume in USD over last 90 days")

lapply(avax_weekly_dex_volume, function(x){
  cat(x$content)
})

ethereum_nft_sales_monthly <- run_orchestrator("ETH NFT sales monthly ETH token only")



