clear all;
close all;

%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
outputfile = "SHRNOnly_grouped.xlsx"; % Summary file name

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

for n = 1:numFiles
    filename = fullfile(tempDir, file_names{n});
    disp([int2str(n) '. Processing: ' filename]);

    try
        apCounts = getAPCountForTrial9(filename);
        % Zero out sweeps 1 to 4 if any are non-zero
        apCounts(1:min(4, numel(apCounts))) = 0;

        sweepCount = numel(apCounts);

        % Extract base prefix (everything except last 4 digits before .abf)
        baseName = file_names{n};
        prefix = regexprep(baseName, '\d{4}\.abf$', '');

        % Store AP counts in the group
        if isKey(fileGroups, prefix)
            tempList = fileGroups(prefix);        % Step 1: retrieve
            tempList{end+1} = apCounts;           % Step 2: modify
            fileGroups(prefix) = tempList;        % Step 3: store back
            groupSweepCounts(prefix) = max(groupSweepCounts(prefix), sweepCount);
        else
            fileGroups(prefix) = {apCounts};
            groupSweepCounts(prefix) = sweepCount;
        end

    catch
        fprintf('Error processing %s, skipped.\n', filename);
    end
end

% Aggregate and average by group
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

% Final output table
varNames = [{'File Group'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxTotalSweeps, 'UniformOutput', false)];
T = cell2table(allResults, 'VariableNames', varNames);
disp(T);

% Save
filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

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
    si_actual = 1e-6 * si;

    for sweep = 1:numSweeps
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        allowedDeviation = 3;
        firstpercentile = prctile(dataallsweeps(starttime_idx:endtime_idx),1); 
        minAmp = firstpercentile + allowedDeviation;

        [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 20, 'MinPeakDistance', 50);
        apCounts(sweep) = numel(spikeLocations);
    end
end


function get_files_from_user(dirname)
    tempDir = fullfile(dirname, 'tempdata', filesep);

    % Keep prompting until user selects at least one file
    while true
        [file, path] = uigetfile('*.abf', ...
            'Select one or more ABF files', ...
            'MultiSelect', 'on');

        % If user cancels, retry
        if isequal(file, 0)
            disp('No files selected. Please select at least one .abf file.');
            continue;
        end

        % Handle single vs multiple file selection
        if ischar(file)
            file = {file};  % Convert to cell for consistency
        end

        % Move selected files to tempDir
        for i = 1:length(file)
            copyfile(fullfile(path, file{i}), tempDir);
        end

        break;  % Exit loop once valid files are selected and copied
    end
end
