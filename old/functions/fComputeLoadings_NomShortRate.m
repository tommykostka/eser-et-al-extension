function [A_Exp_Nom, B_Exp_Nom]   = fComputeLoadings_NomShortRate (mats, K0P_cP, K1P_cP, rho0_cP, rho1_cP)

    nMats   = length(mats);
    
    N       = length(rho1_cP);
    Kap     = eye(N) + K1P_cP; 
    
    A_Exp_Nom   = NaN(1, nMats);
    B_Exp_Nom    = NaN(N, nMats);
    
    for iMat = 1:nMats
        
        A_Exp_Nom (1,iMat)  = rho0_cP + rho1_cP'* (K1P_cP\(Kap^(mats(iMat))-eye(N)))*K0P_cP;
        B_Exp_Nom (:,iMat)  = rho1_cP'*(Kap^(mats(iMat))); 
    
    end
    
          