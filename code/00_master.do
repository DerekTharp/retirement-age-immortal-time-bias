* ============================================================
* 00_master.do
* Reproduces all results for:
*   "Immortal time bias in the association between
*    retirement age and mortality"
*
* Requirements:
*   - Stata 18 or later (tested in StataNow/MP 19.5)
*   - RAND HRS Longitudinal File v2022 (randhrs1992_2022v1.dta)
*   - HRS Fat Files (waves 1996-2010; 1994 file not used)
*
* Run from the project root. Update the HRS root below once.
* ============================================================

version 18
clear all
set more off

capture mkdir "output"
capture mkdir "output/logs"

capture log close master
log using "output/logs/00_master.log", name(master) replace text

* --- USER: Set this path once ---
global hrs_root "SET_YOUR_HRS_DATA_PATH_HERE"

* Derive remaining paths from the HRS root and current project directory
global rand "$hrs_root/randhrs1992_2022v1_STATA"
global fat  "$hrs_root/HRS Fat Files"
global out  "`c(pwd)'"

di "Project root: $out"
di "HRS raw-data root: $hrs_root"

* --- Verify required input files exist ---
capture confirm file "$rand/randhrs1992_2022v1.dta"
if _rc {
    di as error "ERROR: RAND Longitudinal file not found at $rand"
    log close master
    exit 601
}

local fat_files "h96f4a_STATA/h96f4a h98f2c_STATA/h98f2c h00f1d_STATA/h00f1d h02f2c_STATA/h02f2c h04f1c_STATA/h04f1c h06f4b_STATA/h06f4b h08f3b_STATA/h08f3b hd10f6b_STATA/hd10f6b"
foreach ff of local fat_files {
    capture confirm file "$fat/`ff'.dta"
    if _rc {
        di as error "ERROR: HRS Fat File not found: $fat/`ff'.dta"
        log close master
        exit 601
    }
}
di "All required input files verified."

di _n "============================================="
di    "Paths verified. Running pipeline."
di    "============================================="

capture noisily do code/01_build_sample.do
if _rc {
    log close master
    exit _rc
}

capture noisily do code/02_replicate_table2.do
if _rc {
    log close master
    exit _rc
}

capture noisily do code/03_sensitivity_no_postret_exclusion.do
if _rc {
    log close master
    exit _rc
}

* Supplement: variant comparison flows and RAND-occ alternative
capture noisily do code/04b_variant_flow_comparison.do
if _rc {
    log close master
    exit _rc
}

capture noisily do code/04c_rand_occ_alternative.do
if _rc {
    log close master
    exit _rc
}

capture noisily do code/04d_ftpt_comparison.do
if _rc {
    log close master
    exit _rc
}

di _n "============================================="
di    "Pipeline complete."
di    "Results:    output/tables/table2_summary.txt"
di    "Logs:       output/logs/"
di    "Supplement: output/logs/04b_variant_flow.log"
di    "Ancillary:  output/logs/04d_ftpt_comparison.log"
di    "            output/logs/04c_rand_occ_alternative.log"
di    "============================================="

log close master
