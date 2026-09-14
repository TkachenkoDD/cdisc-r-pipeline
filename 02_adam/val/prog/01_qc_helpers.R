# ==============================================================================
# Compares production and validation datasets
#
# ==============================================================================

#---XPT----#

compare_adam_xpt <- function(domain_name, prnt = F){
  
  dev <- read_xpt(sprintf("02_adam/dev/data/xpt/%s.xpt", str_to_lower(domain_name)))
  val <- read_xpt(sprintf("02_adam/val/data/xpt/%s.xpt", str_to_lower(domain_name)))
    
    comp_result <- diffdf(
      base = dev,
      compare = val,
      keys = "USUBJID",
      suppress_warnings = TRUE
    )
    
    if (diffdf_has_issues(comp_result)) {
      vardiff_names <- names(comp_result)[str_detect(names(comp_result), "^VarDiff_")]
      findings <- vardiff_names |>
        lapply(\(nm) comp_result[[nm]] |> mutate(across(c(BASE, COMPARE), as.character))) |>
        bind_rows()
      write_xpt(findings, 
                sprintf("02_adam/val/data/xpt/findings_%s.xpt", str_to_lower(domain_name)))
      message(sprintf("See mismatches in the findings_%s.xpt", str_to_lower(domain_name)))
        if(prnt) {
          print(comp_result)
        }
    } else {
      message("XPT comparison: All EXACTLY EQUAL")
    }
}

#-----JSON------#

compare_adam_json <- function(domain_name, prnt = F) {

  dev_json <- read_dataset_json(sprintf("02_adam/dev/data/json/%s.json", str_to_lower(domain_name)))
  val_json <- read_dataset_json(sprintf("02_adam/val/data/json/%s.json", str_to_lower(domain_name)))
  
  comp_result_json <- diffdf(
    base = dev_json,
    compare = val_json,
    keys = "USUBJID",
    suppress_warnings = TRUE
  )
  
  if (diffdf_has_issues(comp_result_json)) {
    vardiff_names_json <- names(comp_result_json)[str_detect(names(comp_result_json), "^VarDiff_")]
    findings_json <- vardiff_names_json |>
      lapply(\(nm) comp_result_json[[nm]] |> mutate(across(c(BASE, COMPARE), as.character))) |>
      bind_rows()
    write_xpt(findings_json,
              sprintf("02_adam/val/data/json/findings_%s_json.xpt", str_to_lower(domain_name)))
    message(sprintf("See mismatches in the findings_%s_json.xpt", str_to_lower(domain_name)))
    if(prnt) {
      print(comp_result_json)
    }
  } else {
    message("JSON comparison: All EXACTLY EQUAL")
  }
}