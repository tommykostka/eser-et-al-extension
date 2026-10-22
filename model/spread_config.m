function cfg = spread_config(varargin)
% Settings for one run of the DE/IT spread model (spread_estimate.m).
% Call with name/value pairs to override defaults, e.g.
%   cfg = spread_config('base', 'OIS', 'window', {'Mar2009', 'Dec2021'});

    cfg.name      = '';                    % label used for output file names
    cfg.window    = {'Dec2009', 'Aug2014'};% estimation sample {start, end} as 'mmmyyyy'
    cfg.base      = 'DE';                  % level/slope curve shared by DE and IT: 'DE' (Bund yields) or 'OIS'
    cfg.anchor    = 'DE';                  % risk-free curve priced alongside IT: 'DE' (Bunds) or 'OIS' (OIS rates; IT spreads over OIS)
    cfg.pc        = 'pca_est';             % level/slope: 'pca_est' (PCA on estimation sample) or 'observable' (1y, 10y-1y)
    cfg.big4      = 'Dec-21';              % big-4 free-float vintage: 'Dec-21' (actual data) or 'Mar-15' (2015 projection after Mar 2015)
    cfg.fiscal    = 'ff_nom';              % IT fiscal factor, see spread_prepare.m:
                                           %   'ff_nom'         unweighted IT free float, actual (Free_Float.xlsx)
                                           %   'ff_nom_sim2015' same, 2015_03_SIMULATIONBaseline.xlsx (projection after Mar 2015)
                                           %   'ffgdp'          (debt - Eurosystem holdings)/GDP, IT (FF_GDP_IT)
    cfg.events    = {'APP', 'PEPP'};       % event reactions to fit
    cfg.w         = 0.5;                   % weight on the yield-level fit (1-w on the event fit)
    cfg.target    = 'levels';              % 'levels' (DE, IT), 'spread' (DE, IT-DE), 'spread_events' (spread only for APP/PEPP)
    cfg.spreadWeight = 1;                  % weight of the IT (or IT-DE) part relative to DE
    cfg.gamma     = 'fiscal_only';         % default intensity: 'fiscal_only' (only Gamma_1 on the fiscal factor, >= 0) or 'all'
    cfg.fiscalGammaNonneg = true;          % Gamma_1 on the fiscal factor >= 0: default risk rises with fiscal risk
    cfg.maxIntensity = Inf;                % optional cap on IT default intensity, per year (e.g. 0.10 = 10%)
    cfg.signConstraint = true;             % require IT-DE spread loading on the fiscal factor >= 0 at 5-10y
    cfg.penalty   = 1e2;                   % weight of the sign-constraint penalty
    cfg.minElasticity = 0;                 % lower bound on the spread effect of +10 pp of the fiscal factor, bp, 5-10y
    cfg.optimizer = 'lm';                  % 'lm': lsqnonlin in MATLAB, nonlin_residmin in Octave; 'lsqnonlin' forces lsqnonlin
    cfg.maxIter   = 400;
    cfg.tol       = 1e-10;
    cfg.x0        = [];                    % optional starting vector (warm start), full parameter layout
    cfg.outDir    = 'Output_runs';

    for k = 1:2:numel(varargin)
        if ~isfield(cfg, varargin{k}), error('spread_config: unknown setting %s', varargin{k}); end
        cfg.(varargin{k}) = varargin{k+1};
    end
    if isempty(cfg.name)
        cfg.name = sprintf('%s_%s_%s_%s_%s_%s_w%02d_%s', cfg.base, cfg.pc, cfg.fiscal, cfg.big4, cfg.window{1}, cfg.window{2}, round(100*cfg.w), cfg.gamma);
        cfg.name = strrep(cfg.name, '-', '');
    end
end
