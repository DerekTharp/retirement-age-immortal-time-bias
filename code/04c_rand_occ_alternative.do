* ============================================================
* 04c_rand_occ_alternative.do
* Alternative reconstruction using RAND-imputed occupation
* (r1jcocc) instead of the raw HRS core variable (v2720).
*
* The primary pipeline uses v2720 (377 missing, closer to
* Wu et al.'s 524). This script uses r1jcocc (5 missing,
* heavily imputed) to show estimates are robust to this choice.
* ============================================================

version 18
clear all
set more off
set maxvar 32000
set linesize 140

log using "$out/output/logs/04c_rand_occ_alternative.log", replace

* ===========================================================
* Health-reason extraction (identical to primary pipeline)
* ===========================================================

use hhidpn e3049_1 using "$fat/h96f4a_STATA/h96f4a.dta", clear
rename e3049_1 hlth_ret
gen byte hlth_wave = 3
keep if hlth_ret >= 1 & hlth_ret <= 4
tempfile hw3
save `hw3'

use hhidpn f3580_1 using "$fat/h98f2c_STATA/h98f2c.dta", clear
rename f3580_1 hlth_ret
gen byte hlth_wave = 4
keep if hlth_ret >= 1 & hlth_ret <= 4
tempfile hw4
save `hw4'

use hhidpn g3869_1 using "$fat/h00f1d_STATA/h00f1d.dta", clear
rename g3869_1 hlth_ret
gen byte hlth_wave = 5
keep if hlth_ret >= 1 & hlth_ret <= 4
tempfile hw5
save `hw5'

foreach w_info in "6 hj588a h02f2c" "7 jj588a h04f1c" "8 kj588a h06f4b" ///
                  "9 lj588a h08f3b" "10 mj588a hd10f6b" {
    local wv : word 1 of `w_info'
    local vn : word 2 of `w_info'
    local fn : word 3 of `w_info'
    use hhidpn `vn' using "$fat/`fn'_STATA/`fn'.dta", clear
    rename `vn' hlth_ret
    gen byte hlth_wave = `wv'
    keep if hlth_ret >= 1 & hlth_ret <= 4
    tempfile hw`wv'
    save `hw`wv''
}

use `hw3', clear
forvalues w = 4/10 {
    append using `hw`w''
}
bysort hhidpn (hlth_wave): keep if _n == 1
tempfile hlth_reason
save `hlth_reason'

* ===========================================================
* RAND sample with RAND-imputed occupation (r1jcocc)
* ===========================================================

use hhidpn hacohort r1iwstat r1proxy r1agey_b r1lbrf r1jcocc ///
    r2sayret r3sayret r4sayret r5sayret r6sayret ///
    r7sayret r8sayret r9sayret r10sayret ///
    r1iwstat r2iwstat r3iwstat r4iwstat r5iwstat ///
    r6iwstat r7iwstat r8iwstat r9iwstat r10iwstat ///
    r2retyr r3retyr r4retyr r5retyr r6retyr ///
    r7retyr r8retyr r9retyr r10retyr ///
    r2retmon r3retmon r4retmon r5retmon r6retmon ///
    r7retmon r8retmon r9retmon r10retmon ///
    r1iwend r2iwend r3iwend r4iwend r5iwend ///
    r6iwend r7iwend r8iwend r9iwend r10iwend ///
    r2agey_b r3agey_b r4agey_b r5agey_b r6agey_b ///
    r7agey_b r8agey_b r9agey_b r10agey_b ///
    rabyear rabmonth raddate ragender raracem raeduc ///
    r1mstat h1atotn r1smokev r1smoken r1drink r1shlt ///
    r1bmi r1adlw r1vigact ///
    r1hibpe r1diabe r1cancre r1lunge r1hearte r1stroke r1arthre r1psyche ///
    using "$rand/randhrs1992_2022v1.dta", clear

keep if hacohort == 3
keep if r1iwstat == 1
keep if r1proxy == 0
keep if r1agey_b >= 50 & r1agey_b <= 62 & r1agey_b < .
gen byte n_waves = 0
forvalues w = 1/10 {
    replace n_waves = n_waves + 1 if r`w'iwstat == 1
}
keep if n_waves >= 2
keep if r1lbrf == 1

gen byte ret_wave = .
forvalues w = 2/10 {
    replace ret_wave = `w' if r`w'sayret == 1 & ret_wave == .
}
keep if ret_wave != .

* RAND-imputed occupation exclusion (this is the key difference)
drop if r1jcocc >= .
di "After excluding missing RAND occupation (r1jcocc): " _N

merge 1:1 hhidpn using `hlth_reason', keep(match) nogen
gen byte healthy = (hlth_ret == 4)

* Dates (identical to primary)
gen baseline_date = r1iwend
format baseline_date %td
gen byte dead = (raddate < . & raddate > 0)
gen death_date = raddate if dead == 1
format death_date %td
gen byte dead_2011 = (death_date <= mdy(12, 31, 2011) & dead == 1)

gen int ret_yr = .
gen byte ret_mon = .
forvalues w = 2/10 {
    replace ret_yr  = r`w'retyr  if ret_wave == `w' & r`w'retyr  > 0 & r`w'retyr  < .
    replace ret_mon = r`w'retmon if ret_wave == `w' & r`w'retmon > 0 & r`w'retmon < 13
}
gen ret_date = mdy(ret_mon, 15, ret_yr) if ret_yr > 0 & ret_mon > 0 & ret_mon <= 12
replace ret_date = mdy(7, 1, ret_yr) if ret_yr > 0 & ret_yr < . & ret_date == .
forvalues w = 2/10 {
    replace ret_date = r`w'iwend if ret_wave == `w' & ret_date == .
}
format ret_date %td

