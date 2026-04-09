# Immortal Time Bias in the Association Between Retirement Age and Mortality

Replication and methodological critique of:

> Wu C, Odden MC, Fisher GG, Stawski RS. Association of retirement age with mortality: a population-based longitudinal study among older adults in the USA. *J Epidemiol Community Health* 2016;70:917-23. doi:10.1136/jech-2015-207097

## Summary

Wu et al. report that each one-year increase in retirement age is associated with 11% lower mortality (HR 0.89). We show this finding is inflated by immortal time bias: the Cox model sets time-zero at the 1992 baseline interview while using retirement age, observed later during follow-up, as a time-fixed covariate. Within the reconstructed cohort, corrected analyses that align risk-set entry with retirement attenuate the association.

## Requirements

- **Stata 18 or later** (tested in StataNow/MP 19.5)
- **RAND HRS Longitudinal File v2022** (`randhrs1992_2022v1.dta`)
- **HRS Fat Files** (waves 1996-2010 for the retirement-health question; 1994 excluded)

Data available from the [Health and Retirement Study](https://hrsdata.isr.umich.edu/) and [RAND HRS](https://www.rand.org/well-being/social-and-behavioral-policy/centers/aging/dataprod/hrs-data.html) (free registration required).

## Reproduction

1. Run the master script from the project root directory.
2. Open `code/00_master.do` and edit `global hrs_root` so it points to the directory containing:
   - `randhrs1992_2022v1_STATA/`
   - `HRS Fat Files/`
3. Run:
   ```
   stata-mp -b do code/00_master.do
   ```

This single command builds the analytic sample, runs all primary and sensitivity models, and generates the supplemental variant comparison logs. All output appears in `output/tables/` and `output/logs/`.

## File Structure

```
code/
  00_master.do              Master script (run this)
  01_build_sample.do        Sample construction (N=3,212)
  02_replicate_table2.do    Cox models (reconstruction + 3 corrections)
  03_sensitivity_no_postret_exclusion.do
                            Sensitivity: retains <1 year post-retirement cases
  04b_variant_flow_comparison.do
                            Supplement: FT-only raw vs RAND occupation flow
  04c_rand_occ_alternative.do
                            Supplement: RAND-occ alternative models (N=3,107)
  04d_ftpt_comparison.do
                            Ancillary: FT-only vs FT+PT raw-occ flow
output/
  tables/table2_summary.txt Summary of all hazard ratios
  logs/                     Full Stata logs for all scripts
submission/
  sample_reconstruction_note.md
                            Side-by-side restriction counts vs Wu et al.
```

Running `00_master.do` generates additional output in `data/` (analytic `.dta` files) and `output/logs/` (full Stata logs). These are excluded from the repo via `.gitignore` because the `.dta` files contain HRS identifiers.

## Contact

Derek Tharp, University of Southern Maine, derek.tharp@maine.edu
