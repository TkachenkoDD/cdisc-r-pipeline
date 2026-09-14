# ==============================================================================
# Creates and Validates ADSL
# ==============================================================================

source("02_adam/val/prog/00_setup.R")
source("02_adam/val/prog/01_get_metadata.R")
source("02_adam/val/prog/01_io_helpers.R")
source("02_adam/val/prog/01_qc_helpers.R")
source("02_adam/val/prog/01_utils.R")

meta <- get_meta_cached()
adsl_spec <- select_dataset(meta, "ADSL")
#codelist <- meta$codelist

dm <- read_xpt("01_sdtm/dev/data/xpt/dm.xpt")
sv <- read_xpt("01_sdtm/dev/data/xpt/sv.xpt")
ex <- read_xpt("01_sdtm/dev/data/xpt/ex.xpt")
ds <- read_xpt("01_sdtm/dev/data/xpt/ds.xpt")
vs <- read_xpt("01_sdtm/dev/data/xpt/vs.xpt")
sc <- read_xpt("01_sdtm/dev/data/xpt/sc.xpt")
mh <- read_xpt("01_sdtm/dev/data/xpt/mh.xpt")
qs <- read_xpt("01_sdtm/dev/data/xpt/qs.xpt")

site_counts <- dm |> 
  filter(ARM != 'Screen Failure') |> 
  distinct(USUBJID, SITEID) |>
  count(SITEID, name = "N_SUBJECTS")

ex_stdt <- ex |> 
  group_by(USUBJID) |> 
  slice_min(order_by = EXSTDTC, n=1, na_rm = T, with_ties = F) |> 
  select(USUBJID, TRTSDT = EXSTDTC) |> 
  mutate(TRTSDT = as.Date(TRTSDT))

ex_endt <- ex |> 
  group_by(USUBJID) |> 
  slice_tail(n=1) |> 
  select(USUBJID, TRTEDT = EXENDTC) |> 
  mutate(TRTEDT = as.Date(TRTEDT))

visit1date <- sv |> 
  filter(VISITNUM == 1) |> 
  select(USUBJID, VISIT1DT = SVSTDTC) |> 
  mutate(VISIT1DT = as.Date(VISIT1DT))

visit4date <- sv |> 
  filter(VISITNUM == 4) |> 
  select(USUBJID, VISIT4ST = SVSTDTC, VISIT4EN = SVENDTC) |> 
  mutate(VISIT4ST = as.Date(VISIT4ST),
         VISIT4EN = as.Date(VISIT4EN))

visit8date <- sv |> 
  filter(VISITNUM == 8) |> 
  select(USUBJID, VISIT8ST = SVSTDTC, VISIT8EN = SVENDTC) |> 
  mutate(VISIT8ST = as.Date(VISIT8ST),
         VISIT8EN = as.Date(VISIT8EN))

visit16date <- sv |> 
  filter(VISITNUM == 10) |> 
  select(USUBJID, VISIT16ST = SVSTDTC, VISIT16EN = SVENDTC) |> 
  mutate(VISIT16ST = as.Date(VISIT16ST),
         VISIT16EN = as.Date(VISIT16EN))

visit24date <- sv |> 
  filter(VISITNUM == 12) |> 
  select(USUBJID, VISIT24ST = SVSTDTC, VISIT24EN = SVENDTC) |> 
  mutate(VISIT24ST = as.Date(VISIT24ST),
         VISIT24EN = as.Date(VISIT24EN))

disp <- ds |> 
  filter(DSCAT == 'DISPOSITION EVENT') |> 
  select(USUBJID, DSDECOD, DSCAT, DSTERM, VISITNUM, VISIT) |> 
  mutate(DCDECOD = DSDECOD,
         DCREASCD = case_when(
    DCDECOD == "PROTOCOL VIOLATION" & str_detect(DSTERM, 'CRITERIA NOT MET') ~ "I/E Not Met",
    DCDECOD == "COMPLETED"                    ~ "Completed",
    DCDECOD == "ADVERSE EVENT"                ~ "Adverse Event",
    DCDECOD == "DEATH"                        ~ "Death",
    DCDECOD == "LACK OF EFFICACY"             ~ "Lack of Efficacy",
    DCDECOD == "LOST TO FOLLOW-UP"            ~ "Lost to Follow-up",
    DCDECOD == "WITHDRAWAL BY SUBJECT"        ~ "Withdrew Consent",
    DCDECOD == "STUDY TERMINATED BY SPONSOR"  ~ "Sponsor Decision",
    DCDECOD == "PHYSICIAN DECISION"           ~ "Physician Decision",
    DCDECOD == "PROTOCOL VIOLATION"           ~ "Protocol Violation",
    DCDECOD == "SCREEN FAILURE"               ~ "Screen Failure",
    TRUE ~ NA_character_
  ),
  #VISNUMEN = if_else(DCDECOD == "COMPLETED", 12, VISITNUM))
  VISNUMEN = if_else(VISIT == 'WEEK 26', VISITNUM - 1, VISITNUM))

