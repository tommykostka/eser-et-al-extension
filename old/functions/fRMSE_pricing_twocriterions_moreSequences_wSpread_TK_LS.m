%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective Function: RMSE averaged acrossed all maturities
%
%ss
function [MSE, MSE_yields, AX, BX] = fRMSE_pricing_twocriterions_moreSequences_wSpread(w, mX, EstimationData, param, vLambda, paramDE)

    T               = length(EstimationData.Yields);
    N               = length(param.K0P);
    N_eser          = 3;
    dt              = EstimationData.dt;
    vMaturities_TSfit     = EstimationData.mats_TSfit / dt;
    vMaturities_YCfit     = EstimationData.mats_YCfit / dt;
    
    % Gamma0 and gamma1 are guesses
    vGamma0        = vLambda(1); %0.01;
    %vGamma0        = 0; %0.01;
    
    mGamma1        = [0; 0; vLambda(2); vLambda(3)];%0.01*ones(N,1);
        
    % Lambda0 and lambda1 based on current parameter estimates for DE and a
    % guess for debt_gdp
    vLambda0        = [vLambda(4:7)]; %first three lambda zero are fixed       
    mLambda1        = [[reshape(vLambda(8:11), 2,2) zeros(2, 2)]; [zeros(2, 2) reshape(vLambda(12:15), 2,2)]]; %3 by 3 matrix is from germany
    
    %now with DE parameters
    %vLambda0        = [paramDE.Lambda_0(1:2) ; vLambda(4:5)]; %first three lambda zero are fixed       
    %mLambda1        = [[paramDE.Lambda_1(1:2,1:2) zeros(2, 2)]; [zeros(2, 2) reshape(vLambda(6:9), 2,2)]]; %3 by 3 matrix is from germany
    
    % Intercept and loadings of yields on risk factors, given current parameter estimates
    AX              = fATSMDiscrete_YieldLoadingsRecurrence_AX_Gamma(vMaturities_TSfit, param.K0P, param.K1P_level, vLambda0, mLambda1, param.Omega_square, param.rho0 * dt, param.rho1*dt, dt, vGamma0, mGamma1);
    BX              = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(vMaturities_TSfit, param.K1P_level, mLambda1, param.Omega_square, param.rho1*dt, dt, mGamma1 );
    
    
    % First part of the objective function
    vErrors_Yields      = EstimationData.Yields(:) - vec(ones(T,1)*AX + mX * BX);
    MSE_yields         = 1/T * sum(power(vErrors_Yields,2));   % KN: 1/T added in July 2018
       
     
    
    
    % Weighting of the two parts of the objective function
%     MSE                = w * MSE_yields + w/2* MSE_changesyields + w/2* MSE_changesyields
    MSE                = w * MSE_yields %+ dSum_YieldChanges_Events
    