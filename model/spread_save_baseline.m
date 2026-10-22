function improved = spread_save_baseline(R)
% Writes the estimate of baseline run R back to Output_mat/Baselines.mat when
% it improves on the stored one (lower objective), so the next run of
% baseline_PEPP.m / baseline_APP.m continues from the best estimate so far.
    file = fullfile('Output_mat', 'Baselines.mat');
    s = load(file); Baselines = s.Baselines; name = R.cfg.name;
    old = Inf;
    if isfield(Baselines, name) && isfield(Baselines.(name), 'MSE'), old = Baselines.(name).MSE; end
    improved = R.MSE < old;
    if improved
        Baselines.(name).x = R.x;
        Baselines.(name).MSE = R.MSE;
        Baselines.(name).updated = datestr(now, 'yyyy-mm-dd HH:MM');
        save(file, 'Baselines');
        fprintf('%s: improved estimate saved to %s (objective %.4g, was %.4g)\n', name, file, R.MSE, old);
    else
        fprintf('%s: no improvement on the stored estimate (objective %.4g)\n', name, old);
    end
end
