
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
%sEndSample_TS_Estimation    = 'Mar2015'; %  Dec2021
sEndInSample                = 'Mar2015';

bAverageBothRegressions = 1;

% Specify the weight applied to the average RMSE of fitting yields levels
w = 0.50;

%% Specify event dates

bEvent1 = 'Mar2015';
bEvent2 = 'Mar2020';

%%  Load the full dataset for estimation of the model


countries = {'DE', 'IT'}
%     countries = {'IT'}
sEndSampleData = 'Dec-2021';

for ii=1:length(countries); cty=countries{ii};
    load([sInputDirectory 'TS_ECB_'  cty '_' sEndSampleData '.mat']);
    Data_i.(cty)= Data;
    param_i.(cty) = param;
    yields_i.(cty) = yields;
    
end
clear('Data', 'yields', 'param');



%% OIS data
load([sInputDirectory 'OIS.mat']);
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

%cP_OIS_o = [OIS_rates_estimation(:,1) OIS_rates_estimation(:,end)-OIS_rates_estimation(:,1)]; % level and slope factors
%cP_OIS_fullsample = [OIS_rates_fullsample(:,1) OIS_rates_fullsample(:,end)-OIS_rates_fullsample(:,1)];

%% Free-float (big4) data

[Data_Quantity, Header_FreeFloat] = xlsread('Data\Free_Float.xlsx', 'Big4_free-float(Dec-21)');
vDates_FreeFloat = datenum(Header_FreeFloat(2:end,1), 'dd/mm/yyyy');

indexStartSample_estimation_FreeFloat   = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
indexEndSample_estimation_FreeFloat     = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'first');
indexEndSample_FreeFloat                = find(strcmp(cellstr(datestr(vDates_FreeFloat, 'mmm-yyyy')), sEndSampleData), 1, 'first');

vQuantity_Estimation    = Data_Quantity(indexStartSample_estimation_FreeFloat:indexEndSample_estimation_FreeFloat,13); % T-10-year equivalent big-4, from the begining in decimals
vQuantity_FullSample    = Data_Quantity(indexStartSample_estimation_FreeFloat:indexEndSample_FreeFloat,13); % T-10-year equivalent big-4, from the begining in decimals


