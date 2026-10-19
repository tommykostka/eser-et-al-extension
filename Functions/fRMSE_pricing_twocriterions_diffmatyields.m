%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective Function: RMSE averaged acrossed all maturities
%
%
function [MSE, MSE_yields, MSE_changesyields, AX, BX] = fRMSE_pricing_twocriterions_diffmatyields(w, mX, vChangesYields, uSeq, EstimationData, param, vLambda)

    T               = length(EstimationData.Yields);
    N               = length(param.K0P);
    dt              = EstimationData.dt;
    vMaturities_TSfit     = EstimationData.mats_TSfit / dt;
    vMaturities_YCfit     = EstimationData.mats_YCfit / dt;
    
    % Lambda0 and lambda1 based on current parameter estimates
    vLambda0        = [vLambda(1:N-1); 0];
    mLambda1        = [reshape(vLambda(N:end), N-1, N); zeros(1,N)];
    
    % Intercept and loadings of yields on risk factors, given current parameter estimates
    AX              = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(vMaturities_TSfit, param.K0P, param.K1P, vLambda0, mLambda1, param.Omega_square, param.rho0 * dt, param.rho1*dt, dt);
    BX              = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(vMaturities_TSfit, param.K1P, mLambda1, param.Omega_square, param.rho1*dt, dt);
    
    % First part of the objective function
    vErrors_Yields      = EstimationData.Yields(:) - vec(ones(T,1)*AX + mX * BX);
    MSE_yields         = 1/T * sum(power(vErrors_Yields,2));   % KN: 1/T added in July 2018
    
    % Second part of the objective function
    BX_all                  = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(1:vMaturities_YCfit(end), param.K1P, mLambda1, param.Omega_square, param.rho1*dt, dt);
    vErrors_ChangesYields   = vChangesYields' - fYieldsImpact_uSequence(vMaturities_YCfit, uSeq, BX_all', param.K1P_level);
    MSE_changesyields      = sum(power(vErrors_ChangesYields,2));
    
    % Weighting of the two parts of the objective function
    MSE                = w * MSE_yields + (1-w)* MSE_changesyields 
    