
function [MSE, MSE_yields, MSE_changesyields, AX, BX] = estimate_multicountry(w, param,  EstimationData,mX,m_uSeq, mChangesYields,  Estim)

if size(Estim,1)==1
    Estim=Estim';
end

[MSE_DE, MSE_yields.DE, MSE_changesyields.DE, AX.DE, BX.DE] = fRMSE_pricing_twocriterions_moreSequences(w, mX.DE, mChangesYields.DE, m_uSeq.DE, EstimationData.DE, param.DE, Estim(1:8));

param.IT.lamba0_DE = [Estim(1:2); 0];
param.IT.lamba1_DE = [reshape(Estim(3:8), 2, 3); 0 0 0];

[MSE_IT, MSE_yields.IT, MSE_changesyields.IT, AX.IT, BX.IT] = fRMSE_pricing_twocriterions_moreSequences_wSpread_TK(w, mX.IT, mChangesYields.IT, m_uSeq.IT, EstimationData.IT, param.IT, Estim(9:end));

MSE = 0.5*MSE_IT + 0.5*MSE_DE;