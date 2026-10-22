% Code created by Andreea Vladu
% April 2018: ammended by KN for GDP weights
%


    % Clearing memory and graphical interface
    clc;
    clearvars;
    close all;
    
    addpath(genpath([cd '\']));
  
    sOutputDirectory     = 'Input_mat\';  
    
    wType = 'gdp'; % added KN: type of weighting scheme for the yield curve blending: gdp=gdp weights, debt=outstanding debt/bonds weights;
    
    % Specify the weights for constructing the Big4 based on debt of countries
    if ( strcmp(wType,'debt') )   
        dWeight_DE        = 0.26;
        dWeight_FR        = 0.29; 
        dWeight_IT        = 0.3; 
        dWeight_ES        = 0.15;
    elseif ( strcmp( wType, 'gdp') )
        dWeight_DE        = 0.38;    % added KN: 2016 figures, newer are not available in FAME at the moment
        dWeight_FR        = 0.27; 
        dWeight_IT        = 0.21; 
        dWeight_ES        = 0.14;
    else
        disp('Error: please supply a valid yield curve blending scheme: gdp or debt weighted')
    end
    sEndSample = 'Dec-2021';   %'Sep-2017';   'Apr-2018'
    
    load(['TS_ECB_FR_' sEndSample '.mat']); % france has the particularity that it has some more days available, which must be eliminated
    Data_FR     = Data;
    load(['TS_ECB_DE_' sEndSample '.mat']);
    Data_DE     = Data;
    [C, IA, IB] = intersect(Data_FR.nom.d.dates, Data_DE.nom.d.dates);
    
%% Load the information for all big4 countries
    
    load(['TS_ECB_DE_' sEndSample '.mat']);
    jointyields.m.DE = dWeight_DE * yields.m.nom;
    jointyields.w.DE = dWeight_DE * yields.w.nom;
    jointyields.d.DE = dWeight_DE * yields.d.nom(IB,:);
    
    load(['TS_ECB_IT_' sEndSample '.mat']);
    jointyields.m.IT = dWeight_IT * yields.m.nom;
    jointyields.w.IT = dWeight_IT * yields.w.nom;
    jointyields.d.IT = dWeight_IT * yields.d.nom(IB,:);
    
    load(['TS_ECB_ES_' sEndSample '.mat']);
    jointyields.m.ES = dWeight_ES * yields.m.nom;
    jointyields.w.ES = dWeight_ES * yields.w.nom;
    jointyields.d.ES = dWeight_ES * yields.d.nom(IB,:);

    load(['TS_ECB_FR_' sEndSample '.mat']);
    jointyields.m.FR = dWeight_FR * yields.m.nom;
    jointyields.w.FR = dWeight_FR * yields.w.nom;
    jointyields.d.FR = dWeight_DE * yields.d.nom(IA,:);

    % Aggregating all for the daily, weekly and the monthly available
    yields.m.nom        = jointyields.m.DE + jointyields.m.FR + jointyields.m.IT + jointyields.m.ES;
    yields.w.nom        = jointyields.w.DE + jointyields.w.FR + jointyields.w.IT + jointyields.w.ES;
    yields.d.nom        = jointyields.d.DE + jointyields.d.FR + jointyields.d.IT + jointyields.d.ES;

    % Drop for the moment the excess returns information
    yields.m.rxNom  = [];
    yields.w.rxNom  = [];
    

%% Save all information

    sEndSample = datestr(Data.nom.w.dates(end), 'mmm-yyyy');
    save([sOutputDirectory 'TS_ECB_Big4_' sEndSample '.mat'],'yields', 'param', 'Data');

    

  
    
    
    
   