
    % Clearing memory and graphical interface
    clc;
    clearvars;
    close all;
 
    sOutputDirectory    = 'Output_mat\'; 
    sInputDirectory     = 'Input_mat\'; % Output wrt to this code but will be input to the main analysis  

    addpath(genpath([cd '\']));
   

%%  Estimation specifications
    
    sStartSample_TS_Estimation  = 'Mar2009'; %1999, 2014
    sEndSample_TS_Estimation    = 'Dec2021'; %  Dec2021
    sEndInSample                = 'Mar2015';  
    
    bAverageBothRegressions = 1;
 
    % Specify the weight applied to the average RMSE of fitting yields levels
    w = 0.50; 

%% Specify event dates
    
    bEvent1 = 'Mar2015';
    bEvent2 = 'Mar2020';
    
%%  Load the full dataset for estimation of the model

    sEndSampleData = 'Dec-2021';
    sCountry = 'IT';

    load([sInputDirectory 'TS_ECB_' sCountry '_' sEndSampleData '.mat']);

%% Load also the OIS data
    load([sInputDirectory 'OIS.mat']);

%% Event study
    
    vDatesEventDates    = {'04/09/2014', '12/09/2014', '24/09/2014', '25/09/2014', '02/10/2014', '10/10/2014', '24/10/2014', '06/11/2014', '17/11/2014', ...
            '21/11/2014', '27/11/2014', '04/12/2014', '02/01/2015', '08/01/2015', '14/01/2015', '22/01/2015', '05/03/2015'};

    vMaturities_analysis            = [12 24 36 48 60 72 84 96 108 120];
    vMaturities_regressionanalysis  = [60 72 84 96 108 120]; 
    
    
    % Specify the window for the regression analysis
    sDateStart_RegAnalysis  = '31/12/2013';
    sDateEnd_RegAnalysis    = '31/03/2015';
    
    indexDateInitial_Regressions    = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), sDateStart_RegAnalysis));
    indexDateFinal_Regressions      = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd/mm/yyyy')), sDateEnd_RegAnalysis));
    vDates_Selection                = Data.nom.d.dates(indexDateInitial_Regressions+1:indexDateFinal_Regressions);
  
    
    % Select the yields and compute changes in yields
    ZeroYields_MTS.DE       = yields.d.nom(:,vMaturities_analysis);
     
    ZeroYields_MTS.Change_DE       = diff(ZeroYields_MTS.DE(indexDateInitial_Regressions:indexDateFinal_Regressions,:)); 
    
  % Specify the window for the regression analysis
    sDateStart_RegAnalysis  = '31/12/2013';
    sDateEnd_RegAnalysis    = '31/03/2015';
   
    Y               = ZeroYields_MTS.Change_DE(2:end,:);
    X_Dummy         = zeros(length(vDates_Selection),length(vDatesEventDates));
    
    for iEventDate = 1:length(vDatesEventDates)
        
        index = find(strcmp(cellstr(datestr(vDates_Selection, 'dd/mm/yyyy')), vDatesEventDates(iEventDate)));
        X_Dummy(index, iEventDate) = 1;
        
    end
    
     
    X_standard      = [X_Dummy(2:end,:) X_Dummy(1:end-1,:)];    
      
    for imat = 1:length(vMaturities_analysis)

        Beta_standard                       = regress(Y(:,imat), X_standard);
        vChangesYields_Standard(1,imat)     = sum(Beta_standard(1:2*length(vDatesEventDates)));

    end
    
    % Controlled version of the regressions
    load('Input_mat/Surprise_Data_untilMar2015.mat');
    vDates_MacroSurprises       = Surprise_Data(:,1)+693960;
    mMacroSurprises             = Surprise_Data(ismember(vDates_MacroSurprises, vDates_Selection),2:end);
    mIndicesMacroSurprises      = ~isnan(mMacroSurprises);
    mMacroSurprises_zeros       = zeros(size(mIndicesMacroSurprises,1), size(mIndicesMacroSurprises,2));
    mMacroSurprises_zeros(mIndicesMacroSurprises) = mMacroSurprises(mIndicesMacroSurprises);
    
    X_controlled    = [X_Dummy(2:end,:) X_Dummy(1:end-1,:) mMacroSurprises_zeros(2:end,:)];    
    
    for imat = 1:length(vMaturities_analysis)
        
        mBeta_controlled(:,imat)            = regress(Y(:,imat), X_controlled);
        vChangesYields_Controlled(1,imat)   = sum(mBeta_controlled(1:2*length(vDatesEventDates),imat));
            
    end   
        
    if bAverageBothRegressions
        vChangesYields_APP = (vChangesYields_Controlled + vChangesYields_Standard)/2;
    end
    
