function temp = fStartingValues(Results_0, param,  EstimationData)

 
 % Rearanging elements such that the VAR ordering is Level, Slope, Quantity
    temp.K0Q_0        = Results_0.param.K0Q_cP_RPC;
    temp.K1Q_0        = Results_0.param.K1Q_cP_RPC;
    
    temp.K0P_0        = Results_0.param.K0P_cP_RPC;
    temp.K1P_0        = Results_0.param.K1P_cP_RPC;

    temp.Lambda_0     = inv(chol(Results_0.param.Sigma_cP_RPC, 'lower')) * (Results_0.param.K0P_cP_RPC - Results_0.param.K0Q_cP_RPC);
    temp.Lambda_1     = inv(chol(Results_0.param.Sigma_cP_RPC, 'lower')) * (Results_0.param.K1P_cP_RPC - Results_0.param.K1Q_cP_RPC);
    
    temp.Sigma_X      = Results_0.param.Sigma_cP_RPC;
    
    temp.rho1         = Results_0.param.rho1_cP_RPC;
    temp.rho0         = Results_0.param.rho0_cP_RPC;
    
%     
%     [T,J]                       = size(EstimationData.Yields);
%     PC                          = EstimationData.Yields*EstimationData.W';
%     N                           = EstimationData.nPCs+1;
%     mX                          = [PC  EstimationData.vQuantity];
% 
%     
%     % Compute the model-implied yields given these starting values -
%     % function with Q-parameters
%     [BX_0, AX_0]   = gaussianDiscreteYieldLoadingsRecurrence(EstimationData.mats / EstimationData.dt, temp.K0Q_0, temp.K1Q_0, temp.Sigma_X, ...
%                                     temp.rho0*EstimationData.dt, temp.rho1*EstimationData.dt, EstimationData.dt);
%                         
%     % Compute the model-implied yields given these starting values -
% %     % function with lambda parameters
% %     [BX_0_vLambda, AX_0_vLambda]   = gaussianDiscreteYieldLoadingsRecurrence_lambda(EstimationData.mats / EstimationData.dt, temp.K0P_0, temp.K1P_0, temp.Lambda_0, temp.Lambda_1, ...
% %                                         temp.Sigma_X, temp.rho0*EstimationData.dt, temp.rho1*EstimationData.dt, EstimationData.dt);
% % 
% %     By_lambda = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(EstimationData.mats / EstimationData.dt, temp.K1P_0, temp.Lambda_1, temp.Sigma_X, ...
% %                     temp.rho1*EstimationData.dt, EstimationData.dt);
% %     Ay_lambda = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(EstimationData.mats / EstimationData.dt, temp.K0P_0, temp.K1P_0, temp.Lambda_0, temp.Lambda_1, temp.Sigma_X, ...
% %                                             temp.rho0 * EstimationData.dt, temp.rho1*EstimationData.dt, EstimationData.dt);
% 
%                                         
%     yields_m_0     = ones(T,1)*AX_0 + PC * BX_0; % (T+1)*J, model-implied yields
%     
%     
% %     sqrt(mean(power(EstimationData.Yields - yields_m_0,2)))*10000
%    
%     % Compute the model-implied yields given these starting values and
%     % already estimated parameters
%     [BX_combi, AX_combi]     = gaussianDiscreteYieldLoadingsRecurrence(EstimationData.mats / EstimationData.dt, [temp.K0Q_0(1:N-1); param.K0P(3)], ...
%                             [temp.K1Q_0(1:N-1,:) zeros(N-1,1); param.K1P(3,:)], param.Omega_square, param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
% %                                         
% %     By = fATSMDiscrete_YieldLoadingsRecurrence_BX(EstimationData.mats / EstimationData.dt, [temp.K1Q_0(1:N-1,:); param.K1P(3,:)], param.rho1*EstimationData.dt, EstimationData.dt);
% %     Ay = fATSMDiscrete_YieldLoadingsRecurrence_AX(EstimationData.mats / EstimationData.dt, [temp.K0Q_0(1:N-1); param.K0P(3)], [temp.K1Q_0(1:N-1,:); param.K1P(3,:)], param.Omega_hat, ...
% %                                             param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
% %                                         
% %     By_lambda = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(EstimationData.mats / EstimationData.dt, [temp.K1Q_0(1:N-1,:); param.K1P(3,:)], param.rho1*EstimationData.dt, EstimationData.dt);
% %     Ay_lambda = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(EstimationData.mats / EstimationData.dt, [temp.K0Q_0(1:N-1); param.K0P(3)], [temp.K1Q_0(1:N-1,:); param.K1P(3,:)], param.Omega_hat, ...
% %                                             param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
% 
%     [BX_combi_lambda, AX_combi_lambda]   = gaussianDiscreteYieldLoadingsRecurrence_lambda(EstimationData.mats / EstimationData.dt, param.K0P, param.K1P, [temp.Lambda_0; 0],...
%         [temp.Lambda_1 zeros(N-1,1); zeros(1,N)], param.Omega_square, param.rho0*EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
% 
%     By_lambda_combi = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(EstimationData.mats / EstimationData.dt, param.K1P, [temp.Lambda_1 zeros(N-1,1); zeros(1,N)], ...
%                             param.Omega_square, param.rho1*EstimationData.dt, EstimationData.dt);
%                         
%     Ay_lambda_combi = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(EstimationData.mats / EstimationData.dt, param.K0P, param.K1P, [temp.Lambda_0; 0], ...
%                             [temp.Lambda_1 zeros(N-1,1); zeros(1,N)], param.Omega_square, param.rho0 * EstimationData.dt, param.rho1*EstimationData.dt, EstimationData.dt);
% 
%     yields_m_combi  = ones(T,1)*Ay_lambda_combi + mX * By_lambda_combi; % (T+1)*J, model-implied yields

%     sqrt(mean(power(EstimationData.Yields - yields_m_combi,2)))*10000
    
   % Fitting of individual yields
%     for i = 1:length(vMaturities_estimation)
%         
% %         plot([EstimationData.Yields(:,i) yields_m_0(:,i)]*100)
%         plot([EstimationData.Yields(:,i) yields_m_combi(:,i)]*100)
%         
%         legend('observed', 'model')
%         title(['Yield ' num2str(i)])
%         pause(4)
%     end
