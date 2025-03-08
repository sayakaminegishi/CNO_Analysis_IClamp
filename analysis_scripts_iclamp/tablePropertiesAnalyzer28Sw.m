%ap count and freq analyzer
%takes in an EXCEL FILE with values to analyze


filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellAvgApCount.xlsx';

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

% Perform one-sided Mann-Whitney U test (ranksum test)
%to test whether WKY freq is higher than SHR freq.
[p, h] = ranksum(freq2, freq1, 'tail', 'right'); % Tests if freq2 > freq1

% Display results
if h == 1
    fprintf('Significant difference in frequency values (p = %.4f)\n', p);
else
    fprintf('No significant difference in frequency values (p = %.4f)\n', p);
end

%effect size for the difference in AP freq:
mean1 = mean(freq1);
mean2 = mean(freq2);
std_pooled = sqrt((std(freq1)^2 + std(freq2)^2) / 2);
cohens_d = (mean2 - mean1) / std_pooled;

fprintf('Effect size (Cohen''s d) = %.4f\n', cohens_d);

%%%%%%%%%%%%%%%%%%%%%%%%%%%