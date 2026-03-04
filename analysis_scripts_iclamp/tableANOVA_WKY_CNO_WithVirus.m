function [p, tbl, stats, c, m, gnames] = tableANOVA_WKY_CNO_WithVirus(biggestTable)
% TABLEANOVA_WKY_CNO_WITHVIRUS - ANOVA on FI peak response (WKY Strain)
% Compares CNO vs Control in rows that MUST have a virus and specific cell types.

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Column Names
% -----------------------------
col_virus    = 'virus_OntologyName';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName';
col_drug     = 'DrugTreatmentMixtureName'; 
col_data     = 'FIcalc.fitless.peakResponse';

% -----------------------------
% 2) Filter Rows
% -----------------------------
% Requirement A: Strain is WKY
keep_strain = strcmp(string(biggestTable.(col_strain)), 'WKY');

% Requirement B: Virus MUST be present (Not empty/whitespace)
keep_with_virus = ~is_whitespace_col(biggestTable, col_virus);

% Requirement C: Specific Cell Types (Neurons and Glia)
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% Requirement D: Drug is either CNO or Empty (Control)
is_cno = strcmp(string(biggestTable.(col_drug)), 'clozapine N-oxide');
is_empty_drug = is_whitespace_col(biggestTable, col_drug);

% Combine all logic
rowsToKeep = keep_strain & keep_with_virus & keep_celltype & (is_cno | is_empty_drug);
filteredTable = biggestTable(rowsToKeep, :);

% --- DIAGNOSTIC PRINTOUT ---
n_cno = sum(keep_strain & keep_with_virus & keep_celltype & is_cno);
n_control = sum(keep_strain & keep_with_virus & keep_celltype & is_empty_drug);

fprintf('--- Filtering Diagnostics (Virus-Present Groups) ---\n');
fprintf('Condition: Strain=WKY, CellType=%s, Virus=PRESENT\n', target_celltype_str);
fprintf('  Rows found for CNO: %d\n', n_cno);
fprintf('  Rows found for Control (empty drug): %d\n', n_control);
fprintf('----------------------------------------------------\n');

if height(filteredTable) == 0 || (n_cno == 0 || n_control == 0)
    warning('blt:tableANOVA:InsufficientGroups', ...
        'Analysis aborted: Need at least one sample in BOTH CNO and Control groups with a virus.');
    p = NaN; tbl = []; stats = []; c = []; m = []; gnames = {};
    return;
end

% -----------------------------
% 3) Prepare Data
% -----------------------------
y = filteredTable.(col_data);
if iscell(y); y = cell2mat(y); end

% Map group names for the stats
raw_groups = string(filteredTable.(col_drug));
group = repmat("Control + Virus", size(raw_groups)); 
group(strcmp(raw_groups, "clozapine N-oxide")) = "CNO + Virus";

% Remove NaNs from data
valid_idx = ~isnan(y);
y = y(valid_idx);
group = group(valid_idx);

% -----------------------------
% 4) Run One-Way ANOVA
% -----------------------------
figure('Name','ANOVA: WKY CNO vs Control (With Virus)');
[p, tbl, stats] = anova1(y, group, 'on');

xlabel(gca, 'Treatment (WKY with Virus)', 'Interpreter','none');
ylabel(gca, 'Peak firing rate (Hz)', 'Interpreter','none');
title(gca, 'Effect of CNO on WKY (Virus & Co-Culture Present)', 'Interpreter','none');

% -----------------------------
% 5) Multiple Comparisons
% -----------------------------
% Only run if we have a valid p-value and significant groups
if ~isnan(p) && p < 0.05
    figure('Name','Post-hoc: WKY CNO vs Control (With Virus)');
    [c, m, h_mc, gnames] = multcompare(stats, 'display', 'on');
else
    fprintf('ANOVA p = %.4f (No significant difference or insufficient data).\n', p);
    c = []; m = []; gnames = unique(group);
end

end

% ======================================================================
% Helper: whitespace/empty detector (Included for completeness)
% ======================================================================
function is_ws = is_whitespace_col(tbl, colName)
    data = tbl.(colName);
    if iscell(data)
        is_ws = cellfun(@(x) isempty(x) || (ischar(x) && all(isspace(x))) || ...
            (isstring(x) && (x == "" || x == " ")), data);
    elseif isstring(data)
        is_ws = ismissing(data) | (strlength(strip(data)) == 0);
    elseif ischar(data)
        is_ws = all(isspace(data), 2);
    elseif isnumeric(data)
        is_ws = isnan(data);
    else
        is_ws = arrayfun(@isempty, data);
    end
    is_ws = is_ws(:);
end