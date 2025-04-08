% Define file path and add necessary toolbox
addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab')

%%%%%%%%%% ENTER INFO BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx'; %data table containing AP counts for each sweep.
strainName = 'SHR'; 
sheetName = '48h10umCNO-SHR_25sw';
%48h10umCNO-SHR_25sw, 48h10umCNO-WKY_25sw, WKYN_Only, SHRN_Only
outputCsvName = 'shrnChrCNO2.csv'; %name of output csv file with the summary results contained
cno = 1; %Enter 1 if CNO (treatment) is used, 0 otherwise. 

%%%%%%%% MAKE SUMMARY TABLE FOR FREQUENCY VS CURRENT (DO NOT MODIFY) %%%%%%%%%%%%%%%%%%
dataTable = readtable(filename, 'Sheet', sheetName);

% Extract cell names from the first column
cellNames = dataTable{:, 1};  % Assuming the first column contains names

% Define stimulation current
C = linspace(-50e-12, 310e-12, 25);

% Preallocate Rm and Rb
numCells = height(dataTable);
Rm = nan(numCells, 1);
Rb = nan(numCells, 1);

strain=repmat({strainName}, numCells, 1); 
treatment = zeros(numCells,1)+cno; %1 for yes, chronic CNO treatment. 0 otherwise.
maxFiringRate = nan(numCells, 1);

% Loop through each cell
for cellNum = 1:numCells
    % Extract response data for the current cell
    Y = dataTable{cellNum, 2:end};

    % Fit Naka-Rushton function
    [Rm(cellNum), Rb(cellNum)] = vlt.fit.naka_rushton(C(5:end), Y(5:end));

    % Compute fitted curve
    C_fit = vlt.math.rectify(C);

    % Plot results
    figure(gcf);
    plot(C, Y, 'o'); % Original data
    hold on;
    plot(C, Rm(cellNum) * vlt.fit.naka_rushton_func(C_fit(:), Rb(cellNum)), 'rx-'); % Fitted curve
    xlabel('Current (pA)');
    ylabel('Firing rate (Hz)');
    title(['IR Plot for Cell: ', cellNames{cellNum}]); % Show cell name in title
    legend({'Data', 'Fit'}, 'Location', 'best');
    hold off;
    
    maxFiringRate(cellNum)=Rm(cellNum) * vlt.fit.naka_rushton_func(C_fit(end),Rb(cellNum));

    % Display results for debugging
    disp(['Cell ', cellNames{cellNum}, ': Rm = ', num2str(Rm(cellNum)), ', Rb = ', num2str(Rb(cellNum))]);
end


% Define function to remove outliers using IQR
removeOutliers = @(x) ~isoutlier(x, 'quartiles');

% Identify non-outlier indices for all 3 metrics
valid_Rm = removeOutliers(Rm);
valid_Rb = removeOutliers(Rb);
valid_maxFR = removeOutliers(maxFiringRate);

% Combine logical indices to exclude any rows where one of the metrics is an outlier
valid_indices = valid_Rm & valid_Rb & valid_maxFR;

% Filter the table and relevant variables
cellNames = cellNames(valid_indices);
strain = strain(valid_indices);
treatment = treatment(valid_indices);
Rm = Rm(valid_indices);
Rb = Rb(valid_indices);
maxFiringRate = maxFiringRate(valid_indices);

% Create cleaned summary table
T = table(cellNames, strain, treatment, Rm, Rb, maxFiringRate, ...
    'VariableNames', {'CellName', 'strain', 'treatment', 'Rm', 'Rb', 'maxFiringRate'});
% 
% % Create table with results
% T = table(cellNames, strain, treatment, Rm, Rb, maxFiringRate, 'VariableNames', {'CellName', 'strain', 'treatment', 'Rm', 'Rb', 'maxFiringRate'});

% Display and save results
disp(T);
writetable(T, outputCsvName); % Save to CSV file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%