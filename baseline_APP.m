% APP baseline: OIS anchor, sample Mar 2009 - Dec 2021, fitted to the APP
% reaction (OIS and IT-OIS spread, 5-10y) with yield weight w = 0.05:
%   APP_HO2_baseline   (search run HO2, warm start F08)
% The optimizer starts from the stored estimate in Output_mat/Baselines.mat
% (initially those of the search runs) and is restarted until the fit stops
% improving; an improved estimate is written back to Baselines.mat, so each run
% continues from the best one so far. reestimate = false only evaluates the
% stored estimate. Results go to Output_runs/<name>.mat and <name>_chart.csv.
reestimate = true;   % false: evaluate the stored estimates only
rounds = 5;          % optimizer restarts, each from where the previous one stopped

addpath('model'); addpath(genpath('Functions'));
raw = spread_load_inputs();
C = spread_stage_configs('APP_baseline');
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
    spread_save_baseline(R);         % keep the estimate if it beats the stored one
end
