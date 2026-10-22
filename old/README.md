# old/: code not used by the baselines

Kept for reference; nothing here is needed to run `baseline_PEPP.m`, `baseline_APP.m` or
`baseline_charts.m`.

| Folder | Contents |
|---|---|
| `original_scripts/` | The estimation scripts of the original code (`Estimates_spread_DEIT_PEPP.m`, `Estimates_spread_DEIT_APP.m`, `Estimate_multicountry_3.m`, `Estimate_DE*.m`, `Estimate_IT*.m`, ...), comparison and sanity-check scripts, and their scratch `.mat` files. |
| `original_archive/` | The `Archive` folder of the original code (single-country and stress models, ECB yield-curve readers). |
| `original_outputs/` | Two estimation results the original scripts load from `Output/`. |
| `functions/` | Functions of the original code that the baselines do not call (other ATSM recursions, the JSZ library, `tprod`). Same layout as `Functions/`. |
| `search_stages/` | The search stages A-H, FO/GO/HO, GP, GQ and GR that led to the baselines (`spread_stage_configs_archive.m`), and the tools to run and inspect them: `spread_run_stage.m`, `spread_run_batch.m`, `spread_summarize.m`, `spread_evaluate_window.m`, `spread_plot_events.m`, `spread_plot_yields.m`. |
| `octave/` | Octave stand-ins only the original scripts need (`compat/`: `fmincon`, `mvregress`; `noplot/`: further plotting no-ops) and two older Python chart scripts. |

## Running the search stages

From the repository root:

```matlab
addpath('model', 'old/search_stages'); addpath(genpath('Functions'));
spread_run_stage('GQ');      % warm starts are read from Output_runs/ or Output_runs/archive/
```

`model/spread_stage_configs.m` hands any stage other than the baselines to
`spread_stage_configs_archive.m`.

## Running the original scripts

They start with `addpath(genpath([cd '\']))` and read `Output/...`, so run them from a folder
that contains `Functions/` plus `old/functions/` (merged), `Input_mat/`, `Output_mat/`, `Data/`
and `old/original_outputs/` as `Output/`. Do not run them from the repository root: `genpath`
would then also add `octave/`, whose plotting no-ops and Octave wrappers would shadow
MATLAB's own functions.
