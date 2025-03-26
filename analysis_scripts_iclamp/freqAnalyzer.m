%ap count and freq analyzer
%takes in an EXCEL FILE with values to analyze
%compares freq between SHR and WKY neurons (overall)
%25 sweeps

filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx';

%%%%%% table 1 - SHR 25sw Chronic CNO 10uM %%%%%%%%%%%%%%%%
sheet_SHR25ChrCNO = '48h10umCNO-SHR_28sw';  % Change to the desired sheet name

% Import the specific sheet as a table
T = readtable(filename, 'Sheet', sheet_SHR25ChrCNO);

% Compute the mean of each column except the first column
averages = mean(T{:, 2:end})';

% Create a sweep number column (matching the number of columns being averaged)
numSweeps = length(averages); % Number of columns averaged
sweepNumbers = (1:numSweeps)';

% Compute the frequency by dividing AverageValue by 0.5 seconds
frequency = averages / 0.5;

% Create a new table with Sweep Number, Average Value, and Frequency
SHR25ChrCNO_table = table(sweepNumbers, averages, frequency, ...
    'VariableNames', {'SweepNumber', 'AverageValue', 'Frequency(Hz)'});

disp(SHR25ChrCNO_table)
%%%%%% table 2 - WKY 25sw Chronic CNO 10uM %%%%%%%%%%%%%%%%
sheet_48h10umCNOWKY = '48h10umCNO-WKY_28sw';  % Change to the desired sheet name

% Import the specific sheet as a table
T = readtable(filename, 'Sheet', sheet_48h10umCNOWKY);

% Compute the mean of each column except the first column
averages = mean(T{:, 2:end})';

% Create a sweep number column (matching the number of columns being averaged)
numSweeps = length(averages); % Number of columns averaged
sweepNumbers = (1:numSweeps)';

% Compute the frequency by dividing AverageValue by 0.5 seconds
frequency = averages / 0.5;

% Create a new table with Sweep Number, Average Value, and Frequency
WKY25ChrCNO_table = table(sweepNumbers, averages, frequency, ...
    'VariableNames', {'SweepNumber', 'AverageValue', 'Frequency(Hz)'});

disp(WKY25ChrCNO_table)

%%%%%%%%%%% ANALYZE %%%%%%%%%%%%%%%%%
% Extract frequency columns from both tables
freq1 = SHR25ChrCNO_table.("Frequency(Hz)"); % Frequency from first dataset
freq2 = WKY25ChrCNO_table.("Frequency(Hz)"); % Compute frequency for the second table

% Check normality using histogram
figure;
subplot(1,2,1); histogram(freq1); title('Frequency - SHR25ChrCNO');
subplot(1,2,2); histogram(freq2); title('Frequency - WKY25ChrCNO');

[h, p, ci, stats] = ttest2(freq1, freq2, 'Tail', 'right'); % Tests if freq2 > freq1
% Perform independent t-test
[h, p, ci, stats] = ttest2(freq1, freq2, 'Tail', 'both'); % Two-tailed test

% Display t-statistic and p-value
fprintf('t-statistic = %.4f, p-value = %.4f\n', stats.tstat, p);

if p<=0.05

    % Determine direction of difference
    if stats.tstat > 0
        fprintf('freq2 (WKY) is significantly greater than freq1 (SHR).\n');
    elseif stats.tstat < 0
        fprintf('freq1 (SHR) is significantly greater than freq2 (WKY).\n');
    
    end
else
    fprintf('No significant difference detected.\n');
end

% Display confidence interval
fprintf('95%% Confidence Interval: [%.4f, %.4f]\n', ci(1), ci(2));
%%%%%%%%%

%effect size for the difference in AP freq:
mean1 = mean(freq1);
mean2 = mean(freq2);
std_pooled = sqrt((std(freq1)^2 + std(freq2)^2) / 2);
cohens_d = (mean2 - mean1) / std_pooled;

fprintf('Effect size (Cohen''s d) = %.4f\n', cohens_d);

%%%%%%%%%%%%%%%%%%%%%%%%%%%