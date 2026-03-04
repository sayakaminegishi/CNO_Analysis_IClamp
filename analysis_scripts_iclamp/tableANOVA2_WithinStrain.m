function [p, tbl, stats, c, m, gnames] = tableANOVA2_WithinStrain(biggestTable)
% TABLEANOVA2_WithinStrain - Compare specific conditions within a strain
%
% This version filters for 'WKYNDG_Only' and 'WKYNDG_48hCNO' 
% and bypasses the "empty drug" filter to allow CNO groups.

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Column Names
% -----------------------------
col_virus    = 'virus_OntologyName';
col_drug     = 'DrugTreatmentLocationOntology';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName'; % This column contains WKYNDG_Only, etc.
col_data     = 'FIcalc.fitless.peakResponse';

% -----------------------------
% 2) Check Required Columns
% -----------------------------
required_cols = {col_virus, col_drug, col_celltype, col_strain, col_data};
missing_cols = required_cols(~ismember(required_cols, biggestTable.Properties.VariableNames));
if ~isempty(missing_cols)
    error('blt:tableANOVA:MissingColumn', 'Missing columns: %s', strjoin(missing_cols, ', '));
end

% -----------------------------
% 3) Filter Rows (MODIFIED)
% -----------------------------
% Define the specific groups you want to compare
target_groups = {'WKYNDG_Only', 'WKYNDG_48hCNO'};

% Filter for the specific groups in the StrainName column
keep_groups = ismember(string(biggestTable.(col_strain)), target_groups);

% Keep the cell type filter as per your original logic
target_celltype_str = 'CL:0011103, CL:0000516'; 
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% NOTE: Removed keep_virus and keep_drug filters because 
% WKYNDG_48hCNO likely contains data in those columns.
rowsToKeep = keep_groups & keep_celltype;

filteredTable = biggestTable(rowsToKeep, :);

if height(filteredTable) == 0
    warning('blt:tableANOVA:NoData', 'No data matching %s found.', strjoin(target_groups, ' or '));
    p = NaN; tbl = []; stats = []; c = []; m = []; gnames = {};
    return;
end

% -----------------------------
% 4) Extract Data for ANOVA
% -----------------------------
y     = filteredTable.(col_data);
group = filteredTable.(col_strain);

% Ensure y is numeric
if ~isnumeric(y)
    if iscell(y), y = cell2mat(y); else error('Data must be numeric.'); end
end

% Remove NaNs
valid_idx = ~isnan(y);
y = y(valid_idx);
group = group(valid_idx);

% -----------------------------
% 5) Run One-Way ANOVA
% -----------------------------
figure('Name','ANOVA: Within-Strain Comparison');
[p, tbl, stats] = anova1(y, group, 'on');

% Labeling
ax_anova = gca;
xlabel(ax_anova, 'Treatment Group');
ylabel(ax_anova, 'Peak firing rate (Hz)');
title(ax_anova, 'Comparison: WKYNDG Only vs 48h CNO');

printAnova1Summary(tbl, p, col_data, col_strain);

% -----------------------------
% 6) Multiple Comparisons
% -----------------------------
figure('Name','Multcompare: Within-Strain');
[c, m, h_mc, gnames] = multcompare(stats, 'display', 'on');

% Labeling
xlabel(gca, 'Peak firing rate (Hz)');
ylabel(gca, 'Condition');
title(gca, 'Pairwise Comparison within WKYNDG');

% -----------------------------
% 7) Print results
% -----------------------------
printSignificantPairsAndInterpretation(c, gnames, 0.05, col_data);
end

% ... (Keep the helper functions is_whitespace_col, printAnova1Summary, 
% and printSignificantPairsAndInterpretation from your original file here)