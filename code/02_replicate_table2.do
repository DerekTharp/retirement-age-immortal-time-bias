* ============================================================
* 02_replicate_table2.do
* Replicate Wu et al. (2016) Table 2 and apply corrections
*
* Part A: Wu et al. replication (follow-up from baseline)
* Part B: Correction 1 -- Time-origin at retirement
* Part C: Correction 2 -- Age as time scale with left-truncation
* Part D: Correction 3 -- Landmark analysis (Jan 1, 2005)
* Part E: Summary comparison table
* ============================================================

version 18
clear all
set more off
set maxvar 32000
set linesize 140

* $out must be set by 00_master.do

log using "$out/output/logs/02_replicate_table2.log", replace

use "$out/data/analytic_sample.dta", clear
di "Analytic sample loaded: " _N " observations"
assert _N == 3212
tab healthy


* ===========================================================
* Define covariate lists (one place)
* ===========================================================

* Wu et al. adjusted for: sex, race, marital status, education,
* birth year, wealth, occupation, smoking, alcohol, exercise,
* BMI, self-rated health, chronic conditions, ADL limitations

* Use reversed SRH (1=poor...5=exc) to match Wu et al. convention
global covars_basic "male white married i.educ_cat birth_c i.wealth_q i.occ_cat"
global covars_lifestyle "i.smoke_cat alcohol exercise i.bmi_cat"
global covars_health "srh_rev chronic adl_any"
global covars_all "$covars_basic $covars_lifestyle $covars_health"

di _n "Covariates: $covars_all"

* Verify no missing covariates (stcox drops silently)
di _n "Covariate missingness check:"
foreach v in male white married educ_cat birth_c wealth_q occ_cat ///
    smoke_cat alcohol exercise bmi_cat srh_rev chronic adl_any {
    quietly count if `v' == .
    if r(N) > 0 {
        di as error "  WARNING: `v' has " r(N) " missing values"
    }
}
di "  Check complete."


* ===========================================================
* PART A: Wu et al. replication (biased model)
* Time scale: years from baseline interview
* This replicates their immortal-time bias design
* ===========================================================

di _n "============================================="
di    "PART A: Wu et al. replication"
di    "(Follow-up from baseline as time scale)"
di    "============================================="

stset follow_up, failure(dead_2011) id(hhidpn)
stdescribe

* --- Model 1: Unadjusted, healthy retirees only ---
stcox ret_age_c65 if healthy == 1, vce(cluster hhid_n)
estimates store A1_hlth_unadj
di "Model A1: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "TARGET: HR ~ 0.89"

* --- Model 2: Adjusted, healthy retirees only ---
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
estimates store A2_hlth_adj
di "Model A2: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "TARGET: HR = 0.89 (0.85-0.92)"

* --- Model 3: Unadjusted, unhealthy retirees only ---
stcox ret_age_c65 if healthy == 0, vce(cluster hhid_n)
estimates store A3_unhlth_unadj
di "Model A3: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "TARGET: HR ~ 0.91"

* --- Model 4: Adjusted, unhealthy retirees only ---
stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
estimates store A4_unhlth_adj
di "Model A4: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "TARGET: HR = 0.91 (0.88-0.94)"

* --- Model 5: Pooled with interaction ---
stcox ret_age_c65 i.healthy c.ret_age_c65#i.healthy $covars_all, ///
    vce(cluster hhid_n)
estimates store A5_pooled
di _n "Model A5 pooled interaction:"
di "  Ret age HR (unhealthy ref): " exp(_b[ret_age_c65])
di "  Interaction p-value (healthy x ret_age):"
test 1.healthy#c.ret_age_c65

* --- Quadratic term test (Wu et al. tested this) ---
di _n "Quadratic term test (healthy retirees):"
stcox ret_age_c65 ret_age_c65_sq $covars_all if healthy == 1, vce(cluster hhid_n)
test ret_age_c65_sq
di "Wu et al. found quadratic term non-significant (dropped from final model)"

