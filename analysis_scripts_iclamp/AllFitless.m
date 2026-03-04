function [P, TBL, STATS, C, M, gnames] = tableANOVA_WKY_CNO_AllFitless(biggestTable)
% TABLEANOVA_WKY_CNO_ALLFITLESS - Runs ANOVA for all fitless metrics
% Filters: WKY Strain, Virus Present, Specific Cell Type.
% Comparison: CNO vs Control (Empty Drug).

arguments
    biggestTable table
end

% -----------------------------
% 1) Define Columns
% -----------------------------
col_virus    = 'virus_OntologyName';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName';
col_drug     = 'DrugTreatmentMixtureName';

% List of all fitless variables to analyze
fitless_vars = { ...
    'FIcalc.fitless.interpolated_c50', ...
    'FIcalc.fitless.suppressionIndex', ...
    'FIcalc.fitless.responseAtReferenceCurrent', ...
    'FIcalc.fitless.currentClosestToReferenceCurrent', ...
    'FIcalc.fitless.peakResponse', ...
    'FIcalc.fitless.currentAtPeakResponse', ...
    'FIcalc.fitless.firstNonZeroResponse', ...
    'FIcalc.fitless.currentAtFirstNonZeroResponse' ...
};

% -----------------------------
% 2) Apply Global Filters
% -----------------------------
% Strain must be WKY
keep_strain = strcmp(string(biggestTable.(col_strain)), 'WKY');

% Virus MUST be present
keep_with_virus = ~is_whitespace_col(biggestTable, col_virus);

% Specific Cell Types
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% Drug is CNO or Empty
is_cno = strcmp(string(biggestTable.(col_drug)), 'clozapine N-oxide');
is_empty_drug = is_whitespace_col(biggestTable, col_drug);

% Combine filters
rowsToKeep = keep_strain & keep_with_virus & keep_celltype & (is_cno | is_empty_drug);
filteredTable = biggestTable(rowsToKeep, :);

% Check if we have both groups
n_cno = sum(is_cno(rowsToKeep));
n_control = sum(is_empty_drug(rowsToKeep));

fprintf('--- Filtering Diagnostics (WKY + Virus + Co-Culture) ---\n');
fprintf('  Rows found for CNO: %d\n', n_cno);
fprintf('  Rows found for Control: %d\n', n_control);
fprintf('-------------------------------------------------------\n');

if n_cno == 0 || n_control == 0
    warning('Insufficient data for comparison.');
    P = []; TBL = []; STATS = []; C = []; M = []; gnames = {};
    return;
end

% Prepare group labels
raw_groups = string(filteredTable.(col_drug));
group = repmat("Control + Virus", size(raw_groups)); 
group(strcmp(raw_groups, "clozapine N-oxide")) = "CNO + Virus";

% -----------------------------
% 3) Loop over all Variables
% -----------------------------
for i = 1:numel(fitless_vars)
    varName = fitless_vars{i};
    shortName = erase(varName, 'FIcalc.fitless.'); % For clean labels
    
    % Extract numeric data
    y = filteredTable.(varName);
    if iscell(y); y = cell2mat(y); end
    
    % Remove NaNs for this specific variable
    valid = ~isnan(y);
    y_clean = y(valid);
    g_clean = group(valid);
    
    % Only proceed if both groups still have data after NaN removal
    if numel(unique(g_clean)) < 2
        fprintf('Skipping %s: One or more groups contain only NaNs.\n', shortName);
        continue;
    end
    
    % Run ANOVA
    figTitle = sprintf('ANOVA: %s (WKY + Virus)', shortName);
    figure('Name', figTitle);
    [p_val, tbl_res, stats_res] = anova1(y_clean, g_clean, 'on');
    
    % Store in output structs
    P.(shortName)     = p_val;
    TBL.(shortName)   = tbl_res;
    STATS.(shortName) = stats_res;
    
    % Label Axes
    ylabel(gca, shortName, 'Interpreter', 'none');
    title(gca, sprintf('WKY CNO Effect: %s', shortName));
    
    % Print Summary
    printAnova1Summary(tbl_res, p_val, shortName, 'CNO vs Control');
    
    % Multiple Comparisons (if significant)
    if p_val < 0.05
        figure('Name', sprintf('Post-hoc: %s', shortName));
        [c_res, m_res, ~, g_names] = multcompare(stats_res, 'display', 'on');
        C.(shortName) = c_res;
        M.(shortName) = m_res;
        gnames = g_names; % Group names are likely the same for all
    else
        C.(shortName) = [];
        M.(shortName) = [];
    end
end

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
    else
        is_ws = arrayfun(@isempty, data);
    end
    is_ws = is_ws(:);
end

% ======================================================================
% Helper: Print ANOVA summary
% ======================================================================
function printAnova1Summary(tbl, p, dataLabel, groupLabel)
    fprintf('\nANOVA: %s by %s\n', dataLabel, groupLabel);
    try
        fprintf('  F(%d, %d) = %.4f, p = %.4g\n', tbl{2,3}, tbl{3,3}, tbl{2,5}, p);
    catch
        fprintf('  p = %.4g\n', p);
    end
end