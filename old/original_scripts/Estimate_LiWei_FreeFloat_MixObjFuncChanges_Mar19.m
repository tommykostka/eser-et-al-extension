
    % Clearing memory and graphical interface
    clc;
    clearvars;
    close all;
 
    sOutputDirectory = 'Output\LiWei_FreeFloat_NewSpecifications\'; 
    
    addpath(genpath([cd '\']));
   

%%  Estimation specifications
    
    sStartSample_TS_Estimation  = 'Dec2009'; %1999, 2014
    sEndSample_TS_Estimation    = 'Aug2014'; %  Jul2014  DEC2017,  2012, 2017
%     sEndSample_TS_Estimation    = 'Jun2018'; %  Jul2014  DEC2017,  2012, 2017
    sEndInSample                = 'Mar2015';  
    
    sEndSample_TS_Analysis      = 'Jun2018'; %  Jul2014  DEC2017,  2012, 2017
    
    % Specify specifications
    bJan = 0;
    if ~bJan
        bMar = 1;
    else
        bMar = 0;
    end
    bControlledRegressions  = 0;
    bStandardRegressions    = 0;
    bAverageBothRegressions = 1;
   
    % Specify the weight applied to the average RMSE of fitting yields levels
    w                       = 0.50; 
%     w                       = 0.25; 
%     w                       = 0.75; 
    
    
%%  Load the full dataset for estimation of the model

    sEndSampleData = 'Jul-2018';

    sCountry    = 'ECB_Big4';
    
    load(['TS_' sCountry '_' sEndSampleData '.mat']);
    
%% Load structure of results of affine models without quantities in, as starting values

    % Load results of a 2-factor model - only level+slope (for deriving starting values)
    load('Estimation_ATSM2_PerfPriced_MonthlyDec2009_Aug2014_Mat1_6m.mat');
    Results_StartValues = Results;
    clear Results EstimationData
    
%% Determine the end of the sample for the estimation of the time-series part of the objective function
     
    indexStartSample                = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');

    indexEndSample_Estimation       = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
    indexEndSample_Analysis         = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sEndSample_TS_Analysis), 1, 'last');
    indexEndInSample                = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sEndInSample), 1, 'last');
    
    T_fullSample                    = indexEndSample_Analysis - indexStartSample + 1;
    T_eventwindow                   = indexEndInSample - indexEndSample_Estimation + 1;
    
    vMaturities_analysis            = [12 24 36 48 60 72 84 96 108 120]; 
    vMaturities_regressionanalysis  = [60 72 84 96 108 120]; 
    
%     vMaturities_regressionanalysis  = vMaturities_analysis; 
    
%%  Inputs for the second part of the objective function - matching the change in yields over an event window
    
    vDates_ZeroMTS           = Data.nom.d.dates;
%     ZeroYields_MTS.Big4      = yields.d.nom(:,vMaturities_regressionanalysis);
    ZeroYields_MTS.Big4      = yields.d.nom(:,vMaturities_analysis);
    
    % Specify the window for the regression analysis
    sDateStart_RegAnalysis  = '31/12/2013';
    sDateEnd_RegAnalysis    = '31/03/2015';
    
    indexDateInitial        = find(strcmp(cellstr(datestr(vDates_ZeroMTS, 'dd/mm/yyyy')), sDateStart_RegAnalysis));
    indexDateFinal          = find(strcmp(cellstr(datestr(vDates_ZeroMTS, 'dd/mm/yyyy')), sDateEnd_RegAnalysis));
    vDates_Selection        = vDates_ZeroMTS(indexDateInitial+1:indexDateFinal);
    
    % Select the yields and compute changes in yields
    ZeroYields_MTS.ChangesBig4       = diff(ZeroYields_MTS.Big4(indexDateInitial:indexDateFinal,:)); 
    
    
    % Specify the event dates 
    if bJan
        vDatesEventDates    = {'12/09/2014', '24/09/2014', '25/09/2014', '02/10/2014', '10/10/2014', '24/10/2014', '06/11/2014', '17/11/2014', ...
            '21/11/2014', '27/11/2014', '04/12/2014', '02/01/2015', '08/01/2015', '14/01/2015', '22/01/2015'};
    end
    if bMar
        vDatesEventDates    = {'04/09/2014', '12/09/2014', '24/09/2014', '25/09/2014', '02/10/2014', '10/10/2014', '24/10/2014', '06/11/2014', '17/11/2014', ...
            '21/11/2014', '27/11/2014', '04/12/2014', '02/01/2015', '08/01/2015', '14/01/2015', '22/01/2015', '05/03/2015'};
    end
 
    X_Dummy             = zeros(length(vDates_Selection),length(vDatesEventDates));
    
    for iEventDate = 1:length(vDatesEventDates)
        
        index = find(strcmp(cellstr(datestr(vDates_Selection, 'dd/mm/yyyy')), vDatesEventDates(iEventDate)));
        X_Dummy(index, iEventDate) = 1;
        
    end
    
    vindices_EventDates      = arrayfun(@(x) find(strcmp(cellstr(datestr(vDates_Selection, 'dd/mm/yyyy')), x)), vDatesEventDates, 'UniformOutput', false);
    
    % Not needed, but just for reference
