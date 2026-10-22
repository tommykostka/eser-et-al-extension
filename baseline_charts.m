% Main charts of the baseline specifications (run baseline_PEPP.m and
% baseline_APP.m first). Saves each chart as PNG, with the plotted data as
% CSV, in Output_runs/baseline_charts:
%   pepp_event   PEPP reaction at 5-10y: OIS, IT-OIS spread, Italy
%   app_event    APP reaction at 5-10y: OIS, IT-OIS spread, Italy
%   yields       yield fit, Mar 2009 - Dec 2021: OIS and Italy at 2, 5, 10y
%   spread       IT-OIS spread fit, Mar 2009 - Dec 2021, at 2, 5, 10y
%   elasticity   spread effect of +10 pp of the fiscal factor at 1-10y
runs   = {'PEPP_GQ3_e50_baseline', 'PEPP_GR4_e50_baseline', 'PEPP_GQ6_e40_baseline', 'APP_HO2_baseline'};
labels = {'PEPP GQ3 (floor 50)', 'PEPP GR4 (floor 50)', 'PEPP GQ6 (floor 40)', 'APP HO2'};

addpath('model'); addpath(genpath('Functions'));
outDir = fullfile('Output_runs', 'baseline_charts');
if ~exist(outDir, 'dir'), mkdir(outDir); end
raw = spread_load_inputs();
for k = 1:numel(runs)
    B(k) = spread_baseline_series(runs{k}, raw); %#ok<SAGROW>
end
spread_chart('events', B(1:3), labels(1:3), fullfile(outDir, 'pepp_event'), 'PEPP');
spread_chart('events', B(4), labels(4), fullfile(outDir, 'app_event'), 'APP');
spread_chart('yields', B, labels, fullfile(outDir, 'yields'));
spread_chart('spread', B, labels, fullfile(outDir, 'spread'));
spread_chart('elasticity', B, labels, fullfile(outDir, 'elasticity'));
