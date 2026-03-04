function [P, TBL, STATS, C, M, gnames] = tableANOVA_SHR_CNO_AllFitless(biggestTable)
% TABLEANOVA_SHR_CNO_ALLFITLESS - Consolidated ANOVA for all fitless metrics (SHR Strain)
% 
% Features:
%   - Consolidation: All 8 variables plotted in one tiled window.
%   - Robustness: Initializes all outputs (P, TBL, etc.) to prevent assignment errors.
%   - Diagnostics: Prints row counts for CNO vs Control before running stats.
%   - Labeling: Includes Y-axis titles with units and (n) sample sizes.

arguments
    biggestTable table
end

% -------------------------------------------------------------------------
% 1) Initialize Outputs (Prevents "Output argument not assigned" errors)
% -------------------------------------------------------------------------
P = struct(); TBL = struct(); STATS = struct(); 
C = struct(); M = struct(); gnames = {};

% -------------------------------------------------------------------------
% 2) Define Columns and Metric Metadata
% -------------------------------------------------------------------------
col_virus    = 'virus_OntologyName';
col_celltype = 'Treatment_CultureFromCellTypeOntology';
col_strain   = 'StrainName';
col_drug     = 'DrugTreatmentMixtureName';

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

% Units mapping for Y-axis labels
unitsMap = containers.Map(...
    {'interpolated_c50', 'suppressionIndex', 'responseAtReferenceCurrent', ...
     'currentClosestToReferenceCurrent', 'peakResponse', 'currentAtPeakResponse', ...
     'firstNonZeroResponse', 'currentAtFirstNonZeroResponse'}, ...
    {'(Hz)', '', '(Hz)', '(Hz)', '(Hz)', '(Hz)', '', '(Hz)'});

% -------------------------------------------------------------------------
% 3) Apply Global Filters (SHR, Virus-Present, Specific Cell Types)
% -------------------------------------------------------------------------
% Filter A: Strain must be SHR (Changed from WKY)
keep_strain = strcmp(string(biggestTable.(col_strain)), 'SHR');

% Filter B: Virus MUST be present (Negated whitespace check)
keep_with_virus = ~is_whitespace_col(biggestTable, col_virus);

% Filter C: Specific Cell Types (Neurons and Glia)
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% Filter D: Drug is CNO or Empty (Control)
is_cno = strcmp(string(biggestTable.(col_drug)), 'clozapine N-oxide');
is_empty_drug = is_whitespace_col(biggestTable, col_drug);

% Combine all filters
rowsToKeep = keep_strain & keep_with_virus & keep_celltype & (is_cno | is_empty_drug);
filteredTable = biggestTable(rowsToKeep, :);

% Diagnostic check for group counts
n_cno_total = sum(is_cno(rowsToKeep));
n_ctrl_total = sum(is_empty_drug(rowsToKeep));

fprintf('\n--- Filtering Diagnostics (SHR + Virus + Co-Culture) ---\n');
fprintf('  Total Rows Found for CNO: %d\n', n_cno_total);
fprintf('  Total Rows Found for Control: %d\n', n_ctrl_total);
fprintf('-------------------------------------------------------\n');

if n_cno_total == 0 || n_ctrl_total == 0
    warning('blt:tableANOVA:InsufficientGroups', ...
        'Analysis aborted: One or both groups have 0 samples for SHR after filtering.');
    return; 
end

% Map base groups
raw_drugs = string(filteredTable.(col_drug));
group_base = repmat("Control", size(raw_drugs)); 
group_base(strcmp(raw_drugs, "clozapine N-oxide")) = "CNO";

% -------------------------------------------------------------------------
% 4) Setup Single Window Tiled Layout
% -------------------------------------------------------------------------
figure('Name', 'SHR Fitless Metrics: CNO vs Control (Virus Present)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'ANOVA Comparison: SHR Strain (Virus + Co-Culture Present)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% 5) Loop through Metrics and Plot
% -------------------------------------------------------------------------
for i = 1:numel(fitless_vars)
    varName = fitless_vars{i};
    shortName = erase(varName, 'FIcalc.fitless.');
    
    y = filteredTable.(varName);
    if iscell(y); y = cell2mat(y); end
    
    % Clean NaNs specifically for this variable
    valid = ~isnan(y);
    y_clean = y(valid);
    g_clean = group_base(valid);
    
    % Recalculate group n after NaN removal
    n_ctrl = sum(g_clean == "Control");
    n_cno = sum(g_clean == "CNO");
    
    if n_ctrl == 0 || n_cno == 0
        fprintf('Metric: %-30s | Skipped (n=0 for a group)\n', shortName);
        continue; 
    end
    
    % Run ANOVA
    [p_val, tbl_res, stats_res] = anova1(y_clean, g_clean, 'off');
    
    % Store results in structs
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;
    
    % Labeling
    label_ctrl = sprintf('Control (n=%d)', n_ctrl);
    label_cno  = sprintf('CNO (n=%d)', n_cno);
    g_final = strings(size(g_clean));
    g_final(g_clean == "Control") = label_ctrl;
    g_final(g_clean == "CNO") = label_cno;
    g_final = categorical(g_final, {label_ctrl, label_cno});
    
    % Plot
    ax = nexttile;
    boxplot(ax, y_clean, g_final);
    
    % Titles and Y-Labels
    title(ax, sprintf('p = %.4f', p_val));
    unitStr = unitsMap(shortName);
    ylabelStr = shortName;
    if ~isempty(unitStr); ylabelStr = sprintf('%s %s', shortName, unitStr); end
    ylabel(ax, ylabelStr, 'Interpreter', 'none', 'FontWeight', 'bold');
    grid(ax, 'on');
end

% Add info legend in the 9th tile
infoTile = nexttile(9); axis off;
text(0.05, 0.5, sprintf(['Filter Conditions:\n', ...
    '• Strain: SHR\n', ...
    '• Virus: Present\n', ...
    '• Cells: Neurons & Glia\n', ...
    '• Drug: CNO vs Empty']), ...
    'FontSize', 10, 'FontWeight', 'bold');

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