vs_height <- vs |> 
  filter(VSTESTCD =='HEIGHT' & VISITNUM == 1) |> 
  mutate(HEIGHTBL = round_sas(VSSTRESN, 1))

vs_weight <- vs |> 
  filter(VSTESTCD =='WEIGHT' & VISITNUM == 3) |> 
  mutate(WEIGHTBL = round_sas(VSSTRESN, 1))

sc_edu <- sc |> 
  filter(SCTESTCD == 'EDLEVEL') |> 
  mutate(EDUCLVL = as.numeric(SCSTRESN))

mh_prim_d <- mh |> 
  filter(MHCAT == 'PRIMARY DIAGNOSIS') |> 
  mutate(DISONSDT = as.Date(MHSTDTC))

mms <- qs |> 
  filter(QSCAT == 'MINI-MENTAL STATE') |> 
  mutate(QSORRES_NUM = as.numeric(QSORRES)) |> 
  group_by(USUBJID) |> 
  summarise(MMSETOT = if_else(all(is.na(QSORRES_NUM)), NA_integer_, as.numeric(sum(QSORRES_NUM, na.rm = TRUE))
    ), .groups = "drop")

qs_efffl_1 <- qs |> 
  filter(QSTESTCD == 'ACTOT' & VISITNUM > 3) |> 
  distinct(USUBJID) |> 
  mutate(EFFFL_1 = 'Y')

qs_efffl_2 <- qs |> 
  filter(QSTESTCD == 'CIBIC' & VISITNUM > 3) |> 
  distinct(USUBJID) |> 
  mutate(EFFFL_2 = 'Y')

adsl1 <- dm |>
  select(STUDYID, USUBJID, SUBJID, SITEID, ARM, ACTARM, AGE, AGEU,
                              RACE, SEX, ETHNIC, RFSTDTC, RFENDTC, DTHFL) |>
  mutate(TRT01P = if_else(ARM != "Screen Failure", ARM, NA_character_),
         TRT01A = if_else(ACTARM != "Screen Failure", ACTARM, NA_character_),
         #Actually for 12 subjects from DM ARM != ACTARM. Should be TRT01A = ACTARM
         AGE = as.numeric(AGE),
         AGEGR1N = case_when(AGE < 65 ~ 1L,
                             AGE >= 65 & AGE <= 80 ~ 2L,
                             AGE > 80 ~ 3L)
         ) |>
  create_var_from_codelist(adsl_spec, TRT01P, TRT01PN, strict = F) |>
  create_var_from_codelist(adsl_spec, TRT01A, TRT01AN, strict = F) |>
  create_var_from_codelist(adsl_spec, AGEGR1N, AGEGR1,
                    codelist = get_control_term(adsl_spec, AGEGR1N),
                    decode_to_code = FALSE) |>
  create_var_from_codelist(adsl_spec, RACE, RACEN) |> 
  mutate(TRT01PN = as.numeric(TRT01PN),
         TRT01AN = as.numeric(TRT01AN),
         RACEN = as.numeric(RACEN)) |>
  
  left_join(ex_stdt, by = "USUBJID") |>
  left_join(ex_endt, by = "USUBJID") |> 
  
  mutate(TRTEDT = case_when(!is.na(TRTEDT) ~ TRTEDT,
                            is.na(TRTEDT) & ARM != "Screen Failure" ~ as.Date(RFENDTC)),
          TRTDUR = as.numeric(TRTEDT-TRTSDT+1)) |> 
  left_join(site_counts, by = 'SITEID') |> 
  mutate(SITEGR1 = if_else(N_SUBJECTS < 9, as.character('900'), SITEID))

