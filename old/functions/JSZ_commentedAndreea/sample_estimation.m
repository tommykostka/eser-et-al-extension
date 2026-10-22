    clearvars
    close all
    restoredefaultpath
    addpath(genpath('jsz_library'))
    clc

    sCurrentPath                    = 'K:\EC-Mp\CM Division\Vladu\2013-09_MoneyMarketModel';
    addpath(genpath(sCurrentPath));
    
% This gives a sample estimation of an N-factor "without error" GDTSM.
% See "A New Perspective on Gaussian Dynamic Term Structure Models" by Joslin, Singleton and Zhu

    % Load some data: mats (1*J) and yields (T*J)
    load('sample_zeros.mat') 


    % Setup format of model/data:
    % A: indicate the number of factors (PCs)
    N = 3;
    % A: computhe all Js Principal Components
    W = pcacov(cov(yields));
    % A: Select only the Nth PCs
    W = W(:,1:N)';  % N*J
    % A: determine the time series of the portfolio of yields: 
    % paper: cP = W_(N*J) * y_(J*1)
    % since we have a matrix with the time series of the yields_(T*J), we must
    % multiply this with W'_(J*N) => cP_(T*N)
    cP = yields*W'; % T*N
    dt = 1/12;

%%  MODEL RPC

    % Estimate the model by ML. 
    help sample_estimation_fun
    VERBOSE = true;
    [llks, AcP, BcP, AX, BX, kinfQ, K0P_cP, K1P_cP, sigma_e, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, llkP, llkQ,  K0Q_X, K1Q_X, rho0_X, rho1_X, Sigma_cP] = ...
            sample_estimation_fun(W, yields, mats, dt, VERBOSE);

    %   when the model is stationary, the long run mean of the annualized short rate under Q is -kinfQ/K1(m1,m1)     
    [~, isTypicalDiagonal, m1] = jszAdjustK1QX(K1Q_X);
    rinfQ       = -kinfQ/K1Q_X(m1,m1);

%% REPRODUCE VALUES FROM THE TABLES 
    fprintf('Table 2 - Model RPC - \n ML estimates of the risk-neutral parameters of the model-implied PCs \n - (lambdas from K1Q_X) \n %6.3g, %6.3g, %6.3g \n ', diag(K1Q_X))
    fprintf('rQ_inf is %6.3g \n ', rinfQ)
    
    fprintf('Table 3 - Model RPC - \n ML estimates of the physical parameters of the model-implied PCs \n - (K1P_xP*12) \n ')
    K1P_cP_temp     = transpose(K1P_cP);
    (K1P_cP_temp(:))'*12

%     -(inv(K1P_cP)*K0P_cP)'* K1P_cP*12
    
    fprintf('Table 4 - Model RPC - \n ML estimates of the conditional covariance of the model-implied PCs \n')
    fprintf('Annualized volatilities \n ')
    sqrt(diag(Sigma_cP))*sqrt(12)*100
    corr12 = Sigma_cP(1,2)/(sqrt(Sigma_cP(1,1)*Sigma_cP(2,2)));    
    corr13 = Sigma_cP(1,3)/(sqrt(Sigma_cP(1,1)*Sigma_cP(3,3)));
    corr23 = Sigma_cP(2,3)/(sqrt(Sigma_cP(2,2)*Sigma_cP(3,3)));
    fprintf('Correlations \n ')   
    [corr12 corr13 corr23]
    
%%  MODEL RKF

%      [llk, AcP, BcP, AX, BX, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, yields_filtered, cP_filtered] = ...
%         jszLLK_KF(yields, W, K1Q_X, kinfQ, Sigma_cP, mats, dt, K0P_cP, K1P_cP, sigma_e);
    
    [vllk, AcP, BcP, AX, BX, kinfQ, K0P_cP, K1P_cP, sigma_e, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, K0Q_X, K1Q_X, rinfQ, Sigma_cP, yields_filtered, cP_filtered] = ...    
    estimate_jszLLK_KF(W, yields, mats, dt, K1Q_X, Sigma_cP, kinfQ, K0P_cP, K1P_cP, sigma_e, VERBOSE);

%% REPRODUCE VALUES FROM THE TABLES 
    fprintf('Table 2 - Model RKF - \n ML estimates of the risk-neutral parameters of the model-implied PCs \n - (lambdas from K1Q_X) \n %6.3g, %6.3g, %6.3g \n ', diag(K1Q_X))
    fprintf('rQ_inf is %6.3g \n ', rinfQ)
    
    fprintf('Table 3 - Model RKF - \n ML estimates of the physical parameters of the model-implied PCs \n - (K1P_xP*12) \n ')
    K1P_cP_temp     = transpose(K1P_cP);
    (K1P_cP_temp(:))'*12

%     -(inv(K1P_cP)*K0P_cP)'* K1P_cP*12
    
    fprintf('Table 4 - Model RKF - \n ML estimates of the conditional covariance of the model-implied PCs \n')
    fprintf('Annualized volatilities \n ')
    sqrt(diag(Sigma_cP))*sqrt(12)*100
    corr12 = Sigma_cP(1,2)/(sqrt(Sigma_cP(1,1)*Sigma_cP(2,2)));    
    corr13 = Sigma_cP(1,3)/(sqrt(Sigma_cP(1,1)*Sigma_cP(3,3)));
    corr23 = Sigma_cP(2,3)/(sqrt(Sigma_cP(2,2)*Sigma_cP(3,3)));
    fprintf('Correlations \n ')   
    [corr12 corr13 corr23]
    
    fprintf('The average (negative) log likelihood is %6.6g when using KF instead of assuming yields without error at these estimates\n', mean(llk))

