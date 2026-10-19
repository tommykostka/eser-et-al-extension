function raw = spread_load_inputs()
% Reads every input the spread model needs once and caches it in
% Input_mat/cache_spread_inputs.mat. Dates are stored as MATLAB datenums.
    cacheFile = 'Input_mat/cache_spread_inputs.mat';
    if exist(cacheFile, 'file')
        tmp = load(cacheFile); raw = tmp.raw; return;
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
    save(cacheFile, 'raw');
end

function s = sheet(file, name)
    [num, txt] = xlsread(file, name);
    s.dates = datenum(txt(2:end,1), 'dd/mm/yyyy');
    s.num   = num(1:numel(s.dates), :);
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
