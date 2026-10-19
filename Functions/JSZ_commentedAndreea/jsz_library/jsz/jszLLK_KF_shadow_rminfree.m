function outputKF = jszLLK_KF_shadow_rminfree(yields_o, W, mats, dt, K1Q_X, kinfQ, Sigma_cP, K0P_cP, K1P_cP, sigma_e, iSimulationPaths, rmin)

% See "A New Perspective on Gaussian Dynamic Term Structure Models" by Joslin, Singleton and Zhu
%
% INPUTS:
% yields_o          : T*J,      matrix of observed yields (first row are t=0 observations, which likelihood conditions on)
% W                 : N*J,      vector of portfolio weights to fit with error.
% mats              : 1*J,      maturities in years
% dt                : scalar,   length of period in years
% K1Q_X             : N*N,      normalized latent-model matrix (does not have to be diagonal, see form below)
% kinfQ             : scalar,   when the model is stationary, the long run mean of the annualized short rate under Q is -kinfQ/K1(m1,m1) 
% Sigma_cP          : N*N,      positive definite matrix that is the covariance of innovations to cP
% K0P_cP            : N*1,      
% K1P_cP            : N*N,      
% sigma_e           : scalar,   standard error of yield observation errors
% iSimulationPaths  : scalar    number of simulations used for the function that computes yields based on Monte Carlo Simulations
%
% OUTPUTS:
% outputKF          : structure contains all results of the Extended Kalman Filter
% 
% The model takes the form:
%   r(t) = rho0_cP + rho1_cP'*cPt
%        = rinfQ + 1'*Xt  (Xt is the 'jordan-normalized' state
%        = 1 period discount rate (annualized)
%
% Under Q:
%   X(t+1) - X(t)   =          K1Q_X*X(t)  + eps_X(t+1),   cov(eps_X(t+1)) = Sigma_X
%   cP(t+1) - cP(t) = K0Q_cP + K1Q_cP*X(t) + eps_cP(t+1),  cov(eps_cP(t+1)) = Sigma_cP
%   where Sigma_X is chosen to match Sigma_cP 
%
% Under P:
%   cP(t+1) - cP(t) = K0P_cP + K1P_cP*X(t) + eps_cP(t+1),  cov(eps_cP(t+1)) = Sigma_cP
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Setup 
    [T,J]       = size(yields_o);
    % Setup W if we are using individual yields without error:
    if isempty(W)
        W       = eye(J);
        W       = W(ismember(mats, yields_o),:); % N*J    
    end
    N           = size(W,1);
    cP          = yields_o*W'; % (T+1)*N, cP stands for math caligraphic P.
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % COMPUTE THE JSZ-Normalized version of the model:
    % yt = AcP' + BcP'*cPt, AcP is 1*J, BcP is N*J
    [BcP, AcP, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, K0Q_X, K1Q_X, AX, BX, Sigma_X] = jszLoadings(W, K1Q_X, kinfQ, Sigma_cP, mats, dt);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now setup Kalman filter.
    y           = yields_o;  % T*J
    Phi         = eye(N) + K1P_cP; % N*N
    alpha       = K0P_cP; % N*1
    Q           = Sigma_cP;  % N*N
    R           = eye(J)*sigma_e^2;

    % Assume that the t=0 states (the time before any yields are observed)
    % are distributed N(mu, Sigma) with the model stationary distribution,
    [x00, P00]  = asymptoticMomentsGaussian(K0P_cP, K1P_cP, Sigma_cP);
%     A           = BcP.';
%     b           = AcP.';

    % If K1P_cP is non-stationary, we will have a problem with this assumption,
    % so use something else assuming LLK will let us evaluate the likelihood
    eigP00      = eig(P00);
    if any(~isreal(eigP00)) || any(eigP00<0)
        x00     = mean(cP).';
        P00     = cov(cP);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Run Wolfgang's Kalman Filter:
%     [x_tt_WL,P_tt_WL,yprs,Fprs,x_tm1t_WL,P_tm1t_WL,llk_WL] = WL_Kalman(y,b,A,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
    
    % Run Wolfgang's modified Kalman Filter:
%     [m_a_tt_all,m_P_tt_all,m_y_tm1t_all,m_Vary_tm1t,m_a_tm1t_all,m_P_tm1t_all,llh] = WL_Kalman_modifiedmore(y,b,A,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
   
   % Run extended Kalman Filter with MCS for the yields
    funcZ           = @(vstate)(fMCSYields_Shadow_rminfree(rho0_cP,rho1_cP, K0Q_cP,K1Q_cP,vstate,chol(Sigma_cP)',mats,dt,iSimulationPaths,rmin));
    funcJacobianZ   = @(vstate)(gradest_A(funcZ,vstate));
  
    tic
    [x_tt,P_tt,m_y_tm1t_all,m_Vary_tm1t,x_tm1t,P_tm1t,llk_shadow] = WL_ExtKalman_NonlinMeas_modified(y,funcZ,funcJacobianZ,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
    elapsedTime = toc
   
    % Save all the results of the KalmanFilter in one structure
    outputKF.x_tt                   = x_tt.';
    outputKF.x_tm1t                 = x_tm1t.';
    outputKF.P_tt                   = P_tt;
    outputKF.P_tm1t                 = P_tm1t;
    outputKF.m_y_tm1t_all           = m_y_tm1t_all.';
    outputKF.m_Vary_tm1t            = m_Vary_tm1t;
    outputKF.llk                    = -llk_shadow;
  
    yields_filtered_shadow          = transpose(fMCSYields_Shadow_rminfree(rho0_cP,rho1_cP, K0Q_cP,K1Q_cP,...
                                            outputKF.x_tt,chol(Sigma_cP)',mats,dt,iSimulationPaths,rmin)); % T*J
    outputKF.yields_filtered_shadow = yields_filtered_shadow;

 