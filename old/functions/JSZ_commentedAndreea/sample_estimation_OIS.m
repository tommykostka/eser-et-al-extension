    clearvars
    close all
    restoredefaultpath
    addpath(genpath('jsz_library'))
    addpath(genpath(cd));
    clc

% This gives a sample estimation of an N-factor "without error" GDTSM.
% See "A New Perspective on Gaussian Dynamic Term Structure Models" by Joslin, Singleton and Zhu

%% 
%     Load some data: mats (1*J) and yields (T*J)
% load('sample_zeros.mat') 
    load('struct_ZeroRates_OIS.mat') 
    [T,J]       = size(yields);
    
% Setup format of model/data:
% A: indicate the number of factors (PCs)
    N = 3;
% A: compute the loadings on all Js Principal Components
    W = pcacov(cov(yields));
% A: Select only the loadings on the Nth PCs
    W = W(:,1:N)';  % N*J
% A: determine the time series of the portfolio of yields (the Nth PCs) 
% paper: cP = W_(N*J) * y_(J*1)
% since we have a matrix with the time series of the yields_(T*J), we must
% multiply this with W'_(J*N) => cP_(T*N)
    cP = yields*W'; % T*N
    dt = 1/12;

%%  Estimate the model by ML
    help sample_estimation_fun
    VERBOSE     = true;
    [llks, AcP, BcP, AX, BX, kinfQ, K0P_cP, K1P_cP, sigma_e, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, llkP, llkQ,  K0Q_X, K1Q_X, rho0_X, rho1_X, Sigma_cP] = ...
            sample_estimation_fun(W, yields, mats, dt, VERBOSE);

    %   when the model is stationary, the long run mean of the annualized short rate under Q is -kinfQ/K1(m1,m1)     
    [~, isTypicalDiagonal, m1] = jszAdjustK1QX(K1Q_X);
    rinfQ       = -kinfQ/K1Q_X(m1,m1);
    
    save('sample_RPC_model_jsz_OIS.mat')

%%
    [llk, AcP, BcP, AX, BX, K0Q_cP, K1Q_cP, rho0_cP, rho1_cP, cP, yields_filtered, cP_filtered] = ...
        jszLLK_KF(yields, W, K1Q_X, kinfQ, Sigma_cP, mats, dt, K0P_cP, K1P_cP, sigma_e);
    fprintf('The average (negative) log likelihood is %6.6g when using KF instead of assuming yields without error at these estimates\n', mean(llk))

    figure(2)
    plot(year(dates) + month(dates)/12, [yields*W', cP_filtered])
    xlabel('date')
    ylabel('yields')

%%  Some statistics and plots of the fit 
    
    mDiffYields         = yields_filtered - yields;
    mDiffYieldsSquared  = mDiffYields.^2;
    mRMSE               = sqrt(nanmean(mDiffYieldsSquared))*10000

    % Mean yield curve observed vs yield curve fitted
    plot(mats,mean(yields), mats, mean(yields_filtered))
    pause(6);
    close;
    
    %%  Best fit
    [~, index_line]     = min(sum(mDiffYieldsSquared,2));
    
    % Plot the best fit
    x_general   = mats;
    y_general   = yields(index_line,:);
    y           = y_general(~isnan(y_general)); 
    x           = x_general(~isnan(y_general));
    scatter(x,y);
    hold on;

    plot(x,yields_filtered(index_line,:));

    % Set the labels of the axes of the graphs
    ylabel('Level', 'Fontsize', 13);
    xlabel('Maturity', 'Fontsize', 13);

    % Set the limits and the ticks of the x-axis
    xlim([0 max(x)]);

    % Set the limits and the ticks of the y-axis
    ylim ([max(round(min(min(y, yields_filtered(index_line,:)))*100)/100-0.01,0) round(max(max(y, yields_filtered(index_line,:)))*100)/100+0.01]);
    set(gca,'YTick',0:0.0025:max(ylim));
    set(gca,'YTickLabel',num2str(100.*get(gca,'YTick')','%g%%'));
    legend (strcat('Yield curve - ',datestr(dates(index_line))),'Model implied', 'Location','Best');
    title('Best fit', 'Fontsize', 13);
    
    pause(6);
    close;

    %%  Worst ever overfit

    [~, index_column]   = max(max(mDiffYields));
    [~, index_line]     = max(mDiffYields(:,index_column));
    sprintf('Biggest overfit for one maturity %f (bp) \n', mDiffYields(index_line, index_column)*10000)
    
    % Plot the worst overfit
    
    x_general   = mats;
    y_general   = yields(index_line,:);
    y           = y_general(~isnan(y_general)); 
    x           = x_general(~isnan(y_general));
    scatter(x,y);
    hold on;

    plot(x,yields_filtered(index_line,:));

    % Set the labels of the axes of the graphs
    ylabel('Level', 'Fontsize', 13);
    xlabel('Maturity', 'Fontsize', 13);

    % Set the limits and the ticks of the x-axis
    xlim([0 max(x)]);

    % Set the limits and the ticks of the y-axis
    ylim ([max(round(min(min(y, yields_filtered(index_line,:)))*100)/100-0.01,0) round(max(max(y, yields_filtered(index_line,:)))*100)/100+0.01]);
    set(gca,'YTick',0:0.0025:max(ylim));
    set(gca,'YTickLabel',num2str(100.*get(gca,'YTick')','%g%%'));
    legend (strcat('Yield curve - ',datestr(dates(index_line))),'Model implied', 'Location','Best');
    title('Worst ever overfit', 'Fontsize', 13);
    
    pause(6);
    close;

     %% Worst ever underfit
    [~, index_column]   = min(min(mDiffYields));
    [~, index_line]     = min(mDiffYields(:,index_column));
    sprintf('Biggest underfit for one maturity %f (bp) \n', mDiffYields(index_line, index_column)*10000)
   
    % Plot the worst fit
    x_general   = mats;
    y_general   = yields(index_line,:);
    y           = y_general(~isnan(y_general)); 
    x           = x_general(~isnan(y_general));
    scatter(x,y);
    hold on;

    plot(x,yields_filtered(index_line,~isnan(y_general)));

    % Set the labels of the axes of the graphs
    ylabel('Level', 'Fontsize', 13);
    xlabel('Maturity', 'Fontsize', 13);

    % Set the limits and the ticks of the x-axis
    xlim([0 max(x)]);

    % Set the limits and the ticks of the y-axis
    ylim ([max(round(min(min(y, yields_filtered(index_line,~isnan(y_general))))*100)/100-0.01,0) ...
        round(max(max(y, yields_filtered(index_line,~isnan(y_general))))*100)/100+0.01]);
    set(gca,'YTick',0:0.0025:max(ylim));
    set(gca,'YTickLabel',num2str(100.*get(gca,'YTick')','%g%%'));
    legend (strcat('Yield curve - ',datestr(dates(index_line))),'Model implied', 'Location','Best');
    title('Worst ever underfit', 'Fontsize', 13);
    
    pause(6);
    close;
   






