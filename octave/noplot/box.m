function varargout = box(varargin)
% Headless no-op: this server cannot render plots in Octave.
  varargout = cell(1, nargout); varargout(:) = {0};
end
