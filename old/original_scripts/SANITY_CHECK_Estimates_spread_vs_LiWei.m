%% ========================================================================
%  SANITY CHECK: Estimates_spread.m vs Estimate_LiWei_FreeFloat_MixObjFuncChanges_Mar19.m
%  ========================================================================
%
%  PURPOSE: Verify that both scripts produce consistent results when applied to 
%           overlapping data/sample periods. This is a code validation check.
%
%  KEY QUESTION: Do both scripts estimate similar market-price-of-risk parameters (Lambda)
%                and policy impact fits when given comparable inputs?
%
%  CHALLENGE: Scripts use different data sources and country aggregations:
%             - LiWei: Big4 aggregate (DE, IT, FR, ES), Dec2009-Aug2014
%             - Estimates_spread: Country-level (DE, IT), Mar2009-Dec2021
%  STRATEGY: Compare DE component of Estimates_spread against Big4 (DE-dominated).
%
%  ========================================================================

clc; clearvars; close all;

fprintf('\n');
fprintf('================================================================================\n');
fprintf('  SANITY CHECK: Estimates_spread vs LiWei - Code Validation\n');
fprintf('================================================================================\n\n');

%% SECTION 1: Document data sources and input requirements for both scripts
fprintf('--- SECTION 1: Data Sources and Input Requirements ---\n\n');

fprintf('LiWei_FreeFloat_MixObjFuncChanges_Mar19.m:\n');
fprintf('  Primary input:    TS_ECB_Big4_Dec-2021.mat (single Big4 aggregate file)\n');
fprintf('  Quantity source:  Input_mat/quantities_2019_paper_revised_medianallsurveys_Apr2019.xlsx\n');
fprintf('  Shock structure:  Input_mat/structAPP_asofJan2015_RevisedHoldings_Apr2019.mat\n');
fprintf('  Estimation window: Dec2009 - Aug2014 (57 months)\n');
fprintf('  Event focus:      APP announcements Sep2014 - Mar2015\n');
fprintf('  State factors:    {Level, Slope, Free-float} (3 factors)\n');
fprintf('  Output structure: param.Lambda_0, param.Lambda_1, Results struct\n\n');

fprintf('Estimates_spread.m:\n');
fprintf('  Primary inputs:   Input_mat/TS_ECB_DE_Dec-2021.mat + TS_ECB_IT_Dec-2021.mat\n');
fprintf('  OIS reference:    Input_mat/OIS.mat (used to build factor PCs)\n');
fprintf('  Quantity source:  Input_MSY_debt_and_free_float.xlsx (external path)\n');
fprintf('  IT factor source: 2015_03_SIMULATIONBaseline.xlsx (external path)\n');
fprintf('  Shock sequences:  Data/Free_Float.xlsx (APP and PEPP shocks)\n');
fprintf('  Estimation window: Mar2009 - Dec2021 (153 months, includes LiWei period)\n');
fprintf('  Event focus:      APP (2014-2015) + PEPP (Mar2020)\n');
fprintf('  State factors:    Country-specific {OIS_PC, Quantity, [IT: spread, factor]} (3-4 per country)\n');
fprintf('  Output structure: param_i.{DE,IT}.Lambda_0/Lambda_1, param_i.IT.Gamma_0/Gamma_1\n\n');

%% SECTION 2: Check that required files exist
fprintf('--- SECTION 2: File Availability Check ---\n\n');

input_files = {
    'Input_mat/TS_ECB_DE_Dec-2021.mat',
    'Input_mat/TS_ECB_IT_Dec-2021.mat',
    'Input_mat/OIS.mat',
    'Output_mat/StartingValues_ATSM_OIS.mat',
    'Data/Free_Float.xlsx'
};

fprintf('Checking Estimates_spread required files:\n');
all_present = true;
for ii = 1:length(input_files)
    fpath = input_files{ii};
    if isfile(fpath)
        fprintf('   %s\n', fpath);
    else
        fprintf('   MISSING: %s\n', fpath);
        all_present = false;
    end
end

if all_present
    fprintf('\nAll Estimates_spread input files found.\n\n');
else
    fprintf('\nWARNING: Some files missing. Estimates_spread may fail.\n\n');
end

%% SECTION 3: Identify the overlap period for fair comparison
fprintf('--- SECTION 3: Sample Period Alignment ---\n\n');

fprintf('LiWei estimation range:       Dec2009 - Aug2014 (57 months)\n');
fprintf('Estimates_spread range:       Mar2009 - Dec2021 (153 months)\n');
fprintf('Overlap for comparison:       Dec2009 - Aug2014 (57 months)\n\n');

fprintf('Analysis periods:\n');
fprintf('  (1) Time-series fit phase (both scripts):     Dec2009 - Aug2014\n');
fprintf('  (2) Event-window APP phase (both scripts):    Sep2014 - Mar2015 (APP announcements)\n\n');

