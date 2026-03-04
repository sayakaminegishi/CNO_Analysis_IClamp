function [p, tbl, stats, c, m, gnames, n] = tableANOVA_WKY_Clozapine(biggestTable)
% TABLEANOVA_WKY_CLOZAPINE - ANOVA on FI peak response: WKY Strain (Clozapine vs Empty)
%
% Usage:
%   [p, tbl, stats, c, m, gnames, n] = tableANOVA_WKY_Clozapine(biggestTable)
%
% Description:
%   Filters the input table to isolate 'WKY' strain rows where the drug is either
%   'clozapine N-oxide' or empty (Control). It runs a one-way ANOVA on the
%   'FIcalc.fitless.peakResponse' variable.
%
%   Displays TWO figures:
%     1. Standard ANOVA boxplot (showing distribution of data).
%     2. Multiple Comparisons graph (showing means and confidence intervals).
%
% Inputs:
%   biggestTable - A table containing the required electrophysiology and metadata columns.
%
% Outputs:
%   p       - The p-value from the one-way ANOVA.
%   tbl     - The ANOVA table (cell array).
%   stats   - A structure containing statistics for multiple comparisons.
%   c       - Pairwise comparison results matrix (intervals and p-values).
%   m       - Group means and standard errors.
%   gnames  - Cell array of group names.
%   n       - Vector of sample counts per group.

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Column Names
% -----------------------------
col_strain   = 'StrainName';
col_drugMix  = 'DrugTreatmentMixtureName';
col_celltype = 'Treatment_CultureFromCellTypeOntology'; % QC filter
col_data     = 'FIcalc.fitless.peakResponse';

% -----------------------------
% 2) Check Required Columns
% -----------------------------
required_cols = {col_strain, col_drugMix, col_celltype, col_data};
missing_cols = required_cols(~ismember(required_cols, biggestTable.Properties.VariableNames));
if ~isempty(missing_cols)
    error('blt:tableANOVA:MissingColumn', 'Missing columns: %s', strjoin(missing_cols, ', '));
end

% -----------------------------
% 3) Filter Rows
% -----------------------------

% A) Filter for Cell Type (Neurons/Glia)
target_celltype_str = 'CL:0011103, CL:0000516'; 
celltype_data = biggestTable.(col_celltype);
if iscell(celltype_data) || isstring(celltype_data)
    keep_celltype = strcmp(string(celltype_data), target_celltype_str);
else
    keep_celltype = string(celltype_data) == target_celltype_str;
end

% B) Filter for Strain == 'WKY'
strain_data = biggestTable.(col_strain);
target_strain = 'WKY';
if iscell(strain_data)
    keep_strain = strcmp(strain_data, target_strain);
else
    keep_strain = string(strain_data) == target_strain;
end

% C) Filter for Drug: 'clozapine N-oxide' OR Empty
drug_data = biggestTable.(col_drugMix);
is_drug_empty = is_whitespace_col(biggestTable, col_drugMix);

target_drug_name = 'clozapine N-oxide';
if iscell(drug_data)
    is_clozapine = strcmp(drug_data, target_drug_name);
else
    is_clozapine = string(drug_data) == target_drug_name;
end

keep_drug_condition = is_drug_empty | is_clozapine;

% Combine Filters
rowsToKeep = keep_celltype & keep_strain & keep_drug_condition;
filteredTable = biggestTable(rowsToKeep, :);

if height(filteredTable) == 0
    warning('blt:tableANOVA:NoData', 'No data remaining after filtering for WKY + Clozapine/Empty.');
    p = NaN; tbl = []; stats = [];
    c = []; m = []; gnames = {}; n = [];
    return;
end

% -----------------------------
% 4) Extract and Group Data
% -----------------------------
y = filteredTable.(col_data);
raw_drug = filteredTable.(col_drugMix);
group = strings(size(y));

% Assign simple labels
subset_empty = is_whitespace_col(filteredTable, col_drugMix);
group(subset_empty) = "Control"; 
group(~subset_empty) = "Clozapine"; 

% Ensure numeric data
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
    c = []; m = []; gnames = {}; n = [];
    return;
end

y = y(valid_idx);
group = group(valid_idx);

% -----------------------------
% 5) Run One-Way ANOVA (Plot 1)
% -----------------------------
% We call anova1 with 'on' to generate the standard boxplot.
% We DO NOT create a figure() beforehand to avoid the "blank figure" issue.
[p, tbl, stats] = anova1(y, group, 'on');

% Grab the figure anova1 just created to customize it
h_anova = gcf; 
set(h_anova, 'Name', 'ANOVA: WKY Response Distribution'); % Set window title