%     sDateStart_AnticipateAPP  = '04/09/2014'; % alternative dates 22/08/2014
% %     sDateEnd_AnticipateAPP    = '22/01/2015'; % alternative dates 23/01/2015
%     sDateEnd_AnticipateAPP    = '05/03/2015'; % alternative dates 23/01/2015
%     
%     indexDate_Start         = find(strcmp(cellstr(datestr(vDates_ZeroMTS, 'dd/mm/yyyy')), sDateStart_AnticipateAPP));
%     indexDate_End           = find(strcmp(cellstr(datestr(vDates_ZeroMTS, 'dd/mm/yyyy')), sDateEnd_AnticipateAPP));
%     
%     vChangesYields_APPWindow    = (ZeroYields_MTS.Big4(indexDate_End,:) - ZeroYields_MTS.Big4(indexDate_Start,:))*10000;
%     vChangesYields_APPWindow_2d = (ZeroYields_MTS.Big4(indexDate_End+1,:) - ZeroYields_MTS.Big4(indexDate_Start,:))*10000;

%     vDates_Selection(1) = datenum('03-Dec-2015', 'dd-mmm-yyyy');
%     vDates_Selection(2) = datenum('10-Mar-2016', 'dd-mmm-yyyy');
%     vDates_Selection(3) = datenum('08-Dec-2016', 'dd-mmm-yyyy');
%     vDates_Selection(4) = datenum('14-Jun-2018', 'dd-mmm-yyyy');

    % Read in the macroeconomic surprises
    % Find the common dates 
    load('Input_mat/Surprise_Data_untilMar2015.mat');
    vDates_MacroSurprises       = Surprise_Data(:,1)+693960;
    mMacroSurprises             = Surprise_Data(ismember(vDates_MacroSurprises, vDates_Selection),2:end);
    mIndicesMacroSurprises      = ~isnan(mMacroSurprises);
    mMacroSurprises_zeros       = zeros(size(mIndicesMacroSurprises,1), size(mIndicesMacroSurprises,2));
    mMacroSurprises_zeros(mIndicesMacroSurprises) = mMacroSurprises(mIndicesMacroSurprises);
    
    % Conduct regressions
    Y               = ZeroYields_MTS.ChangesBig4(2:end,:);
    X_controlled    = [X_Dummy(2:end,:) X_Dummy(1:end-1,:) mMacroSurprises_zeros(2:end,:)];    
    for imat = 1:length(vMaturities_analysis)
        
        mBeta_controlled(:,imat)            = regress(Y(:,imat), X_controlled);
        vChangesYields_Controlled(1,imat)   = sum(mBeta_controlled(1:2*length(vindices_EventDates),imat));
            
    end    
    
    X_standard      = [X_Dummy(2:end,:) X_Dummy(1:end-1,:)];    
      
    for imat = 1:length(vMaturities_analysis)

        Beta_standard                       = regress(Y(:,imat), X_standard);
        vChangesYields_Standard(1,imat)     = sum(Beta_standard(1:2*length(vindices_EventDates)));

    end  
        
    if bControlledRegressions
       vChangesYields = vChangesYields_Controlled;
    end
    
    if bStandardRegressions
       vChangesYields = vChangesYields_Standard;
    end
    
    if bAverageBothRegressions
        vChangesYields = (vChangesYields_Controlled + vChangesYields_Standard)/2;
    end
    
    % Restrict actually only to the ones as of 5y
    vChangesYields_all  = vChangesYields;
    vChangesYields      = vChangesYields(5:10);
    
    
    % Add the 1m change
%     vChangesYields = [0 vChangesYields];
%     vMaturities_regressionanalysis = [6 vMaturities_regressionanalysis];
    
