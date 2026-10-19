% Code created by Andreea Vladu


    % Clearing memory and graphical interface
    clc;
    clearvars;
    close all;
    
    addpath(genpath([cd '\']));
  
    sInputDirectory         = 'Data\'; % Input 
    sOutputDirectory        = 'Input_mat\'; % Output wrt to this code but will be input to the main analysis  
    
    % Specify the country for the analysis
    sCountry            = 'DE'; %'ES', 'DE', 'FR', 'IT'
    
%%  Input dates to select subsample

    sEndSample          = '31-Dec-2021';  %  '29-Dec-2017'... '29-Sep-2017'; % !!!! THIS MUST BE THE LAST DAY OF THE MONTH BEING ANALYSED
    sStartSample        = '31-Aug-2004'; % !!!! THIS MUST BE THE END OF THE FIRST MONTH FROM THE DESIRED SUBSAMPLE
    % THESE TWO DAYS NEED ACTUALLY TO BE DAYS FOR WHICH DAILY DATA IS AVAILABLE
    sStartDailyData_nom     = '06-Sep-2004'; % This is the date as of which nominal Bund curves started being available on a daily basis    
    
%%  Reading the nominal parameters (Nelson-Svensoson-Siegel parameters)
    
    [Data_raw, Header]      = xlsread([sInputDirectory 'YieldCurves_Parameters_ECB.xlsm'], sCountry);
    
    Data_nominal            = Data_raw;
    vDates_nom              = datenum(Header(10:end,2),'dd/mm/yyyy');
    
    % Identify actual dates
    vDelete     = isnan(Data_nominal);
    if sum(diff(sum(vDelete)))==0 % we have only full lines of missing observations
      
        Data_nominal(vDelete(:,1),:) = [];
        vDates_nom(vDelete(:,1)) = [];
    
    end
    
%% Construct the MONTHLY dataset of nominal parameters

    % Identify indices of end-of-month observations
    index_endmonths_nom = find(month(vDates_nom(1:(end-1))) ~= month(vDates_nom(2:end)));
        
    % Select only those observations
    Data.nom.m.dates            = vDates_nom(index_endmonths_nom);  
    Data.nom.m.dates_endofmonth = eomdate(Data.nom.m.dates); 
    Data.nom.m.param.beta0    = Data_nominal(index_endmonths_nom,1);
    Data.nom.m.param.beta1    = Data_nominal(index_endmonths_nom,2);
    Data.nom.m.param.beta2    = Data_nominal(index_endmonths_nom,3);
    Data.nom.m.param.beta3    = Data_nominal(index_endmonths_nom,4);
    Data.nom.m.param.tau1     = Data_nominal(index_endmonths_nom,5); 
    Data.nom.m.param.tau2     = Data_nominal(index_endmonths_nom,6);
    
%     indexEndSample_Nom  = find(strcmp(cellstr(datestr(Data.nom.m.dates_endofmonth, 'dd-mmm-yyyy')), sEndSample));
    % Exception
    indexEndSample_Nom  = find(strcmp(cellstr(datestr(Data.nom.m.dates, 'dd-mmm-yyyy')), sEndSample));
    
    % If this is empty then we consider that the end date is later then the
    % last observation available
    if ~isempty(indexEndSample_Nom)
        
        Data.nom.m.dates          = Data.nom.m.dates(1:indexEndSample_Nom);
        Data.nom.m.dates_endofmonth = Data.nom.m.dates_endofmonth(1:indexEndSample_Nom);
        Data.nom.m.param.beta0    = Data.nom.m.param.beta0(1:indexEndSample_Nom);
        Data.nom.m.param.beta1    = Data.nom.m.param.beta1(1:indexEndSample_Nom);
        Data.nom.m.param.beta2    = Data.nom.m.param.beta2(1:indexEndSample_Nom);
        Data.nom.m.param.tau1     = Data.nom.m.param.tau1(1:indexEndSample_Nom);
        Data.nom.m.param.beta3    = Data.nom.m.param.beta3(1:indexEndSample_Nom);
        Data.nom.m.param.tau2     = Data.nom.m.param.tau2(1:indexEndSample_Nom);
        
    end
  
    indexStartSample_Nom  = find(strcmp(cellstr(datestr(Data.nom.m.dates_endofmonth, 'dd-mmm-yyyy')), sStartSample));
    % If this is empty then we consider that the start date is sooner then the
    % first observation available
   
    if ~isempty(indexStartSample_Nom)
        
        Data.nom.m.dates          = Data.nom.m.dates(indexStartSample_Nom:end);
        Data.nom.m.dates_endofmonth = Data.nom.m.dates_endofmonth(indexStartSample_Nom:end);
        Data.nom.m.param.beta0    = Data.nom.m.param.beta0(indexStartSample_Nom:end);
        Data.nom.m.param.beta1    = Data.nom.m.param.beta1(indexStartSample_Nom:end);
        Data.nom.m.param.beta2    = Data.nom.m.param.beta2(indexStartSample_Nom:end);
        Data.nom.m.param.tau1     = Data.nom.m.param.tau1(indexStartSample_Nom:end);
        Data.nom.m.param.beta3    = Data.nom.m.param.beta3(indexStartSample_Nom:end);
        Data.nom.m.param.tau2     = Data.nom.m.param.tau2(indexStartSample_Nom:end);
        
    end
    
%% Construct the WEEKLY dataset of nominal parameters
    % Identify indices of end-of-month observations
    index_endweeks_nom = find(weeknum(vDates_nom(1:(end-1))) ~= weeknum(vDates_nom(2:end)));
        
    % Select only those observations
    Data.nom.w.dates          = vDates_nom(index_endweeks_nom);  
    Data.nom.w.param.beta0    = Data_nominal(index_endweeks_nom,1);
    Data.nom.w.param.beta1    = Data_nominal(index_endweeks_nom,2);
    Data.nom.w.param.beta2    = Data_nominal(index_endweeks_nom,3);
    Data.nom.w.param.beta3    = Data_nominal(index_endweeks_nom,4);
    Data.nom.w.param.tau1     = Data_nominal(index_endweeks_nom,5); 
    Data.nom.w.param.tau2     = Data_nominal(index_endweeks_nom,6);

    indexEndSample_Nom  = find(strcmp(cellstr(datestr(Data.nom.w.dates, 'dd-mmm-yyyy')), sEndSample));
    
    % If this is empty then we consider that the end date is later then the
    % last observation available
    if ~isempty(indexEndSample_Nom)
        
        Data.nom.w.dates          = Data.nom.w.dates(1:indexEndSample_Nom);
        Data.nom.w.param.beta0    = Data.nom.w.param.beta0(1:indexEndSample_Nom);
        Data.nom.w.param.beta1    = Data.nom.w.param.beta1(1:indexEndSample_Nom);
        Data.nom.w.param.beta2    = Data.nom.w.param.beta2(1:indexEndSample_Nom);
        Data.nom.w.param.tau1     = Data.nom.w.param.tau1(1:indexEndSample_Nom);
        Data.nom.w.param.beta3    = Data.nom.w.param.beta3(1:indexEndSample_Nom);
        Data.nom.w.param.tau2     = Data.nom.w.param.tau2(1:indexEndSample_Nom);
        
    end

    indexStartSample_Nom  = find(strcmp(cellstr(datestr(Data.nom.w.dates, 'dd-mmm-yyyy')), sStartSample));
    % If this is empty then we consider that the start date is sooner then the
    % first observation available
   
    if ~isempty(indexStartSample_Nom)
        
        Data.nom.w.dates          = Data.nom.w.dates(indexStartSample_Nom:end);
        Data.nom.w.param.beta0    = Data.nom.w.param.beta0(indexStartSample_Nom:end);
        Data.nom.w.param.beta1    = Data.nom.w.param.beta1(indexStartSample_Nom:end);
        Data.nom.w.param.beta2    = Data.nom.w.param.beta2(indexStartSample_Nom:end);
        Data.nom.w.param.tau1     = Data.nom.w.param.tau1(indexStartSample_Nom:end);
        Data.nom.w.param.beta3    = Data.nom.w.param.beta3(indexStartSample_Nom:end);
        Data.nom.w.param.tau2     = Data.nom.w.param.tau2(indexStartSample_Nom:end);
        
    end

%% Construct the DAILY dataset of nominal parameters (by shifting by one day the observations)
   
    indexStartDailyData_Nom  = find(strcmp(cellstr(datestr(vDates_nom, 'dd-mmm-yyyy')), sStartDailyData_nom));
    
    Data.nom.d.dates            = vDates_nom(indexStartDailyData_Nom:end);
    Data.nom.d.param.beta0      = Data_nominal(indexStartDailyData_Nom:end,1);
    Data.nom.d.param.beta1      = Data_nominal(indexStartDailyData_Nom:end,2);
    Data.nom.d.param.beta2      = Data_nominal(indexStartDailyData_Nom:end,3);
    Data.nom.d.param.beta3      = Data_nominal(indexStartDailyData_Nom:end,4);
    Data.nom.d.param.tau1       = Data_nominal(indexStartDailyData_Nom:end,5);
    Data.nom.d.param.tau2       = Data_nominal(indexStartDailyData_Nom:end,6);
    
    % Select also here the subsample
    indexEndSample_daily_Nom  = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd-mmm-yyyy')), sEndSample));
    
    % If this is empty then we consider that the end date is later then the
    % last observation available
    if ~isempty(indexEndSample_daily_Nom)
        
        Data.nom.d.dates          = Data.nom.d.dates(1:indexEndSample_daily_Nom);
        Data.nom.d.param.beta0    = Data.nom.d.param.beta0(1:indexEndSample_daily_Nom);
        Data.nom.d.param.beta1    = Data.nom.d.param.beta1(1:indexEndSample_daily_Nom);
        Data.nom.d.param.beta2    = Data.nom.d.param.beta2(1:indexEndSample_daily_Nom);
        Data.nom.d.param.tau1     = Data.nom.d.param.tau1(1:indexEndSample_daily_Nom);
        Data.nom.d.param.beta3    = Data.nom.d.param.beta3(1:indexEndSample_daily_Nom);
        Data.nom.d.param.tau2     = Data.nom.d.param.tau2(1:indexEndSample_daily_Nom);
        
    end
    
    indexStartSample_daily_Nom  = find(strcmp(cellstr(datestr(Data.nom.d.dates, 'dd-mmm-yyyy')), sStartDailyData_nom));
    % If this is empty then we consider that the start date is sooner then the
    % first observation available
   
    if ~isempty(indexStartSample_daily_Nom)
        
        Data.nom.d.dates          = Data.nom.d.dates(indexStartSample_daily_Nom:end);
        Data.nom.d.param.beta0    = Data.nom.d.param.beta0(indexStartSample_daily_Nom:end);
        Data.nom.d.param.beta1    = Data.nom.d.param.beta1(indexStartSample_daily_Nom:end);
        Data.nom.d.param.beta2    = Data.nom.d.param.beta2(indexStartSample_daily_Nom:end);
        Data.nom.d.param.tau1     = Data.nom.d.param.tau1(indexStartSample_daily_Nom:end);
        Data.nom.d.param.beta3    = Data.nom.d.param.beta3(indexStartSample_daily_Nom:end);
        Data.nom.d.param.tau2     = Data.nom.d.param.tau2(indexStartSample_daily_Nom:end);
        
    end
        
    
%% Finally, construct yields, both nominal, on a daily and monthly basis

    % Compute nominal yields - at daily frequency
    yields.d.nom       = GSWParams2Yields([Data.nom.d.param.beta0 Data.nom.d.param.beta1 Data.nom.d.param.beta2...
        Data.nom.d.param.beta3 Data.nom.d.param.tau1 Data.nom.d.param.tau2])/100;
    
    % Compute nominal yields - at monthly frequency
    mParamNom_m = [Data.nom.m.param.beta0 Data.nom.m.param.beta1 Data.nom.m.param.beta2...
        Data.nom.m.param.beta3 Data.nom.m.param.tau1 Data.nom.m.param.tau2];
    yields.m.nom       = GSWParams2Yields(mParamNom_m)/100;
    
    % Compute nominal yields - at weekly frequency
    mParamNom_w = [Data.nom.w.param.beta0 Data.nom.w.param.beta1 Data.nom.w.param.beta2...
        Data.nom.w.param.beta3 Data.nom.w.param.tau1 Data.nom.w.param.tau2];
    yields.w.nom       = GSWParams2Yields(mParamNom_w)/100;
   
    size(yields.w.nom)
    
%% Construct nominal and real actual excess returns

    param.allMat        = (1:360)/12;
    param.M             = length(param.allMat);   
    param.mT_monthly    = length(Data.nom.m.dates);
    param.mT_daily      = length(Data.nom.d.dates);
    param.mT_weekly     = length(Data.nom.w.dates);
    
%% Read in also the OIS data

% Data loading
    [data_in,text] = xlsread([sInputDirectory 'Data-OIS-Monthly.xlsx'],'DATA_EXPORT_OIS'); 
    OIS_rates = data_in/100;
    MatlabDates = datenum(text(2:end,1),'dd/mm/yyyy');
    
%% Organise data
    Data_OIS.OIS_rates = OIS_rates;
    Data_OIS.mats = [1/12 3/12 6/12 9/12 1:10];
    Data_OIS.MatlabDates = MatlabDates;
    Data_OIS.ReadableDates = datestr(MatlabDates);
    
%% Save all information

    sEndSample = datestr(datenum(sEndSample,'dd-mmm-yyyy'), 'mmm-yyyy');
    
    save([sOutputDirectory 'TS_ECB_' sCountry '_' sEndSample '.mat'],'yields', 'param', 'Data');
    
    save([sOutputDirectory 'OIS.mat'], 'Data_OIS');
    
    
    
   