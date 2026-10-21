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
- optionally a floor on that loading, `minElasticity` (bp of spread per +10 pp of the fiscal factor);
- IT default intensity `Gamma_0 + Gamma_1'X_t` ≥ 0 in every month;
- `Gamma_1` on the fiscal factor ≥ 0 (`fiscalGammaNonneg`, default on);
- optional cap on the default intensity per year (`maxIntensity`).

## Fixes relative to the original scripts
- VAR matrix built as `BETA(2:end,:)'` (one row per equation); `Estimates_spread.m` used `BETA(2:end,:)`.
- Fiscal factor from actual data (`Free_Float.xlsx`); `2015_03_SIMULATIONBaseline.xlsx` is a projection after March 2015.
- Bounded Levenberg–Marquardt least squares instead of `fmincon` + unbounded `fminunc` (which undid the `Gamma` restrictions); tolerances that can actually be met.
- Vectorised yield-impact functions (`Functions/fast/`), 22–25× faster, identical results.

## Running (MATLAB)
Requires the Optimization Toolbox (`lsqnonlin`) and the Statistics and Machine Learning Toolbox (`regress`);
the Parallel Computing Toolbox is used if available. Run from the repository root:

```matlab
addpath(genpath('Functions'));
raw = spread_load_inputs();                                   % reads all inputs once, caches Input_mat/cache_spread_inputs.mat
R = spread_estimate(spread_config('name', 'my_run', 'window', {'Mar2009','Dec2021'}, 'fiscal', 'ffgdp', ...
                                  'w', 0.10, 'gamma', 'fiscal_only', 'maxIntensity', 0.10), raw);
spread_plot_events('my_run', 'Output_runs/my_run_events.png');          % four APP/PEPP x DE/IT panels
spread_plot_yields('my_run', {'Jan2015','Dec2021'}, 'Output_runs/my_run_yields.png');   % yield fit, any window
spread_run_stage('E');                                         % whole search stage (parfor if available) + summary.csv
```

Search stages are defined in `spread_stage_configs.m` (A baseline, B one change at a time, C–E combinations
and refinements); `spread_summarize` writes `Output_runs/summary.csv`. Stages D and E warm-start from earlier
runs when their results are in `Output_runs/`, otherwise from the default starting values.

Optional: `octave/` holds what is needed to run the same code in GNU Octave instead
(`octave/run_octave.sh`, compatibility wrappers, Python chart scripts). MATLAB does not use it.

Inputs (not in the repository): `Input_mat/` (TS_ECB_DE/IT_Dec-2021, OIS, Surprise_Data_untilMar2015),
`Output_mat/StartingValues_ATSM_OIS.mat`, `Data/Free_Float.xlsx`, and the two workbooks the original
scripts read from the P: drive. `spread_load_inputs.m` looks for those in `Data/` and
`Data/Countrydata/` first, then at the original relative paths `../../` and `../Countrydata/`.

## Preferred specifications (OIS anchor, sample Mar 2009 - Dec 2021)

Both fit OIS rates and the IT-OIS spread (`target = 'spread'`); the fiscal factor is IT purchases / GDP (`ffgdp`).

| Event | Run | Stage | Key settings | Event fit (5-10y RMSE) |
|---|---|---|---|---|
| PEPP | `GQ6_e40_w001_fromGP3` | `GQ` | PEPP only, w = 0.01, `minElasticity` 40 | OIS 0.8, IT-OIS 1.9, IT 1.4 bp |
| APP | `HO2_w005_fromF08` | `HO` | APP only, w = 0.05 | OIS 0.6, IT-OIS 1.0 bp |

`minElasticity` keeps the spread effect of +10 pp of the fiscal factor at or above the given number of bp at 5-10y; without it the PEPP-only fit settles near +20 bp (stage `GP`). Run stages F and G, then `GO`, `GP` and `GQ` (and F, then `HO`) in that order with `spread_run_stage`, since each stage warm-starts from earlier runs.
