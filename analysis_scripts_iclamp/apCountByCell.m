clear all;
close all;

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

% Extract base names (excluding last 4 digits)
pattern = '(.*)\d{4}\.abf$';
baseNames = regexprep(file_names, pattern, '$1');
uniqueBaseNames = unique(baseNames);

allResults = {};
maxSweeps = 0;

for i = 1:numel(uniqueBaseNames)
    baseName = uniqueBaseNames{i};
    matchingFiles = file_names(startsWith(file_names, baseName));
    
    groupAPCounts = [];
    
    for j = 1:numel(matchingFiles)
        filename = fullfile(tempDir, matchingFiles{j});
        disp(['Processing: ' filename]);
        
        try
            apCounts = getAPCountForCell(filename, starttime_ms, duration_ms);
            sweepCount = numel(apCounts);
            maxSweeps = max(maxSweeps, sweepCount);
            groupAPCounts = [groupAPCounts; padarray(apCounts, [0, maxSweeps - sweepCount], NaN, 'post')];
        catch
            fprintf('Error processing %s, skipped.\n', filename);
        end
    end
    
    avgAPCounts = mean(groupAPCounts, 1, 'omitnan');
    allResults = [allResults; {baseName, avgAPCounts}];
end

varNames = [{'File Name'}, arrayfun(@(x) sprintf('Sweep_%d', x), 1:maxSweeps, 'UniformOutput', false)];
T = cell2table(allResults, 'VariableNames', varNames);

disp(T);

filenameExcelDoc = fullfile(dirname, outputfile);
writetable(T, filenameExcelDoc, 'Sheet', 1);

rmdir(tempDir, 's');