* --- PH assumption test ---
di _n "Proportional hazards test (adjusted healthy model):"
estimates restore A2_hlth_adj
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n) ///
    scaledsch(sca_A2*)
estat phtest, detail


* ===========================================================
* PART B: Correction 1 -- Time-origin at retirement
* Time scale: years since retirement
* This removes immortal time bias
* ===========================================================

di _n "============================================="
di    "PART B: Correction 1"
di    "(Time-origin at retirement)"
di    "============================================="

stset post_ret, failure(dead_2011) id(hhidpn)
stdescribe

* --- Model 1: Unadjusted, healthy ---
stcox ret_age_c65 if healthy == 1, vce(cluster hhid_n)
estimates store B1_hlth_unadj
di "Model B1: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 2: Adjusted, healthy ---
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
estimates store B2_hlth_adj
di "Model B2: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 3: Unadjusted, unhealthy ---
stcox ret_age_c65 if healthy == 0, vce(cluster hhid_n)
estimates store B3_unhlth_unadj
di "Model B3: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 4: Adjusted, unhealthy ---
stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
estimates store B4_unhlth_adj
di "Model B4: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 5: Pooled with interaction ---
stcox ret_age_c65 i.healthy c.ret_age_c65#i.healthy $covars_all, ///
    vce(cluster hhid_n)
estimates store B5_pooled
di _n "Model B5 pooled interaction:"
di "  Ret age HR (unhealthy ref): " exp(_b[ret_age_c65])
test 1.healthy#c.ret_age_c65


* ===========================================================
* PART C: Correction 2 -- Age as time scale
* Left-truncation at retirement age, exit at age of
* death/censoring. This is the gold-standard approach.
* ===========================================================

di _n "============================================="
di    "PART C: Correction 2"
di    "(Age as time scale, left-truncation at retirement)"
di    "============================================="

* Persons enter the risk set at their retirement age and exit
* at their age of death or censoring
stset exit_age, failure(dead_2011) enter(time ret_age_precise) ///
    id(hhidpn) origin(time 0)
stdescribe

* Diagnostic: observations dropped by stset (exit_age <= ret_age_precise)
quietly count if exit_age <= ret_age_precise
di "Observations with exit_age <= ret_age_precise (dropped by stset): " r(N)

* --- Model 1: Unadjusted, healthy ---
stcox ret_age_c65 if healthy == 1, vce(cluster hhid_n)
estimates store C1_hlth_unadj
di "Model C1: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 2: Adjusted, healthy ---
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
estimates store C2_hlth_adj
di "Model C2: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 3: Unadjusted, unhealthy ---
stcox ret_age_c65 if healthy == 0, vce(cluster hhid_n)
estimates store C3_unhlth_unadj
di "Model C3: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 4: Adjusted, unhealthy ---
stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
estimates store C4_unhlth_adj
di "Model C4: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 5: Pooled with interaction ---
stcox ret_age_c65 i.healthy c.ret_age_c65#i.healthy $covars_all, ///
    vce(cluster hhid_n)
estimates store C5_pooled
di _n "Model C5 pooled interaction:"
di "  Ret age HR (unhealthy ref): " exp(_b[ret_age_c65])
test 1.healthy#c.ret_age_c65


* ===========================================================
* PART D: Correction 3 -- Landmark analysis
* Landmark at Jan 1, 2005 (approximately mid-study)
* Restrict to persons alive and retired before the landmark
* ===========================================================

di _n "============================================="
di    "PART D: Correction 3"
di    "(Landmark analysis at Jan 1, 2005)"
di    "============================================="

* Reload to avoid stset contamination
use "$out/data/analytic_sample.dta", clear

* Define landmark date
gen landmark = mdy(1, 1, 2005)
format landmark %td

* Restrict to alive and already retired before landmark
keep if ret_date < landmark
keep if exit_date >= landmark
di "After landmark restriction (alive & retired before 01jan2005): " _N
assert _N == 2489
tab healthy

