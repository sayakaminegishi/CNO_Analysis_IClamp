function [P, TBL, STATS] = tableANOVA_strainEffect_AllFitless_Ranked(biggestTable)
% TABLEANOVA_STRAINEFFECT_ALLFITLESS_RANKED
% ANOVA on RANKS explicitly comparing WKY vs SHR ONLY WITH GLIA CO-CULTURE.
%
% Filters (as requested):
%   1) StrainName is exactly 'WKY' or 'SHR'
%   2) CellTypeOntology matches Neurons+Glia 
%   3) NO DREADDs / NO VIRUS: virus_OntologyName must be empty/whitespace
%   4) NO CNO: DrugTreatmentMixtureName must be exactly ' ' (single-space control label)
%              AND explicitly must NOT contain 'cno' (extra safety)

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
% 3) Apply Global Filters (EXPLICIT WKY vs SHR, NO VIRUS, NO CNO)
% -------------------------------------------------------------------------
strainVals  = string(biggestTable.(col_strain));
keep_strain = (strainVals == "WKY") | (strainVals == "SHR");

target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);

% NO DREADDs / NO VIRUS
keep_no_virus = is_whitespace_col(biggestTable, col_virus);

% NO CNO (your control encoding is exactly one space ' ')
keep_control_label = string(biggestTable.(col_drug)) == " ";

% Extra safety: even if something weird slips through, exclude any 'cno'
drugStr = lower(strtrim(string(biggestTable.(col_drug))));
keep_no_cno = ~contains(drugStr, "cno");

rowsToKeep = keep_strain & keep_celltype & keep_no_virus & keep_control_label & keep_no_cno;
filteredTable = biggestTable(rowsToKeep, :);

% -------------------------------------------------------------------------
% 4) Define Groups (Strain: WKY vs SHR ONLY)
% -------------------------------------------------------------------------
group_base = string(filteredTable.(col_strain));
group_base(~(group_base == "WKY" | group_base == "SHR")) = missing; % safety

% -------------------------------------------------------------------------
% 5) Setup Figure
% -------------------------------------------------------------------------
figure('Name', 'Strain Effect: WKY vs SHR (Ranked, No Virus, No CNO)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Strain Effect: WKY vs SHR (No Virus/DREADDs; No CNO; Rank-transformed ANOVA)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% 6) Loop and Plot
% -------------------------------------------------------------------------
for i = 1:numel(fitless_vars)
    varName = fitless_vars{i};
    shortName = erase(varName, 'FIcalc.fitless.');

    % --- SKIP SPECIFIC GRAPHS ---
    % Removed: currentClosestToReferenceCurrent, firstNonZeroResponse, responseAtReferenceCurrent
    varsToSkip = {'currentClosestToReferenceCurrent', 'firstNonZeroResponse', 'responseAtReferenceCurrent'};
    if ismember(shortName, varsToSkip)
        continue;
    end

    y = filteredTable.(varName);
    if iscell(y); y = cell2mat(y); end

    valid = ~isnan(y) & ~ismissing(group_base);
    y_clean = y(valid);
    g_clean = group_base(valid);

    n_wky = sum(g_clean == "WKY");
    n_shr = sum(g_clean == "SHR");
    if n_wky == 0 || n_shr == 0
        continue;
    end

    % --- RANK TRANSFORMATION (Non-parametric equivalent) ---
    y_ranked = tiedrank(y_clean);

    [p_val, tbl_res, stats_res] = anova1(y_ranked, categorical(g_clean, ["WKY","SHR"]), 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;

    % --- LABELING WITH n ---
    l_wky = sprintf('WKY (n=%d)', n_wky);
    l_shr = sprintf('SHR (n=%d)', n_shr);

    g_final = strings(size(g_clean));
    g_final(g_clean == "WKY") = l_wky;
    g_final(g_clean == "SHR") = l_shr;
    g_final = categorical(g_final, {l_wky, l_shr});

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
text(0.05, 0.78, "Filter:", 'FontWeight', 'bold');
text(0.05, 0.62, "StrainName in {WKY, SHR}", 'Interpreter', 'none');
text(0.05, 0.46, "CellTypeOntology = Neurons+Glia", 'Interpreter', 'none');
text(0.05, 0.30, "Virus excluded (No DREADDs / No Virus)", 'Interpreter', 'none');
text(0.05, 0.14, "DrugTreatmentMixtureName == ' ' and not CNO", 'Interpreter', 'none');

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