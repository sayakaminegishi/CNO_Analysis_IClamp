function [p, tbl, stats, c, m, gnames] = tableANOVA2(biggestTable)
% TABLEANOVA2 - ANOVA on FI peak response: Strain (Filtered by Co-Culture)
%
% [P, TBL, STATS, C, M, GNAMES] = tableANOVA2(BIGGESTTABLE)
%
% Filters rows (virus/drug empty; celltype matches), runs one-way ANOVA
% on FIcalc.fitless.peakResponse grouped by StrainName, displays:
%   (1) ANOVA plot with axis labels
%   (2) multcompare plot with axis labels
% Prints:
%   - ANOVA summary + interpretation (F, df, p)
%   - multcompare significant pairs + interpretation sentences you can paste

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Column Names
% -----------------------------
col_virus    = 'virus_OntologyName';
col_drug     = 'DrugTreatmentLocationOntology';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName';
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
% 3) Filter Rows
% -----------------------------
keep_virus = is_whitespace_col(biggestTable, col_virus);
keep_drug  = is_whitespace_col(biggestTable, col_drug);

target_celltype_str = 'CL:0011103, CL:0000516';
celltype_data = biggestTable.(col_celltype);

if iscell(celltype_data) || isstring(celltype_data)
    keep_celltype = strcmp(string(celltype_data), target_celltype_str);
else
    keep_celltype = string(celltype_data) == target_celltype_str;
end

rowsToKeep = keep_virus & keep_drug & keep_celltype;
filteredTable = biggestTable(rowsToKeep, :);

if height(filteredTable) == 0
    warning('blt:tableANOVA:NoData', 'No data remaining after filtering.');
    p = NaN; tbl = []; stats = [];
    c = []; m = []; gnames = {};
    return;
end

% -----------------------------
% 4) Extract Data for ANOVA
% -----------------------------
y     = filteredTable.(col_data);
group = filteredTable.(col_strain);

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
    c = []; m = []; gnames = {};
    return;
end

y = y(valid_idx);
group = group(valid_idx);

% -----------------------------
% 5) Run One-Way ANOVA (Figure)
% -----------------------------
figure('Name','ANOVA: Peak response by strain');
[p, tbl, stats] = anova1(y, group, 'on');

% Label ANOVA axes
h_anova = gcf;
ax_anova = findobj(h_anova, 'Type', 'axes');
if ~isempty(ax_anova)
    ax_anova = ax_anova(1);
else
    ax_anova = gca;
end

xlabel(ax_anova, 'Strain', 'Interpreter','none');
ylabel(ax_anova, 'Peak firing rate (Hz)', 'Interpreter','none');
title(ax_anova, 'One-way ANOVA: Peak response by strain', 'Interpreter','none');
grid(ax_anova, 'on');
box(ax_anova, 'off');

% Print ANOVA results + interpretation
printAnova1Summary(tbl, p, col_data, col_strain);

% -----------------------------
% 6) Multiple Comparisons (Figure)
% -----------------------------
figure('Name','Multiple comparisons: Peak response by strain');
[c, m, h_mc, gnames] = multcompare(stats, 'display', 'on');

% Label multcompare axes
figure(h_mc); % ensure correct figure is active
ax_mc = findobj(h_mc, 'Type', 'axes');
if ~isempty(ax_mc)
    ax_mc = ax_mc(1);
else
    ax_mc = gca;
end

xlabel(ax_mc, 'Peak firing rate (Hz)', 'Interpreter','none');
ylabel(ax_mc, 'Strain', 'Interpreter','none');
title(ax_mc, sprintf('Multiple comparisons: %s by %s', col_data, col_strain), ...
    'Interpreter','none');
grid(ax_mc, 'on');
box(ax_mc, 'off');

% -----------------------------
% 7) Print multcompare results + interpretation
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
% Helper: Print ANOVA summary + interpretation (anova1)
% ======================================================================
function printAnova1Summary(tbl, p, dataLabel, groupLabel)
fprintf('\nANOVA (one-way) summary: %s by %s\n', dataLabel, groupLabel);