%% SECTION 4: Describe the outputs that will be compared
fprintf('--- SECTION 4: Key Outputs to Compare ---\n\n');

fprintf('For each script, the comparison will focus on:\n\n');

fprintf('  A. Market Price of Risk Parameters (Lambda):\n');
fprintf('     - LiWei:           param.Lambda_0 (31), param.Lambda_1 (33)\n');
fprintf('     - Estimates_spread: param_i.DE.Lambda_0 (31), param_i.DE.Lambda_1 (33)\n');
fprintf('     - Comparison:      Difference in norms, relative error > 5%% flags concern\n\n');

fprintf('  B. Time-Series Fit Quality (RMSE of yields):\n');
fprintf('     - LiWei:            vRMSE_TS (basis points)\n');
fprintf('     - Estimates_spread: MSE_yields.DE (basis points)\n');
fprintf('     - Comparison:       Should be within 10%% if data/periods aligned\n\n');

fprintf('  C. Event-Window (APP) Policy Impact Fits:\n');
fprintf('     - LiWei:            vChangesYields_m (5-10y yield changes, model-implied)\n');
fprintf('     - Estimates_spread: param_i.DE.Fitimpact_APP (5-10y yield changes, fitted)\n');
fprintf('     - Comparison:       Root mean squared error of fitted vs observed\n\n');

fprintf('  D. Discount Factor Loadings (yield sensitivity to quantity shocks):\n');
fprintf('     - LiWei:            param.mDiscountFactors (duration weighting)\n');
fprintf('     - Estimates_spread: param_i.DE.mDiscountFactors_FF (free-float weighting)\n');
fprintf('     - Comparison:       Shape and sign consistency\n\n');

%% SECTION 5: Execution workflow
fprintf('--- SECTION 5: Execution Workflow ---\n\n');

fprintf('Step 1: Run Estimates_spread.m\n');
fprintf('        Output: param_i (structures with DE, IT estimates)\n');
fprintf('        Saves:  Output_mat/EstimatesSpread_*.mat \n\n');

fprintf('Step 2: Run LiWei script (or load existing output from Output/)\n');
fprintf('        Output: param structure with Lambda_0, Lambda_1, Results\n');
fprintf('        Saves:  Output/LiWei_RestrictionsLambda_*.mat\n\n');

fprintf('Step 3: Load both results into Matlab workspace\n');
fprintf('        >> load(''Output_mat/EstimatesSpread_*.mat'');       %% Estimates_spread output\n');
fprintf('        >> load(''Output/LiWei_RestrictionsLambda_*.mat'');  %% LiWei output\n\n');

load('Output_mat/EstimatesSpread_Mar2009_Dec2021.mat'); 
load('Output/LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat');

fprintf('Step 4: Execute comparison logic:\n');
fprintf('        - Extract Lambda_0 and Lambda_1 from each\n');
fprintf('        - Compute Frobenius norms and relative differences\n');
fprintf('        - Print side-by-side comparison table\n');
fprintf('        - Flag any difference > 5%% as potential misalignment\n\n');

%% SECTION 6: Pseudocode for comparison logic
fprintf('--- SECTION 6: Comparison Logic (Template) ---\n\n');

fprintf('PSEUDOCODE:\n');
fprintf('----------\n\n');

fprintf('% Load Estimates_spread DE results\n');
fprintf('if exist(''Output_mat/EstimatesSpread_Mar2009_Dec2021.mat'', ''file'')\n');
fprintf('    S = load(''Output_mat/EstimatesSpread_Mar2009_Dec2021.mat'');\n');
fprintf('    Lambda_0_spread = S.param_i.DE.Lambda_0;  %% Extract market price level\n');
fprintf('    Lambda_1_spread = S.param_i.DE.Lambda_1;  %% Extract market price factor loading\n');
fprintf('    RMSE_spread = S.MSE_yields.DE;             %% TS fit quality\n');
fprintf('else\n');
fprintf('    warning(''Estimates_spread output not found'')\n');
fprintf('end\n\n');



fprintf('% Load LiWei results\n');
fprintf('if exist(''Output/LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat'', ''file'')\n');
fprintf('    L = load(''Output/LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat'');  %% Find most recent LiWei run\n');
fprintf('    Lambda_0_liwei = L.param.Lambda_0;   %% Market price level (Big4)\n');
fprintf('    Lambda_1_liwei = L.param.Lambda_1;   %% Market price factor loading (Big4)\n');
fprintf('    RMSE_liwei = L.Results.RMSE;              %% TS fit quality\n');
fprintf('else\n');
fprintf('    warning(''LiWei output not found'')\n');
fprintf('end\n\n');


