function msg = findDuplicateCells(dataTable)
%findDuplicateCells Finds duplicate cell recordings in a data table.
%
%   msg = findDuplicateCells(dataTable)
%
%   This function examines a table, typically the output from a function
%   like 'birrenExtractCellLabels', and identifies rows that are duplicates
%   based on the combination of three key columns: 'ExperimentDateString',
%   'cellNumber', and 'cellRecordNumber'.
%
%   Inputs:
%       dataTable - A MATLAB table that must contain the three key columns.
%
%   Output:
%       msg       - A cell array of strings. Each string is a formatted
%                   message detailing a specific duplicate combination and
%                   how many times it was repeated. If no duplicates are
%                   found, the cell array will be empty.
%
%   Example Message:
%       'Cell 2023_08_18 4 3 was repeated 2 times'

    arguments
        dataTable table {mustHaveRequiredColumns(dataTable)}
    end

    % --- 1. Identify Duplicates using groupsummary ---
    % Define the columns that together form the unique key for a cell recording.
    keyVars = {'ExperimentDateString', 'cellNumber', 'cellRecordNumber'};
    
    % Use groupsummary to count occurrences of each unique key combination.
    % This is a highly efficient, vectorized way to find duplicates.
    summaryTable = groupsummary(dataTable, keyVars, 'IncludeEmptyGroups', false);
    
    % Filter the summary to find only the groups that appear more than once.
    duplicateGroups = summaryTable(summaryTable.GroupCount > 1, :);

    % --- 2. Format Output Messages ---
    numDuplicateSets = height(duplicateGroups);
    msg = cell(numDuplicateSets, 1); % Pre-allocate the output cell array for speed.

    % Loop through each set of duplicates found.
    for i = 1:numDuplicateSets
        % Extract the identifying information for the current duplicate group.
        dateStr = duplicateGroups.ExperimentDateString{i};
        cellNum = duplicateGroups.cellNumber(i);
        recNum  = duplicateGroups.cellRecordNumber(i);
        count   = duplicateGroups.GroupCount(i);
        
        % Format the error message string according to the required format.
        msg{i} = sprintf('Cell %s %d %d was repeated %d times', ...
                         dateStr, cellNum, recNum, count);
    end
end


% --- Validation function ---
function mustHaveRequiredColumns(tbl)
    % Custom validation function to ensure the table has the necessary columns.
    requiredCols = {'ExperimentDateString', 'cellNumber', 'cellRecordNumber'};
    if ~all(ismember(requiredCols, tbl.Properties.VariableNames))
        eid = 'findDuplicateCells:MissingColumns';
        msgText = 'Input table must contain "ExperimentDateString", "cellNumber", and "cellRecordNumber" columns.';
        throwAsCaller(MException(eid, msgText));
    end
end
