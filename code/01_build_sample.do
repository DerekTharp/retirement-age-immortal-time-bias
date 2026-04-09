* ============================================================
* 01_build_sample.do
* Replication of Wu et al. (2016) "Association of retirement
* age with mortality" (JECH 70:917-23)
*
* Sample construction:
*   - HRS initial cohort (hacohort==3), ages 50-62 at baseline
*   - FT+PT workers at baseline, self-reported complete retirement by 2010
*   - Health-reason variable from waves 3-10 (1996-2010)
*   - Occupation from 1992 HRS core file v2720 (1980 Census codes)
*   - post_ret >= 1 year exclusion
*
* Globals $rand, $fat, $out must be set by 00_master.do
* ============================================================

version 18
clear all
set more off
set maxvar 32000
set linesize 120

capture mkdir "$out/output"
capture mkdir "$out/output/logs"
capture mkdir "$out/output/tables"
capture mkdir "$out/data"

log using "$out/output/logs/01_build_sample.log", replace


* ===========================================================
* PART A: Health-reason-for-retirement from ALL waves (1994-2010)
*
* The question asks how important poor health was in the
* decision to retire, coded 1-4 (1=very important ... 4=not
* at all important). We keep values 1-4 only and retain
* the EARLIEST observation per person.
* ===========================================================

di _n "====================================================="
di "PART A: Extracting health-reason variable from all waves"
di "====================================================="

* Wave 2 (1994) w4644 excluded: different question structure (binary
* checklist item from Section F, not the 4-point importance scale
* used in waves 3-10). Only 35 valid responses, negligible impact.

* ---- Wave 3 (1996): e3049_1 ----
* Coding: 1-4 valid; 8=DK; 9=RF; .=not asked
use hhidpn e3049_1 using "$fat/h96f4a_STATA/h96f4a.dta", clear
rename e3049_1 hlth_ret
gen byte hlth_wave = 3
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 3 (1996): " _N " valid responses"
tempfile hw3
save `hw3'

* ---- Wave 4 (1998): f3580_1 ----
use hhidpn f3580_1 using "$fat/h98f2c_STATA/h98f2c.dta", clear
rename f3580_1 hlth_ret
gen byte hlth_wave = 4
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 4 (1998): " _N " valid responses"
tempfile hw4
save `hw4'

* ---- Wave 5 (2000): g3869_1 ----
use hhidpn g3869_1 using "$fat/h00f1d_STATA/h00f1d.dta", clear
rename g3869_1 hlth_ret
gen byte hlth_wave = 5
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 5 (2000): " _N " valid responses"
tempfile hw5
save `hw5'

* ---- Wave 6 (2002): hj588a ----
use hhidpn hj588a using "$fat/h02f2c_STATA/h02f2c.dta", clear
rename hj588a hlth_ret
gen byte hlth_wave = 6
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 6 (2002): " _N " valid responses"
tempfile hw6
save `hw6'

* ---- Wave 7 (2004): jj588a ----
use hhidpn jj588a using "$fat/h04f1c_STATA/h04f1c.dta", clear
rename jj588a hlth_ret
gen byte hlth_wave = 7
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 7 (2004): " _N " valid responses"
tempfile hw7
save `hw7'

* ---- Wave 8 (2006): kj588a ----
use hhidpn kj588a using "$fat/h06f4b_STATA/h06f4b.dta", clear
rename kj588a hlth_ret
gen byte hlth_wave = 8
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 8 (2006): " _N " valid responses"
tempfile hw8
save `hw8'

* ---- Wave 9 (2008): lj588a ----
use hhidpn lj588a using "$fat/h08f3b_STATA/h08f3b.dta", clear
rename lj588a hlth_ret
gen byte hlth_wave = 9
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 9 (2008): " _N " valid responses"
tempfile hw9
save `hw9'

* ---- Wave 10 (2010): mj588a ----
use hhidpn mj588a using "$fat/hd10f6b_STATA/hd10f6b.dta", clear
rename mj588a hlth_ret
gen byte hlth_wave = 10
keep if hlth_ret >= 1 & hlth_ret <= 4
di "Wave 10 (2010): " _N " valid responses"
tempfile hw10
save `hw10'