* Post-landmark follow-up
gen float post_landmark = (exit_date - landmark) / 365.25
* Deaths only count if after landmark
gen byte dead_post_lm = (dead_2011 == 1 & death_date >= landmark)

stset post_landmark, failure(dead_post_lm) id(hhidpn)
stdescribe

* --- Model 1: Unadjusted, healthy ---
stcox ret_age_c65 if healthy == 1, vce(cluster hhid_n)
estimates store D1_hlth_unadj
di "Model D1: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 2: Adjusted, healthy ---
stcox ret_age_c65 $covars_all if healthy == 1, vce(cluster hhid_n)
estimates store D2_hlth_adj
di "Model D2: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 3: Unadjusted, unhealthy ---
stcox ret_age_c65 if healthy == 0, vce(cluster hhid_n)
estimates store D3_unhlth_unadj
di "Model D3: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 4: Adjusted, unhealthy ---
stcox ret_age_c65 $covars_all if healthy == 0, vce(cluster hhid_n)
estimates store D4_unhlth_adj
di "Model D4: HR = " exp(_b[ret_age_c65]) ///
   "  95% CI: " exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65]) ///
   " - " exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])

* --- Model 5: Pooled with interaction ---
stcox ret_age_c65 i.healthy c.ret_age_c65#i.healthy $covars_all, ///
    vce(cluster hhid_n)
estimates store D5_pooled
di _n "Model D5 pooled interaction:"
di "  Ret age HR (unhealthy ref): " exp(_b[ret_age_c65])
test 1.healthy#c.ret_age_c65


* ===========================================================
* PART E: Summary comparison table
* Display all HRs side by side
* ===========================================================

di _n "============================================="
di    "PART E: Summary comparison of all methods"
di    "============================================="

di _n "====================================================================="
di    "Table: HR per 1-year increase in retirement age (adjusted models)"
di    "====================================================================="

* --- Healthy retirees ---
di _n "HEALTHY RETIREES (adjusted models):"
di    "---------------------------------------------------------------------"
di    "Method                          | HR      | 95% CI"
di    "---------------------------------------------------------------------"

estimates restore A2_hlth_adj
local hr_A = exp(_b[ret_age_c65])
local lo_A = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_A = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "A. Wu replication (baseline)      | " %5.3f `hr_A' " | " %5.3f `lo_A' " - " %5.3f `hi_A'

estimates restore B2_hlth_adj
local hr_B = exp(_b[ret_age_c65])
local lo_B = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_B = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "B. Time-origin at retirement      | " %5.3f `hr_B' " | " %5.3f `lo_B' " - " %5.3f `hi_B'

estimates restore C2_hlth_adj
local hr_C = exp(_b[ret_age_c65])
local lo_C = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_C = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "C. Age as time scale (left-trunc) | " %5.3f `hr_C' " | " %5.3f `lo_C' " - " %5.3f `hi_C'

estimates restore D2_hlth_adj
local hr_D = exp(_b[ret_age_c65])
local lo_D = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_D = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "D. Landmark (Jan 1, 2005)         | " %5.3f `hr_D' " | " %5.3f `lo_D' " - " %5.3f `hi_D'

di    "---------------------------------------------------------------------"

* --- Unhealthy retirees ---
di _n "UNHEALTHY RETIREES (adjusted models):"
di    "---------------------------------------------------------------------"
di    "Method                          | HR      | 95% CI"
di    "---------------------------------------------------------------------"

estimates restore A4_unhlth_adj
local hr_A = exp(_b[ret_age_c65])
local lo_A = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_A = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "A. Wu replication (baseline)      | " %5.3f `hr_A' " | " %5.3f `lo_A' " - " %5.3f `hi_A'

estimates restore B4_unhlth_adj
local hr_B = exp(_b[ret_age_c65])
local lo_B = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_B = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "B. Time-origin at retirement      | " %5.3f `hr_B' " | " %5.3f `lo_B' " - " %5.3f `hi_B'

