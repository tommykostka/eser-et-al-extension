%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective Function: RMSE averaged acrossed all maturities
%
%
function [MSE,  AX, BX] = fRMSE_pricing_twocriterions_moreSequences(w, mX, mChangesYields, m_uSeq, EstimationData, param, vLambda)

    T               = length(EstimationData.Yields);
    N               = length(param.K0P);
    dt              = EstimationData.dt;
    vMaturities_TSfit     = EstimationData.mats_TSfit / dt;
    vMaturities_YCfit     = EstimationData.mats_YCfit / dt;
    
    % Lambda0 and lambda1 based on current parameter estimates
    vLambda0        = [vLambda(1:N)];
    mLambda1        = [reshape(vLambda(N+1:end), N, N);];
    
    % Intercept and loadings of yields on risk factors, given current parameter estimates
    AX              = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(vMaturities_TSfit, param.K0P, param.K1P, vLambda0, mLambda1, param.Omega_square, param.rho0 * dt, param.rho1*dt, dt);
    BX              = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(vMaturities_TSfit, param.K1P, mLambda1, param.Omega_square, param.rho1*dt, dt);
    
    % First part of the objective function
    vErrors_Yields      = EstimationData.Yields(:) - vec(ones(T,1)*AX + mX * BX);
    MSE_yields         = 1/T * sum(power(vErrors_Yields,2));   % KN: 1/T added in July 2018
    
    % Second part of the objective function
    BX_all                  = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(1:vMaturities_YCfit(end), param.K1P, mLambda1, param.Omega_square, param.rho1*dt, dt);
    
    
    % Weighting of the two parts of the objective function
%     MSE                = w * MSE_yields + w/2* MSE_changesyields + w/2* MSE_changesyields
    MSE                = w * MSE_yields
    