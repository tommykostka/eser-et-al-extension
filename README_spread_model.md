# DE/IT spread model: baselines

Joint term-structure model of the OIS curve and Italian yields (Eser et al. extension with
default risk and a fiscal factor), fitted to the yield reactions to APP and PEPP.

## Baselines

All use the OIS anchor (OIS rates priced in place of Bunds, Italy fitted as a spread over OIS),
the sample Mar 2009 - Dec 2021, the fiscal factor IT purchases / GDP (`ffgdp`) and the
restrictions listed below. The scripts re-optimise each baseline, starting from the estimate
stored in `Output_mat/Baselines.mat` and restarting the optimizer until the fit stops improving;
an improved estimate is written back to `Baselines.mat`, so every run continues from the best
estimate so far. The table shows the re-optimised results (Octave; MATLAB's `lsqnonlin` may end at
slightly different values).

| Run | Fitted to | Yield weight | Fiscal-elasticity floor | Event fit, 5-10y RMSE (OIS / IT-OIS / IT) | +10 pp fiscal factor, IT-OIS at 1 / 5 / 10y |
|---|---|---|---|---|---|
| `PEPP_GQ3_e50_baseline` | PEPP | 0.01 | 50 bp | 1.5 / 2.7 / 3.4 bp | +11 / +50 / +55 bp |
| `PEPP_GR4_e50_baseline` | PEPP | 0.01 | 50 bp | 1.3 / 2.3 / 2.4 bp | +10 / +50 / +51 bp |
| `PEPP_GQ6_e40_baseline` | PEPP | 0.01 | 40 bp | 0.8 / 1.9 / 1.4 bp | +7 / +42 / +41 bp |
| `APP_HO2_baseline` | APP | 0.05 | none | 0.6 / 1.0 / 1.1 bp | -6 / 0 / +13 bp |

Run from the repository root (MATLAB):

| Script | What it does |
|---|---|
| `baseline_PEPP.m` | re-optimises the three PEPP baselines; results in `Output_runs/<name>.mat` and `<name>_chart.csv` |
| `baseline_APP.m` | re-optimises the APP baseline |
| `baseline_charts.m` | main charts in `Output_figures/` (PNG, plus the plotted data as CSV of the same name): PEPP and APP reactions (OIS, IT-OIS spread, Italy), yield fit (OIS and Italy, 2/5/10y), IT-OIS spread fit and the fiscal elasticity by maturity |

Re-optimising left GQ3, GQ6 and HO2 where the search left them and improved GR4 from
2.3 / 2.8 / 4.0 bp; `Baselines.mat` holds these re-optimised estimates. With
`reestimate = false` the scripts only evaluate the stored estimates.

Requires the Optimization Toolbox (`lsqnonlin`). The OIS anchor uses the daily OIS spot curves in
`Data/OIS_rates_and_future_Spot_Curves.xlsx` (sheet "OIS curves FAME") for the event reactions.

## Layout

Only the code the baselines use is kept outside `old/`:

- `baseline_*.m`: the three scripts above.
- `model/`: `spread_config.m` (settings), `spread_load_inputs.m` (reads and caches the inputs),
  `spread_prepare.m` (factors, VAR, event targets), `spread_model.m` (pricing and residuals),
  `spread_estimate.m` (estimation and scores), `spread_stage_configs.m` (baseline
  configurations), `spread_save_baseline.m` (keeps improved estimates),
  `spread_baseline_series.m` and `spread_chart.m` (charts).
- `Functions/`: the four pricing recursions the model uses and, in `Functions/fast/`, the
  vectorised yield-impact functions.
- `Data/`, `Input_mat/`, `Output_mat/`: inputs, starting values and the baseline estimates
  (`Output_mat/Baselines.mat`).
- `octave/`: optional, to run the same code in GNU Octave (`octave/run_octave.sh`);
  `octave/charts/plot_baseline_charts.py` draws the baseline charts from their CSV files where
  Octave cannot render plots.
- `old/`: everything not used by the baselines (original scripts, search stages, unused
  functions); see `old/README.md`.

## Settings (`model/spread_config.m`)

| Setting | Options |
|---|---|
| `window` | estimation sample, e.g. `{'Mar2009','Dec2021'}` |
| `anchor`, `base` | `'DE'` (Bund yields) or `'OIS'` |
| `pc` | `'pca_est'` (PCA on the estimation sample) or `'observable'` (1y, 10y–1y) |
| `fiscal` | IT fiscal factor: `'ff_nom'` (unweighted free float, actual), `'ffgdp'` ((debt − Eurosystem holdings)/GDP), `'ff_nom_sim2015'` (March-2015 projection after Mar 2015) |
| `big4` | big-4 free-float vintage: `'Dec-21'` (actual) or `'Mar-15'` |
| `events` | `{'APP','PEPP'}`, `{'PEPP'}` or `{'APP'}` |
| `w` | weight on the yield fit (1 − w on the event fit) |
| `target` | `'levels'` (DE and IT) or `'spread'` (DE/OIS and the IT spread) |
| `gamma` | default intensity: `'all'` or `'fiscal_only'` |
| `fiscalGammaNonneg`, `maxIntensity`, `signConstraint`, `minElasticity` | restrictions, see below |
| `maxIter` | optimizer iterations; 0 evaluates the starting values only |

Restrictions:
- spread loading on the fiscal factor ≥ 0 at 5–10y (`signConstraint`);
- optionally a floor on that loading, `minElasticity` (bp of spread per +10 pp of the fiscal factor);
- IT default intensity `Gamma_0 + Gamma_1'X_t` ≥ 0 in every month;
- `Gamma_1` on the fiscal factor ≥ 0 (`fiscalGammaNonneg`, default on);
- optional cap on the default intensity per year (`maxIntensity`; 10% in the baselines).

## Fixes relative to the original scripts
- VAR matrix built as `BETA(2:end,:)'` (one row per equation); `Estimates_spread.m` used `BETA(2:end,:)`.
- Fiscal factor from actual data (`Free_Float.xlsx`); `2015_03_SIMULATIONBaseline.xlsx` is a projection after March 2015.
- Bounded Levenberg–Marquardt least squares instead of `fmincon` + unbounded `fminunc` (which undid the `Gamma` restrictions).
- Vectorised yield-impact functions (`Functions/fast/`), 22–25× faster, identical results.

## Other runs

```matlab
addpath('model'); addpath(genpath('Functions'));
raw = spread_load_inputs();
R = spread_estimate(spread_config('name', 'my_run', 'anchor', 'OIS', 'base', 'OIS', 'fiscal', 'ffgdp', ...
                                  'events', {'PEPP'}, 'w', 0.01, 'minElasticity', 50), raw);
```

The search stages that led to the baselines, and their run and plot tools, are in
`old/search_stages/` (e.g. `addpath('old/search_stages'); spread_run_stage('GQ')`).
