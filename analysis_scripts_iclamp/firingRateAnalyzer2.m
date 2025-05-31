%FINAL VERSION OF firingRateAnalyzer!!!!!
%fits a model to AP data to predict shape of rising phase
%% Define file path and add necessary toolbox
addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab')

%%%%%%%%%% ENTER INFO BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx'; 
strainName = 'SHR'; 
sheetName = 'SHRN_Only';
%48h10umCNO-SHR_25sw, 48h10umCNO-WKY_25sw, WKYN_Only, SHRN_Only
outputCsvName = 'SHRN_Only_NEW.csv'; 
cno = 1; % Enter 1 if CNO (treatment) is used, 0 otherwise

%%%%%%%%%% LOAD AND SETUP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dataTable = readtable(filename, 'Sheet', sheetName);
cellNames = dataTable{:, 1};  % Cell name column

C = linspace(-50e-12, 310e-12, 25);   % Current in Amps
C_pA = C * 1e12;                      % Convert to pA for plotting/fitting

numCells = height(dataTable);
Rm = nan(numCells, 1);
Rb = nan(numCells, 1);
tVals = nan(numCells, 1);
maxFiringRate = nan(numCells, 1);

strain = repmat({strainName}, numCells, 1);
treatment = cno * ones(numCells, 1);

%%%%%%%%%% PLOT EACH CELL IN A SUBPLOT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
numRows = ceil(sqrt(numCells));
numCols = ceil(numCells / numRows);

for cellNum = 1:numCells
    Y = dataTable{cellNum, 2:end};

    subplot(numRows, numCols, cellNum);
    hold on;

    try
        % Fit model
        [fitresult, ~] = nakaRushtonThreshFit2(C_pA', Y');

        % Store results
        Rm(cellNum) = fitresult.Rm;
        Rb(cellNum) = fitresult.b;
        tVals(cellNum) = fitresult.t;

        % Compute max firing rate
        c_max = C_pA(end);
        maxFiringRate(cellNum) = max(0, c_max - fitresult.t) * fitresult.Rm / ...
                                 (fitresult.b + max(0, c_max - fitresult.t));

        % Plot raw data and fit
        plot(C_pA, Y, 'bo', 'MarkerSize', 4);
        c_fit = linspace(min(C_pA), max(C_pA), 100);
        fit_y = max(0, c_fit - fitresult.t) .* fitresult.Rm ./ ...
                (fitresult.b + max(0, c_fit - fitresult.t));
        plot(c_fit, fit_y, 'r-', 'LineWidth', 1.2);

        title(cellNames{cellNum}, 'Interpreter', 'none');
        xlabel('Current (pA)');
        ylabel('Hz');
        axis tight;

    catch ME
        warning('Fit failed for cell %s: %s', cellNames{cellNum}, ME.message);
    end

    hold off;
end

sgtitle(['Naka-Rushton Threshold Fits: ', strainName]);

%%%%%%%%%% EXPORT SUMMARY TABLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = table(cellNames, strain, treatment, Rm, Rb, tVals, maxFiringRate, ...
    'VariableNames', {'CellName', 'strain', 'treatment', 'Rm', 'Rb', 'Threshold', 'maxFiringRate'});

disp(T);
writetable(T, outputCsvName);