% %%  Inputs for the second part of the objective function - matching the change in yields over an event window (requires a u-sequence)
% 
%     % Identifying the start and end date of the event window
%     indexDateInitial        = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), '04/09/2014'));
%     indexDateFinal          = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), '22/01/2015'));
%     vChangesYields_OLD          = yields.d.nom(indexDateFinal, vMaturities_regressionanalysis) - yields.d.nom(indexDateInitial, vMaturities_regressionanalysis);
% 
%     
% % ... added to possibly adjust for the impact of the DFR cut on 4 Sept 2014, 1 July 2018, KN    
% % adjust4DFRcut = 0  -> no adjustment is made
% % adjust4DFRcut = 1  -> adjustment is made for the DFR cut
% %
%     if (b_adjust4DFRcut == 1)
%         index_DFRcutInitial   = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), '03/09/2014')); 
%         index_DFRcutFinal     = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), '04/09/2014'));
%         vChangesYields_DRFcut = yields.d.nom(index_DFRcutFinal, vMaturities_estimation) - yields.d.nom(index_DFRcutInitial, vMaturities_estimation);
%         vChangesYields        = vChangesYields - vChangesYields_DRFcut;
%     end
%     
%     % Import the JSZ daily fitted, EC and TP
%     sFileTitle                  = 'yields_OIS_decomp_JSZ.xlsx';
%     JSZ                         = fInputJSZ(sFileTitle);
%     % select the EC over the event window
%     indexDateInitial_JSZ        = find(strcmp(cellstr(datestr(JSZ.Dates, 'dd/mm/yyyy')), sDateStart_EventWindow));
%     indexDateFinal_JSZ          = find(strcmp(cellstr(datestr(JSZ.Dates, 'dd/mm/yyyy')), sDateEnd_EventWindow));
%     vChanges_JSZ_EC             = JSZ.EC(indexDateFinal_JSZ,2:end) - JSZ.EC(indexDateInitial_JSZ,2:end); 
%     
%     % adjust the changes in yields with the changes in EC
%     if b_adjustJSZEC
%         vChangesYields              = vChangesYields - vChanges_JSZ_EC;
%     end
    
%%  Setup format of model/data
    
    EstimationData.mats_TSfit   = vMaturities_analysis/12;
    EstimationData.mats_YCfit   = vMaturities_regressionanalysis/12;
    
    EstimationData.Yields           = yields.m.nom(indexStartSample:indexEndSample_Estimation, vMaturities_analysis);
    EstimationData.YieldsInSample   = yields.m.nom(indexStartSample:indexEndInSample, vMaturities_analysis);
    
    EstimationData.dt           = 1/12; % monthly data
    EstimationData.dates        = Data.nom.m.dates(indexStartSample:indexEndSample_Estimation,1);                       % added KN: 17/04/2018
    EstimationData.dates_fullsample = Data.nom.m.dates(indexStartSample:indexEndSample_Analysis,1);                       % added KN: 17/04/2018
    
    mYields_FullSample          = yields.m.nom(indexStartSample:indexEndSample_Analysis, vMaturities_analysis);
    % Specify how many principal components are used in the estimation 
    EstimationData.nPCs         = 2;
    
%     [V, E] = eig(cov(EstimationData.Yields));
%     [~, idx]=sort(diag(E), 'descend');
%     W = V(:,idx(1:3))';

    [T,J]                       = size(EstimationData.Yields);
    [W, LATENT, EXPLAINED]      = pcacov(cov(EstimationData.Yields)); % loading matrix
    EstimationData.W            = W(:,1:EstimationData.nPCs)';  % nPCs*J
    
