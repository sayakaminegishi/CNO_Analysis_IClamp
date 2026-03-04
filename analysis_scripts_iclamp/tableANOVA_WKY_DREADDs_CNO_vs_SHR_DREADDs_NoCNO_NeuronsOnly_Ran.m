function [P, TBL, STATS] = tableANOVA_WKY_DREADDs_CNO_vs_SHR_DREADDs_NoCNO_NeuronsOnly_Ran(biggestTable)
% TABLEANOVA_WKY_DREADDs_CNO_VS_SHR_DREADDs_NO_CNO_NEURONSONLY_ALLFITLESS_RANKED
% ANOVA on RANKS comparing two SPECIFIC groups:
%   Group A: WKY + Neurons ONLY + Neuronal DREADDs (virus present) + CNO
%   Group B: SHR + Neurons ONLY + Neuronal DREADDs (virus present) + NO CNO (DrugTreatmen
% tMixtureName == ' ')
%
% Notes:
%   - "Neurons ONLY" implemented as: contains CL:0011103 AND NOT CL:0000516
%   - "Neuronal DREADDs" operationalized as virus_OntologyName non-empty/whitespace
%   - "CNO" implemented as DrugTreatmentMixtureName contains "cno" (case-insensitive)
%   - "No CNO" implemented as DrugTreatmentMixtureName == " " (single-space control label)

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
% 3) Base Filters: Neurons ONLY + Virus Present + Drug parsing
% -------------------------------------------------------------------------
strainVals = string(biggestTable.(col_strain));

% Neurons ONLY (no glia), robust to combined ontology strings
cellTypeStr = string(biggestTable.(col_celltype));
has_neuron = contains(cellTypeStr, "CL:0011103");
has_glia   = contains(cellTypeStr, "CL:0000516");
keep_neuron_only = has_neuron & ~has_glia;

% DREADDs present (virus present)
keep_with_virus = ~is_whitespace_col(biggestTable, col_virus);

% Drug parsing
drugRaw = string(biggestTable.(col_drug));
drugNorm = lower(strtrim(drugRaw));
is_cno   = contains(drugNorm, "cno");
is_nocno = (drugRaw == " ");   % single-space control label

% -------------------------------------------------------------------------
% 4) Define the TWO groups explicitly
% -------------------------------------------------------------------------
is_groupA = (strainVals == "WKY") & keep_neuron_only & keep_with_virus & is_cno;
is_groupB = (strainVals == "SHR") & keep_neuron_only & keep_with_virus & is_nocno;

rowsToKeep = is_groupA | is_groupB;
filteredTable = biggestTable(rowsToKeep, :);

group_base = repmat("UNASSIGNED", height(filteredTable), 1);
strainVals_f = string(filteredTable.(col_strain));
drugRaw_f = string(filteredTable.(col_drug));
drugNorm_f = lower(strtrim(drugRaw_f));

% Recompute group membership on the filtered table for safety
cellTypeStr_f = string(filteredTable.(col_celltype));
has_neuron_f = contains(cellTypeStr_f, "CL:0011103");
has_glia_f   = contains(cellTypeStr_f, "CL:0000516");
keep_neuron_only_f = has_neuron_f & ~has_glia_f;

keep_with_virus_f = ~is_whitespace_col(filteredTable, col_virus);

is_cno_f   = contains(drugNorm_f, "cno");
is_nocno_f = (drugRaw_f == " ");

idxA = (strainVals_f == "WKY") & keep_neuron_only_f & keep_with_virus_f & is_cno_f;
idxB = (strainVals_f == "SHR") & keep_neuron_only_f & keep_with_virus_f & is_nocno_f;

group_base(idxA) = "WKY + DREADDs + CNO";
group_base(idxB) = "SHR + DREADDs only (No CNO)";

% Keep only labeled rows (just in case)
keep_labeled = group_base ~= "UNASSIGNED";
filteredTable = filteredTable(keep_labeled, :);
group_base = group_base(keep_labeled);

% -------------------------------------------------------------------------
% 5) Setup Figure (2x3 for 5 plots + 1 info tile)
% -------------------------------------------------------------------------
figure('Name', 'WKY DREADDs+CNO vs SHR DREADDs only (Ranked)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Comparison: WKY + DREADDs + CNO vs SHR + DREADDs only (Neurons only; Rank-transformed ANOVA)', ...
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

    n_A = sum(g_clean == "WKY + DREADDs + CNO");
    n_B = sum(g_clean == "SHR + DREADDs only (No CNO)");
    if n_A == 0 || n_B == 0
        continue;
    end

    % --- RANK TRANSFORMATION ---
    y_ranked = tiedrank(y_clean);

    [p_val, tbl_res, stats_res] = anova1(y_ranked, g_clean, 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;

    % --- LABELING WITH n ---
    lA = sprintf('WKY + DREADDs + CNO (n=%d)', n_A);
    lB = sprintf('SHR + DREADDs only (n=%d)', n_B);

    g_final = strings(size(g_clean));
    g_final(g_clean == "WKY + DREADDs + CNO") = lA;
    g_final(g_clean == "SHR + DREADDs only (No CNO)") = lB;
    g_final = categorical(g_final, {lA, lB});

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

% Info tile (Position 6)
nexttile(6); axis off;
text(0.05, 0.82, 'Groups:', 'FontWeight', 'bold');
text(0.05, 0.66, 'A) WKY + Neurons only + Virus(DREADDs) + CNO', 'Interpreter', 'none');
text(0.05, 0.50, 'B) SHR + Neurons only + Virus(DREADDs) + No CNO (Drug == " ")', 'Interpreter', 'none');
text(0.05, 0.30, 'Neuron-only filter: contains CL:0011103 AND NOT CL:0000516', 'Interpreter', 'none');
text(0.05, 0.14, 'CNO filter: Drug contains "cno"', 'Interpreter', 'none');

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