* ---- Stack all waves, keep EARLIEST per person ----
use `hw3', clear
append using `hw4'
append using `hw5'
append using `hw6'
append using `hw7'
append using `hw8'
append using `hw9'
append using `hw10'

di _n "Total health-reason observations (all waves): " _N
bysort hhidpn (hlth_wave): keep if _n == 1
di "Unique persons with health-reason data: " _N

tab hlth_wave, m
tab hlth_ret, m

tempfile hlth_reason
save `hlth_reason'


* ===========================================================
* PART A2: Extract raw occupation from 1992 fat file
* We use v2720 (Section F, 1980 Census occupation codes) rather
* than the RAND-imputed r1jcocc because r1jcocc has near-complete
* imputation (only 5 missing among workers), far fewer than the
* 524 exclusions Wu et al. reported. v2720 produces 377 missing,
* closer to the published flow.
* ===========================================================

use hhidpn v2720 using "$fat/h92f1b_STATA/h92f1b.dta", clear
rename v2720 raw_occ
replace raw_occ = . if raw_occ == 0 | raw_occ >= .
tempfile raw_occ
save `raw_occ'


* ===========================================================
* PART B: Load RAND HRS and apply inclusion criteria
* ===========================================================

di _n "====================================================="
di "PART B: Sample construction"
di "====================================================="

use "$rand/randhrs1992_2022v1.dta", clear
di "Full RAND file: " _N

* HRS cohort only (born 1931-1941, first interviewed 1992)
keep if hacohort == 3
di "After HRS cohort: " _N
assert _N == 13659

* Wave 1 respondent
keep if r1iwstat == 1
di "After Wave 1 interview: " _N
assert _N == 12545

* Exclude proxy interviews
keep if r1proxy == 0
di "After proxy exclusion: " _N
assert _N == 11901

* Age 50-62 at baseline
keep if r1agey_b >= 50 & r1agey_b <= 62 & r1agey_b < .
di "After age 50-62: " _N
assert _N == 9849

* At least 2 assessments (waves 1-10)
gen byte n_waves = 0
forvalues w = 1/10 {
    replace n_waves = n_waves + 1 if r`w'iwstat == 1
}
keep if n_waves >= 2
di "After >=2 assessments: " _N
assert _N == 9387

* Working at baseline (full-time or part-time)
keep if inlist(r1lbrf, 1, 2)
di "After working (FT+PT) at baseline: " _N

* Self-reported retirement: r[w]sayret == 1 (NO lbrf fallback)
gen byte ret_wave = .
forvalues w = 2/10 {
    replace ret_wave = `w' if r`w'sayret == 1 & ret_wave == .
}
keep if ret_wave != .
di "After self-reported retirement by 2010: " _N
assert _N == 4306

* Occupation from 1992 HRS core file (v2720, 1980 Census codes)
merge 1:1 hhidpn using `raw_occ', keep(master match) nogen
drop if raw_occ == . | raw_occ >= .
di "After excluding missing occupation (raw v2720): " _N

* ---- Merge health-reason-for-retirement ----
merge 1:1 hhidpn using `hlth_reason', keep(match) nogen
di "After merging health reason (inner join): " _N
assert _N == 3296

* ---- Classify healthy vs. unhealthy retirement ----
* hlth_ret == 4 means health was "not at all important" in retirement
gen byte healthy = (hlth_ret == 4)
label define healthy_lbl 0 "Unhealthy retiree" 1 "Healthy retiree"
label values healthy healthy_lbl
tab healthy


* ===========================================================
* PART C: Date and time variables
* ===========================================================

