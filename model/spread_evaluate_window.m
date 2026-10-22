function out = spread_evaluate_window(R, raw, window, big4)
% Model-implied DE and IT yields of an estimated run R over another window,
% keeping all estimated parameters (and PCA weights) fixed and updating the
% factors with actual data. big4: vintage of the big-4 free float to use
% (default 'Dec-21', i.e. actual data; the Mar-15 vintage is a projection after Mar 2015).
    if nargin < 4, big4 = 'Dec-21'; end
    cfg = R.cfg; Sest = spread_prepare(cfg, raw);
    cfg2 = cfg; cfg2.window = window; cfg2.big4 = big4;
    S = spread_prepare(cfg2, raw);                 % factors on the new window (fresh PCA weights)
    mats = 12:12:120;
    % rebuild level/slope with the estimation-sample weights
    if strcmp(cfg.base, 'OIS')
        d = raw.OIS.MatlabDates; m = cellstr(datestr(d, 'mmmyyyy'));
        Yb = raw.OIS.OIS_rates(find(strcmp(m, window{1}), 1):find(strcmp(m, window{2}), 1, 'last'), 5:14);
    else
        Yb = S.E.DE.Yields;
    end
    if strcmp(cfg.pc, 'pca_est'), cPb = Yb * Sest.W.base'; cPi = S.E.IT.Yields * Sest.W.IT'; else cPb = [Yb(:,1) Yb(:,end)-Yb(:,1)]; cPi = [S.E.IT.Yields(:,1) S.E.IT.Yields(:,end)-S.E.IT.Yields(:,1)]; end
    X.DE = [cPb S.mX.DE(:,3)];
    X.IT = [cPb S.mX.IT(:,3) (cPi - cPb) S.mX.IT(:,6)];
    dm = raw.TS.DE.Data.nom.m.dates; m = cellstr(datestr(dm, 'mmmyyyy'));
    out.dates = dm(find(strcmp(m, window{1}), 1):find(strcmp(m, window{2}), 1, 'last'));
    for c = {'DE', 'IT'}
        cty = c{1}; T = size(X.(cty), 1);
        out.(cty).observed = S.E.(cty).Yields;
        out.(cty).fitted   = ones(T,1) * R.AX.(cty) + X.(cty) * R.BX.(cty);
        out.(cty).rmse_bp  = 1e4 * sqrt(mean((out.(cty).observed - out.(cty).fitted).^2));
    end
    out.mats = mats / 12;
end
