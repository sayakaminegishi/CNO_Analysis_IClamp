% MAIN SCRIPT - GET AVG AP COUNT PER SWEEP FOR MULTIPLE FILES
% DESCRIPTION: Reads multiple .abf files, calculates AP counts per sweep, 
% and stores results in a table where:
% - Columns = Sweep numbers
% - Rows = File names
% and shows average AP count per sweep in the final row

% RELIES ON: getAPCountForTrial9.m

% INSTRUCTIONS: save getAPCountForTrial9.m in the same directory as this
% file. Specify excel file name for output. Then click Run on this program. It will direct you to pick your
% abf files for the cell, where each file represents one run of the protocol (one set of
% sweeps) for that cell. It will save the AP counts in a table called
% APCounts.xlsx in the same directory as this script.


% Created by Sayaka (Saya) Minegishi, with some advice from ChatGPT.
% minegishis@brandeis.edu
% 3/4/2025

clear all;
close all;
%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
%please enter the name of the excel file that you want to store the results
%in.
outputfile = "SHRN+DREADDS_10um48hCNO.xlsx"; % Summary file name

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

for n = 1:numFiles
    filename = fullfile(tempDir, file_names{n});
    disp([int2str(n) '. Processing: ' filename]);

    try

        apCounts = getAPCountForTrial9(filename); % Get AP counts for this file
        sweepCount = numel(apCounts); % Number of sweeps in this file
        maxSweeps = max(maxSweeps, sweepCount); % Update max sweep count
        
        % Store results (prepend filename)
       [~, shortFileName, ext] = fileparts(filename);
       allResults{n, 1} = strcat(shortFileName, ext); % Store only the file name with extension

        allResults(n, 2:sweepCount+1) = num2cell(apCounts); % AP counts per sweep
    catch
        fprintf('Error processing %s, skipped.\n', filename);
    end
end

% Ensure all rows have the same number of columns
for i = 1:size(allResults, 1)
    rowLength = numel(allResults(i, :));
    if rowLength < maxSweeps + 1  % +1 accounts for the filename column
        allResults(i, rowLength+1:maxSweeps+1) = {NaN}; % Pad with NaN
    end
end
% Compute the average AP count for each sweep (excluding the filename column)
numericData = allResults(:, 2:end); % Extract only numeric part
validRows = cellfun(@(x) isnumeric(x) || ismissing(x), numericData); % Check valid numeric data

% Convert to matrix while preserving NaNs
sweepData = NaN(size(numericData)); % Preallocate with NaNs
for i = 1:size(numericData, 1)
    numericRow = numericData(i, :);
    numericRow = [numericRow{:}]; % Convert cell row to numeric array
    sweepData(i, 1:numel(numericRow)) = numericRow; % Store values
end

% Compute mean per sweep, ignoring NaNs
avgPerSweep = mean(sweepData, 1, 'omitnan');

% Append final row with averages
allResults{end+1, 1} = 'Average'; % Label row as "Average"
allResults(end, 2:end) = num2cell(avgPerSweep); % Store computed averages


% Define column names
varNames = [{'File Name'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxSweeps, 'UniformOutput', false)];

% Convert to table
T = cell2table(allResults, 'VariableNames', varNames);

% Display results
disp(T);

% Save to Excel
filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

% Remove temp directory
rmdir(tempDir, 's');

