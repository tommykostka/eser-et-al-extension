function vY = fYieldsImpact_uSequence_wSpread_fast(vmat, uSeq, bnMat, Phi, G1)
% Vectorised version of fYieldsImpact_uSequence_wSpread (same formula, no inner loop).
    nPeriods = size(uSeq,1) - 1;
    J        = length(vmat);
    vY       = NaN(J,1);
    uG       = uSeq * G1;                 % G1'u(i)
    uPhi     = uSeq * Phi';               % row i: (Phi*u(i))'
    uPhiG    = uPhi * G1;                 % G1'Phi u(i)
    for j = 1:J
        mat = vmat(j);
        dY  = bnMat(mat,:) * uSeq(1,:)' - ((mat-1)/mat * bnMat(mat-1,:) * uSeq(1,:)' - 1/mat * uPhiG(1));
        TT  = min(nPeriods, mat-1);
        if TT >= 2
            ii = (2:TT)';
            dY = dY + sum(((mat-ii+1)/mat) .* sum(bnMat(mat-ii+1,:) .* uSeq(ii,:), 2)) - sum(uG(ii))/mat ...
                    - sum(((mat-ii)/mat) .* sum(bnMat(mat-ii,:) .* uPhi(ii,:), 2)) + sum(uPhiG(ii))/mat;
        end
        vY(j) = dY - 1/mat * uG(TT+1);
    end
end