%     close all
%     plot(EstimationData.W')
%     legend('PC1', 'PC2'); xlabel('maturities')
%     
    
    % OPPOSITE OF PC2
    EstimationData.W(2,:)       = -EstimationData.W(2,:);
    
    PC                          = EstimationData.Yields*EstimationData.W';
    PC_FullSample               = mYields_FullSample*EstimationData.W';
    N                           = EstimationData.nPCs+1;
 
%% Read in the various quantity measures - Holdings measure

% ... loading the updated free-float series: 1 July 2018, KN
    [Data_Quantity, Header]                 = xlsread('data\quantities_2019_paper_revised_medianallsurveys_Apr2019.xlsx', 'free-float');
    
    % Dates of availability of the quantity variable in the vector of
    % monthly dates of availability of yields
    Date_Quantity                           = datenum(Header(5:end,1),'dd/mm/yyyy');
    indexQuantity_MonthlyData               = cell2mat(arrayfun(@(x) find(Data.nom.m.dates_endofmonth(indexStartSample:indexEndSample_Estimation) == x), Date_Quantity, 'UniformOutput' , false));
    indexQuantity_MonthlyData_FullAnalysis  = cell2mat(arrayfun(@(x) find(Data.nom.m.dates_endofmonth(indexStartSample:indexEndSample_Analysis) == x), Date_Quantity, 'UniformOutput' , false));

    vQuantity_FullSample        = Data_Quantity(indexQuantity_MonthlyData_FullAnalysis,3)/100; % to make it in decimals (takes the 3th column - TE = 10Y equivalent, latest version) 
    sQuantity                   = 'FreeFloatRatio_TE';
    
    % For allocating the quantity variable to monthly values we will take the end-of-period of survey

    EstimationData.vQuantity    = vQuantity_FullSample(1:T); 

    mX                          = [PC  EstimationData.vQuantity];
    mX_FullSample               = [PC_FullSample vQuantity_FullSample];

%% OLS regression for the short rate on the level and slope factors

    vShortRate          = yields.m.nom(indexStartSample:indexEndSample_Estimation, 1);
        
    % these coefficients are in annualized terms
%     [B,BINT]                    = regress(vShortRate, [ones(T,1)  PC]);
    [B,SIGMA,RESID,VARPARAM] = mvregress([ones(T,1)  PC], vShortRate);
    
    param.rho0          = B(1);
    param.rho1          = [B(2:end); 0]; % restriction that the quantity variable doesn't enter the short rate equation
    vShortRate_m        = param.rho0 + PC * param.rho1(1:2);
    
    Theta_mean          = [param.rho0 ; param.rho1(1:2)];
    Theta_variance      = diag(VARPARAM);
    
%% VAR for the P-measure (possibly with restrictions)

    % For the moment allow for full interaction, but we can later restrict The level can be affected only by the lagged level and lagged slope
    
%     [B_level, ~, Residual_level]           = regress(PC(2:end,1), [ones(T-1,1)  PC(1:end-1,:)]);
    [B_level,~,Residual_level,VARPARAM_Level]             = mvregress([ones(T-1,1)  PC(1:end-1,:)], PC(2:end,1));

%     [B_slope, ~, Residual_slope]           = regress(PC(2:end,2), [ones(T-1,1)  PC(1:end-1,:)]);
    [B_slope,~,Residual_slope,VARPARAM_Slope]             = mvregress([ones(T-1,1)  PC(1:end-1,:)], PC(2:end,2));
    % Alternative, for variance - covariance matrix of parameters
    [BETA,~,RESID,VARPARAM] = mvregress([ones(T-1,1)  PC(1:end-1,:)], PC(2:end,:));
    
%     [B_quantity, ~, Residual_quantity]     = regress(EstimationData.vQuantity(2:end), [ones(T-1,1) EstimationData.vQuantity(1:end-1,:)]); %
    [B_quantity,SIGMA,Residual_quantity,VARPARAM_Quantity]             = mvregress([ones(T-1,1) EstimationData.vQuantity(1:end-1,:)], EstimationData.vQuantity(2:end));
    
    param.K0P       = [B_level(1); B_slope(1); B_quantity(1)];
    
    Theta_mean      = [Theta_mean; param.K0P];
    Theta_mean      = [Theta_mean; B_level(2:end); B_slope(2:end); B_quantity(2:end)];
    Theta_variance  = [Theta_variance; VARPARAM_Level(1); VARPARAM_Slope(1); VARPARAM_Quantity(1);...
        diag(VARPARAM_Level(2:end,2:end)); diag(VARPARAM_Slope(2:end,2:end)); diag(VARPARAM_Quantity(2:end,2:end))];
        
%     if B_quantity(2:end)< 1
        param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 B_quantity(2:end)'];
%     else % if non-stationary
%         % Fix the autoregression parameter
%         param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 0.99];
%         % Fix consequently also the intercept
%         param.K0P(3)          =  mean(EstimationData.vQuantity) * 0.01;% mean(EstimationData.vQuantity(2:end) - 0.99 * EstimationData.vQuantity(1:end-1,:));
%         Residual_quantity     =  EstimationData.vQuantity(2:end) - (ones(T-1,1) * param.K0P(3) + EstimationData.vQuantity(1:end-1,:) * 0.99); 
%     end
    
    param.K1P               = param.K1P_level - eye(N);

    param.Residual_level    = Residual_level;
    param.Residual_slope    = Residual_slope;
    param.Residual_quantity = Residual_quantity;
    
    mResiduals              = [Residual_level Residual_slope Residual_quantity];
    param.Omega_square      = 1/(T-1) * mResiduals.' * mResiduals;
    param.Omega_chol        = chol(param.Omega_square, 'lower');  % the Cholesky decomposition of the variance covariance matrix
    
    inds                    = find(tril(ones(N)));
    Theta_mean              = [Theta_mean; param.Omega_chol(inds)];
    Theta_variance          = [Theta_variance; NaN(length(inds),1)];
    