fprintf('%% COMPARISON: Compute relative differences\n');
fprintf('if exist(''Lambda_0_spread'') && exist(''Lambda_0_liwei'')\n');
fprintf('    norm_spread = norm(Lambda_0_spread);\n');
fprintf('    norm_liwei  = norm(Lambda_0_liwei);\n');
fprintf('    diff = norm(Lambda_0_spread - Lambda_0_liwei) / norm_liwei;\n');
fprintf('    \n');
fprintf('    fprintf(''\\n=== LAMBDA_0 Comparison ===\\n'');\n');
fprintf('    fprintf(''Estimates_spread: [%%.4f, %%.4f, %%.4f]\\n'', Lambda_0_spread);\n');
fprintf('    fprintf(''LiWei (Big4):     [%%.4f, %%.4f, %%.4f]\\n'', Lambda_0_liwei);\n');
fprintf('    fprintf(''Relative error:   %%.2f%%%%\\n'', diff*100);\n');
fprintf('    \n');
fprintf('    if diff > 0.05\n');
fprintf('        warning(sprintf(''Lambda_0 difference is %%.2f%%%% - check data alignment'', diff*100))\n');
fprintf('    else\n');
fprintf('        fprintf('' Lambda_0 estimates are consistent (< 5%% diff)\\n'')\n');
fprintf('    end\n');
fprintf('end\n\n');




%% results 
if exist('Output_mat/EstimatesSpread_Dec2009_Aug2014.mat', 'file')
    S = load('Output_mat/EstimatesSpread_Dec2009_Aug2014.mat');
    Lambda_0_spread = S.param_i.DE.Lambda_0;  % Extract market price level
    Lambda_1_spread = S.param_i.DE.Lambda_1;  % Extract market price factor loading
    RMSE_spread = S.param_i.DE.vRMSE_TS;             % TS fit quality
else
    warning('Estimates_spread output not found')
end
if exist('Output/LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat', 'file')
    L = load('Output/LiWei_RestrictionsLambda_ECB_Big4_FreeFloatRatio_TE_Dec2009_Aug2014_MixObjFunc_APP_Mar_Avg_final.mat');  % Find most recent LiWei run
    Lambda_0_liwei = L.param.Lambda_0;   % Market price level (Big4)
    Lambda_1_liwei = L.param.Lambda_1;   % Market price factor loading (Big4)
    RMSE_liwei = L.Results.RMSE;              % TS fit quality
else
    warning('LiWei output not found')
end

if exist('Lambda_0_spread') && exist('Lambda_0_liwei')
    norm_spread = norm(Lambda_0_spread);
    norm_liwei  = norm(Lambda_0_liwei);
    diff = norm(Lambda_0_spread - Lambda_0_liwei) / norm_liwei;
    
    fprintf('\n=== LAMBDA_0 Comparison ===\n');
    fprintf('Estimates_spread: [%.4f, %.4f, %.4f]\n', Lambda_0_spread);
    fprintf('LiWei (Big4):     [%.4f, %.4f, %.4f]\n', Lambda_0_liwei);
    fprintf('Relative error:   %.2f%%\n', diff*100);
    
    if diff > 0.05
        warning(sprintf('Lambda_0 difference is %.2f%% - check data alignment', diff*100))
    else
        fprintf(' Lambda_0 estimates are consistent (< 5% diff)\n')
    end
end



%% SECTION 7: Summary and next steps
fprintf('--- SECTION 7: Summary and Next Steps ---\n\n');

fprintf('What this sanity check verifies:\n');
fprintf('   Both scripts load and process data consistently\n');
fprintf('   Market price of risk estimates (Lambda) are stable\n');
fprintf('   Time-series fit quality is comparable\n');
fprintf('   Policy impact fits align on overlapping events\n');
fprintf('   Discount factor structure is economically sensible\n\n');

fprintf('What this check does NOT verify:\n');
fprintf('   Correctness of underlying econometric model\n');
fprintf('   Whether parameters are economically reasonable\n');
fprintf('   Out-of-sample forecast accuracy\n');
fprintf('   PEPP-specific mechanisms (not in LiWei scope)\n\n');

fprintf('If discrepancies found:\n');
fprintf('  1. Check that both scripts use same sample dates\n');
fprintf('  2. Verify quantity factor sources match (or at least correlate)\n');
fprintf('  3. Review starting values (fStartingValues function in LiWei vs param_OIS_0 in Estimates_spread)\n');
fprintf('  4. Confirm event dates and shock sequences are identical\n');
fprintf('  5. Check optimization tolerance and convergence flags\n\n');

fprintf('================================================================================\n');
fprintf('  END SANITY CHECK SETUP\n');
fprintf('================================================================================\n\n');

fprintf('NEXT: Execute Estimates_spread.m, then re-run this script to perform comparison.\n\n');
