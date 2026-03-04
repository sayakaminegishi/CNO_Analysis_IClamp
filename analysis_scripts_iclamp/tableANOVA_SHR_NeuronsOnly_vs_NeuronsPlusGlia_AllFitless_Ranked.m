function [P, TBL, STATS] = tableANOVA_SHR_NeuronsOnly_vs_NeuronsPlusGlia_AllFitless_Ranked(biggestTable)
% TABLEANOVA_SHR_NEURONSONLY_VS_NEURONSPLUSGLIA_ALLFITLESS_RANKED
% ANOVA on RANKS comparing (within SHR only):
%   Group A: SHR Neurons ONLY
%   Group B: SHR Neurons + Glia
%
% Filters (kept consistent with your conventions):
%   - StrainName == 'SHR'
%   - NO DREADDs / NO VIRUS: virus_OntologyName empty/whitespace
%   - NO CNO / control only: DrugTreatmentMixtureName == ' ' (single-space label)
%
% Cell type logic:
%   - Neurons ONLY: contains CL:0011103 AND NOT CL:0000516
%   - Neurons+Glia: contains CL:0011103 AND contains CL:0000516
% (Robust to composite strings like "CL:0011103, CL:0000516".)

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
% 3) Apply Global Filters (SHR, No Virus, No CNO)
% -------------------------------------------------------------------------
keep_strain = strcmp(string(biggestTable.(col_strain)), "SHR");

% No DREADDs / No Virus
keep_no_virus = is_whitespace_col(biggestTable, col_virus);

% No CNO (control label exactly ' ')
keep_control_only = string(biggestTable.(col_drug)) == " ";

% Cell type parsing (robust)
cellTypeStr = string(biggestTable.(col_celltype));
has_neuron = contains(cellTypeStr, "CL:0011103");
has_glia   = contains(cellTypeStr, "CL:0000516");

keep_neurons_only     = has_neuron & ~has_glia;
keep_neurons_plusglia = has_neuron &  has_glia;

% Keep only rows in either group
rowsToKeep = keep_strain & keep_no_virus & keep_control_only & (keep_neurons_only | keep_neurons_plusglia);
filteredTable = biggestTable(rowsToKeep, :);

% -------------------------------------------------------------------------
% 4) Define Groups (Neurons only vs Neurons+Glia)
% -------------------------------------------------------------------------
cellTypeF = string(filteredTable.(col_celltype));
has_neuronF = contains(cellTypeF, "CL:0011103");
has_gliaF   = contains(cellTypeF, "CL:0000516");

group_base = repmat("UNASSIGNED", height(filteredTable), 1);
group_base(has_neuronF & ~has_gliaF) = "SHR Neurons only";
group_base(has_neuronF &  has_gliaF) = "SHR Neurons + Glia";

% Failsafe: keep only labeled rows
keep_labeled = group_base ~= "UNASSIGNED";
filteredTable = filteredTable(keep_labeled, :);
group_base = group_base(keep_labeled);

% -------------------------------------------------------------------------
% 5) Setup Figure (2x3 for 5 plots + 1 info tile)
% -------------------------------------------------------------------------
figure('Name', 'SHR: Neurons only vs Neurons+Glia (Ranked)', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'SHR: Neurons only vs Neurons + Glia (No Virus/DREADDs; No CNO; Rank-transformed ANOVA)', ...
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

    n_neur = sum(g_clean == "SHR Neurons only");
    n_ng   = sum(g_clean == "SHR Neurons + Glia");
    if n_neur == 0 || n_ng == 0
        continue;
    end

    % --- RANK TRANSFORMATION ---
    y_ranked = tiedrank(y_clean);

    [p_val, tbl_res, stats_res] = anova1(y_ranked, g_clean, 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;

    % --- Labeling with n ---
    l_neur = sprintf('SHR Neurons only (n=%d)', n_neur);
    l_ng   = sprintf('SHR Neurons+Glia (n=%d)', n_ng);

    g_final = strings(size(g_clean));
    g_final(g_clean == "SHR Neurons only") = l_neur;
    g_final(g_clean == "SHR Neurons + Glia") = l_ng;
    g_final = categorical(g_final, {l_neur, l_ng});

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
text(0.05, 0.82, 'Filter:', 'FontWeight', 'bold');
text(0.05, 0.66, 'Strain = SHR', 'Interpreter', 'none');
text(0.05, 0.50, 'No Virus/DREADDs (virus_OntologyName empty)', 'Interpreter', 'none');
text(0.05, 0.34, 'No CNO (DrugTreatmentMixtureName == '' '')', 'Interpreter', 'none');
text(0.05, 0.18, 'Groups: Neurons only vs Neurons+Glia', 'Interpreter', 'none');

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