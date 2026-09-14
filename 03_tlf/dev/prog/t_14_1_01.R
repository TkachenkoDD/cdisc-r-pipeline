# ==============================================================================
# Creates Table_14-1.01 
# ==============================================================================

source("03_tlf/dev/prog/00_setup.R")
source("03_tlf/dev/prog/01_get_metadata.R")
source("03_tlf/dev/prog/01_io_helpers.R")
source("03_tlf/dev/prog/01_utils.R")

adsl <- read_xpt("02_adam/val/data/xpt/adsl.xpt")

adsl_tot <- adsl |> 
  mutate(TRT01P = "Total", TRT01PN = 99) |> 
  bind_rows(adsl)

denoms <- adsl_tot |> 
 group_by(TRT01P, TRT01PN) |> 
  summarise(DEN = n(), .groups = "drop")

ittfl <- adsl_tot |> 
  filter(ITTFL == 'Y') |> 
  group_by(TRT01P, TRT01PN) |> 
  summarise(N = n(), .groups = "drop") |> 
  mutate(SET = 'Intent-To-Treat (ITT)', ord1 = 1)

saffl <- adsl_tot |> 
  filter(SAFFL == 'Y') |> 
  group_by(TRT01P, TRT01PN) |> 
  summarise(N = n(), .groups = "drop") |> 
  mutate(SET = 'Safety', ord1 = 2)

efffl <- adsl_tot |> 
  filter(EFFFL == 'Y') |> 
  group_by(TRT01P, TRT01PN) |> 
  summarise(N = n(), .groups = "drop") |> 
  mutate(SET = 'Efficacy', ord1 = 3)

comp24 <- adsl_tot |> 
  filter(COMP24FL == 'Y') |> 
  group_by(TRT01P, TRT01PN) |> 
  summarise(N = n(), .groups = "drop") |> 
  mutate(SET = 'Completer Week 24', ord1 = 4)

disc <- adsl_tot |> 
  filter(DISCONFL == 'Y') |> 
  group_by(TRT01P, TRT01PN) |> 
  summarise(N = n(), .groups = "drop") |> 
  mutate(SET = 'Discontinued', ord1 = 5)

all <- bind_rows(ittfl, saffl, efffl, comp24, disc) |> 
  arrange(ord1, TRT01PN) |> 
  left_join( select(denoms, TRT01P, DEN), by = 'TRT01P') |> 
  mutate(PCT = if_else(!is.na(N) & !is.na(DEN), round_sas(N/DEN * 100, 0), NA),
         VALUE = sprintf("%3d (%3d%%)", N, PCT)) 

header <- denoms |> 
  mutate(HEADER = str_glue("{TRT01P}\n(N={DEN})")) |> 
  add_row(HEADER = 'Population', TRT01PN = -1) |> 
  arrange(TRT01PN) |> 
  select(HEADER)|> 
  pivot_wider(names_from = HEADER, values_from = HEADER)

final <- all |> 
  select(TRT01PN, SET, VALUE) |> 
  pivot_wider(names_from = TRT01PN, values_from = VALUE, names_prefix = "TRT_")

col_rel_width <- c(2, rep(2, ncol(final) - 1))
colheader_txt <- paste(names(header), collapse = " | ")

tbl <- final |>
  
  rtf_page_header(text = c("CDISC SDTM/ADaM Pilot Project                                                                           CDISCPILOT01",
                           "",
                           "Protocol: CDISCPILOT01                                                                                       Page \\pagenumber of \\pagefield",
                           "Population: All Subjects"),
                  text_justification = c("l", "l", "l", "l"),
                  text_format = c("b", "", "", "")) |> 
  rtf_page_footer (text = paste0("Source: adsl.xpt                                                                                       Date: ",
                                      format(Sys.time(), "%d"),
                                      month.abb[as.integer(format(Sys.time(), "%m"))],
                                      format(Sys.time(), "%Y %H:%M")
                  ),
                  text_justification = c("l"),
                 text_format = c("")) |>
  rtf_page(orientation = "landscape") |> 
  rtf_title(
    title = c("Table 14-1.01", "Summary of Populations"),
    text_space = 1,
    text_format = c("b", "")
  ) |>
  rtf_colheader(
    colheader = colheader_txt,
    col_rel_width = col_rel_width,
    border_color_top = rep("white", 5),
    border_color_left = rep("white", 5),
    border_color_right = rep("white", 5),
    border_color_bottom = rep("black", 5),
    border_bottom = rep("single", 5),
    text_font_size = rep(11, 5)
  ) |>
  rtf_body(
    col_rel_width = col_rel_width,
    text_justification = c("l", "c", "c", "c", "c"),
    border_top = rep("", 5),
    border_first = rep("", 5),
    border_color_top = rep("white", 5),
    border_color_left = rep("white", 5),
    border_color_right = rep("white", 5),
    border_color_bottom = rep("white", 5),
    text_font_size = rep(11, 5)
  ) |>
  rtf_footnote(
    footnote = c("", "", "",
      "NOTE: N in column headers represents number of subjects entered in study (i.e., signed informed consent).",
      "The ITT population includes all subjects randomized.",
      "The Safety population includes all randomized subjects known to have taken at least one dose of randomized study drug.",
      "The Efficacy population includes all subjects in the safety population who also have at least one post-baseline ADAS-Cog and CIBIC+ assessment."
    ),
    border_color_left = "white",
    border_color_right = "white",
    border_color_bottom = "white",
    text_font_size = 11
  ) 

tbl |>
  rtf_encode() |>
  write_rtf("03_tlf/dev/data/t_14_1_01.rtf")

  write_xpt(final, "03_tlf/dev/data/t_14_1_01.xpt")