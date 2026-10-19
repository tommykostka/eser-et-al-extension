function By = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(maturities, K1P, L1, H0d, rho1d, timestep)
   
    chol_H  = chol(H0d, 'lower');
    K1Q     = K1P - chol_H * L1; 

    J       = length(maturities);
    N       = length(rho1d);
    Btemp   = zeros(N,1);
    
    curr_mat = 1;
    for i = 1:maturities(J)
        Btemp               = Btemp + K1Q'*Btemp - rho1d;

        if i==ceil(maturities(curr_mat))                            % KN 29Nov2017: Ceil inserted to cater for the possibility of non-interger maturities - occurs in the case daily data are used in the estimation  
            By(:,curr_mat)  = -Btemp/maturities(curr_mat);
            curr_mat        = curr_mat + 1;
        end
    end

    % Annualize the yields
    if nargin==6
        By = By/timestep;
    end
