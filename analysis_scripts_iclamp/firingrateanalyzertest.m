addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab')

%%%%%%%%%% ENTER INFO BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx';
strainName = 'WKY'; 
sheetName = 'WKYN_Only';
outputCsvName = 'WKYNONLY_with_threshold.csv';
cno = 1;

%%%%%%%%%%%% LOAD DATA %%%%%%%%%%%%%
dataTable = readtable(filename, 'Sheet', sheetName);
cellNames = dataTable{:, 1}; 
C = linspace(-50e-12, 310e-12, 25); % Current in A
numCells = height(dataTable);

Rm = nan(numCells, 1);
Rb = nan(numCells, 1);
t = nan(numCells, 1);
maxFiringRate = nan(numCells, 1);
strain = repmat({strainName}, numCells, 1); 
treatment = ones(numCells,1) * cno;

% Plot layout
figure;
numRows = ceil(sqrt(numCells));
numCols = ceil(numCells / numRows);

for cellNum = 1:numCells
    Y = dataTable{cellNum, 2:end};
    c = C(5:end)';
    r = Y(5:end)';

    % Remove NaNs
    valid = ~isnan(r);
    c = c(valid);
    r = r(valid);

    if numel(r) < 5
        warning("Too few points for cell %s", cellNames{cellNum});
        continue
    end

    try
        % Fit using custom function
        [fitresult, ~] = fit_naka_rushton_shift(c, r);
        coeffs = coeffvalues(fitresult);
        Rm(cellNum) = coeffs(1);
        Rb(cellNum) = coeffs(2);
        t(cellNum) = coeffs(3);

        % Plot
        subplot(numRows, numCols, cellNum);
        plot(C, Y, 'o'); hold on;
        C_fit = linspace(min(C), max(C), 200)';
        r_fit = fittedNR(C_fit, Rm(cellNum), Rb(cellNum), t(cellNum));
        plot(C_fit, r_fit, 'r-', 'LineWidth', 1.5);
        xlabel('Current (A)'); ylabel('Firing rate (Hz)');
        title(sprintf('%s', cellNames{cellNum}));
        legend({'Data', 'Fit'}, 'Location', 'best');
        hold off;

        % Max firing rate
        maxFiringRate(cellNum) = max(r_fit);
    catch ME
        warning("Fit failed for cell %s: %s", cellNames{cellNum}, ME.message);
    end
end

%%%%%%%%%%%% CLEANING & OUTPUT %%%%%%%%%%%%%
% Remove outliers
removeOutliers = @(x) ~isoutlier(x, 'quartiles');
valid_idx = removeOutliers(Rm) & removeOutliers(Rb) & removeOutliers(maxFiringRate);

cellNames = cellNames(valid_idx);
strain = strain(valid_idx);
treatment = treatment(valid_idx);
Rm = Rm(valid_idx);
Rb = Rb(valid_idx);
t = t(valid_idx);
maxFiringRate = maxFiringRate(valid_idx);

T = table(cellNames, strain, treatment, Rm, Rb, t, maxFiringRate, ...
    'VariableNames', {'CellName', 'strain', 'treatment', 'Rm', 'Rb', 'threshold', 'maxFiringRate'});

disp(T);
writetable(T, outputCsvName);
function [fitresult, gof] = fit_naka_rushton_shift(c, r)
    ft = fittype(@(Rm, b, t, c) fittedNR(c, Rm, b, t), ...
        'independent', 'c', 'dependent', 'r');

    t_upper = median(c); 
    startpoints = [max(r), 1e-12, t_upper / 2]; 
    lowerbounds = [0, 0, 0];
    upperbounds = [Inf, Inf, t_upper];

    opts = fitoptions(ft, ...
        'StartPoint', startpoints, ...
        'Lower', lowerbounds, ...
        'Upper', upperbounds, ...
        'MaxIter', 1000, ...
        'Display', 'off');

    [fitresult, gof] = fit(c, r, ft, opts);
end

function R = fittedNR(c, Rm, b, t)
    delta = c - t;
    R = zeros(size(c));
    idx = delta > 0;
    R(idx) = Rm * delta(idx) ./ (b + delta(idx));
end
