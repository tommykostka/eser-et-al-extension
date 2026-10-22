function B = spread_baseline_series(name, raw)
% Observed and fitted series of run Output_runs/<name>.mat for the baseline
% charts: monthly OIS (DE block) and IT yields and the IT-OIS spread at 2, 5
% and 10y (percent), the APP and PEPP reactions at 5-10y (bp, R.chart) and
% the spread effect of +10 pp of the fiscal factor at 1-10y (bp).
    s = load(fullfile('Output_runs', [name '.mat'])); R = s.R; cfg = R.cfg;
    S = spread_prepare(cfg, raw); M = spread_model(R.x(:), S, cfg);
    B.name = name; B.dates = S.dates; B.mats = [2 5 10];
    for c = {'DE', 'IT'}
        E = S.E.(c{1}); j = ismember(E.mats_TSfit, B.mats);
        fit = ones(S.T, 1) * M.AX.(c{1}) + S.mX.(c{1}) * M.BX.(c{1});
        B.obs.(c{1}) = 100 * E.Yields(:, j); B.fit.(c{1}) = 100 * fit(:, j);
    end
    B.obs.SP = B.obs.IT - B.obs.DE; B.fit.SP = B.fit.IT - B.fit.DE;
    B.chart = R.chart;
    % DE does not load on the fiscal factor (factor 6 of IT), so the spread
    % effect is IT's loading: 1000 * loading = bp per +10 pp.
    p = S.param.IT; dt = 1/12;
    BX = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(12*(1:10), p.K1P_level, M.L1.IT, p.Omega_square, p.rho1*dt, dt, M.G1);
    B.elasticity = 1000 * BX(6, :);
end
