function spread_chart(kind, B, labels, file, ev)
% Draws one baseline chart (see baseline_charts.m) from the series of
% spread_baseline_series and saves it as <file>.png, with the plotted data
% in <file>.csv. kind: 'events' (ev = 'APP' or 'PEPP'), 'yields', 'spread'
% or 'elasticity'.
    cols = [42 120 214; 235 104 52; 27 175 122; 98 80 214] / 255;
    lab = struct('DE', 'OIS', 'SP', 'IT-OIS spread', 'IT', 'Italy');
    fid = fopen([file '.csv'], 'w');
    switch kind
        case 'events'
            fig = figure('Color', 'w', 'Position', [100 100 1300 480]);
            m = B(1).chart.maturities; panels = {'DE', 'SP', 'IT'};
            fprintf(fid, 'run,series,maturity,observed_bp,fitted_bp\n');
            for p = 1:3
                c = panels{p};
                subplot(1, 3, p); hold on; grid on; box off;
                o = B(1).chart.(c).([ev '_observed']);
                h = plot(m, o, '-o', 'Color', 'k', 'LineWidth', 2, 'MarkerFaceColor', 'k');
                err = cell(1, numel(B));
                for k = 1:numel(B)
                    f = B(k).chart.(c).([ev '_fitted']);
                    h(end+1) = plot(m, f, '--s', 'Color', cols(k, :), 'LineWidth', 1.6, 'MarkerFaceColor', cols(k, :)); %#ok<AGROW>
                    err{k} = sprintf('%.1f', sqrt(mean((o - f).^2)));
                    for j = 1:numel(m), fprintf(fid, '%s,%s,%d,%.3f,%.3f\n', B(k).name, c, m(j), o(j), f(j)); end
                end
                title(sprintf('%s - %s (RMSE %s bp)', lab.(c), ev, strjoin(err, ' / ')));
                xlabel('Maturity (years)'); set(gca, 'XTick', m);
                if p == 1, ylabel('Change (bp)'); legend(h, [{'Observed'} labels], 'Location', 'best'); end
            end
        case {'yields', 'spread'}
            if strcmp(kind, 'yields'), panels = {'DE', 'IT'}; else panels = {'SP'}; end
            nc = numel(panels);
            fig = figure('Color', 'w', 'Position', [100 100 650*nc 900]);
            fprintf(fid, 'run,series,maturity,date,observed_pct,fitted_pct\n');
            for i = 1:3
                for p = 1:nc
                    c = panels{p};
                    subplot(3, nc, (i-1)*nc + p); hold on; grid on; box off;
                    o = B(1).obs.(c)(:, i);
                    h = plot(B(1).dates, o, 'k-', 'LineWidth', 1.8);
                    err = cell(1, numel(B));
                    for k = 1:numel(B)
                        f = B(k).fit.(c)(:, i);
                        h(end+1) = plot(B(k).dates, f, '--', 'Color', cols(k, :), 'LineWidth', 1.2); %#ok<AGROW>
                        err{k} = sprintf('%.0f', 100 * sqrt(mean((o - f).^2)));
                        for t = 1:numel(o)
                            fprintf(fid, '%s,%s,%d,%s,%.4f,%.4f\n', B(k).name, c, B(k).mats(i), datestr(B(k).dates(t), 'yyyy-mm-dd'), o(t), f(t));
                        end
                    end
                    datetick('x', 'yyyy'); axis tight;
                    title(sprintf('%s - %dy (RMSE %s bp)', lab.(c), B(1).mats(i), strjoin(err, ' / ')));
                    if p == 1, ylabel('Percent'); end
                    if i == 1 && p == 1, legend(h, [{'Observed'} labels], 'Location', 'best'); end
                end
            end
        case 'elasticity'
            fig = figure('Color', 'w', 'Position', [100 100 800 500]);
            hold on; grid on; box off;
            fprintf(fid, 'run,maturity,bp_per_10pp\n');
            h = [];
            for k = 1:numel(B)
                h(k) = plot(1:10, B(k).elasticity, '-o', 'Color', cols(k, :), 'LineWidth', 1.8, 'MarkerFaceColor', cols(k, :));
                for j = 1:10, fprintf(fid, '%s,%d,%.3f\n', B(k).name, j, B(k).elasticity(j)); end
            end
            plot([1 10], [0 0], 'k-', 'LineWidth', 0.5);
            set(gca, 'XTick', 1:10); xlabel('Maturity (years)'); ylabel('bp');
            title('IT-OIS spread effect of +10 pp of the fiscal factor (IT purchases / GDP)');
            legend(h, labels, 'Location', 'best');
        otherwise
            fclose(fid); error('spread_chart: unknown kind %s', kind);
    end
    fclose(fid);
    print(fig, [file '.png'], '-dpng', '-r150');
    close(fig);
end
