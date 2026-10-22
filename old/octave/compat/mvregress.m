function [beta, Sigma, E, CovB, logL] = mvregress(X, Y)
% Octave stand-in for MATLAB's mvregress, for the case used in this project:
% one design matrix X (n x p) shared by all d responses in Y (n x d), no
% missing values. The MLE then equals equation-by-equation OLS.
%   beta  p x d coefficients
%   Sigma d x d MLE noise covariance (divides by n, as MATLAB does)
%   E     n x d residuals
%   CovB  pd x pd covariance of beta(:) = kron(Sigma, inv(X'X))
  if iscell(X) || any(isnan(X(:))) || any(isnan(Y(:)))
    error('mvregress (octave_compat): only a numeric design without NaNs is supported');
  end
  [n, d] = size(Y);
  beta  = X \ Y;
  E     = Y - X * beta;
  Sigma = (E' * E) / n;
  CovB  = kron(Sigma, inv(X' * X));
  logL  = -0.5 * n * (d * log(2*pi) + log(det(Sigma)) + d);
end
