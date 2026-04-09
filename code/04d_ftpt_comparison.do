* ============================================================
* 04d_ftpt_comparison.do
* Compare FT-only vs FT+PT, both with raw occ (v2720)
* ============================================================

version 18
clear all
set more off
set maxvar 32000
set linesize 140

log using "$out/output/logs/04d_ftpt_comparison.log", replace

* Health reason (same as primary)
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

* Raw occ
use hhidpn v2720 using "$fat/h92f1b_STATA/h92f1b.dta", clear
rename v2720 raw_occ
replace raw_occ = . if raw_occ == 0 | raw_occ >= .
tempfile raw_occ
save `raw_occ'

* Build common base through age/assessment restrictions
use "$rand/randhrs1992_2022v1.dta", clear
keep if hacohort == 3
keep if r1iwstat == 1
keep if r1proxy == 0
keep if r1agey_b >= 50 & r1agey_b <= 62 & r1agey_b < .
gen byte n_waves = 0
forvalues w = 1/10 {
    replace n_waves = n_waves + 1 if r`w'iwstat == 1
}
keep if n_waves >= 2

local n_pre_work = _N

* Retirement wave
gen byte ret_wave = .
forvalues w = 2/10 {
    replace ret_wave = `w' if r`w'sayret == 1 & ret_wave == .
}

* Dates for post_ret
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

gen byte dead = (raddate < . & raddate > 0)
gen death_date = raddate if dead == 1
format death_date %td
gen byte dead_2011 = (death_date <= mdy(12, 31, 2011) & dead == 1)
gen last_iw_date = .
forvalues w = 10(-1)1 {
    replace last_iw_date = r`w'iwend if r`w'iwstat == 1 & last_iw_date == .
}
gen exit_date = death_date if dead_2011 == 1
replace exit_date = last_iw_date if dead_2011 == 0
replace exit_date = mdy(12, 31, 2011) if exit_date > mdy(12, 31, 2011) & exit_date < .
format exit_date %td
gen float follow_up = (exit_date - r1iwend) / 365.25
gen float post_ret = (exit_date - ret_date) / 365.25

merge 1:1 hhidpn using `raw_occ', keep(master match) nogen

tempfile base
save `base'

* ===========================================================
* FT only, raw occupation
* ===========================================================
use `base', clear
local ft_pre = _N
keep if r1lbrf == 1
local ft_after_work = _N
local ft_work_drop = `ft_pre' - `ft_after_work'
keep if ret_wave != .
local ft_after_ret = _N
drop if raw_occ == . | raw_occ >= .
local ft_after_occ = _N
local ft_occ_drop = `ft_after_ret' - `ft_after_occ'
merge 1:1 hhidpn using `hlth_reason', keep(match) nogen
local ft_after_hlth = _N
local ft_hlth_drop = `ft_after_occ' - `ft_after_hlth'
gen byte healthy = (hlth_ret == 4)
drop if follow_up <= 0 | follow_up == .
drop if post_ret < 1
local ft_final = _N
local ft_postret_drop = `ft_after_hlth' - `ft_final'
count if healthy == 1
local ft_h = r(N)
count if healthy == 0
local ft_u = r(N)

* ===========================================================
* FT+PT primary, raw occupation
* ===========================================================
use `base', clear
local fp_pre = _N
keep if inlist(r1lbrf, 1, 2)
local fp_after_work = _N
local fp_work_drop = `fp_pre' - `fp_after_work'
keep if ret_wave != .
local fp_after_ret = _N
drop if raw_occ == . | raw_occ >= .
local fp_after_occ = _N
local fp_occ_drop = `fp_after_ret' - `fp_after_occ'
merge 1:1 hhidpn using `hlth_reason', keep(match) nogen
local fp_after_hlth = _N
local fp_hlth_drop = `fp_after_occ' - `fp_after_hlth'
gen byte healthy = (hlth_ret == 4)
drop if follow_up <= 0 | follow_up == .
drop if post_ret < 1
local fp_final = _N
local fp_postret_drop = `fp_after_hlth' - `fp_final'
count if healthy == 1
local fp_h = r(N)
count if healthy == 0
local fp_u = r(N)

* ===========================================================
* Comparison table
* ===========================================================
di _n "================================================================="
di "FT-ONLY vs FT+PT (both with raw occ v2720)"
di "================================================================="
di ""
di %45s "Step" " | " %8s "Wu" " | " %10s "FT only" " | " %10s "FT+PT"
di "----------------------------------------------------------------------------------"
di %45s "Pre-work restriction" " | " %8s "" " | " %10.0f `ft_pre' " | " %10.0f `fp_pre'
di %45s "Excluded: not working at baseline" " | " %8.0f 3010 " | " %10.0f `ft_work_drop' " | " %10.0f `fp_work_drop'
di %45s "After work restriction" " | " %8.0f 5746 " | " %10.0f `ft_after_work' " | " %10.0f `fp_after_work'
di %45s "Excluded: not retired by 2010" " | " %8.0f 1654 " | " %10.0f (`ft_after_work' - `ft_after_ret') " | " %10.0f (`fp_after_work' - `fp_after_ret')
di %45s "Working + retired" " | " %8.0f 4092 " | " %10.0f `ft_after_ret' " | " %10.0f `fp_after_ret'
di %45s "Excluded: missing occupation" " | " %8.0f 524 " | " %10.0f `ft_occ_drop' " | " %10.0f `fp_occ_drop'
di %45s "After occupation exclusion" " | " %8.0f 3568 " | " %10.0f `ft_after_occ' " | " %10.0f `fp_after_occ'
di %45s "Excluded: missing retirement reason" " | " %8.0f 454 " | " %10.0f `ft_hlth_drop' " | " %10.0f `fp_hlth_drop'
di %45s "After retirement-reason exclusion" " | " %8.0f 3114 " | " %10.0f `ft_after_hlth' " | " %10.0f `fp_after_hlth'
di %45s "Excluded: <1 yr post-retirement" " | " %8.0f 158 " | " %10.0f `ft_postret_drop' " | " %10.0f `fp_postret_drop'
di "----------------------------------------------------------------------------------"
di %45s "FINAL SAMPLE" " | " %8.0f 2956 " | " %10.0f `ft_final' " | " %10.0f `fp_final'
di %45s "  Healthy" " | " %8.0f 1934 " | " %10.0f `ft_h' " | " %10.0f `fp_h'
di %45s "  Unhealthy" " | " %8.0f 1022 " | " %10.0f `ft_u' " | " %10.0f `fp_u'
di "----------------------------------------------------------------------------------"
di %45s "Gap from Wu" " | " %8s "---" " | " %10.0f `ft_final' - 2956 " | " %10.0f `fp_final' - 2956

log close
