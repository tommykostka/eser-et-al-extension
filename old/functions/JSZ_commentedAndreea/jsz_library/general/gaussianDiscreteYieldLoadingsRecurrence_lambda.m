function [By, Ay] = gaussianDiscreteYieldLoadingsRecurrence_lambda(maturities, K0P, K1P, L0, L1, H0d, rho0d, rho1d, timestep)
% function [By, Ay] = gaussianDiscreteYieldLoadingsRecurrence(maturities, K0d, K1d, H0d, rho0d, rho1d, timestep)
%
% K0d      : N*1
% K1d      : N*1
% H0d      : N*N
% rho0d    : scalar  
% rho1d    : N*1
% timestep : optional argument.
%
% By : N*M
% Ay : 1*M  (faster to not compute with only one output argument)
%
% r(t)   = rho0d + rho1d'Xt
%        = 1 period discount rate
% P(t)   =  price of  t-period zero coupon bond
%        = EQ0[exp(-r0 - r1 - ... - r(t-1)]
%        = exp(A+B'X0)
% yields = Ay + By'*X0
%   yield is express on a per period basis unless timestep is provided.
%   --For example, if the price of a two-year zero is exp(-2*.06)=exp(-24*.005),
%   --and we have a monthly model, the function will return Ay+By*X0=.005
%   --unless timestep=1/12 is provided in which case it returns Ay+By*X0=.06
%
% Where under Q:
%   X(t+1) - X(t) = K0d + K1d*X(t) + eps(t+1),  cov(eps(t+1)) = H0d
%
% A1 = -rho0d
% B1 = -rho1d
% At = A(t-1) + K0d'*B(t-1)+.5*B(t-1)'*H0d*B(t-1) - rho0d
% Bt = B(t-1) + K1d'*B(t-1) - rho1d
%
% maturities: 1*M # of periods

    % Compute the Q-parameters given the P-parameters and the market prices
    % of risk
    chol_H  = chol(H0d, 'lower');
    K0Q     = K0P - chol_H * L0; 
    K1Q     = K1P - chol_H * L1; 
    
    J       = length(maturities);
    N       = length(K0Q);
    Atemp   = 0;
    Btemp   = zeros(N,1);
    A       = nan(1,J);
    B       = nan(N,J);

    curr_mat = 1;
    for i = 1:maturities(J)
        Atemp               = Atemp + K0Q'*Btemp +.5*Btemp'*H0d*Btemp -rho0d; 
        Btemp               = Btemp + K1Q'*Btemp - rho1d;

        if i==maturities(curr_mat)
            Ay(1,curr_mat)  = -Atemp/maturities(curr_mat);
            By(:,curr_mat)  = -Btemp/maturities(curr_mat);
            curr_mat        = curr_mat + 1;
        end
    end

    % Annualize the yields
    if nargin==9
        Ay = Ay/timestep;
        By = By/timestep;
    end
