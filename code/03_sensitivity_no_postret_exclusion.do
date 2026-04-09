* ============================================================
* 03_sensitivity_no_postret_exclusion.do
* Test whether the post_ret < 1 exclusion changes corrected estimates
*
* Wu excluded 158 people "lost to follow-up in the year they
* reported being completely retired." This exclusion is applied
* BEFORE all models in the main pipeline. But the corrected
* models (age-scale, landmark) may not need it:
*   - Age-scale: left-truncation at retirement handles entry
*   - Landmark: restricts to alive at Jan 2005 anyway
*
* This script re-runs the corrected models on the FULL sample
* (before the post_ret < 1 drop) to check sensitivity.
* ============================================================

version 18
clear all
set more off
set maxvar 32000
set linesize 140

* $out must be set by 00_master.do or manually

log using "$out/output/logs/03_sensitivity_no_postret_exclusion.log", replace

capture confirm file "$out/data/analytic_sample_pre_postret_exclusion.dta"
if _rc {
    di as error "ERROR: Pre-exclusion analytic sample not found."
    di as error "Run code/01_build_sample.do first."
    exit 601
}

* Load the sample after all main restrictions except the
* post_ret < 1 exclusion.
use "$out/data/analytic_sample_pre_postret_exclusion.dta", clear
di "Pre-exclusion analytic sample loaded: " _N
assert _N == 3296
tab healthy

gen float exit_age = (exit_date - mdy(rabmonth, 15, rabyear)) / 365.25
gen float ret_age_c65 = ret_age_precise - 65

* Recreate covariates using the same definitions as 01_build_sample.do
gen byte male = (ragender == 1) if ragender < .
gen byte white = (raracem == 1) if raracem < .
gen byte married = inlist(r1mstat, 1, 2, 3) if r1mstat < .

gen byte educ_cat = .
replace educ_cat = 1 if raeduc <= 2
replace educ_cat = 2 if raeduc == 3
replace educ_cat = 3 if raeduc >= 4 & raeduc < .

gen int birth_c = rabyear - 1931

capture confirm variable h1atotn
if _rc == 0 {
    xtile wealth_q = h1atotn, nq(4)
}
else {
    capture confirm variable h1atota
    if _rc == 0 {
        xtile wealth_q = h1atota, nq(4)
    }
    else {
        gen byte wealth_q = .
    }
}

gen byte occ_cat = .
replace occ_cat = 1 if inlist(raw_occ, 1, 2)
replace occ_cat = 2 if inlist(raw_occ, 3, 4, 5, 6, 7, 8, 9)
replace occ_cat = 3 if raw_occ >= 10 & raw_occ <= 17

gen byte smoke_cat = .
replace smoke_cat = 1 if r1smokev == 0
replace smoke_cat = 2 if r1smokev == 1 & r1smoken == 0
replace smoke_cat = 3 if r1smoken == 1

gen byte alcohol = (r1drink == 1) if r1drink < .

capture confirm variable r1vgactx
if _rc == 0 {
    gen byte exercise = (inlist(r1vgactx, 1, 2)) if r1vgactx < .
}
else {
    capture confirm variable r1vigact
    if _rc == 0 {
        gen byte exercise = (r1vigact == 1) if r1vigact < .
    }
    else {
        gen byte exercise = .
    }
}

gen byte bmi_cat = .
replace bmi_cat = 1 if r1bmi < 25 & r1bmi > 0
replace bmi_cat = 2 if r1bmi >= 25 & r1bmi < 30
replace bmi_cat = 3 if r1bmi >= 30 & r1bmi < .

gen byte srh_rev = 6 - r1shlt if r1shlt < .

gen byte chronic = 0
foreach v in r1hibpe r1diabe r1cancre r1lunge r1hearte r1stroke r1arthre r1psyche {
    capture confirm variable `v'
    if _rc == 0 {
        replace chronic = chronic + (`v' == 1) if `v' < .
    }
}

capture confirm variable r1adlw
if _rc == 0 {
    gen byte adl_any = (r1adlw >= 1) if r1adlw < .
}
else {
    gen byte adl_any = .
}

* HHIDPN = 6-digit HHID + 3-digit PN; divide by 1000 to extract HHID
gen long hhid_n = floor(hhidpn / 1000)

global covars_all "male white married i.educ_cat birth_c i.wealth_q i.occ_cat i.smoke_cat alcohol exercise i.bmi_cat srh_rev chronic adl_any"

* ============================================================
* KEY: This sample does NOT drop post_ret < 1
* ============================================================

di _n "====================================================="
di "FULL SAMPLE (no post_ret exclusion)"
di "====================================================="
di "N = " _N
tab healthy
di "post_ret summary:"
sum post_ret, detail
di "Observations with post_ret < 1: "
count if post_ret < 1
assert r(N) == 84

di _n "For comparison, main analysis sample: N = 3,212"


* ============================================================
* Part A: Wu replication WITH post_ret < 1 people included
* ============================================================

di _n "====================================================="
di "PART A: Wu replication (full sample, no post_ret exclusion)"
di "====================================================="

stset follow_up, failure(dead_2011) id(hhidpn)

stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
di "Full-sample Wu replication (healthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
di "Full-sample Wu replication (unhealthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])


* ============================================================
* Part B: Age as time scale (full sample)
* ============================================================

di _n "====================================================="
di "PART B: Age as time scale (full sample)"
di "====================================================="

stset exit_age, failure(dead_2011) enter(time ret_age_precise) ///
    id(hhidpn) origin(time 0)
stdescribe

stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
di "Full-sample age-scale (healthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
di "Full-sample age-scale (unhealthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])


* ============================================================
* Part C: Landmark (full sample)
* ============================================================

di _n "====================================================="
di "PART C: Landmark (full sample)"
di "====================================================="

* Reload full sample (stset contamination)
* We still have the data in memory, just re-stset
* But landmark needs to drop people, so preserve/restore
preserve

gen landmark = mdy(1, 1, 2005)
format landmark %td
keep if ret_date < landmark
keep if exit_date >= landmark
di "After landmark restriction: " _N
tab healthy

gen float post_landmark = (exit_date - landmark) / 365.25
gen byte dead_post_lm = (dead_2011 == 1 & death_date >= landmark)

stset post_landmark, failure(dead_post_lm) id(hhidpn)

stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
di "Full-sample landmark (healthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
di "Full-sample landmark (unhealthy): HR = " %6.4f exp(_b[ret_age_c65]) ///
   "  CI: " %6.4f exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " %6.4f exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

restore


* ============================================================
* Summary comparison
* ============================================================

di _n "====================================================="
di "COMPARISON: post_ret >= 1 exclusion vs full sample"
di "====================================================="
di "Main-analysis estimates are reported in output/logs/02_replicate_table2.log."
di "Compare those estimates with the full-sample models above."

log close
