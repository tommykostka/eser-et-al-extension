function opts = optimset(varargin)
% Octave stand-in: MATLAB's fminunc/fmincon run until the tolerances are met,
% while Octave stops at much lower default iteration limits (exit flag 0).
% Raise MaxIter/MaxFunEvals unless the caller sets them explicitly.
  here = fileparts(mfilename('fullpath'));
  rmpath(here); restore = onCleanup(@() addpath(here));
  opts = optimset(varargin{:});
  clear restore;
  if nargin > 0 && isstruct(opts)
    if ~isfield(opts,'MaxIter') || isempty(opts.MaxIter),         opts.MaxIter = 20000;      end
    if ~isfield(opts,'MaxFunEvals') || isempty(opts.MaxFunEvals), opts.MaxFunEvals = 200000; end
  end
end
