# ==============================================================================
# Cached wrapper around get_adam_meta().
# Rebuilds from spec_path only if the .rds cache is missing or older than
# the spec file; otherwise loads the cached object. Use force = TRUE to
# always rebuild regardless of mtime.
# ==============================================================================
get_meta_cached <- function(spec_path = "02_adam/00_doc/ADAM_spec.xlsx",
                            rds_path  = "02_adam/00_doc/meta.rds",
                            force = FALSE){
  
  needs_rebuild <- force ||
    !file.exists(rds_path) ||
    file.mtime(spec_path) > file.mtime(rds_path)
  
  if (needs_rebuild) {
    meta <- get_adam_meta(spec_path)
    saveRDS(meta, rds_path)
    message(sprintf("Cache rebuilt and saved to: %s", rds_path))
  } else {
    message(sprintf("Reading cached metadata: %s ...", rds_path))
    meta <- readRDS(rds_path)
  }
  
  return(meta)
}

# ==============================================================================
# Metadata builder: parses ADAM_spec.xlsx into a metacore object
# Requires packages loaded by 00_setup.R
# ==============================================================================

get_adam_meta <- function(spec_path = "02_adam/00_doc/ADAM_spec.xlsx"){
  
message(sprintf("Reading spec file: %s ...", spec_path))

doc <- read_all_sheets(spec_path)

ds_spec <- spec_type_to_ds_spec(doc)
ds_vars <- spec_type_to_ds_vars(doc)
var_spec <- spec_type_to_var_spec(doc)

value_spec <-  spec_type_to_value_spec(
  doc,
  cols = c(dataset = "[D|d]ataset|[D|d]omain", variable = "[N|n]ame|[V|v]ariables?",
           origin = "[O|o]rigin", type = "[T|t]ype", code_id = "[C|c]odelist|Controlled Term",
           sig_dig = "[S|s]ignificant", where = "[W|w]here", derivation_id = "[M|m]ethod",
           predecessor = "[M|m]ethod"),
  sheet = NULL,
  where_sep_sheet = FALSE
)
codelist <- spec_type_to_codelist(doc)
derivation <- spec_type_to_derivations(doc)

meta <- metacore(ds_spec,
                 ds_vars,
                 var_spec,
                 value_spec,
                 derivation,
                 codelist,
                 verbose = "message")

message("Metacore object successfully created!")

return(meta)
}