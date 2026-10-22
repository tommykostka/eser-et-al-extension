function Ay = fATSMDiscrete_YieldLoadingsRecurrence_AX(maturities, K0d, K1d, H0d, rho0d, rho1d, timestep)

    J       = length(maturities);
    N       = length(K0d);
    Atemp   = 0;
    Btemp   = zeros(N,1);
    
    curr_mat = 1;
    for i = 1:maturities(J)
        Atemp               = Atemp + K0d'*Btemp +.5*Btemp'*H0d*Btemp -rho0d; 
        Btemp               = Btemp + K1d'*Btemp - rho1d;

        if i==maturities(curr_mat)
            Ay(1,curr_mat)  = -Atemp/maturities(curr_mat);
            curr_mat        = curr_mat + 1;
        end
    end

    % Annualize the yields
    if nargin==7
        Ay = Ay/timestep;
    end
