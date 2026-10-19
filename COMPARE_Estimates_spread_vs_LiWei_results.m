%% ========================================================================
%  COMPARISON: Load and compare outputs from Estimates_spread vs LiWei
%  ========================================================================
%
%  PRECONDITION: Both Estimates_spread.m and LiWei script must have been run,
%                producing output files in Output_mat/ and Output/ directories.
%
%  PURPOSE: Load both results, align them to overlapping samples, and compute
%           quantitative measures of agreement on key parameters.
%
%  ========================================================================

clc; clearvars; close all;

fprintf('\n');
fprintf('================================================================================\n');
fprintf('  COMPARISON: Loading and Analyzing Estimates_spread vs LiWei Results\n');
fprintf('================================================================================\n\n');

%% SECTION 1: Load Estimates_spread results
fprintf('--- SECTION 1: Load Estimates_spread Results ---\n\n');

try
    % Try to load the DE estimates
    S = load('Output_mat/EstimatesSpread_Dec2009_Aug2014.mat');
    
    % Check what's in the saved file
    if isfield(S, 'DEvariables')
        param_DE_spread = S.DEvariables.paramDE;
        fprintf(' Loaded Estimates_spread DE parameters from Output_mat/LambdasDE.mat\n');
    elseif isfield(S, 'param_i')
        param_DE_spread = S.param_i.DE;
        fprintf(' Loaded Estimates_spread DE parameters (param_i.DE)\n');
    else
        fprintf('Available fields in saved file:\n');
        disp(fieldnames(S));
        param_DE_spread = [];
    end
    
    % Show what we extracted
    if ~isempty(param_DE_spread)
        fprintf('   - Lambda_0 size: %s\n', mat2str(size(param_DE_spread.Lambda_0)));
        fprintf('   - Lambda_1 size: %s\n', mat2str(size(param_DE_spread.Lambda_1)));
        fprintf('   - K0P, K1P, Omega_square present: %d\n', ...
            isfield(param_DE_spread, 'K0P') && isfield(param_DE_spread, 'K1P'));
    end
    
catch ME
    fprintf(' FAILED to load Estimates_spread results:\n');
    fprintf('   Error: %s\n', ME.message);
    fprintf('   Make sure Estimates_spread.m has been run and Output_mat/LambdasDE.mat exists.\n\n');
    param_DE_spread = [];
end

fprintf('\n');

%% SECTION 2: Load LiWei results
fprintf('--- SECTION 2: Load LiWei Results ---\n\n');

% Find the most recent LiWei output file
liwei_dir = 'Output/';
liwei_pattern = 'LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat';  % Targets Mar averaging version

try
    % List all LiWei output files
    d = dir(fullfile(liwei_dir, liwei_pattern));
    
    if ~isempty(d)
        % Sort by date modified, take most recent
        [~, idx] = sort([d.datenum], 'descend');
        latest_file = d(idx(1)).name;
        liwei_path = fullfile(liwei_dir, latest_file);
        
        L = load(liwei_path);
        
        fprintf(' Loaded LiWei results from: %s\n', latest_file);
        fprintf('   Modified: %s\n', datestr(d(idx(1)).datenum));
        
        % Extract parameters
        param_liwei = L.param;
        
        % Show what we extracted
        fprintf('   - Lambda_0 size: %s\n', mat2str(size(param_liwei.Lambda_0)));
        fprintf('   - Lambda_1 size: %s\n', mat2str(size(param_liwei.Lambda_1)));
        fprintf('   - K0P, K1P, Omega_square present: %d\n', ...
            isfield(param_liwei, 'K0P') && isfield(param_liwei, 'K1P'));
        fprintf('   - Results structure present: %d\n', isfield(L, 'Results'));
        
    else
        fprintf(' No LiWei output files found matching: %s\n', liwei_pattern);
        fprintf('   Files in %s:\n', liwei_dir);
        d_all = dir(liwei_dir);
        for ii = 1:length(d_all)
            if d_all(ii).isdir == 0
                fprintf('     - %s\n', d_all(ii).name);
            end
        end
        param_liwei = [];
    end
    
catch ME
    fprintf(' FAILED to load LiWei results:\n');
    fprintf('   Error: %s\n', ME.message);
    param_liwei = [];
end

fprintf('\n');

%% SECTION 3: Check that both results were loaded successfully
fprintf('--- SECTION 3: Readiness Check ---\n\n');

if ~isempty(param_DE_spread) && ~isempty(param_liwei)
    fprintf(' Both results loaded successfully. Proceeding with comparison.\n\n');
    ready = true;
