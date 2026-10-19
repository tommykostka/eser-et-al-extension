function R = spread_estimate(cfg, raw)
% Estimates the DE/IT spread model for one configuration (see spread_config.m),
% scores the fit of the four APP/PEPP x DE/IT reactions and saves the results.
%   R = spread_estimate(spread_config('fiscal', 'ffgdp'));
    if nargin < 2, raw = spread_load_inputs(); end
    t0 = tic;
    S = spread_prepare(cfg, raw);

    % ---- starting values (as in Estimates_spread_DEIT_PEPP.m) ----
    sv = load('Output_mat/StartingValues_ATSM_OIS.mat'); sv = sv.param_OIS_0;
    x0 = zeros(35, 1);
    x0(8:9)   = sv.Lambda_0;
    x0(10:11) = sv.Lambda_0;
    x0(12:17) = reshape([sv.Lambda_1 [0.11; -0.02]], [], 1);
    if ~isempty(cfg.x0), x0 = cfg.x0(:); end

    % ---- free parameters and bounds ----
    free = true(35, 1); lb = -100*ones(35, 1); ub = 100*ones(35, 1);
    if strcmp(cfg.gamma, 'fiscal_only')
        free(1:6) = false; x0(1:6) = 0;        % Gamma_0 and Gamma_1 on non-fiscal factors fixed at 0
    end
    if strcmp(cfg.gamma, 'fiscal_only') || (isfield(cfg, 'fiscalGammaNonneg') && cfg.fiscalGammaNonneg)
        lb(7) = 0;                              % default intensity rises with the fiscal factor
    end
    x0 = min(max(x0, lb), ub);
    resid = @(z) residuals(z, x0, free, S, cfg);

    % ---- bounded least squares on the free parameters ----
    % MATLAB: lsqnonlin (Optimization Toolbox). Octave: nonlin_residmin (optim package).
    z0 = x0(free);
    if exist('OCTAVE_VERSION', 'builtin') && ~strcmp(cfg.optimizer, 'lsqnonlin')
        opts = optimset('lbound', lb(free), 'ubound', ub(free), 'MaxIter', cfg.maxIter, 'TolFun', cfg.tol);
        [z, ~, cvg, outp] = nonlin_residmin(resid, z0, opts);
        info.exitflag = cvg; info.iterations = outp.niter;
    else
        opts = optimoptions('lsqnonlin', 'Display', 'off', 'MaxIterations', cfg.maxIter, ...
                            'FunctionTolerance', cfg.tol, 'StepTolerance', cfg.tol, 'MaxFunctionEvaluations', 1e6);
        [z, ~, ~, info.exitflag, outp] = lsqnonlin(resid, z0, lb(free), ub(free), opts);
        if isfield(outp, 'iterations'), info.iterations = outp.iterations; else info.iterations = outp.niter; end
    end
    x = x0; x(free) = z;
    M = spread_model(x, S, cfg);

    % ---- scores ----
    R.cfg = cfg; R.x = x; R.info = info; R.runtime = toc(t0);
    R.MSE = M.MSE;
    bp = 1e4;
    R.chart.maturities = 5:10;
    rmse_all = [];
    for c = {'DE', 'IT'}
        cty = c{1};
        for e = 1:numel(cfg.events)
            ev = cfg.events{e};
            o = S.target.(cty)(:, e) * bp; f = M.fit.(cty)(:, e) * bp;
            R.chart.(cty).([ev '_observed']) = o'; R.chart.(cty).([ev '_fitted']) = f';
            R.rmse.([cty '_' ev]) = sqrt(mean((o - f).^2));
            rmse_all = [rmse_all; o - f];  %#ok<AGROW>
        end
        R.yieldRMSE.(cty) = sqrt(mean(M.eY.(cty)(:).^2)) * bp;
    end
    % IT-DE spread: reactions and yield fit
    for e = 1:numel(cfg.events)
        ev = cfg.events{e};
        o = R.chart.IT.([ev '_observed']) - R.chart.DE.([ev '_observed']);
        f = R.chart.IT.([ev '_fitted'])   - R.chart.DE.([ev '_fitted']);
        R.chart.SP.([ev '_observed']) = o; R.chart.SP.([ev '_fitted']) = f;
        R.rmse.(['SP_' ev]) = sqrt(mean((o - f).^2));
    end
    R.yieldRMSE.SP = sqrt(mean((M.eY.IT(:) - M.eY.DE(:)).^2)) * bp;
    R.chartRMSE = sqrt(mean(rmse_all.^2));                % bp, all chart points
    R.spreadLoading_bp_per_pp = M.spreadLoading * 100;    % bp change in IT-DE spread per +1pp in the fiscal factor, 5-10y
    R.signOK = all(R.spreadLoading_bp_per_pp >= -0.1);           % spread must not fall when the fiscal factor rises
    R.Gamma_1 = M.G1'; R.Gamma_0 = M.G0;
    R.minIntensity = min(M.intensity);                    % IT default intensity, per month (must be >= 0)
    R.intensityRange_annual = 12 * [min(M.intensity) max(M.intensity)];
    R.signOK = R.signOK && R.Gamma_1(6) >= 0;
    if isfinite(cfg.maxIntensity), R.signOK = R.signOK && R.intensityRange_annual(2) <= cfg.maxIntensity + 1e-3; end
    R.signOK = R.signOK && R.minIntensity >= -1e-5;      % numerically zero (-1e-5 per month = -0.012% per year)
    R.param = S.param; R.L0 = M.L0; R.L1 = M.L1; R.AX = M.AX; R.BX = M.BX;

    if ~exist(cfg.outDir, 'dir'), mkdir(cfg.outDir); end
    save(fullfile(cfg.outDir, [cfg.name '.mat']), 'R');
    write_chart_csv(fullfile(cfg.outDir, [cfg.name '_chart.csv']), R, cfg);
    fprintf('%-60s chartRMSE %6.2f bp | DE APP %5.1f PEPP %5.1f | IT APP %5.1f PEPP %5.1f | spread APP %5.1f PEPP %5.1f | yields DE %5.1f IT %5.1f spread %5.1f bp | spread/pp %5.1f..%5.1f bp | min default int. %8.2e | ok %d | it %d flag %d | %4.0f s\n', ...
            cfg.name, R.chartRMSE, R.rmse.DE_APP, R.rmse.DE_PEPP, R.rmse.IT_APP, R.rmse.IT_PEPP, R.rmse.SP_APP, R.rmse.SP_PEPP, R.yieldRMSE.DE, R.yieldRMSE.IT, R.yieldRMSE.SP, ...
            min(R.spreadLoading_bp_per_pp), max(R.spreadLoading_bp_per_pp), R.minIntensity, R.signOK, info.iterations, info.exitflag, R.runtime);
end

function r = residuals(z, x0, free, S, cfg)
    x = x0; x(free) = z;
    M = spread_model(x, S, cfg);
    r = M.r;
end

function write_chart_csv(file, R, cfg)
    fid = fopen(file, 'w');
    fprintf(fid, 'country,event,maturity,observed_pp,fitted_pp\n');
    for c = {'DE', 'IT', 'SP'}
        for e = 1:numel(cfg.events)
            ev = cfg.events{e}; o = R.chart.(c{1}).([ev '_observed']); f = R.chart.(c{1}).([ev '_fitted']);
            for k = 1:6
                fprintf(fid, '%s,%s,%d,%.6f,%.6f\n', c{1}, ev, k + 4, o(k)/100, f(k)/100);
            end
        end
    end
    fclose(fid);
end
