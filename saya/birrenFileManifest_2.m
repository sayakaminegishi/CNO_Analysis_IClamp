function T = birrenFileManifest(fileManifest, typeTable)
% birrenFileManifest - Processes a file manifest to extract variables based on a type table.
%
%   T = birrenFileManifest(fileManifest, typeTable)
%
%   This function takes a cell array of file paths and a table mapping types
%   and strains to variables. It extracts a "type string" and a "strain"
%   from each file path, finds the unique corresponding row in the typeTable,
%   and populates an output table with the variables from that row.
%
%   Inputs:
%       fileManifest - A cell array where each element is a file path string.
%                      It's assumed that paths use forward slashes ('/') as
%                      delimiters. The path structure is expected to be:
%                      '.../STRAIN/TYPE_STRING/.../file.ext'
%
%       typeTable    - A MATLAB table where the combination of the 'type' and
%                      'strain' columns uniquely identifies a row. The remaining
%                      columns represent the variables to be extracted.
%
%   Output:
%       T            - A MATLAB table where each row corresponds to a file
%                      from the fileManifest. The first column is the full
%                      filename, and the subsequent columns are the extracted
%                      variables. If a file's type/strain combination does not
%                      match any entry in the typeTable, a warning is issued,
%                      and its variable fields will be filled with default
%                      values (NaN for numeric, '' for others).
%
    arguments
        fileManifest (:,1) cell {mustBeText}
        typeTable table {mustHaveRequiredColumns(typeTable)}
    end
    
    % Get variable names from the typeTable (all columns except the keys)
    varNamesFromTypeTable = typeTable.Properties.VariableNames;
    % Exclude 'type' and 'strain' from the variables to be added to the output
    outputVarNamesToAdd = setdiff(varNamesFromTypeTable, {'type', 'strain'}, 'stable');
    outputVarNames = ['filename', outputVarNamesToAdd];

    % Pre-allocate a cell array to hold the data for efficiency
    numFiles = numel(fileManifest);
    numVars = numel(outputVarNames);
    outputData = cell(numFiles, numVars);

    % Loop through each file in the manifest
    for i = 1:numFiles
        filePath = fileManifest{i};
        outputData{i, 1} = filePath; % First column is always the full path

        % --- Strain and Type String Extraction Logic ---
        parts = strsplit(filePath, '/');
        strainFromFile = '';
        typeFromFile = '';

        % Extract strain (the part between the 1st and 2nd slash)
        if numel(parts) >= 3
            strainFromFile = parts{2};
        end
        % Extract type string (between 2nd and last slash)
        if numel(parts) >= 4
            typeFromFile = strjoin(parts(3:end-1), '/');
        end
        % --- End of Extraction Logic ---

        if ~isempty(strainFromFile) && ~isempty(typeFromFile)
            % --- Sophisticated Matching Logic ---
            % Find the row where BOTH the strain and type match.
            % strtrim removes leading/trailing whitespace.
            % strcmpi provides a case-insensitive comparison.
            strainMatch = strcmpi(strtrim(typeTable.strain), strtrim(strainFromFile));
            typeMatch = strcmpi(strtrim(typeTable.type), strtrim(typeFromFile));
            
            matchIdx = find(strainMatch & typeMatch);
            % --- End of Matching Logic ---

            if isscalar(matchIdx)
                % A unique match was found, so we populate the variables for this file
                for j = 1:numel(outputVarNamesToAdd)
                    varName = outputVarNamesToAdd{j};
                    % The outputData index is j+1 because the first column is 'filename'
                    outputData{i, j+1} = typeTable.(varName)(matchIdx);
                end
            else
                % If there is no match or multiple matches, issue a warning and fill with defaults
                if isempty(matchIdx)
                    warning('birrenFileManifest:TypeNotFound', ...
                        'No match found for strain "%s" and type "%s" from file "%s". Using default values.', ...
                        strainFromFile, typeFromFile, filePath);
                else
                    warning('birrenFileManifest:MultipleTypesFound', ...
                        'Multiple matches for strain "%s" and type "%s" from file "%s" were found. Using default values.', ...
                        strainFromFile, typeFromFile, filePath);
                end
                for j = 1:numel(outputVarNamesToAdd)
                    varName = outputVarNamesToAdd{j};
                    outputData{i, j+1} = get_default_value(typeTable.(varName));
                end
            end
        else
            % If the path was too short to extract a strain/type, warn and fill with defaults
            warning('birrenFileManifest:PathTooShort', ...
                'File path "%s" is too short to extract strain and type. Using default values.', filePath);
            for j = 1:numel(outputVarNamesToAdd)
                varName = outputVarNamesToAdd{j};
                outputData{i, j+1} = get_default_value(typeTable.(varName));
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
function mustHaveRequiredColumns(tbl)
    % Custom validation function to ensure the table has 'type' and 'strain' columns
    if ~ismember('type', tbl.Properties.VariableNames)
        eid = 'birrenFileManifest:NoTypeColumn';
        msg = "The 'typeTable' input must have a variable named 'type'.";
        throwAsCaller(MException(eid, msg));
    end
    if ~ismember('strain', tbl.Properties.VariableNames)
        eid = 'birrenFileManifest:NoStrainColumn';
        msg = "The 'typeTable' input must have a variable named 'strain'.";
        throwAsCaller(MException(eid, msg));
    end
end
