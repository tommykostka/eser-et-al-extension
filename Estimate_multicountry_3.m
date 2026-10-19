
function [MSE, MSE_yields, MSE_changesyields, AX, BX] = Estimate_multicountry_3(w, param, EstimationData, mX, m_uSeq, mChangesYields, Estim)

if size(Estim,1)==1
    Estim=Estim';
end
N  = length(param.IT.K0P);
EstimDE= Estim(N+4:N+11); 
  

% [MSE_DE, MSE_yields.DE, MSE_changesyields.DE, AX.DE, BX.DE] = fRMSE_pricing_twocriterions_moreSequences(w, mX.DE, mChangesYields.DE, m_uSeq.DE, EstimationData.DE, param.DE, Estim(1:8));
[MSE_DE, MSE_yields.DE, MSE_changesyields.DE, AX.DE, BX.DE, vLambda0.DE, mLambda1.DE] = fRMSE_pricing_twocriterions_moreSequences(w, mX.DE, mChangesYields.DE, m_uSeq.DE, EstimationData.DE, param.DE, EstimDE);

% param.IT.lamba0_DE = [Estim(1:2); 0];
% param.IT.lamba1_DE = [reshape(Estim(3:8), 2, 3); 0 0 0];

% options         = optimset('display', 'off', 'TolX', 10^-25, 'TolFun',10^-25);
% LB              = -100*ones(length(vLambda0),1);
% UB              = 100*ones(length(vLambda0),1);
% 
% % Start with the fmincon and then run also a fminunc (which also gives accurate Gradient and Hessian)
% [vLambda_dualobj, fval]  = fmincon(@(Z) obj_fun(Z), vLambda0, [], [], [], [], LB,UB,[],options);
% [vLambda_dualobj,FVAL_fminunc,EXITFLAG_fminunc,OUTPUT_fminunc,GRAD_fminunc,HESSIAN_fminunc] = fminunc(@(Z) obj_fun(Z), vLambda_dualobj, options);
Estim(N+4:N+5) = vLambda0.DE(1:2,1)'; % these are the lambda parameters
Estim(N+6:N+11) = vec(mLambda1.DE(1:2,:))'; % these are the lambda parameters



% [MSE_IT, MSE_yields.IT, MSE_changesyields.IT, AX.IT, BX.IT] = fRMSE_pricing_twocriterions_moreSequences_wSpread_TK(w, mX.IT, mChangesYields.IT, m_uSeq.IT, EstimationData.IT, param.IT, Estim(9:end));
[MSE_IT, MSE_yields.IT, MSE_changesyields.IT, AX.IT, BX.IT]  = fRMSE_pricing_twocriterions_moreSequences_ITSpread_multi_3(w, mX.IT, mChangesYields.IT, m_uSeq.IT, EstimationData.IT, param.IT, Estim);   
    


MSE = 0.5*MSE_IT + 0.5*MSE_DE;
% MSE = MSE_DE;