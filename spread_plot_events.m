function spread_plot_events(name, outFile)
% Observed vs fitted yield reactions to APP and PEPP at 5-10y, in bp, for run
% Output_runs/<name>.mat: Germany, Italy and the IT-DE spread (rows) x APP,
% PEPP (columns). Saves a PNG if outFile is given.
%   spread_plot_events('F01_E06_spread', 'Output_runs/F01_events.png')
    s = load(fullfile('Output_runs', [name '.mat'])); R = s.R;
    blue = [42 120 214]/255; orange = [235 104 52]/255;
    rowsC = {'DE', 'IT', 'SP'}; label = struct('DE', 'Germany', 'IT', 'Italy', 'SP', 'IT-DE spread');
    evs = {'APP', 'PEPP'};
    if ~isfield(R.chart, 'SP')                       % runs saved before the spread was scored
        for e = 1:2
            R.chart.SP.([evs{e} '_observed']) = R.chart.IT.([evs{e} '_observed']) - R.chart.DE.([evs{e} '_observed']);
            R.chart.SP.([evs{e} '_fitted'])   = R.chart.IT.([evs{e} '_fitted'])   - R.chart.DE.([evs{e} '_fitted']);
        end
    end
    fig = figure('Color', 'w', 'Position', [100 100 1000 980]);
    m = R.chart.maturities;
    for r = 1:3
        for e = 1:2
            cty = rowsC{r}; ev = evs{e};
            o = R.chart.(cty).([ev '_observed']); f = R.chart.(cty).([ev '_fitted']);
            subplot(3, 2, (r-1)*2 + e); hold on; box off; grid on;
            plot(m([1 end]), [0 0], 'k-', 'LineWidth', 0.5);
            h1 = plot(m, o, '-o', 'Color', blue, 'LineWidth', 2, 'MarkerFaceColor', blue);
            h2 = plot(m, f, '--s', 'Color', orange, 'LineWidth', 2, 'MarkerFaceColor', orange);
            text(m(end) + 0.1, o(end), sprintf('%.0f', o(end)), 'FontSize', 8);
            text(m(end) + 0.1, f(end), sprintf('%.0f', f(end)), 'FontSize', 8);
            title(sprintf('%s - %s   (RMSE %.1f bp)', label.(cty), ev, sqrt(mean((o - f).^2))));
            xlim([m(1) - 0.3, m(end) + 0.6]); set(gca, 'XTick', m);
            if r == 3, xlabel('Maturity (years)'); end
            if e == 1, ylabel('Change (bp)'); end
            if r == 1 && e == 1, legend([h1 h2], {'Observed (event study)', 'Fitted (model)'}, 'Location', 'southwest', 'Box', 'off'); end
        end
    end
    c = R.cfg; tgt = 'levels'; if isfield(c, 'target'), tgt = c.target; end
    annotation(fig, 'textbox', [0 0.96 1 0.04], 'String', sprintf('%s: chart RMSE %.1f bp | %s base, fiscal %s, %s-%s, w = %.2f, target %s', ...
               strrep(c.name, '_', '\_'), R.chartRMSE, c.base, c.fiscal, c.window{1}, c.window{2}, c.w, strrep(tgt, '_', '\_')), ...
               'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    if nargin > 1 && ~isempty(outFile), print(fig, outFile, '-dpng', '-r150'); end
end
