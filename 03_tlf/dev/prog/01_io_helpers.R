# ==============================================================================
# Process and Export ADaM Dataset to .xpt and .json formats
#
# Filters, validates, formats, and exports an ADaM dataset according to the
# provided specification and CDISC standards
# ==============================================================================

end_adam <- function(data, spec, domain_name){
  
# To .xpt
#===============================================================================
  final <- data |> 
    drop_unspec_vars(spec) |>
    check_variables(spec, strict = TRUE) |>
    order_cols(spec) |>
    sort_by_key(spec) |>
    set_variable_labels(spec) |>
    xportr::xportr_type(spec, domain = domain_name) |>
    xportr::xportr_length(spec, domain = domain_name) |> 
    xportr::xportr_format(spec, domain = domain_name)
  
  xportr::xportr_write(
    final,
    path = sprintf("02_adam/val/data/xpt/%s.xpt", str_to_lower(domain_name)),
    metadata = spec,
    domain = domain_name
  )

# To .json
#===============================================================================
  final_ne_na <- final |> 
    mutate(across(where(is.character), ~ ifelse(is.na(.), "", .)))
  
  key_seq <- spec$ds_vars |>
    filter(dataset == domain_name) |>
    select(variable, key_seq)

  columns <- tibble(name = names(final_ne_na)) |>
    left_join(spec$var_spec, by = c("name" = "variable")) |>
    left_join(key_seq, by = c("name" = "variable")) |>
    mutate(
      is_date = !is.na(format) & str_detect(format, "^DATE|^DATETIME|^TIME"),
      dataType = case_when(
        is_date ~ "date",
        type == "integer" ~ "integer",
        type == "float" ~ "float",
        TRUE ~ "string"
      ),
      targetDataType = if_else(is_date, "integer", NA_character_),
      displayFormat = if_else(is_date, format, NA_character_),
      length = if_else(dataType == "string", length, NA_integer_),
      itemOID = paste0(domain_name, ".", name)
    ) |>
    select(itemOID, name, label, dataType, targetDataType,
           length, displayFormat, keySequence = key_seq)

  ds_json <- dataset_json(
    final_ne_na,
    item_oid = domain_name,
    name = domain_name,
    dataset_label = spec$ds_spec$label[spec$ds_spec$dataset == domain_name],
    columns = columns
  )

  write_dataset_json(
    ds_json,
    file = sprintf("02_adam/val/data/json/%s.json", str_to_lower(domain_name))
  )
}