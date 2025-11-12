% FINAL VERSION OF firingRateAnalyzer2!!!
% Fits a thresholded Naka-Rushton model to AP firing data to describe 
% the rising phase of the F-I (firing rate vs. current) curve for each
% cell. Gives values of each paramer in the fitting function, together with their confidence intervals (L & U). 
%
% Created by Sayaka (Saya) Minegishi
% Last updated: 10 November 2025

%% Define file path and add necessary toolbox
addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab')

%%%%%%%%%% ENTER INFO BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename      = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx'; 
    % Path to the Excel file containing average AP counts per sweep
strainName    = 'SHR';    
    % Strain name (e.g., 'SHR', 'WKY') – used to tag the output
sheetName     = 'SHRN_Only'; 
    % Sheet within the Excel file to read (corresponding to one condition)
outputCsvName = 'SHRN_Only_NEW.csv'; 
    % Output filename for summary fit parameters (one row per cell)
diagCsvName   = 'SHRN_Only_NEW_diagnostics.csv'; 
    % Optional long-format CSV for visual inspection of raw data
cno           = 1; 
    % 1 = treated with CNO (chemogenetic activation), 0 = untreated

%%%%%%%%%% LOAD AND SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataTable = readtable(filename, 'Sheet', sheetName); 
    % Read the data from the Excel sheet
cellNames = dataTable{:, 1};  
    % First column = cell identifiers (filenames or cell IDs)

C = linspace(-50e-12, 310e-12, 25);  
    % Injected current steps (in Amperes, for 25-sweep protocol)
C_pA = C * 1e12;  
    % Convert current values from Amperes to picoamperes (pA)

numCells = height(dataTable);  
    % Number of cells (rows) in the table

%%%%%%%%%% Preallocate arrays to store results %%%%%%%%%%%%%%%%%%%%%%%%%%%%
strain        = repmat({strainName}, numCells, 1);   
    % Repeats the strain label for each cell
treatment     = cno * ones(numCells, 1);             
    % Numeric indicator for treatment (1 = CNO, 0 = control)

Rm            = nan(numCells, 1);   
    % Maximum firing rate scaling factor (gain term in model)
Rb            = nan(numCells, 1);   
    % Half-saturation constant (the “b” parameter in Naka-Rushton)
tVals         = nan(numCells, 1);   
    % Threshold (minimum current at which firing begins)
c50           = nan(numCells, 1);   
    % Derived: c50 = b + t (current producing half-max response)
maxFiringRate = nan(numCells, 1);   
    % Maximum firing rate predicted by the fit at max injected current

SSE           = nan(numCells, 1);   
    % Sum of squared errors from the fit
RMSE          = nan(numCells, 1);   
    % Root mean squared error (measure of fit accuracy)
Rsq           = nan(numCells, 1);   
    % R-squared (proportion of variance explained)
Nobs          = zeros(numCells, 1); 
    % Number of valid (non-NaN) data points per cell
fit_ok        = false(numCells, 1); 
    % Logical flag indicating whether the fit succeeded

Rm_L = nan(numCells, 1); Rm_U = nan(numCells, 1);  
Rb_L = nan(numCells, 1); Rb_U = nan(numCells, 1);  
t_L  = nan(numCells, 1); t_U  = nan(numCells, 1);   
    % Lower and upper 95% confidence bounds for Rm, Rb, and t

%%%%%%%%%% PLOT EACH CELL IN A SUBPLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name','Naka-Rushton Threshold Fits','Color','w');
numRows = ceil(sqrt(numCells));  
numCols = ceil(numCells / numRows);  
    % Create a roughly square grid of subplots to show all cells

