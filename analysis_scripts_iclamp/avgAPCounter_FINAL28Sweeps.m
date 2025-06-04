
% MAIN SCRIPT - GET AVG AP COUNT PER SWEEP FOR MULTIPLE FILES
% DESCRIPTION: Reads multiple .abf files, calculates AP counts per sweep, 
% and stores results in a table where:
% - Columns = the current injections (pA)
% - Rows = File names
% and shows average AP count per sweep in the final row

% Created by Sayaka (Saya) Minegishi, with advice from ChatGPT.
% minegishis@brandeis.edu
% Last modified 5/31/2025


clear all;
close all;
%only for files with 28 sweeps
%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
outputfile = "WKYNDG_acuteCNO.xlsx"; % Summary file name for the table with the AP counts for each cell
outputFilename_SEM = 'WKYNDG_acuteCNO_SEM.xlsx'; %excel file name for the table with injected current, mean AP, and their error bars
%%%%%%%%%%%%%%% DO NOT MODIFY BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp("Start of program")

addpath('analysis_scripts_iclamp/');
mkdir tempdata;

dirname = pwd;
disp(['Now working on directory ' dirname]);

tempDir = fullfile(dirname, 'tempdata', filesep);
get_files_from_user(dirname);

currentInjections = [-20, -10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, ...
                     100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250];%injected current for each sweep

list = dir(fullfile(tempDir, '*.abf'));
file_names = {list.name};
numFiles = numel(file_names);

% Initialize storage
fileGroups = containers.Map();
groupSweepCounts = containers.Map();

for n = 1:numFiles
    filename = fullfile(tempDir, file_names{n});
    disp([int2str(n) '. Processing: ' filename]);

    try
        apCounts = getAPCountForTrial9(filename);

        % Only keep up to 28 sweeps
        apCounts = apCounts(1:min(end, 28));

        % Zero out sweeps 1 to 4 if any are non-zero
        apCounts(1:min(2, numel(apCounts))) = 0;

        sweepCount = numel(apCounts);

        baseName = file_names{n};
        prefix = regexprep(baseName, '\d{4}\.abf$', '');

        if isKey(fileGroups, prefix)
            tempList = fileGroups(prefix);
            tempList{end+1} = apCounts;
            fileGroups(prefix) = tempList;
            groupSweepCounts(prefix) = max(groupSweepCounts(prefix), sweepCount);
        else
            fileGroups(prefix) = {apCounts};
            groupSweepCounts(prefix) = sweepCount;
        end

    catch
        fprintf('Error processing %s, skipped.\n', filename);
    end
end

% Aggregate and average by group (max 28 sweeps)
groupNames = keys(fileGroups);
numGroups = length(groupNames);
maxTotalSweeps = min(28, max(cell2mat(values(groupSweepCounts))));

allResults = cell(numGroups + 1, maxTotalSweeps + 1); % +1 for name column
sweepDataGrouped = NaN(numGroups, maxTotalSweeps);
beforeOutliers = cell(numGroups, 1);
afterOutliers = cell(numGroups, 1);

for i = 1:numGroups
    group = groupNames{i};
    apList = fileGroups(group);
    sweepCounts = min(groupSweepCounts(group), 28);

    groupMatrix = NaN(length(apList), maxTotalSweeps);
    for j = 1:length(apList)
        rowData = apList{j};
        rowData = rowData(1:min(end, 28)); % ensure max 28
        groupMatrix(j, 1:numel(rowData)) = rowData;
    end

    beforeOutliers{i} = groupMatrix;

    % Remove outliers (per sweep)
    for s = 1:maxTotalSweeps
        sweepVals = groupMatrix(:, s);
        Q1 = prctile(sweepVals, 28);
        Q3 = prctile(sweepVals, 75);
        IQR = Q3 - Q1;
        lowerBound = Q1 - 1.5 * IQR;
        upperBound = Q3 + 1.5 * IQR;
        outliers = sweepVals < lowerBound | sweepVals > upperBound;
        sweepVals(outliers) = NaN;
        groupMatrix(:, s) = sweepVals;
    end

    afterOutliers{i} = groupMatrix;

    avgGroup = mean(groupMatrix, 1, 'omitnan');
    allResults{i,1} = group;
    allResults(i, 2:maxTotalSweeps+1) = num2cell(avgGroup);
    sweepDataGrouped(i, 1:numel(avgGroup)) = avgGroup;
end

% Final average row
avgPerSweepAll = mean(sweepDataGrouped, 1, 'omitnan');
allResults{end,1} = 'Average_all';
allResults(end, 2:end) = num2cell(avgPerSweepAll);

% Table headers
varNames = [{'File Group'}, arrayfun(@(x) sprintf('%dpA', x), currentInjections(1:maxTotalSweeps), 'UniformOutput', false)];
T = cell2table(allResults, 'VariableNames', varNames);
disp(T);

% Save Excel
filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

%% Visualization: Boxplots after outlier removal only in a neat grid layout

numSweeps = maxTotalSweeps;    % total sweeps
sweepsPerFig = 7;             % number of sweeps to plot per figure
cols = 7;                     % plots per row
rows = ceil(sweepsPerFig / cols);

numFigs = ceil(numSweeps / sweepsPerFig);

