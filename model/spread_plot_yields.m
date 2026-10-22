function spread_plot_yields(name, window, outFile)
% Observed vs model-implied DE and IT yields (2y, 5y, 10y) for run
% Output_runs/<name>.mat over a window (default: its estimation window).
% Outside the estimation window the parameters stay fixed and the factors
% are updated with actual data (spread_evaluate_window.m).
%   spread_plot_yields('E06_ffgdp_restart', {'Jan2015', 'Dec2021'}, 'Output_runs/E06_yields.png')
    s = load(fullfile('Output_runs', [name '.mat'])); R = s.R;
    if nargin < 2 || isempty(window), window = R.cfg.window; end
    raw = spread_load_inputs();
    o = spread_evaluate_window(R, raw, window);
    blue = [42 120 214]/255; orange = [235 104 52]/255;
    names = struct('DE', 'Germany', 'IT', 'Italy');
    fig = figure('Color', 'w', 'Position', [100 100 1000 760]);
    mats = [2 5 10]; ctys = {'DE', 'IT'};
    for r = 1:3
        for c = 1:2
            cty = ctys{c}; j = mats(r);
            subplot(3, 2, (r-1)*2 + c); hold on; box off; grid on;
            plot(o.dates, 100*o.(cty).observed(:, j), '-', 'Color', blue, 'LineWidth', 2);
            plot(o.dates, 100*o.(cty).fitted(:, j), '--', 'Color', orange, 'LineWidth', 1.6);
            datetick('x', 'yyyy', 'keeplimits');
            title(sprintf('%s - %dy   (RMSE %.1f bp)', names.(cty), j, o.(cty).rmse_bp(j)));
            if c == 1, ylabel('Yield (%)'); end
            if r == 1 && c == 1, legend({'Observed', 'Model'}, 'Location', 'best', 'Box', 'off'); end
        end
    end
    annotation(fig, 'textbox', [0 0.955 1 0.045], 'String', sprintf('%s: yields %s-%s (estimated %s-%s)', ...
               strrep(name, '_', '\_'), window{1}, window{2}, R.cfg.window{1}, R.cfg.window{2}), ...
               'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    if nargin > 2 && ~isempty(outFile), print(fig, outFile, '-dpng', '-r150'); end
end