elseif isempty(param_DE_spread)
    fprintf(' Missing Estimates_spread results. Cannot proceed.\n\n');
    ready = false;
elseif isempty(param_liwei)
    fprintf(' Missing LiWei results. Cannot proceed.\n\n');
    ready = false;
end

if ~ready
    fprintf('ABORT: Please run both scripts first:\n');
    fprintf('  1. Estimates_spread.m (with Output_mat/ directory)\n');
    fprintf('  2. Estimate_LiWei_FreeFloat_MixObjFuncChanges_Mar19.m (with Output/ directory)\n\n');
    return;
end

%% SECTION 4: Compare Lambda (Market Price of Risk) Parameters
fprintf('--- SECTION 4: Lambda_0 Comparison (Market Price of Risk - Level) ---\n\n');

Lambda_0_spread = param_DE_spread.Lambda_0;
Lambda_0_liwei  = param_liwei.Lambda_0;

% Compute norms and differences
norm_spread_0 = norm(Lambda_0_spread);
norm_liwei_0  = norm(Lambda_0_liwei);
diff_0        = Lambda_0_spread - Lambda_0_liwei;
rel_error_0   = norm(diff_0) / norm_liwei_0;

fprintf('Estimates_spread (DE component):\n');
fprintf('  Lambda_0 = [%.6f; %.6f; %.6f]\n', Lambda_0_spread(1), Lambda_0_spread(2), Lambda_0_spread(3));
fprintf('  Frobenius norm: %.6f\n\n', norm_spread_0);

fprintf('LiWei (Big4 aggregate):\n');
fprintf('  Lambda_0 = [%.6f; %.6f; %.6f]\n', Lambda_0_liwei(1), Lambda_0_liwei(2), Lambda_0_liwei(3));
fprintf('  Frobenius norm: %.6f\n\n', norm_liwei_0);

fprintf('Difference:\n');
fprintf('  diff = [%.6f; %.6f; %.6f]\n', diff_0(1), diff_0(2), diff_0(3));
fprintf('  Relative error: %.4f (%.2f%%)\n\n', rel_error_0, rel_error_0*100);

% Alert if difference is large
if rel_error_0 > 0.10
    fprintf('   WARNING: Relative error > 10%% - possible data/method mismatch\n\n');
elseif rel_error_0 > 0.05
    fprintf('   NOTE: Relative error between 5-10%% - may be due to:\n');
    fprintf('    - Different data sources (Big4 vs country-level)\n');
    fprintf('    - Different quantity factor definitions\n');
    fprintf('    - Sample window differences\n\n');
else
    fprintf('   GOOD: Relative error < 5%% - estimates are consistent\n\n');
end

%% SECTION 5: Compare Lambda_1 (Factor Loadings)
fprintf('--- SECTION 5: Lambda_1 Comparison (Market Price Factor Loadings) ---\n\n');

Lambda_1_spread = param_DE_spread.Lambda_1;
Lambda_1_liwei  = param_liwei.Lambda_1;

fprintf('Estimates_spread (DE component):\n');
fprintf('  Lambda_1 size: %s\n', mat2str(size(Lambda_1_spread)));
fprintf('  Lambda_1 =\n');
disp(Lambda_1_spread);

fprintf('\nLiWei (Big4 aggregate):\n');
fprintf('  Lambda_1 size: %s\n', mat2str(size(Lambda_1_liwei)));
fprintf('  Lambda_1 =\n');
disp(Lambda_1_liwei);

% Frobenius norm comparison
norm_spread_1 = norm(Lambda_1_spread, 'fro');
norm_liwei_1  = norm(Lambda_1_liwei, 'fro');
diff_1        = Lambda_1_spread - Lambda_1_liwei;
rel_error_1   = norm(diff_1, 'fro') / norm_liwei_1;

fprintf('Frobenius norm comparison:\n');
fprintf('  Estimates_spread: %.6f\n', norm_spread_1);
fprintf('  LiWei:            %.6f\n', norm_liwei_1);
fprintf('  Relative error:   %.4f (%.2f%%)\n\n', rel_error_1, rel_error_1*100);

if rel_error_1 > 0.10
    fprintf('   WARNING: Lambda_1 factor loadings differ by > 10%%\n\n');
elseif rel_error_1 > 0.05
    fprintf('   NOTE: Lambda_1 factor loadings differ by 5-10%%\n\n');
else
    fprintf('   GOOD: Lambda_1 factor loadings are consistent (< 5%% diff)\n\n');
