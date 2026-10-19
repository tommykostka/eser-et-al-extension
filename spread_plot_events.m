function spread_plot_events(name, outFile)
% Four panels (DE/IT x APP/PEPP): observed vs fitted yield reactions at
% 5-10y, in bp, for run Output_runs/<name>.mat. Saves a PNG if outFile is given.
%   spread_plot_events('E06_ffgdp_restart', 'Output_runs/E06_events.png')
    s = load(fullfile('Output_runs', [name '.mat'])); R = s.R;
    blue = [42 120 214]/255; orange = [235 104 52]/255;
    names = struct('DE', 'Germany', 'IT', 'Italy');
    panels = {'DE', 'APP'; 'IT', 'APP'; 'DE', 'PEPP'; 'IT', 'PEPP'};
    fig = figure('Color', 'w', 'Position', [100 100 1000 720]);
    m = R.chart.maturities;
    for k = 1:4
        cty = panels{k, 1}; ev = panels{k, 2};
        o = R.chart.(cty).([ev '_observed']); f = R.chart.(cty).([ev '_fitted']);
        subplot(2, 2, k); hold on; box off; grid on;
        plot(m([1 end]), [0 0], 'k-', 'LineWidth', 0.5);
        h1 = plot(m, o, '-o', 'Color', blue, 'LineWidth', 2, 'MarkerFaceColor', blue);
        h2 = plot(m, f, '--s', 'Color', orange, 'LineWidth', 2, 'MarkerFaceColor', orange);
        text(m(end) + 0.1, o(end), sprintf('%.0f', o(end)), 'FontSize', 8);
        text(m(end) + 0.1, f(end), sprintf('%.0f', f(end)), 'FontSize', 8);
        title(sprintf('%s - %s   (RMSE %.1f bp)', names.(cty), ev, R.rmse.([cty '_' ev])), 'HorizontalAlignment', 'left', 'Units', 'normalized', 'Position', [0 1.02 0]);
        xlim([m(1) - 0.3, m(end) + 0.6]); set(gca, 'XTick', m);
        if k > 2, xlabel('Maturity (years)'); end
        if mod(k, 2) == 1, ylabel('Change in yield (bp)'); end
        if k == 1, legend([h1 h2], {'Observed (event study)', 'Fitted (model)'}, 'Location', 'southwest', 'Box', 'off'); end
    end
    c = R.cfg;
    annotation(fig, 'textbox', [0 0.95 1 0.05], 'String', sprintf('%s: chart RMSE %.1f bp | %s base, %s, fiscal %s, %s-%s, w = %.2f', ...
               strrep(c.name, '_', '\_'), R.chartRMSE, c.base, c.pc, c.fiscal, c.window{1}, c.window{2}, c.w), ...
               'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    if nargin > 1 && ~isempty(outFile), print(fig, outFile, '-dpng', '-r150'); end
end
