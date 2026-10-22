% Main charts of the baseline specifications (run baseline_PEPP.m and
% baseline_APP.m first). Each chart is saved as PNG in Output_figures/, with
% the plotted data in a CSV file of the same name:
%   baseline_PEPP_reaction_fit_5-10y        PEPP reaction: OIS, IT-OIS spread, Italy
%   baseline_APP_reaction_fit_5-10y         APP reaction: OIS, IT-OIS spread, Italy
%   baseline_yield_fit_OIS_IT_2009-2021     OIS and Italian yields at 2, 5, 10y
%   baseline_ITOIS_spread_fit_2009-2021     IT-OIS spread at 2, 5, 10y
%   baseline_fiscal_elasticity_1-10y        spread effect of +10 pp of the fiscal factor
runs   = {'PEPP_GQ3_e50_baseline', 'PEPP_GR4_e50_baseline', 'PEPP_GQ6_e40_baseline', 'APP_HO2_baseline'};
labels = {'PEPP GQ3 (floor 50)', 'PEPP GR4 (floor 50)', 'PEPP GQ6 (floor 40)', 'APP HO2'};

addpath('model'); addpath(genpath('Functions'));
outDir = 'Output_figures';
if ~exist(outDir, 'dir'), mkdir(outDir); end
raw = spread_load_inputs();
for k = 1:numel(runs)
    B(k) = spread_baseline_series(runs{k}, raw); %#ok<SAGROW>
end
spread_chart('events', B(1:3), labels(1:3), fullfile(outDir, 'baseline_PEPP_reaction_fit_5-10y'), 'PEPP');
spread_chart('events', B(4), labels(4), fullfile(outDir, 'baseline_APP_reaction_fit_5-10y'), 'APP');
spread_chart('yields', B, labels, fullfile(outDir, 'baseline_yield_fit_OIS_IT_2009-2021'));
spread_chart('spread', B, labels, fullfile(outDir, 'baseline_ITOIS_spread_fit_2009-2021'));
spread_chart('elasticity', B, labels, fullfile(outDir, 'baseline_fiscal_elasticity_1-10y'));