end

%% SECTION 6: Time-Series Fit Quality
fprintf('--- SECTION 6: Time-Series Fit Quality (RMSE) ---\n\n');

if isfield(param_DE_spread, 'vRMSE_TS')
    rmse_spread = param_DE_spread.vRMSE_TS;
    fprintf('Estimates_spread TS RMSE: %.4f bps\n', rmse_spread);
else
    fprintf('Estimates_spread TS RMSE: Not available in output\n');
    rmse_spread = NaN;
end

if isfield(L, 'Results')
    rmse_liwei = L.Results.RMSE;
    fprintf('LiWei TS RMSE:            %.4f bps\n', rmse_liwei);
else
    fprintf('LiWei TS RMSE:            Not available in output\n');
    rmse_liwei = NaN;
end

%if ~isnan(rmse_spread) && ~isnan(rmse_liwei)
    rmse_diff = abs(rmse_spread - rmse_liwei) ./ rmse_liwei;
    fprintf('\nRelative difference: %.4f (%.2f%%)\n', rmse_diff, rmse_diff*100);
    if rmse_diff > 0.10
        fprintf(' TS fit quality differs significantly (possible data source mismatch)\n');
    elseif rmse_diff > 0.05
        fprintf(' TS fit quality differs moderately (check data alignment)\n');
    else
        fprintf(' TS fit quality is similar\n');
    end
%end

fprintf('\n');

%% SECTION 7: Policy Impact Fits (APP event)
fprintf('--- SECTION 7: Policy Impact Fit Comparison (APP Event) ---\n\n');

fprintf('NOTE: LiWei outputs fitted vs observed APP yield changes.\n');
fprintf('      Estimates_spread outputs fitted impacts per maturity.\n');
fprintf('      Direct comparison requires loading full Results structures.\n\n');

if isfield(L, 'Results') && isfield(L.Results, 'vChangesYields_m')
    app_fit_liwei = L.Results.vChangesYields_m*100;
    fprintf('LiWei APP fitted impacts (maturities 5-10y): ');
    fprintf('[%.4f ', app_fit_liwei);
    fprintf('] (bps)\n\n');
else
    fprintf('LiWei APP fitted impacts: Not readily accessible\n\n');
end

fprintf('Estimates_spread stores impacts in param_i.DE.Fitimpact_APP\n');
fprintf('(requires loading and inspecting param_i structure)\n\n');

app_fit_spread=S.param_i.DE.Fitimpact_APP(:,5:10)  ;
fprintf('EsSpreads APP fitted impacts (maturities 5-10y): ');
    fprintf('[%.4f ', app_fit_spread);
    fprintf('] (bps)\n\n');

%% SECTION 8: Summary and Interpretation
fprintf('--- SECTION 8: Summary and Interpretation ---\n\n');

fprintf('Key findings:\n');
fprintf('  Lambda_0 relative error:  %.2f%%%%\n', rel_error_0*100);
fprintf('  Lambda_1 relative error:  %.2f%%%%\n', rel_error_1*100);

fprintf('\nInterpretation:\n');

if rel_error_0 < 0.05 && rel_error_1 < 0.05
    fprintf('   PASS: Both scripts produce consistent market-price-of-risk estimates.\n');
    fprintf('    This suggests the model implementation is robust and data is aligned.\n');
elseif rel_error_0 < 0.10 && rel_error_1 < 0.10
    fprintf('   CAUTIOUS PASS: Estimates differ by 5-10%%, likely due to:\n');
    fprintf('    - Big4 vs country-level aggregation differences\n');
    fprintf('    - Different quantity factor sources or definitions\n');
    fprintf('    - Rounding or convergence tolerances\n');
    fprintf('    Recommend checking data source alignment.\n');
else
    fprintf('   FAIL: Large discrepancies suggest potential issues:\n');
    fprintf('    - Data loading errors or misalignment\n');
    fprintf('    - Optimization convergence problems\n');
    fprintf('    - Underlying model structure differences\n');
    fprintf('    Recommend detailed debugging of both scripts.\n');
end

fprintf('\nNext steps:\n');
fprintf('  1. If PASS: Estimates_spread is validated for production use\n');
fprintf('  2. If CAUTIOUS PASS: Document the source of discrepancy and proceed cautiously\n');
fprintf('  3. If FAIL: Debug data loading, optimization, and model specification\n\n');

fprintf('================================================================================\n');
fprintf('  END COMPARISON\n');
fprintf('================================================================================\n\n');
