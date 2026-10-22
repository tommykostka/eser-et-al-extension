%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Objective Function: RMSE averaged acrossed all maturities
%
%
function [MSE, MSE_yields, MSE_changesyields, AX, BX] = fRMSE_pricing_twocriterions_moreSequences_ITSpread_multi_2(w, mX, mChangesYields, mChangesSpreads, m_uSeq, m_uSeqSpread, EstimationData, param, vLambda)

    T               = length(EstimationData.Yields);
    N               = length(param.K0P);
    N_eser          = 3;
    dt              = EstimationData.dt;
    vMaturities_TSfit     = EstimationData.mats_TSfit / dt;
    vMaturities_YCfit     = EstimationData.mats_YCfit / dt;
    
     vLambda0_DE = vLambda(N+4:N+5);
     mLambda1_DE = vLambda(N+6:N+11);
    
    % Gamma0 and gamma1 are guesses
    vGamma0        = vLambda(1);
    mGamma1        = vLambda(2:N+1);
    
    % Lambda0 and lambda1 based on current parameter estimates and
    % guesses
    vLambda0        = [vLambda0_DE; 0 ; vLambda(N+2: N+3) ; 0]; %first three lambda zero are fixed
%     mLambda1        = [[reshape(vLambda(N+6:N+9), 2, 2) zeros(2, N_eser)]; [zeros(N_eser, N_eser-1) [vLambda(N+10) 0  0 ; zeros(2, 2) reshape(vLambda(N+11:N+14), 2, 2) ]]]; %3 by 3 matrix is from germany
    mLambda1        = [reshape([mLambda1_DE ; vLambda(N+12:N+17)], 2, 6) ; zeros(1, N); reshape(vLambda(N+18:end), 2, 6) ; zeros(1, N)];
  
  
     % Intercept and loadings of yields on risk factors, given current parameter estimates
    AX              = fATSMDiscrete_YieldLoadingsRecurrence_AX_Gamma(vMaturities_TSfit, param.K0P, param.K1P_level, vLambda0, mLambda1, param.Omega_square, param.rho0 * dt, param.rho1*dt, dt, vGamma0, mGamma1);
    BX              = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(vMaturities_TSfit, param.K1P_level, mLambda1, param.Omega_square, param.rho1*dt, dt, mGamma1 );
   
    
    % First part of the objective function
    vErrors_Yields      = EstimationData.Yields(:) - vec(ones(T,1)*AX + mX * BX);
    MSE_yields         = 1/T * sum(power(vErrors_Yields,2));   % KN: 1/T added in July 2018
    
    % Second part of the objective function
    BX_all                  = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(1:vMaturities_YCfit(end), param.K1P_level, mLambda1, param.Omega_square, param.rho1*dt, dt, mGamma1);
    
    % Identify how many event sequences are there
    nEvents = size(mChangesYields, 2); % each column is a vector of observed yield changes upon an event
    dSum_YieldChanges_Events = 0;
    
    MSE_changesyields =[];    
    for iEevent = 1:nEvents
        
        v_uSeq                  = m_uSeq(:,:,iEevent);
        vErrors_ChangesYields   = mChangesYields(:,iEevent) - fYieldsImpact_uSequence_wSpread(vMaturities_YCfit,v_uSeq, BX_all', param.K1P_level, mGamma1);
        MSE_changesyields       = sum(power(vErrors_ChangesYields,2));
        %dSum_YieldChanges_Events = dSum_YieldChanges_Events + 1/nEvents*w*MSE_changesyields; % all events receive equal weight in the total weight of the sum of errors of changes in yields
        dSum_YieldChanges_Events = dSum_YieldChanges_Events + 1/nEvents*MSE_changesyields; % all events receive equal weight in the total weight of the sum of errors of changes in yields
        
    end
    
    nEventsspread = size(mChangesSpreads, 2); % each column is a vector of observed yield changes upon an event
    dSum_SpreadChanges_Events = 0;
    MSE_changesspreads =[];    
    for iEevent = 1:nEventsspread
        
        v_uSeq                  = m_uSeqSpread(:,:,iEevent);
        vErrors_ChangesSpreads   = mChangesSpreads(:,iEevent) - fYieldsImpact_uSequence_wSpread(vMaturities_YCfit,v_uSeq, BX_all', param.K1P_level, mGamma1) ;
%         vErrors_ChangesSpreads   = mChangesSpreads(:,iEevent) - fYieldsImpact_uSequence_wSpread(vMaturities_YCfit,v_uSeq, BX_all', param.K1P_level, mGamma1) - ChangesYieldsDE;
        MSE_changesspreads       = sum(power(vErrors_ChangesSpreads,2));
        dSum_SpreadChanges_Events = dSum_SpreadChanges_Events + 1/nEventsspread*MSE_changesspreads; % all events receive equal weight in the total weight of the sum of errors of changes in yields
        
    end
    
    
    
    
    
    % Weighting of the two parts of the objective function
%     MSE                = w * MSE_yields + w/2* MSE_changesyields + w/2* MSE_changesyields
    MSE                = w * MSE_yields + w/2*dSum_YieldChanges_Events + w/2*dSum_SpreadChanges_Events;
    