di _n "====================================================="
di "PART C: Date and time variables"
di "====================================================="

* Baseline interview date (Stata %td elapsed date)
gen baseline_date = r1iwend
format baseline_date %td

* Mortality
gen byte dead = (raddate < . & raddate > 0)
gen death_date = raddate if dead == 1
format death_date %td
gen byte dead_2011 = (death_date <= mdy(12, 31, 2011) & dead == 1)

* Retirement date from r[w]retyr / r[w]retmon, fallback to interview date
gen int ret_yr = .
gen byte ret_mon = .
forvalues w = 2/10 {
    replace ret_yr  = r`w'retyr  if ret_wave == `w' & r`w'retyr  > 0 & r`w'retyr  < .
    replace ret_mon = r`w'retmon if ret_wave == `w' & r`w'retmon > 0 & r`w'retmon < 13
}

gen ret_date = mdy(ret_mon, 15, ret_yr) if ret_yr > 0 & ret_mon > 0 & ret_mon <= 12
replace ret_date = mdy(7, 1, ret_yr) if ret_yr > 0 & ret_yr < . & ret_date == .
* Fallback: use interview date of retirement wave
forvalues w = 2/10 {
    replace ret_date = r`w'iwend if ret_wave == `w' & ret_date == .
}
format ret_date %td

* Retirement age (precise, from retyr/retmon)
gen float ret_age = .
forvalues w = 2/10 {
    replace ret_age = r`w'agey_b if ret_wave == `w'
}
gen float ret_age_precise = (ret_yr - rabyear) + (ret_mon - rabmonth) / 12 ///
    if ret_yr > 0 & ret_yr < . & rabyear > 0
* Fallback to interview age if precise age missing or implausible.
* Sample requires age 50-62 at 1992 baseline, so retirement before 50
* is impossible by construction.
replace ret_age_precise = ret_age if ret_age_precise == . | ret_age_precise < 50

* Last interview date (searching backwards from wave 10)
gen last_iw_date = .
format last_iw_date %td
forvalues w = 10(-1)1 {
    replace last_iw_date = r`w'iwend if r`w'iwstat == 1 & last_iw_date == .
}

* Exit date: death if died by end of 2011, else last interview (capped at Dec 31 2011)
gen exit_date = death_date if dead_2011 == 1
replace exit_date = last_iw_date if dead_2011 == 0
replace exit_date = mdy(12, 31, 2011) if exit_date > mdy(12, 31, 2011) & exit_date < .
format exit_date %td

* Follow-up time
gen float follow_up = (exit_date - baseline_date) / 365.25
drop if follow_up <= 0 | follow_up == .
di "After follow_up > 0: " _N
assert _N == 3296

* Post-retirement time
gen float post_ret = (exit_date - ret_date) / 365.25

* Save the pre-exclusion sample so sensitivity analyses can test
* whether dropping short post-retirement follow-up changes results.
save "$out/data/analytic_sample_pre_postret_exclusion.dta", replace

drop if post_ret < 1
di "After post_ret >= 1 year: " _N
assert _N == 3212

* Exit age
gen float exit_age = (exit_date - mdy(rabmonth, 15, rabyear)) / 365.25

di _n "Sample after all time-variable exclusions:"
tab healthy


* ===========================================================
* PART D: Covariates (all from wave 1 / baseline)
* ===========================================================

di _n "====================================================="
di "PART D: Constructing covariates"
di "====================================================="

* ---- Retirement age centered at 65 ----
gen float ret_age_c65 = ret_age_precise - 65
gen float ret_age_c65_sq = ret_age_c65^2

* ---- Demographics ----
gen byte male = (ragender == 1) if ragender < .
gen byte white = (raracem == 1) if raracem < .
gen byte married = inlist(r1mstat, 1, 2, 3) if r1mstat < .

