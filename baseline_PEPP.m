% PEPP baselines: OIS anchor, sample Mar 2009 - Dec 2021, fitted to the PEPP
% reaction (OIS and IT-OIS spread, 5-10y) with yield weight w = 0.01 and a
% floor on the spread effect of +10 pp of the fiscal factor (IT purchases/GDP):
%   PEPP_GQ3_e50_baseline   floor 50 bp (search run GQ3, warm start GP7)
%   PEPP_GR4_e50_baseline   floor 50 bp (search run GR4, warm start GQ6)
%   PEPP_GQ6_e40_baseline   floor 40 bp (search run GQ6, warm start GP3)
% The optimizer starts from the estimates of those search runs
% (Output_mat/Baselines.mat) and is restarted until the fit stops improving;
% reestimate = false only evaluates the stored estimates. Results go to
% Output_runs/<name>.mat and <name>_chart.csv.
reestimate = true;   % false: evaluate the stored estimates only
rounds = 5;          % optimizer restarts, each from where the previous one stopped

addpath('model'); addpath(genpath('Functions'));
raw = spread_load_inputs();
C = spread_stage_configs('PEPP_baseline');
for k = 1:numel(C)
    if ~reestimate
        C{k}.maxIter = 0; spread_estimate(C{k}, raw);
        continue;
    end
    for r = 1:rounds                 % stop once a restart improves the objective by less than 0.01%
        R = spread_estimate(C{k}, raw);
        if r > 1 && R.MSE > mse * (1 - 1e-4), break; end
        mse = R.MSE; C{k}.x0 = R.x;
    end
end
