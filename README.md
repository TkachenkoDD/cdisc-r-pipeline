# CDISC Pilot ADaM & TLF Validation Pipeline in R

An end-to-end clinical data programming, validation, and submission-compliance suite written in **R**, utilizing the modern **Pharmaverse** ecosystem (`metacore`, `xportr`, `r2rtf`, `diffdf`, `datasetjson`).

This repository demonstrates independent secondary programming (Double Programming / Validation) for ADaM datasets and Tables, Listings, and Figures (TLFs), along with CDISC compliance deliverables based on the standard `CDISCPILOT01` study data.

---

## 🌟 Key Features

* **Pharmaverse Ecosystem**: Metadata-driven pipeline built with `metacore` for specification management and `xportr` for CDISC-compliant `.xpt` export.
* **Dual Output Formats**: Full support for classical `.xpt` (SAS v5 transport) as well as the modern **Dataset-JSON** standard via `datasetjson`.
* **Submission Deliverables**: Includes metadata definition standard **Define-XML v2.0** (`define.xml`) and formal **Pinnacle 21** compliance validation reports.
* **Automated Quality Control**: Automated dataset comparison (`diffdf`) generating structured findings (`findings_*.xpt`) for non-matching records.
* **SAS-Compliant Precision**: Custom SAS-style numerical rounding (`round_sas`) to avoid artificial tie-breaking mismatches between R and SAS (IEEE 754 vs IEC 60559).
* **Metadata Performance Optimization**: Smart caching (`meta.rds`) with file modification timestamp tracking (`file.mtime`).
* **TLF Generation**: Production of publication-ready RTF summary tables (`r2rtf`) with standard clinical metadata headers, footers, and footnotes.

---

## 📁 Repository Structure

```text
.
├── 01_sdtm/            
│   └── dev/
│       └── data/       
│           └── json/      # Input SDTM datasets (.json)
│           └── xpt/       # Input SDTM datasets (.xpt)
│
├── 02_adam/
│   ├── 00_doc/            # Metadata specifications, Define-XML & Pinnacle 21 reports
│   │                        # (ADAM_spec.xlsx, define-*.xml, P21_report.xlsx/html)
│   ├── dev/
│   │   └── data/              
│   │        └── json/     # Production / Base outputs (.json)
│   │        └── xpt/      # Production / Base outputs (.xpt)
│   │
│   └── val/               # Independent Validation programs and outputs
│       ├── prog/          # R scripts (00_setup.R, 01_utils.R, adsl.R, etc.)
│       └── data/       
│           └── json/      # Validation outputs (.json, findings)
│           └── xpt/       # Validation outputs (.xpt, findings)
│ 
└── 03_tlf/                
    ├── 00_doc/            # Study description and list of tables
    └── dev/              
         ├── prog/         # R scripts (00_setup.R, 01_utils.R, t_14_1_01.R, etc.)
         └── data/         # TLF outputs (.rtf, .xpt)
```

🛠️ Tech Stack & Dependencies
* Language: R

* Core Packages:

  * dplyr, tidyr, stringr, purrr — Data transformation & manipulation
  
  * metacore, metatools — Metadata specification handling
  
  * xportr — CDISC dataset attributes, validation, and XPT export
  
  * datasetjson — CDISC Dataset-JSON v1.0 export and validation
  
  * diffdf — Quality control and dataset comparison
  
  * r2rtf — RTF table generation
  
  * haven, readxl — File I/O

* Compliance & Validation Standards:

  * CDISC ADaM v2.1 & SDTM v1.3
  
  * Pinnacle 21 Community (Compliance Rules Verification)
  
  * Define-XML v2.0 Specification

🔍 Validation Findings & Resolution
During independent validation of the ADSL domain against production outputs, two critical specification/production bugs were identified and successfully documented:

1. TRT01A / TRT01AN Discrepancy (Actual Treatment):

    * Issue: Production code assigned TRT01A = ARM, ignoring 12 subjects where DM.ARM != DM.ACTARM.
    
    * Validation Fix: Correctly derived TRT01A based on actual treatment administered (DM.ACTARM), preserving CDISC standards for actual vs. planned treatment variables.

2. BMIBLGR1 Imputation Error:

    * Issue: Production assigned missing baseline weight/height records to the <25 BMI category.
    
    * Validation Fix: Preserved NA values for missing baseline anthropometric measurements.

📄 Data Source & Disclaimer
This project uses publicly available sample data from the CDISC SDTM/ADaM Pilot Project (CDISCPILOT01), provided by CDISC for testing and educational purposes.

  * No real patient health information (PHI) or proprietary trial data is included.
  * All code, validation scripts, and generated compliance artifacts are created strictly for educational and portfolio demonstration purposes.

