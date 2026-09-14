# ==============================================================================
# Shared utility functions for ADaM validation programs
# ==============================================================================

# SAS-style rounding: round half away from zero (R's round() rounds half to
# even, per IEC 60559, which can disagree with SAS ROUND() at exact ties,
# e.g. round(0.45, 1) == 0.4 in R but 0.5 in SAS).
round_sas <- function(x, digits = 0) {
  scale <- 10^digits
  sign(x) * trunc(abs(x) * scale + 0.5 + 1e-9) / scale
}
