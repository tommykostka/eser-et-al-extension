function raw = spread_load_inputs()
% Reads every input the spread model needs once and caches it in
% Input_mat/cache_spread_inputs.mat. Dates are stored as MATLAB datenums.
    cacheFile = 'Input_mat/cache_spread_inputs.mat';
    oisFile = 'Data/OIS_rates_and_future_Spot_Curves.xlsx';
    if exist(cacheFile, 'file')
        tmp = load(cacheFile); raw = tmp.raw;
        if ~isfield(raw, 'OISd') && exist(oisFile, 'file')
            raw.OISd = daily_ois(oisFile); save(cacheFile, 'raw');
        end
        return;
    end
    for cty = {'DE', 'IT'}
        S = load(['Input_mat/TS_ECB_' cty{1} '_Dec-2021.mat']);
        raw.TS.(cty{1}).Data = S.Data; raw.TS.(cty{1}).yields = S.yields;
    end
    S = load('Input_mat/OIS.mat'); raw.OIS = S.Data_OIS;
    S = load('Input_mat/Surprise_Data_untilMar2015.mat'); raw.Surprise = S.Surprise_Data;

    raw.ff_unw   = sheet('Data/Free_Float.xlsx', 'unweighted_IT_freefloat');   % col 14 FreeFloat_nom, 13 FreeFloat_teny
    raw.ff_gdp   = sheet('Data/Free_Float.xlsx', 'FF_GDP_IT');                 % col 1, percent of GDP
    raw.big4_Dec21 = sheet('Data/Free_Float.xlsx', 'Big4_free-float(Dec-21)'); % col 13 FreeFloat_teny
    raw.big4_Mar15 = sheet(first_existing({'Data/Input_MSY_debt_and_free_float.xlsx', '../../Input_MSY_debt_and_free_float.xlsx'}), 'Mar-15');
    raw.ff_sim2015 = sheet(first_existing({'Data/Countrydata/2015_03_SIMULATIONBaseline.xlsx', '../Countrydata/2015_03_SIMULATIONBaseline.xlsx'}), 'IT');
    raw.dev_big4FF = sheet('Data/Free_Float.xlsx', 'Deviations_Big4FF');       % col 1 APP (Mar 2015), col 2 PEPP (Mar 2020)
    raw.dev_ITFF   = sheet('Data/Free_Float.xlsx', 'Deviations_ITFF_unw_v2');  % same layout, IT unweighted free float
    raw.dev_ITfisc = sheet('Data/Free_Float.xlsx', 'Deviations_Big4Fiscal');   % same layout, IT purchases / GDP
    if exist(oisFile, 'file'), raw.OISd = daily_ois(oisFile); end
    save(cacheFile, 'raw');
end

function o = daily_ois(file)
% Daily OIS spot rates (percent) from the FAME export: row 3 holds the
% maturity in days, data start in row 7. Returns 1y..10y in decimals.
    [~, ~, raw] = xlsread(file, 'OIS curves FAME');
    tau = cell2mat(raw(3, 2:end));
    body = raw(7:end, :);
    ok = cellfun(@(c) isnumeric(c) && isscalar(c) && ~isnan(c), body(:, 1));
    d = cell2mat(body(ok, 1)) + 693960;
    B = body(ok, 2:end); V = NaN(size(B));
    isn = cellfun(@(c) isnumeric(c) && isscalar(c), B); V(isn) = cell2mat(B(isn));
    cols = zeros(1, 10);
    for y = 1:10, cols(y) = find(tau == 360*y, 1); end
    keep = all(isfinite(V(:, cols)), 2);                % drop days without quotes (e.g. 1 Jan)
    o.dates = d(keep); o.rates = V(keep, cols) / 100; o.file = file;
end

function s = sheet(file, name)
% Reads a sheet whose first column holds dates and whose first row holds
% headers. Works whether xlsread returns the dates as text (MATLAB on
% Windows) or as Excel serial numbers (MATLAB on Mac/Linux, Octave).
    [~, ~, raw] = xlsread(file, name);
    body = raw(2:end, :);
    n = size(body, 1);
    d = NaN(n, 1);
    for i = 1:n
        c = body{i, 1};
        if isnumeric(c) && isscalar(c) && ~isnan(c)
            d(i) = c + 693960;                          % Excel serial date -> MATLAB datenum
        elseif ischar(c) && ~isempty(c)
            d(i) = datenum(c, 'dd/mm/yyyy');
        end
    end
    keep = ~isnan(d);
    vals = body(keep, 2:end);
    num = NaN(size(vals));
    isnum = cellfun(@(c) isnumeric(c) && isscalar(c), vals);
    num(isnum) = cell2mat(vals(isnum));
    s.dates = d(keep);
    s.num   = num;                                      % column k = k-th column after the date column
    s.file  = file; s.sheet = name;
end

function f = first_existing(candidates)
% The original scripts read these files from the P: drive (relative paths
% ../../ and ../Countrydata/); the repository keeps copies under Data/.
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file'), f = candidates{k}; return; end
    end
    error('spread_load_inputs: none of %s found', strjoin(candidates, ', '));
end