%     L0          = chol(Sigma_cP0, 'lower');
%     cholSigma_cP0 = L0(inds);
%     
%     inds        = find(tril(ones(N)));
%     L(inds)     = cholSigma_cP;
%     L           = reshape(L, [N,N]);
%     Sigma_cP    = L*L';

    % Compare model-implied unconditional mean of factors with sample mean
%     vLongRunMeanFactors     = (-param.K1P)\param.K0P; % alternatively mean([PC  EstimationData.vQuantity])
%     % Faster alternative for a full VAR
%     [Gamma_hat, alpha_hat, Omega_hat_0]   = regressVAR([PC  EstimationData.vQuantity]);
    
%%  Initial estimates for the market price of risk parameters
    
   structParam0 = fStartingValues(Results_StartValues, param, EstimationData);
    
    
%% Extract the u-sequence

    % Extract the u-sequence
    % New version
%     load('structAPP_Mar2015_RevisedHoldings.mat');
    load('structAPP_asofJan2015_RevisedHoldings_Apr2019.mat');
    
    date_vintage_estimation     = datenum('05-Mar-2015', 'dd-mmm-yyyy');
    index_vintage               = find(cell2mat({structAPP.Date_num}')==date_vintage_estimation);
    index_StartSequence         = find(vDates_structAPP==eomdate(date_vintage_estimation));
       
    uSequence_Event_FreeFloat   = structAPP(index_vintage).freefloat.GovC(index_StartSequence:end);
    % Calculate the number of months between the date when the expectations
    % are inferred and the month as of which the revisions actually start
    
    uSequence_Event = [zeros(length(uSequence_Event_FreeFloat),2), uSequence_Event_FreeFloat];
    
    
%%  Dual optimization problem
    
    % Specify the objective function
    obj_fun         = @(vLambda) fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields, uSequence_Event, EstimationData, param, vLambda);
    
    vLambda0        = [structParam0.Lambda_0(1:N-1); vec([structParam0.Lambda_1(1:2,:) [0.11; -0.02]])];

    [MSE_fun_0, Fy, Fdy]  = fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields, uSequence_Event, EstimationData, param, vLambda0);   % KN added extra output July 2018 
    % Seting up optimization function
    options         = optimset('display', 'off', 'TolX', 10^-25, 'TolFun',10^-25);
    LB              = -100*ones(length(vLambda0),1);
    UB              = 100*ones(length(vLambda0),1);
    
    % Start with the fmincon and then run also a fminunc (which also gives accurate Gradient and Hessian)
    [vLambda_dualobj, fval]  = fmincon(@(Z) obj_fun(Z), vLambda0, [], [], [], [], LB,UB,[],options);
    [vLambda_dualobj,FVAL_fminunc,EXITFLAG_fminunc,OUTPUT_fminunc,GRAD_fminunc,HESSIAN_fminunc] = fminunc(@(Z) obj_fun(Z), vLambda_dualobj, options);

%%  Alternative single-objected optimization problem 

%     obj_fun         = @(vLambda) fRMSE_pricingyields(mX, EstimationData, param, vLambda);
%     options         = optimset('display', 'off', 'TolX', 10^-25, 'TolFun',10^-25);
%     LB              = -100*ones(length(vLambda0),1);
%     UB              = 100*ones(length(vLambda0),1);
%     
%     % Start with the fmincon and then run also a fminunc (which also gives accurate Gradient and Hessian)
%     [vLambda_dualobj, fval]  = fmincon(@(Z) obj_fun(Z), vLambda0, [], [], [], [], LB,UB,[],options);
%     [vLambda_dualobj,FVAL_fminunc,EXITFLAG_fminunc,OUTPUT_fminunc,GRAD_fminunc,HESSIAN_fminunc] = fminunc(@(Z) obj_fun(Z), vLambda_dualobj, options);

    
    Theta_mean      = [Theta_mean; vLambda_dualobj];
    Theta_variance  = [Theta_variance; NaN(length(vLambda_dualobj),1)];
    
