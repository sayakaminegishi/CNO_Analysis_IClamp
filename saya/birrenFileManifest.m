function [T, msg] = birrenFileManifest(fileManifest, typeTable)
% birrenFileManifest - Processes a file manifest to extract variables based on a type table.
%
%   [T, msg] = birrenFileManifest(fileManifest, typeTable)
%
%   This function takes a cell array of file paths and a table mapping types
%   to variables. It extracts a "type string" from each file path, finds the
%   corresponding row in the typeTable, and populates an output table with
%   the variables from that row.
%
%   Inputs:
%       fileManifest - A cell array where each element is a file path string.
%                      It's assumed that paths use forward slashes ('/') as
%                      delimiters. The path structure is expected to be:
%                      '.../TYPE_STRING/.../file.ext'
%
%       typeTable    - A MATLAB table where the first column, named 'type',
%                      contains string identifiers. The remaining columns
%                      represent the variables to be extracted.
%
%   Outputs:
%       T            - A MATLAB table where each row corresponds to a file
%                      from the fileManifest.
%
%       msg          - A cell array of unique warning messages generated
%                      during processing.
%
    arguments
        fileManifest (:,1) cell {mustBeText}
        typeTable table {mustHaveTypeColumn(typeTable)}
    end
    
    % Get variable names from the typeTable (all columns except the first, which is the key)
    varNamesFromTypeTable = typeTable.Properties.VariableNames;
    outputVarNamesToAdd = setdiff(varNamesFromTypeTable, {'type'}, 'stable');
    outputVarNames = ['filename', outputVarNamesToAdd];
    
    % Pre-allocate for efficiency
    numFiles = numel(fileManifest);
    numVars = numel(outputVarNames);
    outputData = cell(numFiles, numVars);
    warningMessages = {}; % Cell array to collect all warning messages

    % Loop through each file in the manifest
    for i = 1:numFiles
        filePath = fileManifest{i};
        outputData{i, 1} = filePath; % First column is always the full path

        % --- Type String Extraction Logic ---
        % The "type string" is the information after the second slash and
        % before the last slash of the file path.
        parts = strsplit(filePath, '/');
        typeFromFile = '';
        % Need at least 4 parts for this logic (e.g., dir1/dir2/typestring/file)
        if numel(parts) >= 4 
            typeFromFile = strjoin(parts(3:end-1), '/');
        end
        % --- End of Extraction Logic ---

        if ~isempty(typeFromFile)
            % --- Matching Logic ---
            % Find rows where the type matches (case-insensitive, ignoring whitespace).
            matchIdx = find(strcmpi(strtrim(typeTable.type), strtrim(typeFromFile)));
            
            if isempty(matchIdx)
                % CASE 1: No match was found.
                warnStr = sprintf('Type string "%s" from file "%s" was not found in the typeTable.', typeFromFile, filePath);
                warningMessages{end+1} = warnStr;
                
                % Fill the rest of the row with default values
                for j = 1:numel(outputVarNamesToAdd)
                    varName = outputVarNamesToAdd{j};
                    outputData{i, j+1} = get_default_value(typeTable.(varName));
                end
            else
                % CASE 2: At least one match was found.
                if numel(matchIdx) > 1
                    % If multiple matches exist, issue a warning.
                    warnStr = sprintf('Multiple matches for type string "%s" were found. Using the first instance.', typeFromFile);
                    warningMessages{end+1} = warnStr;
                end
                
                % Use the parameters from the FIRST match found.
                firstMatchIdx = matchIdx(1);
                
                % Populate the variables for this file using the first match.
                for j = 1:numel(outputVarNamesToAdd)
                    varName = outputVarNamesToAdd{j};
                    outputData{i, j+1} = typeTable.(varName)(firstMatchIdx);
                end
            end
        else
            % CASE 3: The path was too short to extract a type string.
            warnStr = sprintf('File path "%s" is too short to extract a type string.', filePath);
            warningMessages{end+1} = warnStr;

            % Fill with defaults
            for j = 1:numel(outputVarNamesToAdd)
                varName = outputVarNamesToAdd{j};
                outputData{i, j+1} = get_default_value(typeTable.(varName));
            end
        end
    end
    
    % Convert the cell array to a final table
    T = cell2table(outputData, 'VariableNames', outputVarNames);
    
    % Return the unique warning messages, preserving order of first appearance
    msg = unique(warningMessages, 'stable');
    
    % Display the unique warnings to the command window
    for k = 1:numel(msg)
        warning('birrenFileManifest:ProcessingWarning', '%s', msg{k});
    end
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