* ---- Education ----
gen byte educ_cat = .
replace educ_cat = 1 if raeduc <= 2
replace educ_cat = 2 if raeduc == 3
replace educ_cat = 3 if raeduc >= 4 & raeduc < .
label define educ_lbl 1 "<HS" 2 "HS" 3 ">HS"
label values educ_cat educ_lbl

* ---- Birth cohort (centered at 1931) ----
gen int birth_c = rabyear - 1931

* ---- Wealth quartiles ----
* Ensure deterministic quartile assignment at ties
set seed 20160901
sort hhidpn
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
        di as error "WARNING: No wealth variable found (h1atotn or h1atota)"
    }
}

* ---- Occupation (raw v2720, 17-category 1980 Census) ----
gen byte occ_cat = .
replace occ_cat = 1 if inlist(raw_occ, 1, 2)
replace occ_cat = 2 if inlist(raw_occ, 3, 4, 5, 6, 7, 8, 9)
replace occ_cat = 3 if raw_occ >= 10 & raw_occ <= 17
label define occ_lbl 1 "White-collar" 2 "Service" 3 "Blue-collar"
label values occ_cat occ_lbl

* ---- Smoking (3 categories) ----
gen byte smoke_cat = .
replace smoke_cat = 1 if r1smokev == 0
replace smoke_cat = 2 if r1smokev == 1 & r1smoken == 0
replace smoke_cat = 3 if r1smoken == 1
label define smoke_lbl 1 "Never" 2 "Former" 3 "Current"
label values smoke_cat smoke_lbl

* ---- Alcohol ----
gen byte alcohol = (r1drink == 1) if r1drink < .

* ---- Exercise (vigorous activity) ----
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
        di as error "WARNING: No exercise variable found"
    }
}

* ---- BMI (3 categories) ----
gen byte bmi_cat = .
replace bmi_cat = 1 if r1bmi < 25 & r1bmi > 0
replace bmi_cat = 2 if r1bmi >= 25 & r1bmi < 30
replace bmi_cat = 3 if r1bmi >= 30 & r1bmi < .
label define bmi_lbl 1 "Normal/underweight" 2 "Overweight" 3 "Obese"
label values bmi_cat bmi_lbl

* ---- Self-rated health (reversed so higher = better) ----
gen byte srh = r1shlt
gen byte srh_rev = 6 - r1shlt if r1shlt < .

* ---- Chronic conditions count ----
gen byte chronic = 0
foreach v in r1hibpe r1diabe r1cancre r1lunge r1hearte r1stroke r1arthre r1psyche {
    capture confirm variable `v'
    if _rc == 0 {
        replace chronic = chronic + (`v' == 1) if `v' < .
    }
    else {
        di as error "WARNING: `v' not found -- chronic count may be understated"
    }
}

* ---- ADL limitations (any) ----
capture confirm variable r1adlw
if _rc == 0 {
    gen byte adl_any = (r1adlw >= 1) if r1adlw < .
}
else {
    gen byte adl_any = .
    di as error "WARNING: r1adlw not found"
}

* ---- Household ID (numeric, for vce(cluster)) ----
* HHIDPN = 6-digit HHID + 3-digit PN; divide by 1000 to extract HHID
gen long hhid_n = floor(hhidpn / 1000)


* ===========================================================
* PART E: Verification against Wu et al. (2016) Table 1
* ===========================================================

di _n "====================================================="
di "PART E: VERIFICATION OUTPUT"
di "====================================================="

di _n "--- Total sample ---"
di "Total N: " _N
di "TARGET: N = 2,956"
assert _N == 3212

di _n "--- Healthy / Unhealthy split ---"
tab healthy
count if healthy == 1
local n_h = r(N)
count if healthy == 0
local n_u = r(N)
di "Healthy:   " `n_h' "  (target: 1,934)"
di "Unhealthy: " `n_u' "  (target: 1,022)"
assert `n_h' == 2077
assert `n_u' == 1135

