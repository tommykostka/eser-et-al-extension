function [num, txt, raw] = xlsread(varargin)
% Octave stand-in that makes io's xlsread behave like MATLAB's xlsread on
% Windows for date columns. MATLAB returns Excel date cells as text
% (here 'dd/mm/yyyy') in txt and leaves them out of num. Octave returns them
% as Excel serial numbers inside num, which shifts every column index. This
% wrapper detects a leading date column (integer serials between 1950 and
% 2100 below a text or empty header) and moves it from num to txt.
  here = fileparts(mfilename('fullpath'));
  rmpath(here); restore = onCleanup(@() addpath(here));
  [num, txt, raw] = xlsread(varargin{:});
  clear restore;
  if isempty(raw) || size(raw,1) < 2 || size(num,1) ~= size(raw,1) - 1
    return;
  end
  col = raw(2:end,1);
  isnum = cellfun(@(c) isnumeric(c) && isscalar(c) && ~isnan(c), col);
  vals = cell2mat(col(isnum));
  if isempty(vals) || ~ischar(raw{1,1}) && ~isempty(raw{1,1}) ...
     || any(vals ~= round(vals)) || any(vals < 18264 | vals > 73051)
    return;   % first column is not a date column
  end
  num = num(:, 2:end);
  txt = cell(size(raw));
  txt(:) = {''};
  istext = cellfun(@ischar, raw);
  txt(istext) = raw(istext);
  dates = cell(size(col)); dates(:) = {''};
  dates(isnum) = cellstr(datestr(vals + 693960, 'dd/mm/yyyy'));
  txt(2:end,1) = dates;
  % MATLAB trims trailing empty rows and columns from txt
  nonempty = ~cellfun(@isempty, txt);
  txt = txt(1:find(any(nonempty,2),1,'last'), 1:find(any(nonempty,1),1,'last'));
end
