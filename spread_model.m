function M = spread_model(x, S, cfg)
% Prices DE and IT yields and the event reactions for parameter vector x
% (35 x 1, the layout of Estimate_multicountry_3) and returns the weighted
% residual vector M.r with sum(M.r.^2) == the original objective MSE
% (0.5*MSE_DE + 0.5*MSE_IT), plus a sign-constraint penalty when enabled.
%   x(1)      Gamma_0               x(2:7)   Gamma_1 (IT default intensity)
%   x(8:9)    IT Lambda_0, spread level/slope
%   x(10:11)  Lambda_0, level/slope (DE and IT)
%   x(12:17)  Lambda_1 rows 1:2, cols 1:3 (DE and IT)
%   x(18:23)  IT Lambda_1 rows 1:2, cols 4:6
%   x(24:35)  IT Lambda_1 rows 4:5, cols 1:6
% Rows 3 and 6 of Lambda (the quantity factors) are zero.
    x = x(:); w = cfg.w; dt = 1/12;
    nEv = size(S.target.DE, 2);

    % ---- DE (3 factors) ----
    p = S.param.DE; E = S.E.DE; mX = S.mX.DE; T = S.T;
    L0 = [x(10:11); 0];
    L1 = [reshape(x(12:17), 2, 3); zeros(1, 3)];
    mT = E.mats_TSfit / dt; mR = E.mats_YCfit / dt;
    AX = fATSMDiscrete_YieldLoadingsRecurrence_AX_Lambda(mT, p.K0P, p.K1P, L0, L1, p.Omega_square, p.rho0*dt, p.rho1*dt, dt);
    BX = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(mT, p.K1P, L1, p.Omega_square, p.rho1*dt, dt);
    Ball = fATSMDiscrete_YieldLoadingsRecurrence_BX_Lambda(1:mR(end), p.K1P, L1, p.Omega_square, p.rho1*dt, dt);
    eY.DE = E.Yields - (ones(T,1)*AX + mX*BX);
    fit.DE = zeros(numel(mR), nEv);
    for e = 1:nEv
        fit.DE(:, e) = fYieldsImpact_uSequence_fast(mR, S.U.DE(:,:,e), Ball', p.K1P_level);
    end
    M.AX.DE = AX; M.BX.DE = BX; M.L0.DE = L0; M.L1.DE = L1;

    % ---- IT (6 factors, default-adjusted pricing) ----
    p = S.param.IT; E = S.E.IT; mX = S.mX.IT;
    G0 = x(1); G1 = x(2:7);
    L0 = [x(10:11); 0; x(8:9); 0];
    L1 = [reshape([x(12:17); x(18:23)], 2, 6); zeros(1, 6); reshape(x(24:35), 2, 6); zeros(1, 6)];
    AX = fATSMDiscrete_YieldLoadingsRecurrence_AX_Gamma(mT, p.K0P, p.K1P_level, L0, L1, p.Omega_square, p.rho0*dt, p.rho1*dt, dt, G0, G1);
    BX = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(mT, p.K1P_level, L1, p.Omega_square, p.rho1*dt, dt, G1);
    Ball = fATSMDiscrete_YieldLoadingsRecurrence_BX_Gamma(1:mR(end), p.K1P_level, L1, p.Omega_square, p.rho1*dt, dt, G1);
    eY.IT = E.Yields - (ones(T,1)*AX + mX*BX);
    fit.IT = zeros(numel(mR), nEv);
    for e = 1:nEv
        fit.IT(:, e) = fYieldsImpact_uSequence_wSpread_fast(mR, S.U.IT(:,:,e), Ball', p.K1P_level, G1);
    end
    M.AX.IT = AX; M.BX.IT = BX; M.L0.IT = L0; M.L1.IT = L1; M.G0 = G0; M.G1 = G1;

    % ---- residuals ----
    r = [];
    for c = {'DE', 'IT'}
        cty = c{1};
        eE = S.target.(cty) - fit.(cty);
        r = [r; sqrt(0.5*w/T) * eY.(cty)(:); sqrt(0.5*(1-w)/nEv) * eE(:)];  %#ok<AGROW>
        M.MSE_yields.(cty) = sum(eY.(cty)(:).^2) / T;
        M.MSE_events.(cty) = sum(eE(:).^2) / nEv;
    end
    M.MSE = sum(r.^2);
    % Spread response to the fiscal factor: DE does not load on it, so it is
    % IT's loading on factor 6 (decimal yield per unit of the factor), 5-10y.
    M.spreadLoading = M.BX.IT(6, 5:10);
    M.violation = max(0, -M.spreadLoading);
    if cfg.signConstraint
        r = [r; sqrt(cfg.penalty) * M.violation(:)];
    end
    % Default intensity of IT, Gamma_0 + Gamma_1'X_t, must not be negative in any month.
    M.intensity = G0 + S.mX.IT * G1;
    r = [r; sqrt(cfg.penalty) * max(0, -M.intensity)];
    if isfield(cfg, 'maxIntensity') && isfinite(cfg.maxIntensity)
        r = [r; sqrt(cfg.penalty) * max(0, M.intensity - cfg.maxIntensity/12)];
    end
    M.r = r; M.fit = fit; M.eY = eY;
end
