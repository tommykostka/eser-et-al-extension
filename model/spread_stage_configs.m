function C = spread_stage_configs(stage)
% Baseline specifications (OIS anchor, sample Mar 2009 - Dec 2021; OIS rates
% and the IT-OIS spread are fitted, fiscal factor = IT purchases / GDP).
%   'baseline'       all four runs below
%   'PEPP_baseline'  PEPP-only fits with a floor on the fiscal elasticity
%   'APP_baseline'   APP-only fit
% Each starts from its own estimate in Output_mat/Baselines.mat, so a rerun
% reproduces it. Any other stage name is passed to the archived search
% stages in Archive/spread_stages (spread_stage_configs_archive.m).
    o = {'anchor', 'OIS', 'base', 'OIS', 'pc', 'pca_est', 'big4', 'Dec-21', 'fiscal', 'ffgdp', 'window', {'Mar2009', 'Dec2021'}, ...
         'gamma', 'all', 'fiscalGammaNonneg', true, 'maxIntensity', 0.10, 'signConstraint', true, ...
         'maxIter', 3000, 'penalty', 1e3, 'target', 'spread'};
    p = [o {'events', {'PEPP'}, 'w', 0.01}];
    a = [o {'events', {'APP'}, 'w', 0.05, 'maxIter', 1500}];
    pepp = { [p {'name', 'PEPP_GQ3_e50_baseline', 'minElasticity', 50, 'x0', baseline_x('PEPP_GQ3_e50_baseline')}], ...  % from GP7
             [p {'name', 'PEPP_GR4_e50_baseline', 'minElasticity', 50, 'x0', baseline_x('PEPP_GR4_e50_baseline')}], ...  % from GQ6
             [p {'name', 'PEPP_GQ6_e40_baseline', 'minElasticity', 40, 'x0', baseline_x('PEPP_GQ6_e40_baseline')}] };   % from GP3
    app  = { [a {'name', 'APP_HO2_baseline', 'x0', baseline_x('APP_HO2_baseline')}] };                                 % from F08
    switch stage
        case 'baseline',      v = [pepp app];
        case 'PEPP_baseline', v = pepp;
        case 'APP_baseline',  v = app;
        otherwise
            addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'Archive', 'spread_stages'));
            C = spread_stage_configs_archive(stage);
            return;
    end
    C = cell(size(v));
    for k = 1:numel(v), C{k} = spread_config(v{k}{:}); end
end

function x = baseline_x(name)
% Estimated parameter vector of a baseline run (Output_mat/Baselines.mat).
    s = load(fullfile('Output_mat', 'Baselines.mat'));
    x = s.Baselines.(name).x;
end
