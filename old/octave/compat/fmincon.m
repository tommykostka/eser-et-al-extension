function [x, fval, exitflag, output] = fmincon(fun, x0, A, b, Aeq, beq, lb, ub, varargin)
% Octave stand-in for the bound-constrained use of MATLAB's fmincon.
% Two MATLAB behaviours that Octave's optim fmincon lacks:
%  - a starting point outside [lb, ub] is projected onto the bounds
%    (Octave errors: "Initial parameters violate constraints");
%  - variables with lb == ub are held fixed (Octave's solver fails with
%    "pivot is zero").
% Fixed variables are removed and the optim package version is called on
% the free ones only.
  n = numel(x0);
  if nargin < 7 || isempty(lb), lb = -inf(n,1); end
  if nargin < 8 || isempty(ub), ub =  inf(n,1); end
  lb = lb(:); ub = ub(:); x0 = min(max(x0(:), lb), ub);
  free = lb < ub;
  if ~(isempty(A) && isempty(Aeq)) && ~all(free)
    error('fmincon (octave_compat): fixed bounds with linear constraints not supported');
  end
  expand = @(z) fill_free(x0, free, z);
  here = fileparts(mfilename('fullpath'));
  rmpath(here); restore = onCleanup(@() addpath(here));
  [z, fval, exitflag, output] = fmincon(@(z) fun(expand(z)), x0(free), A, b, Aeq, beq, ...
                                        lb(free), ub(free), varargin{:});
  clear restore;
  x = expand(z);
end

function x = fill_free(x, free, z)
  x(free) = z;
end
