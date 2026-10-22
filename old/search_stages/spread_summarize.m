function spread_summarize(pattern)
% Collects Output_runs/<pattern>.mat results into Output_runs/summary.csv,
% sorted by the chart fit (RMSE over the 24 APP/PEPP x DE/IT points, bp).
    if nargin < 1, pattern = '*'; end
    f = dir(fullfile('Output_runs', [pattern '.mat']));
    rows = {};
    for k = 1:numel(f)
        s = load(fullfile('Output_runs', f(k).name)); R = s.R; c = R.cfg;
        if ~isfield(R, 'minIntensity'), R.minIntensity = NaN; end
        if ~isfield(R, 'intensityRange_annual'), R.intensityRange_annual = [NaN NaN]; end
        rows(end+1, :) = {c.name, R.chartRMSE, R.rmse.DE_APP, R.rmse.DE_PEPP, R.rmse.IT_APP, R.rmse.IT_PEPP, ...
                          R.yieldRMSE.DE, R.yieldRMSE.IT, min(R.spreadLoading_bp_per_pp), max(R.spreadLoading_bp_per_pp), ...
                          R.intensityRange_annual(1), R.intensityRange_annual(2), R.signOK, R.info.iterations, R.info.exitflag, R.runtime, ...
                          c.base, c.pc, c.fiscal, c.big4, [c.window{1} '-' c.window{2}], c.w, c.gamma};  %#ok<AGROW>
    end
    [~, o] = sort(cell2mat(rows(:, 2))); rows = rows(o, :);
    fid = fopen(fullfile('Output_runs', 'summary.csv'), 'w');
    fprintf(fid, 'name,chart_rmse_bp,DE_APP,DE_PEPP,IT_APP,IT_PEPP,yield_rmse_DE,yield_rmse_IT,spread_per_pp_min,spread_per_pp_max,default_intensity_min_pa,default_intensity_max_pa,constraints_ok,iterations,exitflag,runtime_s,base,pc,fiscal,big4,window,w,gamma\n');
    for k = 1:size(rows, 1)
        fprintf(fid, '%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.4f,%.4f,%d,%d,%d,%.0f,%s,%s,%s,%s,%s,%.2f,%s\n', rows{k, :});
    end
    fclose(fid);
    type(fullfile('Output_runs', 'summary.csv'));
end
