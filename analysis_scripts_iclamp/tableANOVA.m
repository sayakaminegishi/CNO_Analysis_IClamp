function [p, tbl, stats] = tableANOVA(biggestTable)
% TABLEANOVA - ANOVA on FI peak response: Strain (Filtered by Co-Culture)
%
% [P, TBL, STATS] = BLT.TABLEANOVA(BIGGESTTABLE)
%
% Inputs:
%   BIGGESTTABLE - The table output from blt.makeTable
%
% Outputs:
%   P     - p-value from One-way ANOVA
%   TBL   - ANOVA table
%   STATS - ANOVA statistics structure
%
% This function filters the table to exclude rows where:
%   - 'virus_OntologyName' is not whitespace/empty
%   - 'DrugTreatmentLocationOntology' is not whitespace/empty
%
% And restricts to rows where 'Treatment_CultureFromCellTypeOntology'
% is exactly the string: 'CL:0011103, CL:0000516'. NEURON, GLIA 
%
% It then performs a One-way ANOVA on:
%   - Variable: FIcalc.fitless.peakResponse
%   - Group: StrainName
%
% Displays the ANOVA table and a multiple comparison plot.

arguments
    biggestTable table
end

% 1. Define Column Names
col_virus = 'virus_OntologyName';
col_drug = 'DrugTreatmentLocationOntology';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain = 'StrainName';
col_data = 'FIcalc.fitless.peakResponse';

% 2. Check Required Columns
required_cols = {col_virus, col_drug, col_celltype, col_strain, col_data};
missing_cols = required_cols(~ismember(required_cols, biggestTable.Properties.VariableNames));
if ~isempty(missing_cols)
    error('blt:tableANOVA:MissingColumn', 'Missing columns: %s', strjoin(missing_cols, ', '));
end

% 3. Filter Rows

% A. Virus and Drug must be whitespace/empty
keep_virus = is_whitespace_col(biggestTable, col_virus);
keep_drug = is_whitespace_col(biggestTable, col_drug);

% B. Cell Type must match exactly 'CL:0011103, CL:0000516'
target_celltype_str = 'CL:0011103, CL:0000516';
celltype_data = biggestTable.(col_celltype);

if iscell(celltype_data) || isstring(celltype_data)
    % Exact string match
    keep_celltype = strcmp(string(celltype_data), target_celltype_str);
else
    % If it's char array or categorical
    keep_celltype = string(celltype_data) == target_celltype_str;
end

% Combine filters
rowsToKeep = keep_virus & keep_drug & keep_celltype;

filteredTable = biggestTable(rowsToKeep, :);

if height(filteredTable) == 0
    warning('blt:tableANOVA:NoData', 'No data remaining after filtering.');
    p = NaN; tbl = []; stats = [];
    return;
end

% 4. Extract Data for ANOVA
y = filteredTable.(col_data);
group = filteredTable.(col_strain);   % Strain only

% Ensure y is numeric
if ~isnumeric(y)
    if iscell(y)
        y = cell2mat(y);
    else
        error('blt:tableANOVA:NonNumericData', 'Data column must be numeric.');
    end
end

% Remove NaNs
valid_idx = ~isnan(y);
if sum(valid_idx) == 0
    warning('blt:tableANOVA:AllNaNs', 'All data points are NaN.');
    p = NaN; tbl = []; stats = [];
    return;
end

y = y(valid_idx);
group = group(valid_idx);

% 5. Run One-Way ANOVA
% Factor: Strain
% Display set to 'on'
[p, tbl, stats] = anova1(y, group, 'on');

% 6. Multiple Comparisons
figure;
multcompare(stats);

end

function is_ws = is_whitespace_col(tbl, colName)
    data = tbl.(colName);

    if iscell(data)
        is_ws = cellfun(@(x) isempty(x) || (ischar(x) && all(isspace(x))) || (isstring(x) && (x == "" || x == " ")), data);
    elseif isstring(data)
        is_ws = ismissing(data) | (strlength(strip(data)) == 0);
    elseif ischar(data)
        is_ws = all(isspace(data), 2);
    elseif isnumeric(data)
        is_ws = isnan(data);
    elseif iscategorical(data)
        is_ws = isundefined(data) | (strlength(strip(string(data))) == 0);
    else
        is_ws = arrayfun(@isempty, data);
    end
    is_ws = is_ws(:);
end