%% Debt to GDP
%
%     [Data_debt, Header_debt] = xlsread('Data\Free_Float.xlsx', 'FF_GDP_IT');
%     vDates_debt = datenum(Header_debt(2:end,1), 'dd/mm/yyyy');
%
%     indexStartSample_estimation_debt   = find(strcmp(cellstr(datestr(vDates_debt, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
%     indexEndSample_estimation_debt     = find(strcmp(cellstr(datestr(vDates_debt, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'first');
%     indexEndSample_debt               = find(strcmp(cellstr(datestr(vDates_debt, 'mmm-yyyy')), sEndSampleData), 1, 'first');
%
%     vDebt    = Data_debt(indexStartSample_estimation_debt:indexEndSample_estimation_debt,1)./100;
%     vDebt_FullSample = Data_debt(indexStartSample_estimation_debt:indexEndSample_debt,1)./100;


%% Event study

vDatesEventDates    = {'04/09/2014', '12/09/2014', '24/09/2014', '25/09/2014', '02/10/2014', '10/10/2014', '24/10/2014', '06/11/2014', '17/11/2014', ...
    '21/11/2014', '27/11/2014', '04/12/2014', '02/01/2015', '08/01/2015', '14/01/2015', '22/01/2015', '05/03/2015'};

vMaturities_analysis            = [12 24 36 48 60 72 84 96 108 120];
vMaturities_regressionanalysis  = [60 72 84 96 108 120];


% Specify the window for the regression analysis
sDateStart_RegAnalysis  = '31/12/2013';
sDateEnd_RegAnalysis    = '31/03/2015';

indexDateInitial_Regressions    = find(strcmp(cellstr(datestr(Data_i.(cty).nom.d.dates, 'dd/mm/yyyy')), sDateStart_RegAnalysis));
indexDateFinal_Regressions      = find(strcmp(cellstr(datestr(Data_i.(cty).nom.d.dates, 'dd/mm/yyyy')), sDateEnd_RegAnalysis));
vDates_Selection                = Data_i.(cty).nom.d.dates(indexDateInitial_Regressions+1:indexDateFinal_Regressions);


% Select the yields and compute changes in yields
for ii=1:length(countries); cty=countries{ii};
    
    ZeroYields_MTS.(cty)       = yields_i.(cty).d.nom(:,vMaturities_analysis);
    ZeroYields_MTS.(['Change_' cty]) = diff(ZeroYields_MTS.(cty)(indexDateInitial_Regressions:indexDateFinal_Regressions,:));
    
    % Specify the window for the regression analysis
    sDateStart_RegAnalysis  = '31/12/2013';
    sDateEnd_RegAnalysis    = '31/03/2015';
    
    Y               = ZeroYields_MTS.(['Change_' cty])(2:end,:);
    X_Dummy         = zeros(length(vDates_Selection),length(vDatesEventDates));
    
    for iEventDate = 1:length(vDatesEventDates)
        
        index = find(strcmp(cellstr(datestr(vDates_Selection, 'dd/mm/yyyy')), vDatesEventDates(iEventDate)));
        X_Dummy(index, iEventDate) = 1;
        
    end
    
    X_standard      = [X_Dummy(2:end,:) X_Dummy(1:end-1,:)];
    
    for imat = 1:length(vMaturities_analysis)
        
        Beta_standard.(cty)                       = regress(Y(:,imat), X_standard);
        vChangesYields_Standard.(cty)(1,imat)     = sum(Beta_standard.(cty)(1:2*length(vDatesEventDates))); %sum of all event fixed effects and their lags
        
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
        
        mBeta_controlled.(cty)(:,imat)            = regress(Y(:,imat), X_controlled);
        vChangesYields_Controlled.(cty)(1,imat)   = sum(mBeta_controlled.(cty)(1:2*length(vDatesEventDates),imat));
        
    end
    
    if bAverageBothRegressions
        vChangesYields_APP.(cty) = (vChangesYields_Controlled.(cty) + vChangesYields_Standard.(cty))/2;
    end
    
    
    
    %% Changes in yields from 18-Mar to 20-Mar
    
    indexStart_YieldChanges_PEPP     = find(strcmp(cellstr(datestr(Data_i.(cty).nom.d.dates, 'dd-mmm-yyyy')), '18-Mar-2020'), 1, 'first');
    indexEnd_YieldChanges_PEPP       = find(strcmp(cellstr(datestr(Data_i.(cty).nom.d.dates, 'dd-mmm-yyyy')), '20-Mar-2020'), 1, 'last');
    
    vChangesYields_PEPP.(cty) = yields_i.(cty).d.nom(indexEnd_YieldChanges_PEPP,12:12:120) - yields_i.(cty).d.nom(indexStart_YieldChanges_PEPP,12:12:120);
    
    
    
    %%  Setup format of model/data
    
    %% sovereign yield curve
    indexStartSample_estimation_yields     = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_yields       = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
    
    T = indexEndSample_estimation_yields - indexStartSample_estimation_yields+1;
    vDates = Data_i.(cty).nom.m.dates(indexStartSample_estimation_yields:indexEndSample_estimation_yields);
    
    indexEndSample_Analysis         = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmm-yyyy')), sEndSampleData), 1, 'last');
    T_fullSample                    = indexEndSample_Analysis - indexStartSample_estimation_yields + 1;
    
    EstimationData_i.(cty).mats_TSfit       = vMaturities_analysis/12;
    EstimationData_i.(cty).mats_YCfit       = vMaturities_regressionanalysis/12;
    
    EstimationData_i.(cty).Yields           = yields_i.(cty).m.nom(indexStartSample_estimation_yields:indexEndSample_estimation_yields, vMaturities_analysis);
    EstimationData_i.(cty).YieldsFullSample   = yields_i.(cty).m.nom(indexStartSample_estimation_yields:indexEndSample_Analysis, vMaturities_analysis);
    EstimationData_i.(cty).dt = 1/12;
    
    %% sovereign yield curve factors
    
    index_mats= 12:12:120;
    indexStartSample_estimation    = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation       = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
    indexEndSample_fullsample       = find(strcmp(cellstr(datestr(Data_i.(cty).nom.m.dates, 'mmm-yyyy')), sEndSampleData), 1, 'last');
    
    yields_estimation.(cty)   = yields_i.(cty).m.nom(indexStartSample_estimation:indexEndSample_estimation,index_mats); % OIS rates from 1y to 10y (leave for the moment longer or shorter maturities out)
    yields_fullsample.(cty)   = yields_i.(cty).m.nom(indexStartSample_estimation:indexEndSample_fullsample,index_mats); % OIS rates from 1y to 10y (leave for the moment longer or shorter maturities out)
    
    W = pca(yields_fullsample.(cty));  % Compute loading matrix for principal components
    % explained_cum = cumsum(explained);
    W = W(:,1:N_OIS)';            % N*J ("J" is the number of maturities)
    % OPPOSITE OF PC2
    W(2,:)       = -W(2,:);
    
    cP_o.(cty) = yields_estimation.(cty)*W';   % T*N % principal components ("cP" stands for "caligraphic P", as in the JSZ paper)
    cP_fullsample.(cty) = yields_fullsample.(cty)*W';   % T*N % principal components ("cP" stands for "caligraphic P", as in the JSZ paper)
    
    %cP_o.(cty) = [yields_estimation.(cty)(:,1) yields_estimation.(cty)(:,end)-yields_estimation.(cty)(:,1)];
    %cP_fullsample.(cty) = [yields_fullsample.(cty)(:,1) yields_fullsample.(cty)(:,end)-yields_fullsample.(cty)(:,1)];
    
    cP_vsOIS_o.(cty) = cP_o.(cty) - cP_OIS_o;
    cP_vsOIS_fullsample.(cty) = cP_fullsample.(cty) - cP_OIS_fullsample;
    
    %         cP_vsDE_o.(cty) = cP_o.(cty) - cP_o.DE;
    %         cP_vsDE_fullsample.(cty) = cP_fullsample.(cty) - cP_fullsample.DE;
    
    %%  Pricing factors
    mX.(cty) = [cP_OIS_o vQuantity_Estimation];
    %mX.(cty) = [cP_o.DE vQuantity_Estimation];
    
    if strcmp(cty, 'IT')
        mX.(cty) = [mX.(cty) cP_vsOIS_o.(cty)];
        %             mX.(cty) = [mX.DE cP_vsOIS_o.(cty) vDebt];
        %mX.(cty) = [mX.DE cP_vsDE_o.(cty) vDebt];
        
    end
    
    N_estimation.(cty) = size(mX.(cty),2);
    %mX_FullSample   = [cP_OIS_fullsample vQuantity_FullSample];
    
    %% OLS regression for the short rate on the level and slope factors
    
    vShortRate          = yields_i.(cty).m.nom(indexStartSample_estimation_yields:indexEndSample_estimation_yields, 1);
    
    % Version 1: with only OIS PCs
    if strcmp(cty, 'IT')
        [B,SIGMA,RESID,VARPARAM] = mvregress([ones(T,1)  mX.(cty)(:,[1:2 4:5])], vShortRate);
        param_i.(cty).rho1          = [B(2:3); 0; B(4:5); 0]; % restriction that the quantity variable doesn't enter the short rate equation
        param_i.(cty).rho1          = [B(2:3); 0; B(4:5)]; % with Debt
    else
        [B,SIGMA,RESID,VARPARAM] = mvregress([ones(T,1)  mX.(cty)(:,[1:2])], vShortRate);
        param_i.(cty).rho1          = [B(2:3); 0] ;
    end
    
    param_i.(cty).rho0          = B(1);
    % Version 1: with only OIS PCs
    
    
    vShortRate_m        = param_i.(cty).rho0 + mX.(cty) * param_i.(cty).rho1;
    
    % Checks/Plots
    figure
    plot(vDates, [vShortRate vShortRate_m])
    datetick('x','yyyy')
    legend('observed', 'fitted')
    
    errors = mean(abs(vShortRate - vShortRate_m))*100; % Only fitted rates at maturities used for estimation are picked
    
    %% VAR for the P-measure (possibly with restrictions)
    
    
    [BETA,~,RESID,VARPARAM] = mvregress([ones(T-1,1)  mX.(cty)(1:end-1,1:2)], mX.(cty)(2:end,1:2));
    [B_quantity,SIGMA,Residual_quantity,VARPARAM_Quantity] = mvregress([ones(T-1,1) vQuantity_Estimation(1:end-1,:)],vQuantity_Estimation(2:end));
    
    
    param_i.(cty).K0P       = [BETA(1,1:2)'; B_quantity(1)];
    param_i.(cty).K1P_level  = [BETA(2:end,:) zeros(2,1); zeros(1,2) min(B_quantity(2), 0.99)];
    
    mResiduals              = [RESID Residual_quantity ];
    
    
    if strcmp(cty, 'IT')
        [BETA_spread,~,RESID_spread,VARPARAM_spread] = mvregress([ones(T-1,1)  mX.(cty)(1:end-1,[4:5])], mX.(cty)(2:end,[4:5]));
        %             [B_debt,~,Residual_debt,VARPARAM_debt]             = mvregress([ones(T-1,1)  vDebt(1:end-1,:)], vDebt(2:end,1));
        
        %             with Debt
        %             param_i.(cty).K0P       = [param_i.(cty).K0P; BETA_spread(1,1:2)' ; B_debt(1)];
        %             param_i.(cty).K1P_level = [param_i.(cty).K1P_level zeros(3,3); zeros(3,3) [BETA_spread(2:end,:) zeros(2,1); zeros(1,2) min(B_debt(2), 0.99)]];
        %            mResiduals              =[mResiduals RESID_spread Residual_debt]
        param_i.(cty).K0P       = [param_i.(cty).K0P; BETA_spread(1,1:2)' ];
        param_i.(cty).K1P_level = [param_i.(cty).K1P_level zeros(3,2); zeros(2,3) BETA_spread(2:end,:)];
        
        mResiduals              =[mResiduals RESID_spread ]
    end
    
    param_i.(cty).K1P = param_i.(cty).K1P_level - eye(N_estimation.(cty));
    
    %if B_quantity(2:end)< 1
    %    param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 B_quantity(2:end)'];
    %else % if non-stationary
    % Fix the autoregression parameter
    %    param.K1P_level       = [B_level(2:end)' 0; B_slope(2:end)' 0; 0 0 0.99];
    % Fix consequently also the intercept
    %    param.K0P(3)          =  mean(vQuantity_Estimation) * 0.01;% mean(EstimationData.vQuantity(2:end) - 0.99 * EstimationData.vQuantity(1:end-1,:));
    %    Residual_quantity     =  vQuantity_Estimation(2:end) - (ones(T-1,1) * param.K0P(3) + vQuantity_Estimation(1:end-1,:) * 0.99);
    %end
    
    param_i.(cty).Omega_square      = 1/(T-1) * mResiduals.' * mResiduals;
    param_i.(cty).Omega_chol        = chol(param_i.(cty).Omega_square, 'lower');  % the Cholesky decomposition of the variance covariance matrix
    
    
    
    
    %%  Initial estimates for the market price of risk parameters
    
    load([sOutputDirectory 'StartingValues_ATSM_OIS.mat']);
    
    
end




%% Extract the u-sequence and the changes in yields (only for the PEPP episode for now)

% useries and yield changes for DE
[Data_Quantityseq, Header_FreeFloat] = xlsread('Data\Free_Float.xlsx', 'Deviations_Big4FF');

uSequence.DE(:,:,1) = [zeros(120,2), Data_Quantityseq(1:120,1)]; %APP FF
uSequence.DE(:,:,2) = [zeros(120,2), Data_Quantityseq(61:180,2)]; %PEPP FF
%     uSequence.DE(:,:,1) = [zeros(120,2), Data_Quantityseq(61:180,2)]; %PEPP FF

mChangesYields.DE = [vChangesYields_APP.DE(EstimationData_i.DE.mats_YCfit); vChangesYields_PEPP.DE(EstimationData_i.DE.mats_YCfit)]';
%mChangesYields.DE = [vChangesYields_APP.DE(EstimationData_i.DE.mats_YCfit)]';
%     mChangesYields.DE = [vChangesYields_PEPP.DE(EstimationData_i.DE.mats_YCfit)]';


% useries and yield changes for IT
%     [Data_DebtSeq, Header_DebtSeq] = xlsread('Data\Free_Float.xlsx', 'Deviations_Big4Fiscal');

uSequence.IT(:,:,1) = [zeros(120,2), Data_Quantityseq(1:120,1) zeros(120,2)];
uSequence.IT(:,:,2) = [zeros(120,2), Data_Quantityseq(61:180,2) zeros(120,2) ];
%uSequence.IT(:,:,2) = [zeros(120,2), Data_Quantityseq(61:180,2) zeros(120,2) Data_DebtSeq(61:180,2) ];
%with debt
%     uSequence.IT(:,:,1) = [zeros(120,2), Data_Quantityseq(1:120,1) zeros(120,3)];
%uSequence.IT(:,:,1) = [zeros(120,2), Data_Quantityseq(61:180,2) zeros(120,2) Data_DebtSeq(61:180,2) ];
%     uSequence.IT(:,:,1) = [zeros(120,2), Data_Quantityseq(61:180,2) zeros(120,2) ];

mChangesYields.IT = [vChangesYields_APP.IT(EstimationData_i.IT.mats_YCfit); vChangesYields_PEPP.IT(EstimationData_i.IT.mats_YCfit)]';
%mChangesYields.IT = [vChangesYields_APP.IT(EstimationData_i.IT.mats_YCfit)]';
%     mChangesYields.IT = [vChangesYields_PEPP.IT(EstimationData_i.IT.mats_YCfit)]';



%%  Dual optimization problem


%     % Specify the objective function - both the APP and PEPP event
%
%    lambda0_0 = [1; 1; 0];
%    lambda1_0 = [1 1 1; 1 1 1; 0 0 0];
%
%    gamma0_0        = 1; %
%    gamma1_0      =  [0; 0; 0; 1; 1; 1];
%
%    %Estim_DE = [param_i.DE.lambda0_0(param_i.DE.lambda0_0>0); param_i.DE.lambda1_0(param_i.DE.lambda1_0>0)];
%    Estim_DE = [lambda0_0(lambda0_0>0); lambda1_0(lambda1_0>0)];
%    Estim_IT = [Estim_DE; gamma0_0(gamma0_0>0); gamma1_0(gamma1_0>0)];
%
%    Estim_0 = 0.1*[Estim_DE; Estim_IT];

%mChangesYields.DE=[]; mChangesYields.IT=[];
obj_fun         = @(vEstimate) Estimate_multicountry(w, param_i, EstimationData_i, mX, uSequence, mChangesYields, vEstimate);

vLambda0_DE        = [param_OIS_0.Lambda_0; vec([param_OIS_0.Lambda_1 [0.11; -0.02]])]; %for DE
%     vLambda0.IT        = [0.11*ones(N_estimation+1,1) ; param_OIS_0.Lambda_0; param_OIS_0.Lambda_0; vec(param_OIS_0.Lambda_1); 0.11*ones(6,1); vec(param_OIS_0.Lambda_1); 0.11*ones(6,1)]; %for IT

vLambda0        = [0.11*ones(N_estimation.IT+1,1) ; param_OIS_0.Lambda_0; vLambda0_DE; 0.11*ones(4,1); vec(param_OIS_0.Lambda_1); 0.11*ones(6,1)]; %for IT

Estim_0 = vLambda0;

[MSE_fun_0, Fy, Fdy]  = Estimate_multicountry(w, param_i, EstimationData_i, mX, uSequence, mChangesYields, Estim_0);

% Start with the fmincon and then run also a fminunc (which also gives accurate Gradient and Hessian)
%     problem = createOptimProblem('fmincon','objective',obj_fun,'x0',Estim_0);
%     gs = GlobalSearch;
%     [Estim_final_gs,fg,flg,og] = run(gs,problem); %Estim_final_gs=Estim_final;
%
%     %initpop = randn(20,size(Estim_0,1)) + repmat(Estim_0',20,1);
%
%     %opts = optimoptions('ga','InitialPopulationMatrix',initpop);
%     [Estim_final_ga,fga,flga,oga] = ga(obj_fun,20); %Estim_final_ga =Estim_final'

%opts = optimoptions('particleswarm','InitialSwarmMatrix',initpop);
%    [Estim_final_ps,fpso,flgpso,opso] = particleswarm(obj_fun,20,[],[],opts); %Estim_final_ps =Estim_final'


% Seting up optimization function
options         = optimset('display', 'off', 'TolX', 10^-25, 'TolFun',10^-25);
LB              = -100*ones(length(Estim_0),1);
UB              = 100*ones(length(Estim_0),1);
[Estim_1, fval]  = fmincon(@(Z) obj_fun(Z), Estim_0, [], [], [], [], LB,UB,[],options);
[Estim_final_fminunc,FVAL_fminunc,EXITFLAG_fminunc,OUTPUT_fminunc,GRAD_fminunc,HESSIAN_fminunc] = fminunc(@(Z) obj_fun(Z), Estim_1, options);

Estim_final=Estim_final_fminunc;
%     Estim_final=Estim_final_gs;


% [MSE_DE, MSE_yields.DE, MSE_changesyields.DE, AX.DE, BX.DE] = fRMSE_pricing_twocriterions_moreSequences(w, mX.DE, mChangesYields.DE, uSequence.DE, EstimationData_i.DE, param_i.DE, Estim_final(1:8));

% param_i.IT.lamba0_DE = [Estim_final(1:2); 0];
% param_i.IT.lamba1_DE = [reshape(Estim_final(3:8), 2, 3); 0 0 0];
% [MSE_IT, MSE_yields.IT, MSE_changesyields.IT, AX.IT, BX.IT] = fRMSE_pricing_twocriterions_moreSequences_wSpread_TK(w, mX.IT, mChangesYields.IT, uSequence.IT, EstimationData_i.IT, param_i.IT, Estim_final(9:end));


%% Compute final results

param_i.IT.Gamma_0          = Estim_final(1);
param_i.IT.Gamma_1          = Estim_final(2:N_estimation.IT+1);
N_eser                  = 3; %risk factors priced in eser et al


param_i.IT.Lambda_0         = [Estim_final(N_estimation.IT+4: N_estimation.IT+5); 0 ; Estim_final(N_estimation.IT+2: N_estimation.IT+3)];
param_i.IT.Lambda_1         = [reshape(Estim_final(N_estimation.IT+6:N_estimation.IT+15), 2, 5) ; zeros(1, N_estimation.IT); reshape(Estim_final(N_estimation.IT+16:end), 2, N_estimation.IT)];

param_i.DE.Lambda_0         = [Estim_final(N_estimation.IT+4: N_estimation.IT+5); 0];
param_i.DE.Lambda_1         = [reshape(Estim_final(N_estimation.IT+6:N_estimation.IT+11), N_OIS, N_eser); zeros(1,N_eser)];


for ii=1:2;cty=countries{ii};
    
    N_estimation=length(param_i.(cty).Lambda_0);
    
    param_i.(cty).K0Q              = param_i.(cty).K0P - param_i.(cty).Omega_chol * param_i.(cty).Lambda_0;
    param_i.(cty).K1Q              = param_i.(cty).K1P - param_i.(cty).Omega_chol * param_i.(cty).Lambda_1;
    param_i.(cty).K1Q_level        = param_i.(cty).K1Q + eye(N_estimation);   % KN added
    
    if strcmp(cty, 'IT') %with default
        [BX_estimated, AX_estimated, B_price, A_price]  = gaussianDiscreteYieldLoadingsRecurrence_wDefault(EstimationData_i.(cty).mats_TSfit / EstimationData_i.(cty).dt, param_i.(cty).K0Q, param_i.(cty).K1Q_level, param_i.(cty).Omega_square, ...
            param_i.(cty).rho0 * EstimationData_i.(cty).dt, param_i.(cty).rho1*EstimationData_i.(cty).dt, EstimationData_i.(cty).dt, param_i.(cty).Gamma_0, param_i.(cty).Gamma_1);
    else
        [BX_estimated, AX_estimated, B_price, A_price]  = gaussianDiscreteYieldLoadingsRecurrence(EstimationData_i.(cty).mats_TSfit / EstimationData_i.(cty).dt, param_i.(cty).K0Q, param_i.(cty).K1Q, param_i.(cty).Omega_square, ...
            param_i.(cty).rho0 * EstimationData_i.(cty).dt, param_i.(cty).rho1*EstimationData_i.(cty).dt, EstimationData_i.(cty).dt);
        
    end
    
    % Computing the fit of the yields over the TS window
    yields_m                = ones(T,1)*AX_estimated + mX.(cty) * BX_estimated; % (T+1)*J, model-implied yields
    %yields_m_FullSample     = ones(T_fullSample,1)*AX_estimated + mX_FullSample.(cty) * BX_estimated; % (T+1)*J, model-implied yields
    
    figure()
    for i = 1:10
        %       plot([yields_m(:,i) EstimationData_i.(cty).YieldsFullSample(:,i)]*100)
        plot([yields_m(:,i) EstimationData_i.(cty).Yields(:,i)]*100)
        title([cty, num2str(i)])
        pause(1)
    end
    
    % Plot Contribution of the 3rd factor
    mContribution_Q          = mX.(cty)(:,3) * BX_estimated(3,:);
    mContribution_LS         = mX.(cty)(:,1:2) * BX_estimated(1:2,:);
    figure()
    plot([yields_fullsample.(cty)(:,end) mContribution_Q(:,end)]*100)
    title([cty, num2str(i)])
    
    
end

% Plot Contribution of the 3rd factor
%mContribution_Q          = mX_FullSample(:,3) * BX_estimated(3,:);
%mContribution_LS         = mX_FullSample(:,1:2) * BX_estimated(1:2,:);

%plot([yields_m_FullSample(:,end) mContribution_Q(:,end)]*100)

%vRMSE_TS            = sqrt(mean(power(EstimationData.Yields - yields_m,2)))*10000
%     vRMSE_TS            = sqrt(mean(power(EstimationData.Yields - mContribution_LS(1:66,:),2)))*10000
%vRMSE_FullSample    = sqrt(mean(power(EstimationData.YieldsFullSample - yields_m_FullSample,2)))*10000



%% Save the discount factors



%%  Fit of the changes in DE yields over the APP period
%for ii=1:length(countries); cty=countries{ii};
%    vChangesYields_APP_m   = fYieldsImpact_uSequence(EstimationData_i.(cty).mats_YCfit / EstimationData_i.(cty).dt, uSequence.(cty)(:,:,1),...
%        fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData_i.(cty).mats_YCfit(end)/EstimationData_i.(cty).dt, param_i.(cty).K1Q,param_i.(cty).rho1*EstimationData_i(cty)DE.dt, EstimationData_i.(cty).dt)', param_i.(cty).K1P_level);

%    figure
%    plot([5:10],[vChangesYields_APP.(cty)(5:10)' vChangesYields_APP_m]*100)
%    legend('observed', 'fitted')

%end


%%  Fit of the changes in DE yields over the APP and PEPP period

cty='DE';
BX.(cty) = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(1:EstimationData_i.(cty).mats_YCfit(end), param_i.(cty).K1P, param_i.(cty).Lambda_1, param_i.(cty).Omega_square ,param_i.(cty).rho1*EstimationData_i.(cty).dt,EstimationData_i.(cty).dt)';
vChangesYields_APP_m   = fYieldsImpact_uSequence(EstimationData_i.(cty).mats_YCfit , uSequence.(cty)(:,:,1),...
    BX.(cty),  param_i.(cty).K1P_level);

ChangesYields_APP_m.(cty) = vChangesYields_APP_m;

figure
plot([5:10],[vChangesYields_APP.(cty)(5:10)' ChangesYields_APP_m.(cty)]*100)
legend('observed', 'fitted')

vChangesYields_PEPP_m   = fYieldsImpact_uSequence(EstimationData_i.(cty).mats_YCfit , uSequence.(cty)(:,:,2),...
    BX.(cty),  param_i.(cty).K1P_level);

ChangesYields_PEPP_m.(cty) = vChangesYields_PEPP_m;

figure
plot([5:10],[vChangesYields_PEPP.(cty)(5:10)' ChangesYields_PEPP_m.(cty)]*100)
legend('observed', 'fitted')


%%  Fit of the changes in IT yields over the APP and PEPP period

cty='IT';
BX.(cty) = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(1:EstimationData_i.(cty).mats_YCfit(end), param_i.(cty).K1P_level, param_i.(cty).Lambda_1, param_i.(cty).Omega_square ,param_i.(cty).rho1*EstimationData_i.(cty).dt,EstimationData_i.(cty).dt, param_i.(cty).Gamma_1)';

vChangesYields_APP_m  = fYieldsImpact_uSequence_wSpread(EstimationData_i.(cty).mats_YCfit , uSequence.(cty)(:,:,1),...
    BX.(cty),  param_i.(cty).K1P_level, param_i.(cty).Gamma_1);

ChangesYields_APP_m.(cty) = vChangesYields_APP_m;

figure
plot([5:10],[vChangesYields_APP.(cty)(5:10)' ChangesYields_APP_m.(cty)]*100)
legend('observed', 'fitted')

vChangesYields_PEPP_m   = fYieldsImpact_uSequence_wSpread(EstimationData_i.(cty).mats_YCfit , uSequence.(cty)(:,:,2),...
    BX.(cty),  param_i.(cty).K1P_level, param_i.(cty).Gamma_1);
ChangesYields_PEPP_m.(cty) = vChangesYields_PEPP_m;

figure
plot([5:10],[vChangesYields_PEPP.(cty)(5:10)' ChangesYields_PEPP_m.(cty)]*100)
legend('observed', 'fitted')

%% Fit of the changes in DE yields upon PEPP announcement
%for ii=1:length(countries); cty=countries{ii};

%     cty='DE'
%     vChangesYields_PEPP_m   = fYieldsImpact_uSequence(EstimationData_i.(cty).mats_YCfit / EstimationData_i.(cty).dt, uSequence.(cty)(:,:,1),...
%         fATSMDiscrete_YieldLoadingsRecurrence_BX(1:EstimationData_i.(cty).mats_YCfit(end)/EstimationData_i.(cty).dt, param_i.(cty).K1Q, param_i.(cty).rho1*EstimationData_i.(cty).dt, EstimationData_i.(cty).dt)', param_i.(cty).K1P_level);
%
%     figure
%     plot([5:10],[vChangesYields_PEPP.(cty)(5:10)' vChangesYields_PEPP_m]*100)
%     legend('observed', 'fitted')
%
%
%     cty='IT'
%     vChangesYields_PEPP_m   = fYieldsImpact_uSequence_wSpread(EstimationData_i.(cty).mats_YCfit / EstimationData_i.(cty).dt, uSequence.(cty)(:,:,1),...
%         fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(1:EstimationData_i.(cty).mats_YCfit(end)/EstimationData_i.(cty).dt, param_i.(cty).K1Q, param_i.(cty).Lambda_1, param_i.(cty).Omega_square, param_i.(cty).rho1*EstimationData_i.(cty).dt, EstimationData_i.(cty).dt, param_i.(cty).Gamma_1)', param_i.(cty).K1P_level, param_i.(cty).Gamma_1);
%
%     figure
%     plot([5:10],[vChangesYields_PEPP.(cty)(5:10)' vChangesYields_PEPP_m]*100)
%     legend('observed', 'fitted')
%



%end



%  %% Computing discount factors
%
%     % Specify maturities
%     vMaturities         = 1:1:10/EstimationData.dt;
%
%     % Estimated loadings
%     [BX, AX]            = gaussianDiscreteYieldLoadingsRecurrence(vMaturities, param.K0Q, param.K1Q, param.Omega_square, ...
%                                 param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
%     param.mDiscountFactors      = zeros(length(vMaturities),length(EstimationData.mats_TSfit));
%
%     for j = 1:length(EstimationData.mats_TSfit)
%
%         dMat_analysis                   = EstimationData.mats_TSfit(j);
%
%         % Express the yield maturity in the frequency of the model
%         mat                             = dMat_analysis/EstimationData.dt;
%
%         H = mat-1;
%
%         % Estimated weighting function
%         vDiscounting_estimated    = NaN(H,1);
%         for ii = 1:H
%             vDiscounting_estimated(ii) = ((mat-(ii-1))/mat * BX(3, mat-(ii-1)) - (mat-ii)/mat * BX(3, mat-ii)*param.K1P_level(3,3));
%         end
%
%         param.mDiscountFactors(1:H,j) = vDiscounting_estimated;
%
%     end
%
%     %     save()
%
%     DEvariables.paramDE = param;
%     DEvariables.yields_m_FullSampleDE = yields_m_FullSample;
%     DEvariables.EstimatedYieldsFullSampleDE = EstimationData.YieldsFullSample;
% %     name = ;
%     save([sOutputDirectory 'LambdasDE_TK.mat'], 'DEvariables');