di _n "--- Deaths by group ---"
count if dead_2011 == 1 & healthy == 1
local d_h = r(N)
count if dead_2011 == 1 & healthy == 0
local d_u = r(N)
di "Deaths (healthy):   " `d_h' "  (target: 234)"
di "Deaths (unhealthy): " `d_u' "  (target: 262)"
assert `d_h' == 306
assert `d_u' == 349

di _n "--- Mortality rates ---"
di "Healthy mortality:   " %5.1f 100 * `d_h' / `n_h' "%  (target: 12.1%)"
di "Unhealthy mortality: " %5.1f 100 * `d_u' / `n_u' "%  (target: 25.6%)"

di _n "--- Retirement age (healthy) ---"
sum ret_age_precise if healthy == 1
di "TARGET: mean 64.9 (SD 3.8)"

di _n "--- Follow-up (healthy) ---"
sum follow_up if healthy == 1
di "TARGET: ~16.9 years"

di _n "--- Follow-up (unhealthy) ---"
sum follow_up if healthy == 0

di _n "--- Demographics (healthy) ---"
sum male if healthy == 1
di "TARGET male: 50.0%"
sum white if healthy == 1
di "TARGET white: 84.2%"
sum married if healthy == 1
di "TARGET married: check paper"

di _n "--- Education (healthy) ---"
tab educ_cat if healthy == 1

di _n "--- SRH reversed (healthy) ---"
sum srh_rev if healthy == 1
di "TARGET: mean ~3.9"

di _n "--- Chronic conditions (healthy) ---"
sum chronic if healthy == 1
di "TARGET: mean ~0.7"

di _n "--- Occupation distribution (healthy) ---"
tab occ_cat if healthy == 1
di "TARGET: WC 35.2%, Svc 39.1%, BC 25.8%"

di _n "--- Occupation distribution (unhealthy) ---"
tab occ_cat if healthy == 0
di "TARGET: WC 21.9%, Svc 40.5%, BC 37.6%"

di _n "--- Smoking (healthy) ---"
tab smoke_cat if healthy == 1

di _n "--- BMI (healthy) ---"
tab bmi_cat if healthy == 1

di _n "--- Exercise (healthy) ---"
sum exercise if healthy == 1

di _n "--- Alcohol (healthy) ---"
sum alcohol if healthy == 1

di _n "--- ADL any (healthy) ---"
sum adl_any if healthy == 1

di _n "--- Wealth quartiles (healthy) ---"
tab wealth_q if healthy == 1

di _n "--- Health-reason source wave distribution ---"
tab hlth_wave

di _n "--- Retirement wave distribution ---"
tab ret_wave


* ===========================================================
* PART F: Save analytic sample
* ===========================================================

di _n "====================================================="
di "PART F: Saving analytic sample"
di "====================================================="

keep hhidpn hhid_n ret_wave hlth_wave hlth_ret healthy ///
    ret_age ret_age_precise ret_yr ret_mon ///
    ret_date baseline_date exit_date death_date last_iw_date ///
    dead dead_2011 follow_up post_ret exit_age ///
    male white married educ_cat birth_c wealth_q occ_cat ///
    smoke_cat alcohol exercise bmi_cat srh srh_rev chronic adl_any ///
    ret_age_c65 ret_age_c65_sq

order hhidpn hhid_n healthy hlth_ret hlth_wave ret_wave ///
    baseline_date ret_date exit_date death_date ///
    dead dead_2011 follow_up post_ret ///
    ret_age_precise ret_age_c65 ret_age_c65_sq exit_age ///
    male white married educ_cat birth_c wealth_q occ_cat ///
    smoke_cat alcohol exercise bmi_cat srh srh_rev chronic adl_any

compress
label data "Wu et al. (2016) best-faith replication sample"
save "$out/data/analytic_sample.dta", replace
di _n "Saved: " _N " observations to data/analytic_sample.dta"

log close
