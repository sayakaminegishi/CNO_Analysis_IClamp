% MAIN SCRIPT - GET AVG AP COUNT PER SWEEP FOR MULTIPLE FILES
% DESCRIPTION: Reads multiple .abf files, calculates AP counts per sweep, 
% and stores results in a table where:
% - Columns = the current injections (pA)
% - Rows = File names
% and shows average AP count per sweep in the final row

% THIS PROGRAM GROUPS FILES BY THE CELL AND CALCULATES AVERAGE AP COUNT
% FROM ALL THE FILES FOR THAT PARTICULAR CELL. 

% Created by Sayaka (Saya) Minegishi, with advice from ChatGPT.
% minegishis@brandeis.edu
% Last modified 6/5/2025
clear all;
close all;

%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
outputfile_grouped = "SHRNOnly_grouped.xlsx";     % Grouped output
outputfile_ungrouped = "SHRNOnly_ungrouped.xlsx"; % Ungrouped output

%%%%%%%%%%%%%%% DO NOT MODIFY BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp("Start of program")

addpath('analysis_scripts_iclamp/');
mkdir tempdata;

dirname = pwd;
disp(['Now working on directory ' dirname]);

tempDir = fullfile(dirname, 'tempdata', filesep);
get_files_from_user(dirname);

list = dir(fullfile(tempDir, '*.abf'));
file_names = {list.name};
numFiles = numel(file_names);

% Initialize storage
fileGroups = containers.Map(); % Key = prefix, Value = cell array of AP counts
groupSweepCounts = containers.Map(); % To track max sweeps per group

%%% ADDITION: Prepare ungrouped matrix %%%
maxSweepsUngrouped = 0;
ungroupedResults = {};  % Cell array for ungrouped data
ungroupedNames = {};    % Corresponding file names

for n = 1:numFiles
    filename = fullfile(tempDir, file_names{n});
    disp([int2str(n) '. Processing: ' filename]);

    try
        apCounts = getAPCountForTrial9(filename);
        apCounts(1:min(4, numel(apCounts))) = 0;
        sweepCount = numel(apCounts);

        % Store ungrouped data
        ungroupedResults{end+1} = apCounts;
        ungroupedNames{end+1} = file_names{n};
        maxSweepsUngrouped = max(maxSweepsUngrouped, sweepCount);

        % Grouping by prefix
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

%%% ADDITION: Create ungrouped output table with SEM %%%
T_ungrouped = cell(numel(ungroupedResults), maxSweepsUngrouped + 2); % +2 for file name and SEM
for i = 1:numel(ungroupedResults)
    row = ungroupedResults{i};
    T_ungrouped{i,1} = ungroupedNames{i};                 % File name
    T_ungrouped(i,2:numel(row)+1) = num2cell(row);        % AP counts
    T_ungrouped{i,end} = std(row, 'omitnan') / sqrt(sum(~isnan(row)));  % SEM
end

ungroupedVarNames = [{'File Name'}, ...
    arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxSweepsUngrouped, 'UniformOutput', false), ...
    {'SEM'}];

T_ungrouped = cell2table(T_ungrouped, 'VariableNames', ungroupedVarNames);
disp("Ungrouped AP Count Table with SEM:");
disp(T_ungrouped);

%%% Save ungrouped table %%%
filenameExcelUngrouped = fullfile(dirname, outputfile_ungrouped);
writetable(T_ungrouped, filenameExcelUngrouped, 'Sheet', 1);
%%% Continue with grouped logic as before %%%
groupNames = keys(fileGroups);
numGroups = length(groupNames);
allResults = cell(numGroups + 1, 1); % +1 for final average row
maxTotalSweeps = max(cell2mat(values(groupSweepCounts)));

sweepDataGrouped = NaN(numGroups, maxTotalSweeps);

for i = 1:numGroups
    group = groupNames{i};
    apList = fileGroups(group);
    sweepCounts = groupSweepCounts(group);

    groupMatrix = NaN(length(apList), sweepCounts);
    for j = 1:length(apList)
        rowData = apList{j};
        groupMatrix(j, 1:numel(rowData)) = rowData;
    end

    avgGroup = mean(groupMatrix, 1, 'omitnan');
    allResults{i,1} = group;
    allResults(i, 2:sweepCounts+1) = num2cell(avgGroup);
    sweepDataGrouped(i, 1:numel(avgGroup)) = avgGroup;
end

% Final overall average row
avgPerSweepAll = mean(sweepDataGrouped, 1, 'omitnan');
allResults{end,1} = 'Average_all';
allResults(end, 2:end) = num2cell(avgPerSweepAll);

% Final grouped output table
varNames = [{'File Group'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxTotalSweeps, 'UniformOutput', false)];
T_grouped = cell2table(allResults, 'VariableNames', varNames);
disp("Grouped AP Count Table:");
disp(T_grouped);

% Save grouped table
filenameExcelDoc = fullfile(dirname, outputfile_grouped);
writetable(T_grouped, filenameExcelDoc, 'Sheet', 1);

% Cleanup
rmdir(tempDir, 's');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INTERNAL FUNCTION: getAPCountForTrial9 (same as original)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [apCounts] = getAPCountForTrial9(filename1)
    [dataallsweeps, si, h] = abf2load(filename1); 
    numSweeps = size(dataallsweeps, 3);
    apCounts = zeros(1, numSweeps);
    
    if numSweeps > 28
        return;
    end
    
    starttime_ms = 138;
    duration_ms = 500;
    
    starttime_idx = round(starttime_ms / (si * 1e-3));
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;

    for sweep = 1:numSweeps
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        allowedDeviation = 3;
        firstpercentile = prctile(dataallsweeps(starttime_idx:endtime_idx),1); 
        minAmp = firstpercentile + allowedDeviation;

        [~, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 20, 'MinPeakDistance', 50);
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
