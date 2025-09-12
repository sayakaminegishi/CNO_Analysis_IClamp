function T = birrenFileManifest(fileManifest, typeTable)
% birrenFileManifest - Processes a file manifest to extract variables based on a type table.
%
%   T = birrenFileManifest(fileManifest, typeTable)
%
%   This function takes a cell array of file paths and a table mapping types
%   to variables. It extracts a "type string" from each file path, finds the
%   corresponding row in the typeTable, and populates an output table with
%   the variables from that row.
%
%   Inputs:
%       fileManifest - A cell array where each element is a file path string.
%                      It's assumed that paths use forward slashes ('/') as
%                      delimiters.
%
%       typeTable    - A MATLAB table where the first column, named 'type',
%                      contains unique string identifiers. The remaining columns
%                      represent the variables to be extracted.
%
%   Output:
%       T            - A MATLAB table where each row corresponds to a file
%                      from the fileManifest. The first column is the full
%                      filename, and the subsequent columns are the extracted
%                      variables. If a file's type string does not match any
%                      entry in the typeTable, a warning is issued, and its 
%                      variable fields will be filled with default values 
%                      (NaN for numeric, '' for others).
%
    arguments
        fileManifest (:,1) cell {mustBeText}
        typeTable table {mustHaveTypeColumn(typeTable)}
    end

    % Get variable names from the typeTable (all columns except the first, which is the key)
    varNamesFromTypeTable = typeTable.Properties.VariableNames;
    outputVarNames = ['filename', varNamesFromTypeTable(2:end)];
    
    % Pre-allocate a cell array to hold the data for efficiency
    numFiles = numel(fileManifest);
    numVars = numel(outputVarNames);
    outputData = cell(numFiles, numVars);
    
    % Loop through each file in the manifest
    for i = 1:numFiles
        filePath = fileManifest{i};
        outputData{i, 1} = filePath; % First column is always the full path

        % --- Type String Extraction Logic (Updated) ---
        % Based on the prompt, the "type string" is the information after the
        % second slash and before the last slash of the file path. This segment
        % can itself contain slashes.
        parts = strsplit(filePath, '/');
        typeString = '';
        % Need at least 4 parts for this logic to be meaningful (e.g., dir1/dir2/typestring/file)
        if numel(parts) >= 4 
            typeString = strjoin(parts(3:end-1), '/');
        end
        % --- End of Type String Extraction Logic ---

        if ~isempty(typeString)
            % Find the row in typeTable that matches the extracted typeString
            matchIdx = find(strcmp(typeTable.type, typeString));

            if isscalar(matchIdx)
                % A unique match was found, so we populate the variables for this file
                for j = 2:numel(varNamesFromTypeTable)
                    varName = varNamesFromTypeTable{j};
                    outputData{i, j} = typeTable.(varName)(matchIdx);
                end
            else
                % If there is no match or multiple matches, issue a warning and fill with defaults
                if isempty(matchIdx)
                    warning('birrenFileManifest:TypeNotFound', 'Type string "%s" from file "%s" was not found in the typeTable.', typeString, filePath);
                else
                    warning('birrenFileManifest:MultipleTypesFound', 'Multiple matches for type string "%s" from file "%s" were found in the typeTable. Using default values.', typeString, filePath);
                end
                for j = 2:numel(varNamesFromTypeTable)
                    outputData{i, j} = get_default_value(typeTable.(varNamesFromTypeTable{j}));
                end
            end
        else
            % If the path was too short to extract a type string, fill with defaults
            for j = 2:numel(varNamesFromTypeTable)
                outputData{i, j} = get_default_value(typeTable.(varNamesFromTypeTable{j}));
            end
        end
    end

    % Convert the cell array to a final table
    T = cell2table(outputData, 'VariableNames', outputVarNames);
end

function defaultValue = get_default_value(columnData)
    % Helper function to get a type-appropriate default value for non-matches.
    if isnumeric(columnData)
        defaultValue = NaN;
    elseif iscategorical(columnData)
        % Create a new category for undefined, if necessary
        if ~ismember('<undefined>', categories(columnData))
             columnData = addcats(columnData, '<undefined>');
        end
        defaultValue = categorical({'<undefined>'});
    else % For cell arrays of strings or other types
        defaultValue = {''};
    end
end

% --- Validation function ---
function mustHaveTypeColumn(tbl)
    % Custom validation function to ensure the table has a 'type' column
    if ~ismember('type', tbl.Properties.VariableNames)
        eid = 'birrenFileManifest:NoTypeColumn';
        msg = "The 'typeTable' input must have a variable named 'type'.";
        throwAsCaller(MException(eid, msg));
    end
end
