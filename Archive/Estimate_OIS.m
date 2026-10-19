
    % Clearing memory and graphical interface
    clc;
    clearvars;
    close all;
 
    sOutputDirectory    = 'Output_mat\'; 
    sInputDirectory     = 'Input_mat\'; % Output wrt to this code but will be input to the main analysis  

    addpath(genpath([cd '\']));
    
%%  Estimation specifications
    
    sStartSample_TS_Estimation  = 'Mar2009'; %1999, 2014
    sEndSample_TS_Estimation    = 'Aug2014'; %  Dec2021
    
%% Load also the OIS data
    load([sInputDirectory 'OIS.mat']);

    %% OIS data

    %Specify the OIS yields to be used for constructing the level and the
    %slope factors
    index_mats_OIS = 5:14; % from 1y to 10y
    indexStartSample_estimation_OIS     = find(strcmp(cellstr(datestr(Data_OIS.MatlabDates, 'mmmyyyy')), sStartSample_TS_Estimation), 1, 'first');
    indexEndSample_estimation_OIS       = find(strcmp(cellstr(datestr(Data_OIS.MatlabDates, 'mmmyyyy')), sEndSample_TS_Estimation), 1, 'last');
   
    OIS_rates   = Data_OIS.OIS_rates(indexStartSample_estimation_OIS:indexEndSample_estimation_OIS,index_mats_OIS); % OIS rates from 1y to 10y (leave for the moment longer or shorter maturities out)
    N_OIS = 2;  
    
    W = pca(OIS_rates);  % Compute loading matrix for principal components 

    % explained_cum = cumsum(explained);
    W = W(:,1:N_OIS)';            % N*J ("J" is the number of maturities)
    % OPPOSITE OF PC2
    W(2,:)       = -W(2,:);
   
    cP_OIS_o = OIS_rates*W';   % T*N % principal components ("cP" stands for "caligraphic P", as in the JSZ paper)

    mats = 1:10;
    dt = 1/12;
    
    % surveys)
    VERBOSE = true;
    [llks, AcP, BcP, AX, BX, kinfQ, K0P_cP, K1P_cP, Sigma_cP, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, llkP, llkQ, K0Q_X, K1Q_X, rho0_X, rho1_X] = ...
        sample_estimation_fun(W, OIS_rates, mats, dt, VERBOSE);

%% Saving parameters 

    param_OIS_0.K0Q_0        = K0Q_cP;
    param_OIS_0.K1Q_0        = K1Q_cP;
    
    param_OIS_0.K0P_0        = K0P_cP;
    param_OIS_0.K1P_0        = K1P_cP;

    param_OIS_0.Lambda_0     = inv(chol(Sigma_cP, 'lower')) * (K0P_cP - K0Q_cP);
    param_OIS_0.Lambda_1     = inv(chol(Sigma_cP, 'lower')) * (K1P_cP - K1Q_cP);
    
    param_OIS_0.Sigma_X      = Sigma_cP;
    
    param_OIS_0.rho1         = rho1_cP;
    param_OIS_0.rho0         = rho0_cP;
    
    save([sOutputDirectory 'StartingValues_ATSM_OIS.mat'], 'param_OIS_0');
    
    
