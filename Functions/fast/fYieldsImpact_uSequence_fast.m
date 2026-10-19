function vY = fYieldsImpact_uSequence_fast(vmat, uSeq, bnMat, Phi)
% Vectorised version of fYieldsImpact_uSequence (same formula, no inner loop).
% dY(m) = b(m)'u(1) + sum_{i=1}^{TT} (m-i)/m * b(m-i)'(u(i+1) - Phi*u(i))
    nPeriods = size(uSeq,1) - 1;
    J        = length(vmat);
    vY       = NaN(J,1);
    D        = uSeq(2:end,:) - uSeq(1:end-1,:) * Phi';   % row i: (u(i+1) - Phi*u(i))'
    for j = 1:J
        mat = vmat(j);
        dY  = bnMat(mat,:) * uSeq(1,:)';
        TT  = min(nPeriods, mat-1);
        if nPeriods > 0 && TT > 0
            ii = (1:TT)';
            dY = dY + sum(((mat-ii)/mat) .* sum(bnMat(mat-ii,:) .* D(ii,:), 2));
        end
        vY(j) = dY;
    end
end
