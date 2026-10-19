function [llk, AcP, BcP, AX, BX, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, yields_filtered, cP_filtered, outputKF] = ...
    jszLLK_KF_estimation(yields_o, W,  mats, dt,K1Q_X, kinfQ, Sigma_cP, K0P_cP, K1P_cP, sigma_e)
%
% This function computest the likelihood for a Gaussian term structure.
% See "A New Perspective on Gaussian Dynamic Term Structure Models" by Joslin, Singleton and Zhu
% 
%
% INPUTS:
% yields_o   : T*J,     matrix of observed yields (first row are t=0 observations, which likelihood conditions on)
% mats       : 1*J,      maturities in years
% dt         : scalar,   length of period in years
% W          : N*J,      vector of portfolio weights to fit without error.
% K1Q_X      : N*N,      normalized latent-model matrix (does not have to be diagonal, see form below)
% kinfQ      : scalar,   when the model is stationary, the long run mean of the annualized short rate under Q is -kinfQ/K1(m1,m1) 
% Sigma_cP   : N*N,      positive definite matrix that is the covariance of innovations to cP
% K0P_cP     : N*1,      
% K1P_cP     : N*N,      
% sigma_e    : scalar,   standard error of yield observation errors
%
%
% Compute likelihood conditioned on first observation!
%
% llk        : T*1       time series of -log likelihoods (includes 2-pi constants)
% AcP        : 1*J       yt = AcP' + BcP'*cPt  (yt is J*1 vector)
% BcP        : N*J       AcP, BcP satisfy internal consistency condition that AcP*W' = 0, BcP*W' = I_N
% AX         : 1*J       yt = AX' + BX'*Xt  
% BX         : N*J       Xt is the 'jordan-normalized' latent state
% yields_filtered : T*J  E[cPt|y^o(t), y^o(t-1), .., y^o(1)]
% cP_filtered     : T*N  E[yt|y^o(t), y^o(t-1), .., y^o(1)]
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
%
%
    
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
    
%     iSimulationPaths = 1000;
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
    A           = BcP.';
    b           = AcP.';

    % If K1P_cP is non-stationary, we will have a problem with this assumption,
    % so use something else assuming LLK will let us evaluate the likelihood
    eigP00      = eig(P00);
    if any(~isreal(eigP00)) || any(eigP00<0)
        x00     = mean(cP).';
        P00     = cov(cP);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Run Wolfgang's original Kalman Filter:
%     [x_tt_WL,P_tt_WL,yprs,Fprs,x_tm1t_WL,P_tm1t_WL,llk_WL] = WL_Kalman(y,b,A,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
    
%     % Run Wolfgang's modified Kalman Filter:
%     [m_a_tt_all,m_P_tt_all,m_y_tm1t_all,m_Vary_tm1t,m_a_tm1t_all,m_P_tm1t_all,llh] = WL_Kalman_modifiedmore(y,b,A,R,alpha,Phi,eye(N),Q,x00,P00,1,0);

%     % Run JSZ original Kalman Filter:
%     [x_tm1t, P_tm1t, x_tt, P_tt, K_t, llk] = kf( y.', Phi, alpha, A, b, Q, R, x00, P00);

    % Run extended Kalman Filter with the Closed form expression for the yields
    funcZ               = @(vstate) (b + A * vstate');
    funcJacobianZ       = @(state) A;

    [x_tt,P_tt,m_y_tm1t_all,m_Vary_tm1t,x_tm1t,P_tm1t,llk] = WL_ExtKalman_NonlinMeas_modified(y,funcZ,funcJacobianZ,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
    
%     % Run extended Kalman Filter with MCS for the yields
%     funcZ           = @(vstate)(fMCSYields_Gaussian(rho0_cP,rho1_cP, K0Q_cP,K1Q_cP,vstate,chol(Sigma_cP)',mats,dt,iSimulationPaths));
%     funcJacobianZ   = @(vstate)(gradest_A(funcZ,vstate));
% 
%     tic
%     [m_a_tt_all,m_P_tt_all,m_y_tm1t_all,m_Vary_tm1t,m_a_tm1t_all,m_P_tm1t_all,llh] = WL_ExtKalman_NonlinMeas_modified(y,funcZ,funcJacobianZ,R,alpha,Phi,eye(N),Q,x00,P00,1,0);
%     elapsedTime = toc
%    
%     [x_tm1t, P_tm1t, x_tt, P_tt, K_t, llk] = kf( y.', Phi, alpha, A, b, Q, R, x00, P00);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    llk                 = -llk; % we return negative of the llk
    cP_filtered         = x_tt.';     % T*N  E[cPt|y^o(t), y^o(t-1), .., y^o(1)]
    yields_filtered     = cP_filtered*BcP + ones(T,1)*AcP; % T*J

    % Save all the results of the KalmanFilter in one structure
    outputKF.x_tt           = x_tt.';
    outputKF.x_tm1t         = x_tm1t.';
    outputKF.P_tt           = P_tt;
    outputKF.P_tm1t         = P_tm1t;
    outputKF.m_y_tm1t_all   = m_y_tm1t_all.';
    outputKF.m_Vary_tm1t    = m_Vary_tm1t;
    outputKF.llk            = llk;
    
