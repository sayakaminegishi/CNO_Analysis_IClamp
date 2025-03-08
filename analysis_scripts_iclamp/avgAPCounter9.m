% UNDERDEVELOPED - JUST FOR TEST

clear all;
close all;

%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
outputfile = "SHRND+G_singles13.xlsx"; % Summary file name

%%%%%%%%%%%%%%% DO NOT MODIFY BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp("Start of program")

addpath('analysis_scripts_iclamp/');
mkdir tempdata; % Create temp folder for selected files

dirname = pwd; % Current working directory
disp(['Now working on directory ' dirname]);

tempDir = fullfile(dirname, 'tempdata', filesep); % Folder for selected data

get_files_from_user(dirname); % Let user select files, move to tempdata

% Get file names
list = dir(fullfile(tempDir, '*.abf'));
file_names = {list.name}; % List of ABF file names
numFiles = numel(file_names);

% Initialize storage for AP counts
allResults = {}; % Will hold file names & AP counts
maxSweeps = 0;   % Track the max number of sweeps

% Group files by prefix (excluding last 4 digits)
fileGroups = containers.Map();

for n = 1:numFiles
    filename = file_names{n};
    
    % Extract file name prefix (excluding last 4 digits and extension)
    [~, shortFileName, ~] = fileparts(filename);
    prefix = shortFileName(1:end-4); % Remove last 4 characters
    
    if ~isKey(fileGroups, prefix)
        fileGroups(prefix) = {};
    end
    
    fileGroups(prefix){end+1} = fullfile(tempDir, filename);
end

% Process each group
groupKeys = keys(fileGroups);
groupResults = {}; % Storage for final results

for g = 1:numel(groupKeys)
    groupName = groupKeys{g};
    groupFiles = fileGroups(groupName);
    numGroupFiles = numel(groupFiles);
    
    allGroupData = []; % Store all AP counts from this group

    for n = 1:numGroupFiles
        filename = groupFiles{n};
        disp(['Processing: ' filename]);

        try
            apCounts = getAPCountForTrial8(filename); % Get AP counts for this file
            sweepCount = numel(apCounts); % Number of sweeps in this file
            maxSweeps = max(maxSweeps, sweepCount); % Update max sweep count
            
            % Store results in matrix for averaging later
            apCountsPadded = NaN(1, maxSweeps);
            apCountsPadded(1:sweepCount) = apCounts;
            allGroupData = [allGroupData; apCountsPadded]; % Append data
        catch
            fprintf('Error processing %s, skipped.\n', filename);
        end
    end

   if ~isempty(allGroupData)
    % Compute average AP count per sweep, ignoring NaNs
    avgAPCounts = mean(allGroupData, 1, 'omitnan');
else
    % If no valid data, fill with NaNs
    avgAPCounts = NaN(1, maxSweeps);
end

    % Store results
    groupResults{g, 1} = groupName; % Use group name instead of individual file names
    groupResults(g, 2:maxSweeps+1) = num2cell(avgAPCounts); % AP counts per sweep
end

% Ensure all rows have the same number of columns
for i = 1:size(groupResults, 1)
    rowLength = numel(groupResults(i, :));
    if rowLength < maxSweeps + 1  % +1 accounts for the filename column
        groupResults(i, rowLength+1:maxSweeps+1) = {NaN}; % Pad with NaN
    end
end

% Define column names
varNames = [{'File Name'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxSweeps, 'UniformOutput', false)];

% Convert to table
T = cell2table(groupResults, 'VariableNames', varNames);

% Display results
disp(T);

% Save to Excel
filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

% Remove temp directory
rmdir(tempDir, 's');