%     mInformationMatrix_v2      = GRAD_fminunc * GRAD_fminunc';    
%     vStdErrors_sandwisch_v2   = sqrt(diag(inv(HESSIAN_fminunc) * mInformationMatrix_v2 * inv(HESSIAN_fminunc)));
% 
%     % Standard errors
%     
%     tmpfun                  = @(vLambda_dualobj)(fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields, uSequence_Event, EstimationData, param, vLambda_dualobj));
%     score                   = gradest(obj_fun, vLambda_dualobj); 
%     mInformationMatrix      = score' * score; 
%     H                       = fHessian(tmpfun,vLambda_dualobj);
%     invH                    = inv(H);
%     Variance_Robust         = invH * mInformationMatrix * invH;
%     vStdErrors_sandwisch   = sqrt(diag(Variance_Robust));
%     
%     Variance                        = inv(mInformationMatrix);
%     vStdErrors_paramJSZ_asymptotic  = sqrt(diag(Variance));
%     
%     mInformationMatrix_v2      = GRAD' * GRAD;    
%     vStdErrors_sandwisch_v2   = sqrt(diag(inv(HESSIAN) * mInformationMatrix_v2 * inv(HESSIAN)'));

    % Check
    [MSE_fun, Fy, Fdy, AX, BX]  = fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields, uSequence_Event, EstimationData, param, vLambda_dualobj);
      
%    
% %% Standard errors
%     
% %     vFixedSteps             = 0.01*vLambda_dualobj; 
%     vFixedSteps             = 0.0001*ones(length(vLambda_dualobj),1); 
%     
%         
%     score                   = gradest_FixedStep(tmpfun,vLambda_dualobj, vFixedSteps); 
%     score_woFixedSteps      = gradest(tmpfun,vLambda_dualobj); 
%    
% %     Variance                = inv(mInformationMatrix);
% %     vStdErrors_asymptotic   = sqrt(diag(Variance));
    
    
%% Compute final results

    param.Lambda_0         = [vLambda_dualobj(1:N-1); 0];
    param.Lambda_1         = [reshape(vLambda_dualobj(N:end), N-1, N); zeros(1,N)];
    
    param.K0Q              = param.K0P - param.Omega_chol * param.Lambda_0; 
    param.K1Q              = param.K1P - param.Omega_chol * param.Lambda_1; 
    param.K1Q_level        = param.K1Q + eye(N);   % KN added
    
   
    % Store also the vectorized parameter estimates
    param.Theta_mean        = Theta_mean;
    param.Theta_variance    = Theta_variance;
    param.Theta_Explanation = {'rho0', 'rho_1L', 'rho_1S','K0P_L','K0P_S','K0P_Q','K1P_LL','K1P_LS','K1P_SL','K1P_SS','K1P_QQ','Omega_LL','Omega_chol_SL',...
        'Omega_chol_SS','Omega_chol_QL','Omega_chol_QS','Omega_chol_QQ','Lambda0_L','Lambda0_S','Lambda1_LL','Lambda1_SL','Lambda1_LS','Lambda1_LL','Lambda1_LQ','Lambda1_SQ'}
    
   
    [BX_estimated, AX_estimated, B_price, A_price]  = gaussianDiscreteYieldLoadingsRecurrence(EstimationData.mats_TSfit / EstimationData.dt, param.K0Q, param.K1Q, param.Omega_square, ...
                                            param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);

    % Computing the fit of the yields over the TS window 
    yields_m                = ones(T,1)*AX_estimated + mX * BX_estimated; % (T+1)*J, model-implied yields
    yields_m_FullSample     = ones(T_fullSample,1)*AX_estimated + mX_FullSample * BX_estimated; % (T+1)*J, model-implied yields
    
    % Plot Contribution of the 3rd factor
    mContribution_Q          = mX_FullSample(:,3) * BX_estimated(3,:);
    mContribution_LS         = mX_FullSample(:,1:2) * BX_estimated(1:2,:);
    
    
    plot([yields_m_FullSample(:,end) mContribution_Q(:,end)]*100)
    
    % Computing the fit of the yields over the full sample available over
    % which the free float is available
    vRMSE_TS            = sqrt(mean(power(EstimationData.Yields - yields_m,2)))*10000
    vRMSE_FullSample    = sqrt(mean(power(mYields_FullSample - yields_m_FullSample,2)))*10000
    vRMSE_OutofSample   = sqrt(mean(power(mYields_FullSample(T+1:end,:) - yields_m_FullSample(T+1:end,:),2)))*10000 % as of Sep2014
    vRMSE_OutofSample   = sqrt(mean(power(mYields_FullSample(58:end,:) - yields_m_FullSample(58:end,:),2)))*10000 % as of Sep2014
    vRMSE_InSample   = sqrt(mean(power(mYields_FullSample(1:57,:) - yields_m_FullSample(1:57,:),2)))*10000 % as of Sep2014
    
    [vRMSE_TS; vRMSE_OutofSample; vRMSE_FullSample]
   
    vChangesYields_m   = fYieldsImpact_uSequence(EstimationData.mats_YCfit / EstimationData.dt, uSequence_Event,...
        fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData.mats_YCfit(end)/EstimationData.dt, param.K1Q,param.rho1*EstimationData.dt, EstimationData.dt)', param.K1P_level);
    title('Contribution of free-float factor to the 10y Big4 yield - B_Q * Q')
    
    vChangesYields_m_v2   = fYieldsImpact_uSequence(EstimationData.mats_TSfit / EstimationData.dt, uSequence_Event,...
        fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData.mats_YCfit(end)/EstimationData.dt, param.K1Q, param.rho1*EstimationData.dt, EstimationData.dt)', param.K1P_level);
  
%% Term Premia Decompositions - for the full monthly sample

    vMaturities                 = 1:1:120;
    [A_Exp_Nom, B_Exp_Nom]      = fComputeLoadings_NomShortRate(vMaturities, param.K0P, param.K1P, param.rho0, param.rho1); 
           
    mExpected_ShortRate             = ones(T_fullSample,1)*A_Exp_Nom + mX_FullSample*B_Exp_Nom; 
    mAverageExpectated_ShortRate    = cumsum(mExpected_ShortRate,2)./ repmat(vMaturities,T_fullSample,1);
    mAverageExpectated_ShortRate    = mAverageExpectated_ShortRate(:,vMaturities_analysis);
    mTermPremia                     = yields_m_FullSample - mAverageExpectated_ShortRate;
    
    figure
    plot([yields_m_FullSample(:,end) mAverageExpectated_ShortRate(:,end) mTermPremia(:,end)])
    legend('yield', 'expectations', 'premia')
    title('10y yield')
    
%     plot(BX_estimated(1,:)')
%     plot(BX_estimated(2,:)')

%     %Fitting of individual yields
%     figure
%     for i = 1:length(EstimationData.mats / EstimationData.dt)
%         plot([mYields_FullSample(:,i) yields_m_FullSample(:,i)]*100)
%         legend('observed', 'model')
%         title(['Yield ' num2str(i)])
%         pause(2)
%     end
%     
    % Implications of the model
    eigQ                      = eigs(eye(3) + param.K1Q); % eigenvalues under the Q-measure
    eigP                      = eigs(eye(3) + param.K1P);
    vLongRunMeanFactors_P     = inv(-param.K1P)*param.K0P; % alternatively
    vLongRunMeanFactors_Q     = inv(-param.K1Q)*param.K0Q; % alternatively
%     vLongRunMeanFactors       = inv(-structParam0.K1Q_0)*structParam0.K0Q_0; % alternatively
    
    rinf_P = param.rho0 + param.rho1' * vLongRunMeanFactors_P;
    rinf_Q = param.rho0 + param.rho1' * vLongRunMeanFactors_Q;
    
    % Store all these in one big structure
    EstimationData.mX                  = mX;
    EstimationData.mX_fullsample       = mX_FullSample;
       
    Results.eigQ                    = eigQ;
    Results.eigP                    = eigP;
    Results.rinf_P                  = rinf_P;
    Results.rinf_Q                  = rinf_Q;
    Results.vLongRunMeanFactors_P   = vLongRunMeanFactors_P;
    Results.vLongRunMeanFactors_Q   = vLongRunMeanFactors_Q;
    Results.yields_m                = yields_m;
    Results.yields_fullsample_m     = yields_m_FullSample;
    Results.vChangesYields_m        = vChangesYields_m;
    Results.vChangesYields_all_m    = vChangesYields_m_v2;
    Results.vShortRate_m            = vShortRate_m;
    Results.m.AvgExpShortRate       = mAverageExpectated_ShortRate;
    Results.m.TP                    = mTermPremia;
    
   
    param.BX                       = BX_estimated;
    param.AX                       = AX_estimated;
    
    EstimationData.T_eventwindow    = T_eventwindow;
    EstimationData.T_fullSample     = T_fullSample;
    
    % Store indications about the details of the models
    EstimationData.Yields_FullSample                           = mYields_FullSample;
    EstimationData.Specification.vDatesEventDates        = vDatesEventDates;
%     EstimationData.Specification.sDateEnd_EventWindow          = sDateEnd_EventWindow;
    EstimationData.Specification.sStartSample_TS_Estimation    = sStartSample_TS_Estimation;
    EstimationData.Specification.sEndSample_TS_Estimation      = sEndSample_TS_Estimation;
    EstimationData.Specification.sEndSample_TS_Analysis        = sEndSample_TS_Analysis; 
    EstimationData.Specification.w                             = w;
    EstimationData.Specification.mats_TSfit                    = vMaturities_analysis;
    EstimationData.Specification.mats_YCfit                    = vMaturities_regressionanalysis;
    EstimationData.EventWindow.uSequenceEvent                  = uSequence_Event;
    EstimationData.EventWindow.YieldsChange_obs                = vChangesYields';
    EstimationData.EventWindow.YieldsChange_all_obs            = vChangesYields_all';
    EstimationData.EventWindow.Beta_controlled                 = mBeta_controlled;
    EstimationData.vShortRate                                  = vShortRate;
   
%% Computing discount factors

    % Specify maturities

    vMaturities         = 1:1:10/EstimationData.dt;
      
    % Estimated loadings 
    [BX, AX]            = gaussianDiscreteYieldLoadingsRecurrence(vMaturities, param.K0Q, param.K1Q, param.Omega_square, ...
                                param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
%     [BX_RF, AX_RF]      = gaussianDiscreteYieldLoadingsRecurrence(vMaturities, param.K0P, param.K1P, param.Omega_square, ...
%                                 param.rho0 * Results.EstimationData.dt, param.rho1*Results.EstimationData.dt, Results.EstimationData.dt);
% 
%     BX_TP               = BX - BX_RF;
%     AX_TP               = AX - AX_RF;
% 
%     yields_m            = ones(T,1)*AX + mX * BX; % (T+1)*J, model-implied yields
%     EC_m                = ones(T,1)*AX_RF + mX * BX_RF; % (T+1)*J, model-implied yields
%     TP_m                = yields_m - EC_m;
%     
%     index_mat           = 120;
%     close all
%     plot([yields_m(:,index_mat), EC_m(:,index_mat), TP_m(:,index_mat)]*100)
%     
%     TP_FreeFloat_m  = mX(:,3) * BX(3,:);
%     close all
%     plot([TP_m(:,index_mat), TP_FreeFloat_m(:,index_mat), TP_m(:,index_mat) - TP_FreeFloat_m(:,index_mat)]*100)
%     legend('TP all', 'TP free float', 'TP level and slope')
    
    param.mDiscountFactors      = zeros(length(vMaturities),length(EstimationData.mats_TSfit));                % added KN Apr 2018

    for j = 1:length(EstimationData.mats_TSfit)                                                  % added KN Apr 2018
        dMat_analysis                   = EstimationData.mats_TSfit(j);                          % added KN Apr 2018 

        % Express the yield maturity in the frequency of the model
        mat                             = dMat_analysis/EstimationData.dt;

        H = mat-1;

        % Estimated weighting function
        vDiscounting_estimated    = NaN(H,1);
        for ii = 1:H 
            vDiscounting_estimated(ii) = ((mat-(ii-1))/mat * BX(3, mat-(ii-1)) - (mat-ii)/mat * BX(3, mat-ii)*param.K1P_level(3,3));
        end  
        
        param.mDiscountFactors(1:H,j) = vDiscounting_estimated;
        
    end                                                                                 

%% Plots 
 
    figure
    plot([vChangesYields' vChangesYields_m]*10000); legend('actual', 'model implied')
    
    figure
    plot(param.BX(3,:)'*10000*0.01) % impact in bps of an increase of 1 percentage points in the free float
    plot(-BX_estimated(3,:) .* EstimationData.mats_TSfit)
    
%     plot(BX_estimated')
   
    plot(param.mDiscountFactors(:,[2 5 10]))
    
%% Save output 

    if bJan
        if bControlledRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Jan_Controlled'], ...
                'Results', 'param', 'EstimationData', 'Data', 'yields');
        elseif bStandardRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Jan_Standard'], ...
                'Results', 'param', 'EstimationData', 'Data', 'yields');
        elseif bAverageBothRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Jan_Average'], ...
                        'Results', 'param', 'EstimationData', 'Data', 'yields');
        end
    else
        if bControlledRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Mar_Controlled'], ...
                'Results', 'param', 'EstimationData', 'Data', 'yields');
        elseif bStandardRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Mar_Standard'], ...
                'Results', 'param', 'EstimationData', 'Data', 'yields');
        elseif bAverageBothRegressions
            save([sOutputDirectory 'LiWei_RestrictionsLambda_' sCountry '_' sQuantity '_' sStartSample_TS_Estimation '_' sEndSample_TS_Estimation '_MixObjFunc_APP_Mar_Avg_final'], ...
                'Results', 'param', 'EstimationData', 'Data', 'yields');
        end
    end
    
    