for cellNum = 1:numCells
    Y = dataTable{cellNum, 2:end};          
        % Firing rate values (Hz) for this cell across current steps
    Y = Y(:)';                             
        % Ensure row vector format
    Nobs(cellNum) = sum(~isnan(Y));        
        % Count valid data points (exclude NaNs)

    subplot(numRows, numCols, cellNum);
    hold on;

    try
        % Fit the thresholded Naka-Rushton model
        [fitresult, gof] = nakaRushtonThreshFit2(C_pA', Y');

        % Extract and store fit parameters
        Rm(cellNum)    = fitresult.Rm;
        Rb(cellNum)    = fitresult.b;
        tVals(cellNum) = fitresult.t;
        c50(cellNum)   = Rb(cellNum) + tVals(cellNum);
        fit_ok(cellNum)= true;

        % Store goodness-of-fit metrics
        SSE(cellNum)   = gof.sse;
        RMSE(cellNum)  = gof.rmse;
        Rsq(cellNum)   = gof.rsquare;

        % Confidence intervals for each parameter
        ci95 = confint(fitresult);
        Rm_L(cellNum) = ci95(1,1); Rm_U(cellNum) = ci95(2,1);
        Rb_L(cellNum) = ci95(1,2); Rb_U(cellNum) = ci95(2,2);
        t_L(cellNum)  = ci95(1,3); t_U(cellNum)  = ci95(2,3);

        % Compute maximum firing rate at highest injected current
        c_max = C_pA(end);
        maxFiringRate(cellNum) = max(0, c_max - fitresult.t) * fitresult.Rm / ...
                                 (fitresult.b + max(0, c_max - fitresult.t));

        % Plot data points and fitted curve
        plot(C_pA, Y, 'o', 'MarkerSize', 4, 'DisplayName','data');
        c_fit = linspace(min(C_pA), max(C_pA), 200);
        fit_y = max(0, c_fit - fitresult.t) .* fitresult.Rm ./ ...
                (fitresult.b + max(0, c_fit - fitresult.t));
        plot(c_fit, fit_y, '-', 'LineWidth', 1.2, 'DisplayName','fit');

        title(cellNames{cellNum}, 'Interpreter', 'none');
        xlabel('Current (pA)');
        ylabel('Firing rate (Hz)');
        axis tight;

    catch ME
        % If fitting fails, display a warning and plot only data
        warning('Fit failed for cell %s: %s', cellNames{cellNum}, ME.message);
        plot(C_pA, Y, 'o', 'MarkerSize', 4, 'DisplayName','data');
        title(sprintf('%s (FIT FAILED)', cellNames{cellNum}), 'Interpreter', 'none', 'Color',[0.7 0 0]);
        xlabel('Current (pA)'); ylabel('Firing rate (Hz)');
        axis tight;
    end

    hold off;
end

% Overall figure title
sgtitle(['Naka-Rushton Threshold Fits: ', strainName]);

%%%%%%%%%% EXPORT SUMMARY TABLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Combine all results into a summary table (one row per cell)
T = table(cellNames, strain, treatment, Nobs, fit_ok, ...
          Rm, Rm_L, Rm_U, ...
          Rb, Rb_L, Rb_U, ...
          tVals, t_L, t_U, ...
          c50, maxFiringRate, ...
          SSE, RMSE, Rsq, ...
    'VariableNames', {'CellName','strain','treatment','N','fit_ok', ...
                      'Rm','Rm_L','Rm_U', ...
                      'Rb','Rb_L','Rb_U', ...
                      'Threshold','Threshold_L','Threshold_U', ...
                      'c50','maxFiringRate', ...
                      'SSE','RMSE','Rsq'});

% Display and save summary table
disp(T);
writetable(T, outputCsvName);

%%%%%%%%%% OPTIONAL: PER-CELL DIAGNOSTIC DUMP %%%%%%%%%%%%%%
% Creates a long-format table listing each data point for quick inspection
try
    longCell = strings(0,1);
    longC    = [];
    longR    = [];
    for i = 1:numCells
        Yi = dataTable{i, 2:end};
        mask = ~isnan(Yi);
        longCell = [longCell; repmat(string(cellNames{i}), sum(mask), 1)]; %#ok<AGROW>
        longC    = [longC; C_pA(mask)'];                                    %#ok<AGROW>
        longR    = [longR; Yi(mask)'];                                      %#ok<AGROW>
    end
    Tdiag = table(longCell, longC, longR, ...
        'VariableNames', {'CellName','Current_pA','FiringRate_Hz'});
    writetable(Tdiag, diagCsvName);
catch ME
    warning('Could not write diagnostics CSV: %s', ME.message);
end
