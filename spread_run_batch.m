function spread_run_batch(stage, worker, nWorkers)
% Runs the configurations of a stage (spread_stage_configs.m) assigned to
% this worker: configs worker, worker+nWorkers, ... One line per run is
% printed; results go to Output_runs/<name>.mat.
    addpath(genpath('Functions'));
    raw = spread_load_inputs();
    C = spread_stage_configs(stage);
    for k = worker:nWorkers:numel(C)
        try
            spread_estimate(C{k}, raw);
        catch err
            fprintf('%-60s FAILED: %s\n', C{k}.name, err.message);
        end
    end
end
