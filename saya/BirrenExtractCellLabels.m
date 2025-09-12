function outputTable = BirrenExtractCellLabels(inputTable)
%BirrenExtractCellLabels Extracts metadata from filenames in a table.
%   outputTable = BirrenExtractCellLabels(inputTable) takes a MATLAB table
%   as input. The table must contain a variable named 'filename' with full
%   file paths.
%
%   The function parses the filename (without path or extension) to extract
%   three new pieces of information:
%     - 'ExperimentDateString': The first part of the filename, assumed to
%       be the date (e.g., '2023_08_18').
%     - 'cellNumber': The integer found between the 3rd and 4th underscore.
%     - 'cellRecordNumber': The integer found after the last underscore.
%
%   These three new variables are added as columns to the output table,
%   inserted immediately to the right of the original 'filename' column.
%   Filenames that do not match the expected 'DATE_CELL_REC.ext' format
%   will result in empty or NaN values in the new columns, and a warning
%   will be displayed.
%
%   Example:
%     A filename like '.../2023_08_18_04_0003.abf' yields:
%       ExperimentDateString: '2023_08_18'
%       cellNumber: 4
%       cellRecordNumber: 3

% --- 1. Input Validation ---
if ~istable(inputTable)
    error('Input must be a MATLAB table.');
end
if ~ismember('filename', inputTable.Properties.VariableNames)
    error("Input table must contain a variable named 'filename'.");
end

% --- 2. Extract Basenames from File Paths ---
% Use fileparts to get just the filename without the directory or extension.
% This operation is vectorized and works on the entire cell array of paths.
[~, baseNames, ~] = fileparts(inputTable.filename);

% --- 3. Define Regex Pattern and Extract Tokens ---
% This pattern is designed to capture the three required pieces of data
% based on the structure defined by the underscores.
%
% Pattern Breakdown:
%   ^                  - Start of the string
%   ([^_]*_[^_]*_[^_]*) - Capture Group 1: Everything before the 3rd underscore.
%                        This matches and captures the date string.
%   _                  - The literal 3rd underscore.
%   ([^_]*)            - Capture Group 2: Everything between the 3rd and 4th
%                        underscores. This captures the cell number.
%   _                  - The literal 4th (and last) underscore.
%   ([^_]*)$           - Capture Group 3: Everything after the last underscore
%                        until the end of the string. Captures the record number.
pattern = '^([^_]*_[^_]*_[^_]*)_([^_]*)_([^_]*)$';

% The 'tokens' option returns a cell array. Each cell within it contains
% another cell array holding the captured strings for one filename.
allTokens = regexp(baseNames, pattern, 'tokens');

% --- 4. Process Tokens and Populate New Columns ---
numRows = height(inputTable);

% Find which filenames successfully matched the pattern.
% cellfun applies the 'isempty' function to each cell in allTokens.
isMatch = ~cellfun('isempty', allTokens);

% Pre-allocate the new columns with default "not found" values.
experimentDateString = repmat({''}, numRows, 1); % Empty string for dates
cellNumber = NaN(numRows, 1);                   % NaN for numbers
cellRecordNumber = NaN(numRows, 1);

% Process all matching files in a single, vectorized block.
if any(isMatch)
    % Get the tokens only from the rows that had a match.
    matchedTokens = vertcat(allTokens{isMatch});
    
    % The result is nested, so we concatenate the inner cells to form a
    % single N-by-3 cell matrix of the captured string data.
    tokenData = vertcat(matchedTokens{:});
    
    % Assign the extracted data to the corresponding rows in our final arrays.
    experimentDateString(isMatch) = tokenData(:, 1);
    cellNumber(isMatch) = str2double(tokenData(:, 2));
    cellRecordNumber(isMatch) = str2double(tokenData(:, 3));
end

% Issue a single warning for all filenames that failed to parse.
if any(~isMatch)
    nonMatchingFiles = strjoin(baseNames(~isMatch), ', ');
    warning('The following filenames did not match the expected format and were not parsed: %s', nonMatchingFiles);
end

% --- 5. Assemble and Reorder the Final Table ---
% Start by copying the original table.
outputTable = inputTable;

% Add the new data as new variables (columns).
outputTable.ExperimentDateString = experimentDateString;
outputTable.cellNumber = cellNumber;
outputTable.cellRecordNumber = cellRecordNumber;

% Find the position of the 'filename' column to insert the new columns after it.
originalVars = inputTable.Properties.VariableNames;
filenameIdx = find(strcmp(originalVars, 'filename'), 1);

% Create the desired new order of columns programmatically.
newOrder = [originalVars(1:filenameIdx), ...
            {'ExperimentDateString', 'cellNumber', 'cellRecordNumber'}, ...
            originalVars(filenameIdx+1:end)];
            
% Reorder the table columns to match the new order.
outputTable = outputTable(:, newOrder);

end
