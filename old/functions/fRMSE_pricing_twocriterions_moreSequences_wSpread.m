%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective Function: RMSE averaged acrossed all maturities
%
%
function [MSE, MSE_yields, MSE_changesyields, AX, BX] = fRMSE_pricing_twocriterions_moreSequences_wSpread(w, mX, mChangesYields, m_uSeq, EstimationData, param, vLambda, paramDE)

    T               = length(EstimationData.Yields);
    N               = length(param.K0P);
    N_eser          = 3;
    dt              = EstimationData.dt;
    vMaturities_TSfit     = EstimationData.mats_TSfit / dt;
    vMaturities_YCfit     = EstimationData.mats_YCfit / dt;
    
    % Gamma0 and gamma1 are guesses
    vGamma0        = vLambda(1);
    mGamma1        = vLambda(2:N+1);
    
    % Lambda0 and lambda1 based on current parameter estimates for DE and a
    % guess for debt_gdp
    vLambda0        = [paramDE.Lambda_0; 0 ; 0]; %first three lambda zero are fixed
    mLambda1        = [[paramDE.Lambda_1 zeros(N_eser, N-N_eser)]; [zeros(N-N_eser, N_eser) [vLambda(end-1) 0 ; 0 vLambda(end) ]]]; %3 by 3 matrix is from germany
    
    
    
    % Intercept and loadings of yields on risk factors, given current parameter estimates
    AX              = fATSMDiscrete_YieldLoadingsRecurrence_AX_Gamma(vMaturities_TSfit, param.K0P, param.K1P_level, vLambda0, mLambda1, param.Omega_square, param.rho0 * dt, param.rho1*dt, dt, vGamma0, mGamma1);
    BX              = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(vMaturities_TSfit, param.K1P_level, mLambda1, param.Omega_square, param.rho1*dt, dt, mGamma1 );
    
    
    % First part of the objective function
    vErrors_Yields      = EstimationData.Yields(:) - vec(ones(T,1)*AX + mX * BX);
    MSE_yields         = 1/T * sum(power(vErrors_Yields,2));   % KN: 1/T added in July 2018
       
    
    BX_all                  = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(1:vMaturities_YCfit(end), param.K1P_level, mLambda1, param.Omega_square, param.rho1*dt, dt, mGamma1);
    
    % Identify how many event sequences are there
    nEvents = size(mChangesYields, 2); % each column is a vector of observed yield changes upon an event
    dSum_YieldChanges_Events = 0;
    
    for iEevent = 1:nEvents
        
%         v_uSeq                  = m_uSeq(:,:,1);
        v_uSeq                  = m_uSeq(:,:,iEevent);
        vErrors_ChangesYields   = mChangesYields(:,iEevent) - fYieldsImpact_uSequence_wSpread(vMaturities_YCfit,v_uSeq, BX_all', param.K1P_level, mGamma1);
        MSE_changesyields       = sum(power(vErrors_ChangesYields,2));
        dSum_YieldChanges_Events = dSum_YieldChanges_Events + 1/nEvents*w*MSE_changesyields; % all events receive equal weight in the total weight of the sum of errors of changes in yields
        
    end
    
    
    % Weighting of the two parts of the objective function
%     MSE                = w * MSE_yields + w/2* MSE_changesyields + w/2* MSE_changesyields
    MSE                = w * MSE_yields + dSum_YieldChanges_Events
    