ax_anova = gca;
xlabel(ax_anova, 'Condition', 'Interpreter','none');
ylabel(ax_anova, 'Peak firing rate (Hz)', 'Interpreter','none');
title(ax_anova, 'WKY Strain: Clozapine vs Control (Distribution)', 'Interpreter','none');
grid(ax_anova, 'on');
box(ax_anova, 'off');

% Print ANOVA results
printAnova1Summary(tbl, p, col_data, 'Drug Condition');

% -----------------------------
% 6) Multiple Comparisons (Plot 2)
% -----------------------------
% Create a NEW figure for the multcompare plot
figure('Name', 'Comparison: WKY Response (Clozapine vs Control)');
[c, m, h_mc, gnames] = multcompare(stats, 'display', 'on');

% Customize multcompare axes
figure(h_mc); 
ax_mc = findobj(h_mc, 'Type', 'axes');
if ~isempty(ax_mc), ax_mc = ax_mc(1); else, ax_mc = gca; end

xlabel(ax_mc, 'Peak firing rate (Hz)', 'Interpreter','none');
ylabel(ax_mc, 'Condition', 'Interpreter','none');
title(ax_mc, 'Multiple Comparisons: Mean ± 95% Interval', 'Interpreter','none');
grid(ax_mc, 'on');
box(ax_mc, 'off');

% -----------------------------
% 7) Calculate and Print Sample Counts
% -----------------------------
n = zeros(length(gnames), 1);
fprintf('Sample Size Summary:\n');
for i = 1:length(gnames)
    currentGroup = string(gnames{i});
    count = sum(group == currentGroup);
    n(i) = count;
    fprintf('  %s: n = %d\n', currentGroup, count);
end
fprintf('\n');

% -----------------------------
% 8) Print Interpretation
% -----------------------------
printSignificantPairsAndInterpretation(c, gnames, 0.05, col_data);

end

% ======================================================================
% Helper: whitespace/empty detector
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
elseif iscategorical(data)
    is_ws = isundefined(data) | (strlength(strip(string(data))) == 0);
else
    is_ws = arrayfun(@isempty, data);
end

is_ws = is_ws(:);
end

% ======================================================================
% Helper: Print ANOVA summary
% ======================================================================
function printAnova1Summary(tbl, p, dataLabel, groupLabel)
fprintf('\nANOVA (one-way) summary: %s by %s\n', dataLabel, groupLabel);

F = NaN; df1 = NaN; df2 = NaN;
try
    df1 = tbl{2,3};   
    df2 = tbl{3,3};   
    F   = tbl{2,5};   
catch
end

if ~isnan(F) && ~isnan(df1) && ~isnan(df2)
    fprintf('  F(%d, %d) = %.4f, p = %.4g\n', df1, df2, F, p);
else
    fprintf('  p = %.4g\n', p);
end

alpha = 0.05;
if isnan(p)
    fprintf('  Interpretation: p is NaN (insufficient valid data).\n\n');
elseif p < alpha
    fprintf('  Interpretation: Significant effect of %s (p < %.2f).\n\n', ...
        groupLabel, alpha);
else
    fprintf('  Interpretation: No significant effect of %s (p >= %.2f).\n\n', ...
        groupLabel, alpha);
end
end

% ======================================================================
% Helper: Print multcompare results
% ======================================================================
function printSignificantPairsAndInterpretation(c, gnames, alpha, dataLabel)
fprintf('Comparison summary:\n');

if isempty(c)
    fprintf('  No output to report.\n\n');
    return;
end

pcol = 6; dcol = 4; lcol = 3; ucol = 5;
sig = c(:,pcol) < alpha;

if ~any(sig)
    fprintf('  No significant differences found (alpha = %.3f).\n\n', alpha);
    return;
end

sigC = c(sig,:);
[~, ord] = sort(sigC(:,pcol), 'ascend');
sigC = sigC(ord,:);

fprintf('  Significant differences (alpha = %.3f):\n', alpha);

for i = 1:size(sigC,1)
    g1 = sigC(i,1);
    g2 = sigC(i,2);
    name1 = string(gnames{g1});
    name2 = string(gnames{g2});
    diffEst = sigC(i,dcol);
    ciLo = sigC(i,lcol);
    ciHi = sigC(i,ucol);
    pAdj = sigC(i,pcol);

    if diffEst > 0, higher = name1; lower = name2;
    else, higher = name2; lower = name1; end

    fprintf('    %s > %s (Δ = %.2f Hz, 95%% CI [%.2f, %.2f], p = %.4g)\n', ...
        higher, lower, abs(diffEst), ciLo, ciHi, pAdj);
end
fprintf('\n');
end