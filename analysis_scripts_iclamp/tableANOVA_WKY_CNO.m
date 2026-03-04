function [p, tbl, stats, c, m, gnames] = tableANOVA_WKY_CNO(biggestTable)
% TABLEANOVA_WKY_CNO - ANOVA on FI peak response: CNO vs Control (WKY Strain, with virus)
%
% Filters rows for StrainName == 'WKY', checks DrugTreatmentMixtureName 
% for 'clozapine N-oxide' vs empty, and maintains original virus/celltype filters.

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Column Names
% -----------------------------
col_virus    = 'virus_OntologyName';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName';
col_drug     = 'DrugTreatmentMixtureName'; % Changed to MixtureName for CNO comparison
col_data     = 'FIcalc.fitless.peakResponse';

% -----------------------------
% 2) Check Required Columns
% -----------------------------
required_cols = {col_virus, col_celltype, col_strain, col_drug, col_data};
missing_cols = required_cols(~ismember(required_cols, biggestTable.Properties.VariableNames));
if ~isempty(missing_cols)
    error('blt:tableANOVA:MissingColumn', 'Missing columns: %s', strjoin(missing_cols, ', '));
end

% -----------------------------
% 3) Filter Rows
% -----------------------------
% Filter A: Strain must be WKY
keep_strain = strcmp(string(biggestTable.(col_strain)), 'WKY');

% Filter B: Drug is CNO OR Empty
is_cno = strcmp(string(biggestTable.(col_drug)), 'clozapine N-oxide');
is_empty_drug = is_whitespace_col(biggestTable, col_drug);
keep_drug = is_cno | is_empty_drug;

% Filter C: Original constraints (No virus & specific cell type)
keep_no_virus = is_whitespace_col(biggestTable, col_virus);
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% Combine filters
rowsToKeep = keep_strain & keep_drug & keep_no_virus & keep_celltype;
filteredTable = biggestTable(rowsToKeep, :);

if height(filteredTable) == 0
    warning('blt:tableANOVA:NoData', 'No WKY data found for CNO vs Control comparison.');
    p = NaN; tbl = []; stats = []; c = []; m = []; gnames = {};
    return;
end

% -----------------------------
% 4) Extract and Clean Data
% -----------------------------
y = filteredTable.(col_data);
if iscell(y); y = cell2mat(y); end

% Create a descriptive group array for the plot
raw_groups = string(filteredTable.(col_drug));
group = repmat("Control", size(raw_groups)); 
group(strcmp(raw_groups, "clozapine N-oxide")) = "CNO";

% Remove NaNs
valid_idx = ~isnan(y);
y = y(valid_idx);
group = group(valid_idx);

% -----------------------------
% 5) Run One-Way ANOVA
% -----------------------------
figure('Name','ANOVA: WKY Peak response (CNO vs Control)');
[p, tbl, stats] = anova1(y, group, 'on');

xlabel(gca, 'Treatment (WKY Strain)', 'Interpreter','none');
ylabel(gca, 'Peak firing rate (Hz)', 'Interpreter','none');
title(gca, 'One-way ANOVA: CNO Effect on WKY Peak Response', 'Interpreter','none');

printAnova1Summary(tbl, p, col_data, 'Treatment (CNO vs Control)');

% -----------------------------
% 6) Multiple Comparisons
% -----------------------------
figure('Name','Post-hoc: WKY CNO vs Control');
[c, m, h_mc, gnames] = multcompare(stats, 'display', 'on');

xlabel(gca, 'Peak firing rate (Hz)', 'Interpreter','none');
ylabel(gca, 'Treatment', 'Interpreter','none');
title(gca, 'CNO vs Control Pairwise Comparison', 'Interpreter','none');

printSignificantPairsAndInterpretation(c, gnames, 0.05, col_data);

end

% ======================================================================
% Re-using your existing Helpers
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

function printAnova1Summary(tbl, p, dataLabel, groupLabel)
    fprintf('\nANOVA (one-way) summary: %s by %s\n', dataLabel, groupLabel);
    try
        df1 = tbl{2,3}; df2 = tbl{3,3}; F = tbl{2,5};
        fprintf('  F(%d, %d) = %.4f, p = %.4g\n', df1, df2, F, p);
    catch
        fprintf('  p = %.4g\n', p);
    end
    if p < 0.05
        fprintf('  Interpretation: Significant effect of %s (p < 0.05).\n\n', groupLabel);
    else
        fprintf('  Interpretation: No significant effect detected.\n\n');
    end
end

function printSignificantPairsAndInterpretation(c, gnames, alpha, dataLabel)
    if isempty(c); return; end
    sig = c(:,6) < alpha;
    if ~any(sig)
        fprintf('  No significant pairwise differences.\n\n');
        return;
    end
    for i = find(sig)'
        name1 = gnames{c(i,1)}; name2 = gnames{c(i,2)};
        diffEst = c(i,4);
        fprintf('    %s vs %s: Δ = %.3f Hz, p_adj = %.4g\n', name1, name2, diffEst, c(i,6));
    end
end