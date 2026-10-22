function spread_run_stage(stage, useParallel)
% Runs every configuration of a search stage (see spread_stage_configs.m)
% and writes Output_runs/summary.csv. Uses parfor when useParallel is true
% (default: true if the Parallel Computing Toolbox is available).
%   spread_run_stage('E')
    if nargin < 2
        useParallel = license('test', 'Distrib_Computing_Toolbox') && ~isempty(ver('parallel'));
    end
    addpath(genpath('Functions'));
    raw = spread_load_inputs();
    C = spread_stage_configs(stage);
    if useParallel
        parfor k = 1:numel(C)
            run_one(C{k}, raw);
        end
    else
        for k = 1:numel(C)
            run_one(C{k}, raw);
        end
    end
    spread_summarize();
end

function run_one(cfg, raw)
    try
        spread_estimate(cfg, raw);
    catch err
        fprintf('%-60s FAILED: %s\n', cfg.name, err.message);
    end
end