gen float ret_age = .
forvalues w = 2/10 {
    replace ret_age = r`w'agey_b if ret_wave == `w'
}
gen float ret_age_precise = (ret_yr - rabyear) + (ret_mon - rabmonth) / 12 ///
    if ret_yr > 0 & ret_yr < . & rabyear > 0
replace ret_age_precise = ret_age if ret_age_precise == . | ret_age_precise < 50

gen last_iw_date = .
format last_iw_date %td
forvalues w = 10(-1)1 {
    replace last_iw_date = r`w'iwend if r`w'iwstat == 1 & last_iw_date == .
}
gen exit_date = death_date if dead_2011 == 1
replace exit_date = last_iw_date if dead_2011 == 0
replace exit_date = mdy(12, 31, 2011) if exit_date > mdy(12, 31, 2011) & exit_date < .
format exit_date %td

gen float follow_up = (exit_date - baseline_date) / 365.25
drop if follow_up <= 0 | follow_up == .
gen float post_ret = (exit_date - ret_date) / 365.25
drop if post_ret < 1
gen float exit_age = (exit_date - mdy(rabmonth, 15, rabyear)) / 365.25
gen float ret_age_c65 = ret_age_precise - 65

* Covariates (occupation from RAND r1jcocc)
gen byte male = (ragender == 1) if ragender < .
gen byte white = (raracem == 1) if raracem < .
gen byte married = inlist(r1mstat, 1, 2, 3) if r1mstat < .
gen byte educ_cat = .
replace educ_cat = 1 if raeduc <= 2
replace educ_cat = 2 if raeduc == 3
replace educ_cat = 3 if raeduc >= 4 & raeduc < .
gen int birth_c = rabyear - 1931
xtile wealth_q = h1atotn, nq(4)
gen byte occ_cat = .
replace occ_cat = 1 if inlist(r1jcocc, 1, 2)
replace occ_cat = 2 if inlist(r1jcocc, 3, 4, 5, 6, 7, 8, 9)
replace occ_cat = 3 if r1jcocc >= 10 & r1jcocc <= 17
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
gen long hhid_n = floor(hhidpn / 1000)

global covars_all "male white married i.educ_cat birth_c i.wealth_q i.occ_cat i.smoke_cat alcohol exercise i.bmi_cat srh_rev chronic adl_any"

di _n "===== RAND-OCCUPATION ALTERNATIVE SAMPLE ====="
di "N = " _N
tab healthy

* ===========================================================
* Models (identical specifications to primary pipeline)
* ===========================================================

* A: Wu replication
stset follow_up, failure(dead_2011) id(hhidpn)
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
local hr_a2 = exp(_b[ret_age_c65])
local lo_a2 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_a2 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
local hr_a4 = exp(_b[ret_age_c65])
local lo_a4 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_a4 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* B: Diagnostic — origin at retirement
stset post_ret, failure(dead_2011) id(hhidpn)
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
local hr_b2 = exp(_b[ret_age_c65])
local lo_b2 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_b2 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
local hr_b4 = exp(_b[ret_age_c65])
local lo_b4 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_b4 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* C: Age as time scale
stset exit_age, failure(dead_2011) enter(time ret_age_precise) ///
    id(hhidpn) origin(time 0)
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
local hr_c2 = exp(_b[ret_age_c65])
local lo_c2 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_c2 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
local hr_c4 = exp(_b[ret_age_c65])
local lo_c4 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_c4 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* C: Landmark
preserve
gen landmark = mdy(1, 1, 2005)
keep if ret_date < landmark
keep if exit_date >= landmark
di "After landmark: " _N

gen float post_landmark = (exit_date - landmark) / 365.25
gen byte dead_post_lm = (dead_2011 == 1 & death_date >= landmark)
stset post_landmark, failure(dead_post_lm) id(hhidpn)

stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
local hr_d2 = exp(_b[ret_age_c65])
local lo_d2 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_d2 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
local hr_d4 = exp(_b[ret_age_c65])
local lo_d4 = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_d4 = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
restore

* ===========================================================
* Summary
* ===========================================================
di _n "================================================================="
di "RAND-OCCUPATION ALTERNATIVE RESULTS (N=" _N ")"
di "================================================================="
di ""
di %35s "Model" " | " %22s "HR (95% CI)"
di "-----------------------------------------------------------------"
di %35s "Wu replication (healthy)" " | " %5.3f `hr_a2' " (" %5.3f `lo_a2' " - " %5.3f `hi_a2' ")"
di %35s "Wu replication (unhealthy)" " | " %5.3f `hr_a4' " (" %5.3f `lo_a4' " - " %5.3f `hi_a4' ")"
di %35s "Diagnostic: origin@ret (healthy)" " | " %5.3f `hr_b2' " (" %5.3f `lo_b2' " - " %5.3f `hi_b2' ")"
di %35s "Diagnostic: origin@ret (unhealthy)" " | " %5.3f `hr_b4' " (" %5.3f `lo_b4' " - " %5.3f `hi_b4' ")"
di %35s "Age-scale (healthy)" " | " %5.3f `hr_c2' " (" %5.3f `lo_c2' " - " %5.3f `hi_c2' ")"
di %35s "Age-scale (unhealthy)" " | " %5.3f `hr_c4' " (" %5.3f `lo_c4' " - " %5.3f `hi_c4' ")"
di %35s "Landmark (healthy)" " | " %5.3f `hr_d2' " (" %5.3f `lo_d2' " - " %5.3f `hi_d2' ")"
di %35s "Landmark (unhealthy)" " | " %5.3f `hr_d4' " (" %5.3f `lo_d4' " - " %5.3f `hi_d4' ")"

log close