cumdose_compfl <- adsl1 |> 
  select(USUBJID, TRTSDT, TRTEDT, TRTDUR, TRT01PN, RFENDTC) |> 
  left_join(visit4date, by = 'USUBJID') |> 
  left_join(visit8date, by = 'USUBJID') |> 
  left_join(visit16date, by = 'USUBJID') |> 
  left_join(visit24date, by = 'USUBJID') |> 
  mutate(v4_end  = pmin(VISIT4EN, TRTEDT, na.rm = TRUE),
         visint1 = if_else(!is.na(v4_end) & v4_end >= TRTSDT, as.numeric(v4_end - TRTSDT + 1), 0L),
         v24_end = pmin(VISIT24EN, TRTEDT, na.rm = TRUE),
         visint2 = if_else(!is.na(VISIT4EN) & TRTEDT > VISIT4EN, 
                           as.numeric(pmin(v24_end, TRTEDT) - VISIT4EN), 0L),
         visint3 = if_else(!is.na(VISIT24EN) & TRTEDT > VISIT24EN, 
                           as.numeric(TRTEDT - VISIT24EN), 0L),
         CUMDOSE = case_when(TRT01PN %in% c(0, 54) ~ as.numeric(TRT01PN*TRTDUR),
                             TRT01PN == 81 ~ as.numeric((visint1*54) + (visint2 * 81) + (visint3 * 54))),
         AVGDD = if_else(!is.na(CUMDOSE) & !is.na(TRTDUR), round_sas(CUMDOSE/TRTDUR, 1), NA_real_),
         COMP8FL = if_else(!is.na(VISIT8ST) & !is.na(VISIT8EN) & RFENDTC >= VISIT8EN, 'Y', 'N'),
         COMP16FL = if_else(!is.na(VISIT16ST) & !is.na(VISIT16EN) & RFENDTC >= VISIT16EN, 'Y', 'N'),
         COMP24FL = if_else(!is.na(VISIT24ST) & !is.na(VISIT24EN) & RFENDTC >= VISIT24EN, 'Y', 'N'))

adsl2 <- adsl1 |> 
  left_join(select(cumdose_compfl, USUBJID, CUMDOSE, AVGDD, COMP8FL, COMP16FL, COMP24FL), by = 'USUBJID') |> 
  left_join(select(disp, USUBJID, DCDECOD, DCREASCD, VISNUMEN), by = 'USUBJID') |> 
  left_join(select(vs_height, USUBJID, HEIGHTBL), by = 'USUBJID') |> 
  left_join(select(vs_weight, USUBJID, WEIGHTBL), by = 'USUBJID') |> 
  mutate(ITTFL = if_else(!is.na(ARM), 'Y', 'N'),
         SAFFL = if_else(ITTFL == 'Y' & !is.na(TRTSDT), 'Y', 'N'),
         DISCONFL = if_else(DCREASCD != 'Completed', 'Y', NA_character_),
         DSRAEFL = if_else(DCREASCD == 'Adverse Event', 'Y', NA_character_),
         VISNUMEN = as.numeric(VISNUMEN),
         BMIBL = if_else(!is.na(HEIGHTBL) & !is.na(WEIGHTBL), round_sas(WEIGHTBL / ((HEIGHTBL / 100)^2), 1), NA_real_),
         # BMIBLGR1 = case_when(!is.na(BMIBL) & BMIBL < 25 ~ as.character('Normal'),
         #                      BMIBL >= 25 & BMIBL < 30 ~ as.character('Overweight'),
         #                      BMIBL >= 30 ~ as.character('Obese'))) |> 
         BMIBLGR1 = case_when(!is.na(BMIBL) & BMIBL < 25 ~ as.character('<25'),
                              BMIBL >= 25 & BMIBL < 30 ~ as.character('25-<30'),
                              BMIBL >= 30 ~ as.character('>=30'))) |>
  left_join(select(sc_edu, USUBJID, EDUCLVL), by = 'USUBJID') |> 
  left_join(select(mh_prim_d, USUBJID, DISONSDT), by = 'USUBJID') |> 
  left_join(select(visit1date, USUBJID, VISIT1DT), by = 'USUBJID') |> 
  left_join(qs_efffl_1, by = 'USUBJID') |> 
  left_join(qs_efffl_2, by = 'USUBJID') |> 
  mutate(DURDIS = if_else(!is.na(VISIT1DT) & !is.na(DISONSDT), round_sas(as.numeric(VISIT1DT - DISONSDT + 1) / 30.4375, 1), NA_real_),
         DURDSGR1 = if_else(DURDIS >= 12, '>=12', '<12'),
         RFENDT = as.Date(RFENDTC),
         EFFFL = if_else(SAFFL == 'Y' & EFFFL_1 == 'Y' & EFFFL_2 == 'Y', 'Y', 'N', 'N')) |> 
  left_join(mms, by = 'USUBJID') |> 
  filter(ARM != 'Screen Failure')

end_adam(adsl2, adsl_spec, "ADSL")
compare_adam_xpt ("ADSL", F)
compare_adam_json ("ADSL", F)
