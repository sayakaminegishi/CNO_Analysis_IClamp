function [P, TBL, STATS] = tableANOVA_SHR_CNO_DREADDS_AllFitless_Ranked(biggestTable)
% TABLEANOVA_SHR_VIRUSEFFECT_ALLFITLESS_RANKED
% ANOVA on RANKS comparing Virus vs No Virus
% Filter: Strain=SHR, CellType=Neurons+Glia.
% NOW MODIFIED TO: **CONTAINS CNO** (only include rows whose DrugTreatmentMixtureName mentions CNO)

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
% 3) Apply Global Filters
% -------------------------------------------------------------------------
keep_strain = strcmp(string(biggestTable.(col_strain)), "SHR");

target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% ONLY keep rows that CONTAIN CNO in DrugTreatmentMixtureName (robust)
drugStr = lower(strtrim(string(biggestTable.(col_drug))));
keep_cno_only = contains(drugStr, "cno");

rowsToKeep = keep_strain & keep_celltype & keep_cno_only;
filteredTable = biggestTable(rowsToKeep, :);

% -------------------------------------------------------------------------
% 4) Define Groups (Virus Presence)
% -------------------------------------------------------------------------
is_virus_present = ~is_whitespace_col(filteredTable, col_virus);
group_base = repmat("No Virus", size(is_virus_present));
group_base(is_virus_present) = "With Virus";

% -------------------------------------------------------------------------
% 5) Setup Figure (Adjusted to 2x3 for 5 plots + 1 info tile)
% -------------------------------------------------------------------------
figure('Name', 'SHR: Virus Presence Comparison (Ranked, CNO Only)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'SHR Neurons + Glia, CNO Only: Virus vs No Virus (Rank-transformed ANOVA)', ...
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

    n_v_pos = sum(g_clean == "With Virus");
    n_v_neg = sum(g_clean == "No Virus");
    if n_v_pos == 0 || n_v_neg == 0
        continue;
    end

    % --- RANK TRANSFORMATION ---
    y_ranked = tiedrank(y_clean);

    [p_val, tbl_res, stats_res] = anova1(y_ranked, g_clean, 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;

    % --- ROBUST LABELING ---
    l_neg = sprintf('No Virus (n=%d)', n_v_neg);
    l_pos = sprintf('With Virus (n=%d)', n_v_pos);

    g_final = strings(size(g_clean));
    g_final(g_clean == "No Virus") = l_neg;
    g_final(g_clean == "With Virus") = l_pos;
    g_final = categorical(g_final, {l_neg, l_pos});

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
text(0.05, 0.62, 'Filter:', 'FontWeight', 'bold');
text(0.05, 0.48, 'Strain = SHR', 'Interpreter', 'none');
text(0.05, 0.34, 'CellType = Neurons+Glia', 'Interpreter', 'none');
text(0.05, 0.20, 'DrugTreatmentMixtureName contains "CNO"', 'Interpreter', 'none');

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