function By = fATSMDiscrete_YieldLoadingsRecurrence_BX(maturities, K1d, rho1d, timestep)
   
    J       = length(maturities);
    N       = length(rho1d);
    Btemp   = zeros(N,1);
    
    curr_mat = 1;
    for i = 1:maturities(J)
        Btemp               = Btemp + K1d'*Btemp - rho1d;

        if i==maturities(curr_mat)
            By(:,curr_mat)  = -Btemp/maturities(curr_mat);
            curr_mat        = curr_mat + 1;
        end
    end

    % Annualize the yields
    if nargin==4
        By = By/timestep;
    end
