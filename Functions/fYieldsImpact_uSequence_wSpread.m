function vY = fYieldsImpact_uSequence_wSpread(vmat, uSeq, bnMat, Phi, G1)
% Model is Li and wei IJCB, 
%INPUT:
% uSeq is anticipated sequence of shocks, h=0,..,H, 
% this is define as XHat_t = X_t + u_t, ie the shock is how Xt would differ
% between a world with and without QE. u_t is NOT the reduced-form
% innovations (only for the initial)
% bnMat are the YIELD loadings (n by 3 matrix)
% Phi is the VAR matrix under PP measures
% G1 is the gamma1 vector in the default probability function
% n=maturity of interest
% OUTPUT: change in yield of maturity n due to shock sequence vs no shock
% sequence

    nPeriods    = size(uSeq,1)-1; % 119
    J           = length(vmat);   %10
    vY          = NaN(J,1);
    
    for j = 1:J
        
        mat = vmat(j);
%         dY = bnMat(mat,:) * uSeq(1,:)';
          dY =  bnMat(mat,:) * uSeq(1,:)'- ((mat-1)/mat * bnMat(mat-1,:) - 1/mat * G1'*Phi )* uSeq(1,:)' ;
          
              
        TT = min(nPeriods, mat-1); % it's always mat-1
        if TT>0
%             for ii =1:TT
            for ii = 2:TT
%                 dY = dY + ((mat-ii)/mat * (bnMat(mat-ii,:)) - 1/mat * G1')* (uSeq(ii+1,:)'- Phi * uSeq(ii,:)'); % note the u Matrix starts with obs t+0, i.e. uSeq(2)=u_{t+1} usw
                dY = dY + ((mat-(ii-1))/mat * (bnMat(mat-(ii-1),:)) - 1/mat * G1')* (uSeq(ii,:)') - ...
                          ((mat-ii)/mat * (bnMat(mat-ii,:)) - 1/mat * G1')*Phi * uSeq(ii,:)'; % note the u Matrix starts with obs t+0, i.e. uSeq(2)=u_{t+1} usw
            
            end
        end
%         vY(j) = dY ;%- 1/mat * G1'* uSeq(TT+1,:)' ;
        vY(j) = dY  - 1/mat * G1'* uSeq(TT+1,:)' ;
    end
    
%            
%            
%            
%            
%            
%            
%        
    