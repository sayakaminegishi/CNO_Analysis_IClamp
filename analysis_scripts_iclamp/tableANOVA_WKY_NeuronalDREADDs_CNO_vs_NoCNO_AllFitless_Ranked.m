function [P, TBL, STATS] = tableANOVA_WKY_NeuronalDREADDs_CNO_vs_NoCNO_AllFitless_Ranked(biggestTable)
% TABLEANOVA_WKY_NEURONALDREADDS_CNO_VS_NO_CNO_ALLFITLESS_RANKED
% ANOVA on RANKS comparing:
%   WKY Neurons+Glia + Neuronal DREADDs + CNO  vs  WKY Neurons+Glia + Neuronal DREADDs only (No CNO)
%
% Assumptions based on your table structure:
%   - DREADDs presence is encoded by virus_OntologyName being non-empty (i.e., "With Virus")
%   - "Neuronal DREADDs" are samples where the culture includes neurons (Neurons+Glia)
%     (If you have a separate column indicating viral tropism/target cell type, tell me and I’ll swap in that logic.)
%   - "No CNO" means DrugTreatmentMixtureName == ' ' (single-space control label)
%   - "CNO" means DrugTreatmentMixtureName contains "cno" (case-insensitive)

arguments
    biggestTable table
end

% -------------------------------------------------------------------------
% 1) Initialize Outputs
% -------------------------------------------------------------------------
P = struct(); TBL = struct(); STATS = struct();

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

unitsMap = containers.Map(...
    {'interpolated_c50', 'suppressionIndex', 'responseAtReferenceCurrent', ...
     'currentClosestToReferenceCurrent', 'peakResponse', 'currentAtPeakResponse', ...
     'firstNonZeroResponse', 'currentAtFirstNonZeroResponse'}, ...
    {'(pA)', ' ', '(Hz)', '(pA)', '(Hz)', '(pA)', '(Hz)', '(pA)'});

% -------------------------------------------------------------------------
% 3) Apply Global Filters (WKY, Neurons+Glia, WITH DREADDs/Virus)
% -------------------------------------------------------------------------
keep_strain = strcmp(string(biggestTable.(col_strain)), "WKY");

% Neurons+Glia exact encoded string (matches your prior scripts)
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% "Neuronal DREADDs" (operationalized here as: virus present, and culture includes neurons)
% If you have more specific targeting metadata, replace this block.
keep_with_virus = ~is_whitespace_col(biggestTable, col_virus);

rows_base = keep_strain & keep_celltype & keep_with_virus;

% -------------------------------------------------------------------------
% 4) Define Drug Groups (CNO vs No CNO)
% -------------------------------------------------------------------------
drugStr_raw = string(biggestTable.(col_drug));
drugStr = lower(strtrim(drugStr_raw));

is_cno    = contains(drugStr, "cno");
is_nocno  = (drugStr_raw == " ");   % your control label convention

rowsToKeep = rows_base & (is_cno | is_nocno);
filteredTable = biggestTable(rowsToKeep, :);

% Build group labels
drugStr_raw_f = string(filteredTable.(col_drug));
drugStr_f = lower(strtrim(drugStr_raw_f));

group_base = repmat("DREADDs only (No CNO)", height(filteredTable), 1);
group_base(contains(drugStr_f, "cno")) = "DREADDs + CNO";

% -------------------------------------------------------------------------
% 5) Setup Figure (2x3 for 5 plots + 1 info tile)
% -------------------------------------------------------------------------
figure('Name', 'WKY: Neuronal DREADDs + CNO vs DREADDs only (Ranked)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'WKY Neurons+Glia + Neuronal DREADDs: CNO vs No CNO (Rank-transformed ANOVA)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% 6) Loop and Plot
% -------------------------------------------------------------------------
for i = 1:numel(fitless_vars)
    varName = fitless_vars{i};
    shortName = erase(varName, 'FIcalc.fitless.');

    % --- SKIP SPECIFIC GRAPHS ---
    varsToSkip = {'currentClosestToReferenceCurrent', 'firstNonZeroResponse', 'responseAtReferenceCurrent'};
    if ismember(shortName, varsToSkip)
        continue;
    end

    y = filteredTable.(varName);
    if iscell(y); y = cell2mat(y); end

    valid = ~isnan(y);
    y_clean = y(valid);
    g_clean = group_base(valid);

    n_cno   = sum(g_clean == "DREADDs + CNO");
    n_nocno = sum(g_clean == "DREADDs only (No CNO)");
    if n_cno == 0 || n_nocno == 0
        continue;
    end

    % --- RANK TRANSFORMATION ---
    y_ranked = tiedrank(y_clean);

    [p_val, tbl_res, stats_res] = anova1(y_ranked, g_clean, 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;

    % --- ROBUST LABELING WITH n ---
    l_nocno = sprintf('DREADDs only (n=%d)', n_nocno);
    l_cno   = sprintf('DREADDs + CNO (n=%d)', n_cno);

    g_final = strings(size(g_clean));
    g_final(g_clean == "DREADDs only (No CNO)") = l_nocno;
    g_final(g_clean == "DREADDs + CNO") = l_cno;
    g_final = categorical(g_final, {l_nocno, l_cno});

    ax = nexttile;
    boxplot(ax, y_clean, g_final);

    set(ax, 'XTickLabelRotation', 0);
    title(ax, sprintf('p_{rank} = %.4f', p_val));

    unitStr = unitsMap(shortName);
    ylabelStr = shortName;
    if ~isempty(unitStr)
        ylabelStr = sprintf('%s %s', shortName, unitStr);
    end
    ylabel(ax, ylabelStr, 'Interpreter', 'none', 'FontWeight', 'bold');
    grid(ax, 'on');
end

% Info tile (Position 6 in a 2x3 grid)
nexttile(6); axis off;
text(0.05, 0.80, 'Filter:', 'FontWeight', 'bold');
text(0.05, 0.64, 'Strain = WKY', 'Interpreter', 'none');
text(0.05, 0.48, 'CellType = Neurons+Glia', 'Interpreter', 'none');
text(0.05, 0.32, 'Virus present (Neuronal DREADDs assumed)', 'Interpreter', 'none');
text(0.05, 0.16, 'Group: CNO (contains "cno") vs No CNO (Drug == " ")', 'Interpreter', 'none');

end

% ======================================================================
% Helper: whitespace detector
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