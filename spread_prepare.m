function S = spread_prepare(cfg, raw)
% Builds everything the DE/IT spread model needs for one configuration:
% pricing factors, P-dynamics (VAR), short-rate equation, event-study
% targets and u-sequences. Follows Estimates_spread_DEIT_PEPP.m, with the
% options in spread_config.m.
    countries = {'DE', 'IT'};
    vMaturities_analysis = 12:12:120;                 % months, yields fitted
    vMaturities_reg      = 60:12:120;                 % months, event reactions fitted
    sStart = cfg.window{1}; sEnd = cfg.window{2};

    % anchor = 'OIS': the 'DE' block holds OIS rates (fitted without default risk),
    % so Italy is modelled as a spread over OIS; the base curve is then OIS too.
    anchor = 'DE'; if isfield(cfg, 'anchor'), anchor = cfg.anchor; end
    if strcmp(anchor, 'OIS'), cfg.base = 'OIS'; end
    S.anchor = anchor;

    %% Event-study targets (independent of the configuration)
    for ii = 1:2
        cty = countries{ii};
        if strcmp(cty, 'DE') && strcmp(anchor, 'OIS')
            if ~isfield(raw, 'OISd'), error('spread_prepare: anchor OIS needs Data/OIS_rates_and_future_Spot_Curves.xlsx'); end
            dd = raw.OISd.dates; yd = raw.OISd.rates;
        else
            dd = raw.TS.(cty).Data.nom.d.dates; yd = raw.TS.(cty).yields.d.nom(:, vMaturities_analysis);
        end
        [S.obs.APP.(cty), S.obs.PEPP.(cty)] = event_changes(raw, dd, yd);
    end

    %% Level/slope of the base curve
    if strcmp(cfg.base, 'OIS')
        d = raw.OIS.MatlabDates; [i0, i1] = window_idx(d, sStart, sEnd);
        baseY = raw.OIS.OIS_rates(i0:i1, 5:14);       % OIS 1y-10y
    else
        d = raw.TS.DE.Data.nom.m.dates; [i0, i1] = window_idx(d, sStart, sEnd);
        baseY = raw.TS.DE.yields.m.nom(i0:i1, vMaturities_analysis);
    end
    [cP_base, S.W.base] = level_slope(baseY, cfg.pc);
    T = size(cP_base, 1);

    %% Quantity factors
    big4 = raw.(['big4_' strrep(cfg.big4, '-', '')]);
    vQuantity = series(big4, 13, sStart, sEnd, T, 'big-4 free float');
    switch cfg.fiscal
        case 'ff_nom',         vFiscal = series(raw.ff_unw, 14, sStart, sEnd, T, 'IT free float');     devFisc = raw.dev_ITFF;
        case 'ff_nom_sim2015', vFiscal = series(raw.ff_sim2015, 14, sStart, sEnd, T, 'IT free float'); devFisc = raw.dev_ITFF;
        case 'ffgdp',          vFiscal = series(raw.ff_gdp, 1, sStart, sEnd, T, 'IT net debt/GDP') / 100; devFisc = raw.dev_ITfisc;
        otherwise, error('spread_prepare: unknown fiscal factor %s', cfg.fiscal);
    end
    S.vFiscal = vFiscal;

    %% Country blocks
    for ii = 1:2
        cty = countries{ii};
        if strcmp(cty, 'DE') && strcmp(anchor, 'OIS')
            dm = raw.OIS.MatlabDates; [j0, j1] = window_idx(dm, sStart, sEnd);
            Y = raw.OIS.OIS_rates(j0:j1, 5:14);       % OIS 1y-10y
            r = raw.OIS.OIS_rates(j0:j1, 1);          % 1-month OIS as the short rate
        else
            dm = raw.TS.(cty).Data.nom.m.dates; [j0, j1] = window_idx(dm, sStart, sEnd);
            Y = raw.TS.(cty).yields.m.nom(j0:j1, vMaturities_analysis);
            r = raw.TS.(cty).yields.m.nom(j0:j1, 1);
        end
        if j1 - j0 + 1 ~= T, error('spread_prepare: sample length mismatch for %s', cty); end
        E.mats_TSfit = vMaturities_analysis / 12;
        E.mats_YCfit = vMaturities_reg / 12;
        E.Yields = Y; E.dt = 1/12;
        S.E.(cty) = E;

        if strcmp(cty, 'DE')
            mX = [cP_base vQuantity];
        else
            [cP_IT, S.W.IT] = level_slope(Y, cfg.pc);  % IT's own level/slope, as in the original scripts
            mX = [cP_base vQuantity (cP_IT - cP_base) vFiscal];
        end
        S.mX.(cty) = mX;
        N = size(mX, 2);

        % Short rate on level/slope (quantity factors excluded)
        if N == 6, cols = [1 2 4 5]; else cols = [1 2]; end
        B = [ones(T,1) mX(:,cols)] \ r;
        rho1 = zeros(N,1); rho1(cols) = B(2:end);
        p.rho0 = B(1); p.rho1 = rho1;

        % P-dynamics: VAR(1) for level/slope (and spread level/slope), AR(1) for quantities.
        % BETA has one column per equation, so K1P = BETA(2:end,:)'.
        blocks = {[1 2], 3};
        if N == 6, blocks = {[1 2], 3, [4 5], 6}; end
        K0P = zeros(N,1); K1P_level = zeros(N); Res = zeros(T-1, N);
        for b = 1:numel(blocks)
            c = blocks{b};
            Xl = [ones(T-1,1) mX(1:end-1, c)];
            BETA = Xl \ mX(2:end, c);
            K0P(c) = BETA(1,:)';
            if numel(c) == 1, BETA(2) = min(BETA(2), 0.99); end
            K1P_level(c, c) = BETA(2:end,:)';
            Res(:, c) = mX(2:end, c) - Xl * BETA;
        end
        p.K0P = K0P; p.K1P_level = K1P_level; p.K1P = K1P_level - eye(N);
        p.Omega_square = Res' * Res / (T-1);
        p.Omega_chol = chol(p.Omega_square, 'lower');
        S.param.(cty) = p;

        % Targets and u-sequences (APP: Mar 2015 path; PEPP: Mar 2020 path)
        tgt = []; U = [];
        for e = 1:numel(cfg.events)
            ev = cfg.events{e};
            obs = S.obs.(ev).(cty);
            tgt = [tgt obs(E.mats_YCfit)'];  %#ok<AGROW>
            if strcmp(ev, 'APP'), rows = 1:120; col = 1; else rows = 61:180; col = 2; end
            u = zeros(120, N);
            u(:, 3) = raw.dev_big4FF.num(rows, col);
            if N == 6, u(:, 6) = devFisc.num(rows, col); end
            U(:, :, e) = u;  %#ok<AGROW>
        end
        S.target.(cty) = tgt; S.U.(cty) = U;
    end
    S.T = T; S.cfg = cfg;
end

function [cP, W] = level_slope(Y, how, W)
% Level and slope factors of a 1y..10y curve (T x 10).
    switch how
        case 'pca_est'
            if nargin < 3
            [V, D] = eig(cov(Y)); [~, o] = sort(diag(D), 'descend'); W = V(:, o(1:2))';
            if sum(W(1,:)) < 0, W(1,:) = -W(1,:); end          % level: positive weights
            if W(2,end) < W(2,1), W(2,:) = -W(2,:); end        % slope: rises with maturity
            end
            cP = Y * W';
        case 'observable'
            cP = [Y(:,1) Y(:,end) - Y(:,1)]; W = [];
        otherwise
            error('level_slope: unknown option %s', how);
    end
end

function v = series(s, col, sStart, sEnd, T, label)
    [i0, i1] = window_idx(s.dates, sStart, sEnd);
    v = s.num(i0:i1, col);
    if numel(v) ~= T || any(isnan(v))
        error('spread_prepare: %s (%s, %s) does not cover %s-%s', label, s.file, s.sheet, sStart, sEnd);
    end
end

function [i0, i1] = window_idx(d, sStart, sEnd)
    m = cellstr(datestr(d, 'mmmyyyy'));
    i0 = find(strcmp(m, sStart), 1, 'first');
    i1 = find(strcmp(m, sEnd), 1, 'last');
    if isempty(i0) || isempty(i1), error('spread_prepare: window %s-%s not in data', sStart, sEnd); end
end

function [vAPP, vPEPP] = event_changes(raw, dd, yd)
% APP: average of the standard and macro-surprise-controlled event regressions
% (17 announcement dates, Sep 2014 - Mar 2015), on daily data from the last
% trading day up to 31 Dec 2013 to 31 Mar 2015. PEPP: 18-20 Mar 2020 change.
% dd: daily dates; yd: rates at 1..10y (one column per maturity).
    ev = {'04/09/2014', '12/09/2014', '24/09/2014', '25/09/2014', '02/10/2014', '10/10/2014', '24/10/2014', '06/11/2014', '17/11/2014', ...
          '21/11/2014', '27/11/2014', '04/12/2014', '02/01/2015', '08/01/2015', '14/01/2015', '22/01/2015', '05/03/2015'};
    a = find(dd <= datenum(2013, 12, 31), 1, 'last'); if isempty(a), a = 1; end
    b = find(dd <= datenum(2015, 3, 31), 1, 'last');
    sel = dd(a+1:b);
    dY = diff(yd(a:b, :)); Y = dY(2:end, :);
    X = zeros(numel(sel), numel(ev)); ss = cellstr(datestr(sel, 'dd/mm/yyyy'));
    for k = 1:numel(ev), X(strcmp(ss, ev{k}), k) = 1; end
    Xs = [X(2:end,:) X(1:end-1,:)];
    sd = raw.Surprise(:,1) + 693960;
    M = zeros(numel(sel), size(raw.Surprise, 2) - 1);       % macro surprises aligned to the trading days, 0 if none
    [found, loc] = ismember(sel, sd);
    M(found, :) = raw.Surprise(loc(found), 2:end); M(isnan(M)) = 0;
    Xc = [Xs M(2:end,:)];
    n = 2*numel(ev);
    bs = regress_cols(Y, Xs); bc = regress_cols(Y, Xc);
    vAPP = (sum(bs(1:n,:), 1) + sum(bc(1:n,:), 1)) / 2;
    p0 = find(dd == datenum(2020, 3, 18), 1, 'first');
    p1 = find(dd == datenum(2020, 3, 20), 1, 'last');
    vPEPP = yd(p1, :) - yd(p0, :);
end

function B = regress_cols(Y, X)
% Same estimator as MATLAB's regress (QR least squares; rank-deficient columns get zero).
    B = zeros(size(X,2), size(Y,2));
    for j = 1:size(Y,2), B(:,j) = regress(Y(:,j), X); end
end
