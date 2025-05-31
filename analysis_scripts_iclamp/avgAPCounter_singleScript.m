% MAIN SCRIPT - GET AVG AP COUNT PER SWEEP FOR MULTIPLE FILES
% DESCRIPTION: Reads multiple .abf files, calculates AP counts per sweep, 
% and stores results in a table where:
% - Columns = Sweep numbers
% - Rows = File names
% and shows average AP count per sweep in the final row

% Created by Sayaka (Saya) Minegishi, with advice from ChatGPT.
% Combined version with internal function
% minegishis@brandeis.edu
% 3/4/2025, merged 5/29/2025

clear all;
close all;

%%%%%%%%%%% USER INPUT!!!!!!! %%%%%%%%%%%%%%%%%%%%
outputfile = "WKYN+WKYGD+10uMacuteCNO_new.xlsx"; % Summary file name

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
file_names = {list.name};
numFiles = numel(file_names);

% Initialize storage
allResults = {};
maxSweeps = 0;

for n = 1:numFiles
    filename = fullfile(tempDir, file_names{n});
    disp([int2str(n) '. Processing: ' filename]);

    try
        apCounts = getAPCountForTrial9(filename);
        sweepCount = numel(apCounts);
        maxSweeps = max(maxSweeps, sweepCount);
        
        [~, shortFileName, ext] = fileparts(filename);
        allResults{n, 1} = strcat(shortFileName, ext);
        allResults(n, 2:sweepCount+1) = num2cell(apCounts);
    catch
        fprintf('Error processing %s, skipped.\n', filename);
    end
end

% Pad rows with NaNs
for i = 1:size(allResults, 1)
    rowLength = numel(allResults(i, :));
    if rowLength < maxSweeps + 1
        allResults(i, rowLength+1:maxSweeps+1) = {NaN};
    end
end

% Compute average AP count per sweep
numericData = allResults(:, 2:end);
sweepData = NaN(size(numericData));
for i = 1:size(numericData, 1)
    numericRow = numericData(i, :);
    numericRow = [numericRow{:}];
    sweepData(i, 1:numel(numericRow)) = numericRow;
end
avgPerSweep = mean(sweepData, 1, 'omitnan');
allResults{end+1, 1} = 'Average';
allResults(end, 2:end) = num2cell(avgPerSweep);

% Save results
varNames = [{'File Name'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxSweeps, 'UniformOutput', false)];
T = cell2table(allResults, 'VariableNames', varNames);
disp(T);

filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

% Cleanup
rmdir(tempDir, 's');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INTERNAL FUNCTION: getAPCountForTrial9
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
    endtime_ms = starttime_ms + duration_ms;
    si_actual = 1e-6 * si;

    for sweep = 1:numSweeps
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        allowedDeviation = 3;
        firstpercentile = prctile(dataallsweeps(starttime_idx:endtime_idx),1); 
        minAmp = firstpercentile + allowedDeviation;

        [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 20, 'MinPeakDistance', 50);
        apCounts(sweep) = numel(spikeLocations);

        dvdt = diff(data) / si_actual;
        max_dvdt = max(abs(dvdt));
        % maxDvdtPerSweep(sweep) = max_dvdt; % Optional
    end
end