F = NaN; df1 = NaN; df2 = NaN;

try
    df1 = tbl{2,3};   % groups df
    df2 = tbl{3,3};   % error df
    F   = tbl{2,5};   % F statistic
catch
    % Fallback: print p only
end

if ~isnan(F) && ~isnan(df1) && ~isnan(df2)
    fprintf('  F(%d, %d) = %.4f, p = %.4g\n', df1, df2, F, p);
else
    fprintf('  p = %.4g\n', p);
end

alpha = 0.05;
if isnan(p)
    fprintf('  Interpretation: p is NaN (insufficient valid data after filtering).\n\n');
elseif p < alpha
    fprintf('  Interpretation: Significant effect of %s on %s (p < %.2f). At least one group mean differs.\n\n', ...
        groupLabel, dataLabel, alpha);
else
    fprintf('  Interpretation: No significant effect of %s on %s (p >= %.2f). No evidence of differences in group means.\n\n', ...
        groupLabel, dataLabel, alpha);
end
end

% ======================================================================
% Helper: multcompare significant pairs + interpretation sentences
% ======================================================================
function printSignificantPairsAndInterpretation(c, gnames, alpha, dataLabel)
% c columns:
% 1 group1, 2 group2, 3 lower, 4 diff (g1-g2), 5 upper, 6 p-value

fprintf('Multiple comparisons (post hoc) summary:\n');

if isempty(c)
    fprintf('  No multcompare output to report.\n\n');
    return;
end

pcol = 6; dcol = 4; lcol = 3; ucol = 5;
sig = c(:,pcol) < alpha;

if ~any(sig)
    fprintf('  No significant pairwise differences after adjustment (alpha = %.3f).\n', alpha);
    fprintf('  Interpretation: No evidence that any specific pair of group means differs (with multiple-comparisons correction).\n\n');
    return;
end

sigC = c(sig,:);

% Sort by adjusted p-value ascending
[~, ord] = sort(sigC(:,pcol), 'ascend');
sigC = sigC(ord,:);

fprintf('  Significant pairwise differences (alpha = %.3f, adjusted p-values):\n', alpha);

% Print numeric results
for i = 1:size(sigC,1)
    g1 = sigC(i,1);
    g2 = sigC(i,2);

    name1 = string(gnames{g1});
    name2 = string(gnames{g2});

    diffEst = sigC(i,dcol);
    ciLo    = sigC(i,lcol);
    ciHi    = sigC(i,ucol);
    pAdj    = sigC(i,pcol);

    if diffEst > 0
        dirTxt = sprintf('%s > %s', name1, name2);
    elseif diffEst < 0
        dirTxt = sprintf('%s < %s', name1, name2);
    else
        dirTxt = sprintf('%s = %s', name1, name2);
    end

    fprintf('    %s: Δ = %.3f Hz (95%% CI [%.3f, %.3f]), p_adj = %.4g\n', ...
        dirTxt, diffEst, ciLo, ciHi, pAdj);
end

% Interpretation text 
fprintf('\n  Interpretation:\n');
for i = 1:size(sigC,1)
    g1 = sigC(i,1);
    g2 = sigC(i,2);

    name1 = string(gnames{g1});
    name2 = string(gnames{g2});

    diffEst = sigC(i,dcol);
    ciLo    = sigC(i,lcol);
    ciHi    = sigC(i,ucol);
    pAdj    = sigC(i,pcol);

    if diffEst > 0
        higher = name1; lower = name2;
        deltaTxt = sprintf('%.2f', abs(diffEst));
    elseif diffEst < 0
        higher = name2; lower = name1;
        deltaTxt = sprintf('%.2f', abs(diffEst));
    else
        higher = name1; lower = name2;
        deltaTxt = sprintf('%.2f', 0);
    end

    fprintf('    %s exhibited a significantly higher %s than %s (Δ = %s Hz, 95%% CI [%.2f, %.2f], adjusted p = %.4g).\n', ...
        higher, dataLabel, lower, deltaTxt, ciLo, ciHi, pAdj);
end
fprintf('\n');
end
