# Online Supplemental Note: Sample Reconstruction

## Exclusion flow

Table S1 compares the published exclusion flow with the primary reconstruction and an alternative specification. The primary reconstruction includes full-time and part-time workers at baseline, matching Wu et al.'s description of participants who were "working at baseline." It uses the occupation classification from the 1992 HRS core interview file (variable v2720, 1980 Census occupation codes) rather than the RAND-imputed version, because the RAND variable's near-complete imputation produces only 5 missing values among baseline workers, far fewer than the 524 exclusions Wu et al. reported. The primary reconstruction's occupation exclusion count (527) is nearly exact. The alternative restricts to full-time workers only and uses the RAND-imputed occupation variable (r1jcocc).

The primary reconstruction is slightly larger than the published sample, consistent with the 2022 RAND HRS longitudinal file containing updated records relative to the version available to Wu et al. Wu et al. describe excluding participants "lost to follow-up in the year they reported complete retirement"; the present reconstruction excludes participants with less than one year of post-retirement follow-up.

**Table S1.** Sample exclusion flow: published and reconstructed

| Restriction step | Wu et al. | Primary | Alternative |
|---|---:|---:|---:|
| Working + retired by 2010 | 4,092 | 4,306 | 3,641 |
| Excluded: missing occupation | -524 | -527 | -5 |
| Excluded: missing retirement reason | -454 | -483 | -445 |
| Excluded: <1 yr post-retirement | -158 | -84 | -84 |
| **Final sample** | **2,956** | **3,212** | **3,107** |
| Healthy | 1,934 | 2,077 | 2,007 |
| Unhealthy | 1,022 | 1,135 | 1,100 |

Primary = FT+PT workers, raw 1992 occupation (v2720). Alternative = FT only, RAND-imputed occupation (r1jcocc).

## Alternative model results

Table S2 reports the corrected hazard ratios under the alternative reconstruction using the RAND-imputed occupation variable with full-time workers only (N=3,107). Covariates and model specifications are identical to the primary reconstruction reported in the manuscript. The alternative yields the same attenuation pattern: the baseline-origin association weakens under the age-as-time-scale correction, and the association is no longer statistically significant among retirees who reported health as a reason for retirement.

**Table S2.** Corrected hazard ratios under alternative reconstruction (FT only, RAND occupation, N=3,107)

| Analysis | Non-health HR (95% CI) | Health HR (95% CI) |
|---|:---:|:---:|
| Reconstruction | 0.91 (0.89 to 0.94) | 0.92 (0.90 to 0.95) |
| Origin at retirement | 1.13 (1.09 to 1.17) | 1.08 (1.04 to 1.11) |
| Age as time scale | 0.94 (0.91 to 0.97) | 0.97 (0.94 to 1.00) |
| Landmark (Jan 2005) | 0.95 (0.91 to 0.99) | 0.96 (0.92 to 1.01) |

Non-health = health not reported as a retirement reason. Health = health reported as a retirement reason. All models adjusted for the same covariates as in Table 1 of the manuscript.

## Traceability

The primary reconstruction counts and model estimates are produced by `code/01_build_sample.do` and `code/02_replicate_table2.do`, with output logged to `output/logs/01_build_sample.log` and `output/logs/02_replicate_table2.log`. The alternative column in Table S1 is produced by `code/04b_variant_flow_comparison.do` (logged to `output/logs/04b_variant_flow.log`). Table S2 model estimates are produced by `code/04c_rand_occ_alternative.do` (logged to `output/logs/04c_rand_occ_alternative.log`). `code/04d_ftpt_comparison.do` provides an ancillary FT+PT-versus-FT-only raw-occupation comparison and is not cited in the current supplement tables. All scripts are run sequentially by `code/00_master.do`. The Wu et al. sample-flow counts are from Figure 1 of the published article.
