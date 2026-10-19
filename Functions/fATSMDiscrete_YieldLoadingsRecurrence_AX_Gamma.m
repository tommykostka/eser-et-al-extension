function Ay = fATSMDiscrete_YieldLoadingsRecurrence_AX_Gamma(maturities, K0P, K1P, L0, L1, H0d, rho0d, rho1d, timestep, G0, G1)

    chol_H  = chol(H0d, 'lower');
    K0Q     = K0P - chol_H * L0; 
    K1Q     = K1P - chol_H * L1; 
    
    J       = length(maturities);
    N       = length(K0Q);
    Atemp   = 0;
    Btemp   = zeros(N,1);
    
    curr_mat = 1;
    for i = 1:maturities(J)
        Atemp               = Atemp + K0Q'*(Btemp - G1) +.5*(Btemp - G1)'*H0d*(Btemp - G1) -rho0d - G0; 
        Btemp               = K1Q'*(Btemp - G1) - rho1d;

        if i==ceil(maturities(curr_mat))                             % KN 29Nov2017: Ceil inserted to cater for the possibility of non-interger maturities - occurs in the case daily data are used in the estimation  
            Ay(1,curr_mat)  = -Atemp/maturities(curr_mat);
            curr_mat        = curr_mat + 1;
        end
    end

    % Annualize the yields
    if nargin==9
        Ay = Ay/timestep;
    end