%% Changes in yields from 18-Mar to 20-Mar

    indexStart_YieldChanges_PEPP     = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd-mmm-yyyy')), '18-Mar-2020'), 1, 'first');
    indexEnd_YieldChanges_PEPP       = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd-mmm-yyyy')), '20-Mar-2020'), 1, 'last');
   
    vChangesYields_PEPP = yields.d.nom(indexEnd_YieldChanges_PEPP,12:12:120) - yields.d.nom(indexStart_YieldChanges_PEPP,12:12:120);
    
%% OIS data

    %Specify the OIS yields to be used for constructing the level and the
    %slope factors
    index_mats_OIS = 5:14; % from 1y to 10y
    indexStartSample_estimation_OIS     = find(strcmp(cellstr(datestr(Data_OIS.MatlabDates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_OIS       = find(strcmp(cellstr(datestr(Data_OIS.MatlabDates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
    indexEndSample_fullsample_OIS       = find(strcmp(cellstr(datestr(Data_OIS.MatlabDates, 'mmm-yyyy')), sEndSampleData), 1, 'last');
    
   
    OIS_rates_estimation   = Data_OIS.OIS_rates(indexStartSample_estimation_OIS:indexEndSample_estimation_OIS,index_mats_OIS); % OIS rates from 1y to 10y (leave for the moment longer or shorter maturities out)
    OIS_rates_fullsample   = Data_OIS.OIS_rates(indexStartSample_estimation_OIS:indexEndSample_fullsample_OIS,index_mats_OIS); % OIS rates from 1y to 10y (leave for the moment longer or shorter maturities out)
    
    N_OIS = 2;
    
    W = pca(OIS_rates_estimation);  % Compute loading matrix for principal components 

    % explained_cum = cumsum(explained);
    W = W(:,1:N_OIS)';            % N*J ("J" is the number of maturities)
    % OPPOSITE OF PC2
    W(2,:)       = -W(2,:);
   
    cP_OIS_o = OIS_rates_estimation*W';   % T*N % principal components ("cP" stands for "caligraphic P", as in the JSZ paper)
    cP_OIS_fullsample = OIS_rates_fullsample*W';   % T*N % principal components ("cP" stands for "caligraphic P", as in the JSZ paper)

    
%%  Setup format of model/data
    
    indexStartSample_estimation_yields     = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_yields       = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
    
    T = indexEndSample_estimation_yields - indexStartSample_estimation_yields+1;
    vDates = Data.nom.m.dates(indexStartSample_estimation_yields:indexEndSample_estimation_yields);
    
    indexEndSample_Analysis         = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'mmm-yyyy')), sEndSampleData), 1, 'last');
    T_fullSample                    = indexEndSample_Analysis - indexStartSample_estimation_yields + 1;
    
    EstimationData.mats_TSfit       = vMaturities_analysis/12;
    EstimationData.mats_YCfit       = vMaturities_regressionanalysis/12;
    
    EstimationData.Yields           = yields.m.nom(indexStartSample_estimation_yields:indexEndSample_estimation_yields, vMaturities_analysis);
    EstimationData.YieldsFullSample   = yields.m.nom(indexStartSample_estimation_yields:indexEndSample_Analysis, vMaturities_analysis);
    EstimationData.dt = 1/12;

%% Stress indicator - priced factor

    [Data_CISS, Header_CISS] = xlsread('Data\Free_Float.xlsx', 'CISS');
    vDates_StressIndicator = datenum(Header_CISS(2:end,1), 'dd/mm/yyyy');
    
    indexStartSample_estimation_CISS   = find(strcmp(cellstr(datestr(vDates_StressIndicator, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_CISS     = find(strcmp(cellstr(datestr(vDates_StressIndicator, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'first');
    indexEndSample_CISS               = find(strcmp(cellstr(datestr(vDates_StressIndicator, 'mmm-yyyy')), sEndSampleData), 1, 'first');
    
    vCISS    = Data_CISS(indexStartSample_estimation_CISS:indexEndSample_estimation_CISS,1); 
    vCISS_FullSample = Data_CISS(indexStartSample_estimation_CISS:indexEndSample_CISS,1); 
    
%% Free-float (big4) data
    
    [Data_Quantity, Header_FreeFloat] = xlsread('Data\Free_Float.xlsx', 'Big4_free-float(Dec-21)');
    vDates_FreeFloat = datenum(Header_FreeFloat(2:end,1), 'dd/mm/yyyy');
    
    indexStartSample_estimation_FreeFloat   = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_FreeFloat     = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'first');
    indexEndSample_FreeFloat                = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmm-yyyy')), sEndSampleData), 1, 'first');
    
    vQuantity_Estimation    = Data_Quantity(indexStartSample_estimation_FreeFloat:indexEndSample_estimation_FreeFloat,13); % T-10-year equivalent big-4, from the begining in decimals
    vQuantity_FullSample    = Data_Quantity(indexStartSample_estimation_FreeFloat:indexEndSample_FreeFloat,13); % T-10-year equivalent big-4, from the begining in decimals

%% Free-float for individual countries
    [Data_Fiscal, Header_Fiscal] = xlsread('Data\Free_Float.xlsx', 'FF_IndividualCountries');
    
    % find specific country
    for i = 1:size(Header_Fiscal)-1
        Header_Country = char(Header_Fiscal(1,i+1));
            if strcmp(Header_Country(end-1:end), sCountry)
            end
            
    end
    
    
%% Putting together all factors

    mX = [cP_OIS_o vCISS vQuantity_Estimation]; % Quantitiy will always be the last factor
%     mX = [cP_OIS_o  vQuantity_Estimation]; % Quantitiy will always be the last factor
    
    N_estimation = size(mX,2);
    
    
%%  Full sample of pricing factors

    PC_FullSample   = OIS_rates_fullsample * W';
    mX_FullSample   = [cP_OIS_fullsample vCISS_FullSample vQuantity_FullSample];
    
%% OLS regression for the short rate on the level and slope factors

    vShortRate          = yields.m.nom(indexStartSample_estimation_yields:indexEndSample_estimation_yields, 1);
        
    % Version 1: with only OIS PCs
    [B,SIGMA,RESID,VARPARAM] = mvregress([ones(T,1)  mX(:,1:end-1)], vShortRate);
    % Version 2: also with the free-float
%     [B,SIGMA,RESID,VARPARAM] = mvregress([ones(T,1)  mX], vShortRate);
    
    param.rho0          = B(1)
    % Version 1: with only OIS PCs
    param.rho1          = [B(2:end); 0] % restriction that the quantity variable doesn't enter the short rate equation
    % Version 2: also with the free-float
%     param.rho1          = B(2:end); % drop restriction that the quantity variable doesn't enter the short rate equation

    vShortRate_m        = param.rho0 + mX * param.rho1;
    % Checks/Plots
    figure
    plot(vDates, [vShortRate vShortRate_m])
    datetick('x','yyyy') 
    legend('observed', 'fitted')
    
    errors = mean(abs(vShortRate - vShortRate_m))*100; % Only fitted rates at maturities used for estimation are picked

%% VAR for the P-measure (possibly with restrictions)

    [B_level,~,Residual_level,VARPARAM_Level]             = mvregress([ones(T-1,1)  cP_OIS_o(1:end-1,:)], cP_OIS_o(2:end,1));
    [B_slope,~,Residual_slope,VARPARAM_Slope]             = mvregress([ones(T-1,1)  cP_OIS_o(1:end-1,:)], cP_OIS_o(2:end,2));
    
%     [BETA,~,RESID,VARPARAM] = mvregress([ones(T-1,1)  cP_OIS_o(1:end-1,:)], cP_OIS_o(2:end,:));
    [BETA,~,RESID,VARPARAM] = mvregress([ones(T-1,1)  mX(1:end-1,1:N_estimation-1)], mX(2:end,1:N_estimation-1));

    [B_quantity,SIGMA,Residual_quantity,VARPARAM_Quantity]             = mvregress([ones(T-1,1) vQuantity_Estimation(1:end-1,:)],vQuantity_Estimation(2:end));

%     param.K0P       = [B_level(1); B_slope(1); B_quantity(1)];
    param.K0P       = [BETA(1,:)'; B_quantity(1)];

    if B_quantity(2:end)< 1
         param.K1P_level       = [BETA(2:end,:) zeros(N_estimation-1,1); [zeros(1,N_estimation-1) B_quantity(2:end)']];
%         param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 B_quantity(2:end)'];
    else % if non-stationary
        % Fix the autoregression parameter
%         param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 0.99];
        param.K1P_level       = [BETA(2:end,:) zeros(N_estimation-1,1); [zeros(1,N_estimation-1) 0.99]];
        % Fix consequently also the intercept
        param.K0P(3)          =  mean(vQuantity_Estimation) * 0.01;% mean(EstimationData.vQuantity(2:end) - 0.99 * EstimationData.vQuantity(1:end-1,:));
        Residual_quantity     =  vQuantity_Estimation(2:end) - (ones(T-1,1) * param.K0P(3) + vQuantity_Estimation(1:end-1,:) * 0.99); 
    end

    
    param.K1P               = param.K1P_level - eye(N_estimation);

%     param.Residual_level    = Residual_level;
%     param.Residual_slope    = Residual_slope;
%     param.Residual_quantity = Residual_quantity;
    
    mResiduals              = [RESID Residual_quantity];
    param.Omega_square      = 1/(T-1) * mResiduals.' * mResiduals;
    param.Omega_chol        = chol(param.Omega_square, 'lower');  % the Cholesky decomposition of the variance covariance matrix
   
%%  Initial estimates for the market price of risk parameters

    load([sOutputDirectory 'StartingValues_ATSM_OIS.mat']);
    
%% Extract the u-sequence
    
    % First, for Mar 2015
    [Data_Quantity, Header_FreeFloat] = xlsread('Data\Free_Float.xlsx', 'Deviations_Big4FF');
%     vDates_FreeFloatDeviations = datestr()  
    uSequence_FreeFloat_APP   = Data_Quantity(:,1);
    uSequence_FreeFloat_PEPP   = Data_Quantity(61:end,2);
    
    uSequence_FreeFloat_APP = [zeros(length(uSequence_FreeFloat_APP),N_estimation-1), uSequence_FreeFloat_APP];
    uSequence_FreeFloat_PEPP = [zeros(length(uSequence_FreeFloat_PEPP),N_estimation-1), uSequence_FreeFloat_PEPP];
   
     
%%  Dual optimization problem
    
    % Select yields only as of 5 years onwards, for Germany
    vChangesYields_APP = vChangesYields_APP(EstimationData.mats_YCfit);
    vChangesYields_PEPP = vChangesYields_PEPP(EstimationData.mats_YCfit);
    
%     % Specify the objective function - only the APP event
%     obj_fun         = @(vLambda) fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields_APP, uSequence_FreeFloat_APP, EstimationData, param, vLambda);
    
    
    % Specify the objective function - both the APP and PEPP event
    m_uSequence_FreeFloat(:,:,1) = uSequence_FreeFloat_APP(1:120,:);
    m_uSequence_FreeFloat(:,:,2) = uSequence_FreeFloat_PEPP(1:120,:);
    mChangesYields               = [vChangesYields_APP' vChangesYields_PEPP']; 
    
    obj_fun         = @(vLambda) fRMSE_pricing_twocriterions_moreSequences(w, mX, mChangesYields, m_uSequence_FreeFloat, EstimationData, param, vLambda);
    
    vLambda0        = [param_OIS_0.Lambda_0; 0.01; vec([param_OIS_0.Lambda_1 [0.01; 0.01] [0.11; -0.02] ; [ 0.01 0.01 0.01 0.01]])];
  
    [MSE_fun_0, Fy, Fdy]  = fRMSE_pricing_twocriterions_moreSequences(w, mX, mChangesYields, m_uSequence_FreeFloat, EstimationData, param, vLambda0);   
    
    % Seting up optimization function
    options         = optimset('display', 'off', 'TolX', 10^-25, 'TolFun',10^-25);
    LB              = -100*ones(length(vLambda0),1);
    UB              = 100*ones(length(vLambda0),1);
    
    % Start with the fmincon and then run also a fminunc (which also gives accurate Gradient and Hessian)
    [vLambda_dualobj, fval]  = fmincon(@(Z) obj_fun(Z), vLambda0, [], [], [], [], LB,UB,[],options);
    [vLambda_dualobj,FVAL_fminunc,EXITFLAG_fminunc,OUTPUT_fminunc,GRAD_fminunc,HESSIAN_fminunc] = fminunc(@(Z) obj_fun(Z), vLambda_dualobj, options);

    
    %% Compute final results

    param.Lambda_0         = [vLambda_dualobj(1:N_estimation-1); 0];
    param.Lambda_1         = [reshape(vLambda_dualobj(N_estimation:end), N_estimation-1, N_estimation); zeros(1,N_estimation)];
    
    param.K0Q              = param.K0P - param.Omega_chol * param.Lambda_0; 
    param.K1Q              = param.K1P - param.Omega_chol * param.Lambda_1; 
    param.K1Q_level        = param.K1Q + eye(N_estimation);   % KN added
    
    [BX_estimated, AX_estimated, B_price, A_price]  = gaussianDiscreteYieldLoadingsRecurrence(EstimationData.mats_TSfit / EstimationData.dt, param.K0Q, param.K1Q, param.Omega_square, ...
                                            param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);

    % Computing the fit of the yields over the TS window 
    yields_m                = ones(T,1)*AX_estimated + mX * BX_estimated; % (T+1)*J, model-implied yields
    yields_m_FullSample     = ones(T_fullSample,1)*AX_estimated + mX_FullSample * BX_estimated; % (T+1)*J, model-implied yields
  
    for i = 1:10
        plot([yields_m_FullSample(:,i) EstimationData.YieldsFullSample(:,i)]*100)
        title(num2str(i))
        pause(5)
        
    end
    
    % Plot Contribution of the 3rd factor
    mContribution_Q          = mX_FullSample(:,end) * BX_estimated(end,:);
    mContribution_CISS       = mX_FullSample(:,end-1) * BX_estimated(end-1,:);
    mContribution_LS         = mX_FullSample(:,1:end-2) * BX_estimated(1:end-2,:);
    
    figure
    plot([EstimationData.YieldsFullSample(:,end) mContribution_Q(:,end) mContribution_CISS(:,end)]*100)
    legend('observed', 'contribution_Q', 'contribution_CISS')
    
    vRMSE_TS            = sqrt(mean(power(EstimationData.Yields - yields_m,2)))*10000
%     vRMSE_TS            = sqrt(mean(power(EstimationData.Yields - mContribution_LS(1:66,:),2)))*10000
    vRMSE_FullSample    = sqrt(mean(power(EstimationData.YieldsFullSample - yields_m_FullSample,2)))*10000
    
%%  Fit of the changes in DE yields over the APP period

    vChangesYields_APP_m   = fYieldsImpact_uSequence(EstimationData.mats_YCfit / EstimationData.dt, uSequence_FreeFloat_APP,...
        fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData.mats_YCfit(end)/EstimationData.dt, param.K1Q,param.rho1*EstimationData.dt, EstimationData.dt)', param.K1P_level);
   
    figure
    plot([vChangesYields_APP' vChangesYields_APP_m]*100)
    legend('observed', 'fitted')
    
%% Fit of the changes in DE yields upon PEPP announcement    

    vChangesYields_PEPP_m   = fYieldsImpact_uSequence(EstimationData.mats_YCfit / EstimationData.dt, uSequence_FreeFloat_PEPP,...
        fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData.mats_YCfit(end)/EstimationData.dt, param.K1Q,param.rho1*EstimationData.dt, EstimationData.dt)', param.K1P_level);
   
    figure
    plot([vChangesYields_PEPP' vChangesYields_PEPP_m]*100)
    legend('observed', 'fitted')
    
 %% Computing discount factors

    % Specify maturities
    vMaturities         = 1:1:10/EstimationData.dt;
      
    % Estimated loadings 
    [BX, AX]            = gaussianDiscreteYieldLoadingsRecurrence(vMaturities, param.K0Q, param.K1Q, param.Omega_square, ...
                                param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
    param.mDiscountFactors      = zeros(length(vMaturities),length(EstimationData.mats_TSfit));                

    for j = 1:length(EstimationData.mats_TSfit)   
        
        dMat_analysis                   = EstimationData.mats_TSfit(j);                          

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
   
%% Save the discount factors

    save()