for figIdx = 1:numFigs
    figure('Name', sprintf('Boxplots After Outlier Removal - Figure %d', figIdx), ...
           'Position', [100 100 1400 800]);
    
    startSweep = (figIdx-1)*sweepsPerFig + 1;
    endSweep = min(figIdx*sweepsPerFig, numSweeps);
    currentSweeps = startSweep:endSweep;
    numSweepsInFig = length(currentSweeps);
    rowsCurrent = ceil(numSweepsInFig / cols);

    for i = 1:numSweepsInFig
        s = currentSweeps(i);
        subplot(rowsCurrent, cols, i);
        
        cleanVals = [];
        for g = 1:numGroups
            if s <= size(afterOutliers{g}, 2)
                vals = afterOutliers{g}(:, s);
                vals = vals(~isnan(vals));
                cleanVals = [cleanVals; vals];
            end
        end
        
        if ~isempty(cleanVals)
            boxplot(cleanVals, 'Labels', {sprintf('%d pA', currentInjections(s))});
            annotate_boxplot_values();
        else
            text(0.5, 0.5, 'No data', 'HorizontalAlignment', 'center');
            axis off;
        end
        
        title(sprintf('Sweep %d', s));
        xlabel('Current injection (pA)');
        ylabel('Number of AP');
    end
end

% Scatterplot with SEM remains unchanged
meanAP = mean(sweepDataGrouped, 1, 'omitnan');
semAP = std(sweepDataGrouped, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(sweepDataGrouped), 1));

% Create a table using injected current values
currentValues = currentInjections(:);  % ensure it's a column vector

T_bounds = table(currentValues(1:maxTotalSweeps), meanAP', meanAP' - semAP', meanAP' + semAP', ...
    'VariableNames', {'CurrentInjection_pA', 'MeanAP', 'LowerBound', 'UpperBound'});

disp(T_bounds);

% Save to Excel

writetable(T_bounds, outputFilename_SEM);

fprintf('Table saved to %s\n', outputFilename_SEM);

figure('Name', 'AP Counts per Sweep with Original Data, Mean and SEM', 'Position', [100 100 900 450]);
hold on;
for g = 1:numGroups
    x = 1:maxTotalSweeps;
    y = sweepDataGrouped(g, :);
    valid = ~isnan(y);
    scatter(x(valid), y(valid), 50, 'filled', 'MarkerFaceAlpha', 0.3);
end
errorbar(1:maxTotalSweeps, meanAP, semAP, 'o-', 'LineWidth', 2, 'MarkerSize', 8, ...
    'MarkerFaceColor', 'r', 'Color', 'k');
xlabel('Current injection (pA)');
xticks(1:maxTotalSweeps);
xticklabels(arrayfun(@(x) sprintf('%dpA', x), currentInjections(1:maxTotalSweeps), 'UniformOutput', false));

ylabel('Number of AP');
title('AP Counts per Sweep: Original Points + Mean ± SEM');
grid on;
hold off;

% Cleanup
rmdir(tempDir, 's');

%% Internal Functions
function [apCounts] = getAPCountForTrial9(filename1)
    [dataallsweeps, si, h] = abf2load(filename1); 
    numSweeps = min(size(dataallsweeps, 3), 28); 
    apCounts = zeros(1, numSweeps);
    
    starttime_ms = 138;
    duration_ms = 500;
    
    starttime_idx = round(starttime_ms / (si * 1e-3));
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;

    for sweep = 1:numSweeps
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        allowedDeviation = 3;
        firstpercentile = prctile(data, 1); 
        minAmp = firstpercentile + allowedDeviation;

        [~, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, ...
            'MinPeakProminence', 20, 'MinPeakDistance', 50);
        apCounts(sweep) = numel(spikeLocations);
    end
end

function get_files_from_user(dirname)
    tempDir = fullfile(dirname, 'tempdata', filesep);
    while true
        [file, path] = uigetfile('*.abf', 'Select one or more ABF files', 'MultiSelect', 'on');
        if isequal(file, 0)
            disp('No files selected. Please select at least one .abf file.');
            continue;
        end
        if ischar(file)
            file = {file};
        end
        for i = 1:length(file)
            copyfile(fullfile(path, file{i}), tempDir);
        end
        break;
    end
end

function annotate_boxplot_values()
    hold on;
    hMedian = findobj(gca,'Tag','Median');
    for i = 1:length(hMedian)
        xMed = mean(get(hMedian(i), 'XData'));
        yMed = mean(get(hMedian(i), 'YData'));
        text(xMed + 0.15, yMed, sprintf('Median: %.2f', yMed), 'Color', 'red', 'FontWeight', 'bold');
    end
    
    hWhisker = findobj(gca,'Tag','Whisker');
    for i = 1:length(hWhisker)
        xWhisk = mean(get(hWhisker(i), 'XData'));
        yWhisk = mean(get(hWhisker(i), 'YData'));
        text(xWhisk + 0.15, yWhisk, sprintf('Whisker: %.2f', yWhisk), 'Color', 'blue');
    end
    
    hBox = findobj(gca,'Tag','Box');
    for i = 1:length(hBox)
        xBox = mean(get(hBox(i), 'XData'));
        yBox = get(hBox(i), 'YData');
        yUnique = unique(yBox);
        if length(yUnique) >= 2
            text(xBox + 0.15, yUnique(1), sprintf('Q1: %.2f', yUnique(1)), 'Color', 'green');
            text(xBox + 0.15, yUnique(end), sprintf('Q3: %.2f', yUnique(end)), 'Color', 'green');
        end
    end
    hold off;
end