estimates restore C4_unhlth_adj
local hr_C = exp(_b[ret_age_c65])
local lo_C = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_C = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "C. Age as time scale (left-trunc) | " %5.3f `hr_C' " | " %5.3f `lo_C' " - " %5.3f `hi_C'

estimates restore D4_unhlth_adj
local hr_D = exp(_b[ret_age_c65])
local lo_D = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
local hi_D = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
di "D. Landmark (Jan 1, 2005)         | " %5.3f `hr_D' " | " %5.3f `lo_D' " - " %5.3f `hi_D'

di    "---------------------------------------------------------------------"

* --- Full estimates table (all 20 models) ---
di _n _n "Full estimates table (coefficient on ret_age_c65):"
estimates table ///
    A1_hlth_unadj A2_hlth_adj A3_unhlth_unadj A4_unhlth_adj A5_pooled ///
    B1_hlth_unadj B2_hlth_adj B3_unhlth_unadj B4_unhlth_adj B5_pooled ///
    C1_hlth_unadj C2_hlth_adj C3_unhlth_unadj C4_unhlth_adj C5_pooled ///
    D1_hlth_unadj D2_hlth_adj D3_unhlth_unadj D4_unhlth_adj D5_pooled, ///
    keep(ret_age_c65) b(%7.4f) se(%7.4f) stats(N ll chi2)

* --- Exponentiated coefficients ---
di _n "Exponentiated (HRs) for retirement age:"
estimates table ///
    A1_hlth_unadj A2_hlth_adj A3_unhlth_unadj A4_unhlth_adj ///
    B1_hlth_unadj B2_hlth_adj B3_unhlth_unadj B4_unhlth_adj ///
    C1_hlth_unadj C2_hlth_adj C3_unhlth_unadj C4_unhlth_adj ///
    D1_hlth_unadj D2_hlth_adj D3_unhlth_unadj D4_unhlth_adj, ///
    keep(ret_age_c65) eform


* ===========================================================
* Save summary to file
* ===========================================================

capture file close sumfile
file open sumfile using "$out/output/tables/table2_summary.txt", write replace

file write sumfile "Wu et al. (2016) Replication and Corrections" _n
file write sumfile "HR per 1-year increase in retirement age" _n
file write sumfile "=============================================" _n _n

file write sumfile "HEALTHY RETIREES" _n
file write sumfile "Method                         ,HR    ,LCI  ,UCI" _n

foreach panel in A B C D {
    estimates restore `panel'2_hlth_adj
    local hr  = exp(_b[ret_age_c65])
    local lci = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
    local uci = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
    if "`panel'" == "A" local label "Wu replication (baseline)"
    if "`panel'" == "B" local label "Time-origin at retirement"
    if "`panel'" == "C" local label "Age as time scale"
    if "`panel'" == "D" local label "Landmark (Jan 2005)"
    file write sumfile "`label'" "," %5.3f (`hr') "," %5.3f (`lci') "," %5.3f (`uci') _n
}

file write sumfile _n "UNHEALTHY RETIREES" _n
file write sumfile "Method                         ,HR    ,LCI  ,UCI" _n

foreach panel in A B C D {
    estimates restore `panel'4_unhlth_adj
    local hr  = exp(_b[ret_age_c65])
    local lci = exp(_b[ret_age_c65] - 1.96*_se[ret_age_c65])
    local uci = exp(_b[ret_age_c65] + 1.96*_se[ret_age_c65])
    if "`panel'" == "A" local label "Wu replication (baseline)"
    if "`panel'" == "B" local label "Time-origin at retirement"
    if "`panel'" == "C" local label "Age as time scale"
    if "`panel'" == "D" local label "Landmark (Jan 2005)"
    file write sumfile "`label'" "," %5.3f (`hr') "," %5.3f (`lci') "," %5.3f (`uci') _n
}

file close sumfile
di _n "Summary table saved to: $out/output/tables/table2_summary.txt"


di _n "============================================="
di    "ANALYSIS COMPLETE"
di    "============================================="

log close
