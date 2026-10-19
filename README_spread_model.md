# DE/IT spread model: configurable driver

`spread_estimate.m` estimates the joint DE/IT term-structure model of
`Estimates_spread*.m` (objective `Estimate_multicountry_3`) for one
configuration and scores how well it fits the APP and PEPP yield reactions
(5–10y, DE and IT). It reproduces `Estimates_spread_DEIT_PEPP.m` to rounding
error when set up the same way.

## Settings (`spread_config.m`)

| Setting | Options |
|---|---|
| `window` | estimation sample, e.g. `{'Mar2009','Dec2021'}` |
| `base` | level/slope curve: `'DE'` (Bund yields) or `'OIS'` |
| `pc` | `'pca_est'` (PCA on the estimation sample) or `'observable'` (1y, 10y–1y) |
| `fiscal` | IT fiscal factor: `'ff_nom'` (unweighted free float, actual), `'ffgdp'` ((debt − Eurosystem holdings)/GDP), `'ff_nom_sim2015'` (March-2015 projection after Mar 2015) |
| `big4` | big-4 free-float vintage: `'Dec-21'` (actual) or `'Mar-15'` |
| `w` | weight on the yield fit (1 − w on the APP/PEPP fit) |
| `gamma` | default intensity: `'all'` or `'fiscal_only'` |
| `fiscalGammaNonneg`, `maxIntensity`, `signConstraint` | economic restrictions, see below |

Restrictions always enforced or available:
- IT–DE spread loading on the fiscal factor ≥ 0 at 5–10y (`signConstraint`);
- IT default intensity `Gamma_0 + Gamma_1'X_t` ≥ 0 in every month;
- `Gamma_1` on the fiscal factor ≥ 0 (`fiscalGammaNonneg`, default on);
- optional cap on the default intensity per year (`maxIntensity`).

## Fixes relative to the original scripts
- VAR matrix built as `BETA(2:end,:)'` (one row per equation); `Estimates_spread.m` used `BETA(2:end,:)`.
- Fiscal factor from actual data (`Free_Float.xlsx`); `2015_03_SIMULATIONBaseline.xlsx` is a projection after March 2015.
- Bounded Levenberg–Marquardt least squares instead of `fmincon` + unbounded `fminunc` (which undid the `Gamma` restrictions); tolerances that can actually be met.
- Vectorised yield-impact functions (`Functions/fast/`), 22–25× faster, identical results.

## Running
MATLAB: `R = spread_estimate(spread_config('window', {'Mar2009','Dec2021'}, 'fiscal', 'ffgdp'));`

GNU Octave (with optim, statistics, io, financial): `./run_octave.sh "spread_run_batch('E', 1, 1)"`.
Stages of the specification search are defined in `spread_stage_configs.m`; `spread_summarize` writes
`Output_runs/summary.csv`. `charts/plot_app_pepp.py` draws the four APP/PEPP × DE/IT panels from a run's `_chart.csv`.

Inputs (not in the repository): `Input_mat/` (TS_ECB_DE/IT_Dec-2021, OIS, Surprise_Data_untilMar2015),
`Output_mat/StartingValues_ATSM_OIS.mat`, `Data/Free_Float.xlsx`, and the two files the original
scripts read from the P: drive, at `../../Input_MSY_debt_and_free_float.xlsx` and
`../Countrydata/2015_03_SIMULATIONBaseline.xlsx`.
