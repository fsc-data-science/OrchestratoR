source("orchestrate.R")

# Test template manipulation ----
test_dir <- make_directory("test directory for manipulation markdowns files. Name the directory markdown_manipulation_test please.")

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

# Create some vanilla sets to test RMarkdown manipulation ----
create_set(
  directory = "markdown_manipulation_test",
  setname = "summary_stats",
  heading = "Basic Summary Statistics",
  bullets = c("Basic statistical summary", "Data quality checks"),
  sql_chunk = list(
    object_name = "summary_data",
    query = "select amount, timestamp from trades"
  ),
  analysis_chunks = list(
    list(
      object_name = "basic_stats",
      code = "summary_data %>%
        summarise(
          n_rows = n(),
          mean_amount = mean(amount),
          median_amount = median(amount),
          missing_timestamps = sum(is.na(timestamp))
        )"
    )
  )
)

create_set(
  directory = "markdown_manipulation_test",
  setname = "hourly_analysis",
  heading = "Hourly Volume Patterns",
  bullets = c("Hourly trading patterns", "Volume concentration analysis"),
  sql_chunk = list(
    object_name = "hourly_data",
    query = "select date_trunc('hour', timestamp) as hour_, sum(amount) as volume from trades group by 1"
  ),
  analysis_chunks = list(
    list(
      object_name = "hourly_plot",
      code = "plot_ly(data = hourly_data) %>%
        add_lines(x = ~hour_, y = ~volume) %>%
        layout(title = 'Hourly Trading Volume')"
    )
  )
)

create_set(
  directory = "markdown_manipulation_test",
  setname = "trader_analysis",
  heading = "Trader Behavior Analysis",
  bullets = c("Trader categorization", "Activity patterns"),
  sql_chunk = list(
    object_name = "trader_data",
    query = "select trader, count(*) as n_trades, sum(amount) as total_volume from trades group by 1"
  ),
  analysis_chunks = list(
    list(
      object_name = "trader_summary",
      code = "trader_data %>%
        mutate(avg_trade = total_volume / n_trades) %>%
        arrange(desc(total_volume)) %>%
        head(10)"
    ),
    list(
      object_name = "volume_dist",
      code = "plot_ly(data = trader_data) %>%
        add_histogram(x = ~total_volume, nbinsx = 30) %>%
        layout(title = 'Distribution of Trader Volumes')"
    ),
    list(
      object_name = "quantile_analysis",
      code = "quantile(trader_data$total_volume, probs = seq(0, 1, 0.1))"
    )
  )
)

create_set(
  directory = "markdown_manipulation_test",
  setname = "data_quality",
  heading = "Data Quality Assessment",
  bullets = c("Missing value analysis", "Anomaly detection"),
  sql_chunk = list(
    object_name = "quality_data",
    query = "select * from trades where timestamp >= current_date - 7"
  ),
  analysis_chunks = list(
    list(
      object_name = "missing_check",
      code = "colSums(is.na(quality_data))"
    ),
    list(
      object_name = "outlier_plot",
      code = "plot_ly(data = quality_data) %>%
        add_boxplot(y = ~amount) %>%
        layout(title = 'Amount Distribution with Outliers')"
    )
  )
)

format_set(set = fromJSON("markdown_manipulation_test/example_query.json"))
format_set(set = fromJSON("markdown_manipulation_test/data_quality.json"))
format_set(set = fromJSON("markdown_manipulation_test/hourly_analysis.json"))
format_set(set = fromJSON("markdown_manipulation_test/trader_analysis.json"))

# Test the Write ---- 
write_sets(json_files = c("markdown_manipulation_test/data_quality.json",
                          "markdown_manipulation_test/example_query.json",
                          "markdown_manipulation_test/hourly_analysis.json",
                          "markdown_manipulation_test/summary_stats.json",
                          "markdown_manipulation_test/trader_analysis.json"),
           template_file = "markdown_manipulation_test/markdown_processing_report.Rmd",
           output_file = "output-reports/markdown_test_complete.Rmd" 
)


write_sets(c("avalanche_dex_volume_analysis/01-weekly-volume.json",
             "avalanche_dex_volume_analysis/02-volume-statistics.json"), 
           template_file = "avalanche_dex_volume_analysis/weekly_dex_volume_report.Rmd", 
           output_file = "output-reports/weekly_dex_volume_report_complete.Rmd")
