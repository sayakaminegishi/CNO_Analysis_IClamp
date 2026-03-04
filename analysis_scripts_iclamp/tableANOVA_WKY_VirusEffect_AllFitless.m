function [P, TBL, STATS] = tableANOVA_WKY_VirusEffect_AllFitless(biggestTable)
% TABLEANOVA_WKY_VIRUSEFFECT_FIXEDLABELS - ANOVA comparing Virus vs No Virus
% Filter: Strain=WKY, CellType=Neurons+Glia.
% Comparison: Virus Present vs Virus Absent.

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
    {'(Hz)', '', '(Hz)', '(Hz)', '(Hz)', '(Hz)', '', '(Hz)'});

% -------------------------------------------------------------------------
% 3) Apply Global Filters
% -------------------------------------------------------------------------
keep_strain = strcmp(string(biggestTable.(col_strain)), 'WKY');
target_celltype_str = 'CL:0011103, CL:0000516';
keep_celltype = strcmp(string(biggestTable.(col_celltype)), target_celltype_str);
is_control_only = is_whitespace_col(biggestTable, col_drug);

rowsToKeep = keep_strain & keep_celltype & is_control_only;
filteredTable = biggestTable(rowsToKeep, :);

% -------------------------------------------------------------------------
% 4) Define Groups (Virus Presence)
% -------------------------------------------------------------------------
is_virus_present = ~is_whitespace_col(filteredTable, col_virus);
group_base = repmat("No Virus", size(is_virus_present));
group_base(is_virus_present) = "With Virus";

% -------------------------------------------------------------------------
% 5) Setup Figure
% -------------------------------------------------------------------------
figure('Name', 'WKY: Virus Presence Comparison', ...
       'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.85]);
t = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(t, 'Effect of Virus: WKY Neurons + Glia (Control Drug only)', ...
      'FontSize', 14, 'FontWeight', 'bold');

% -------------------------------------------------------------------------
% 6) Loop and Plot
% -------------------------------------------------------------------------
for i = 1:numel(fitless_vars)
    varName = fitless_vars{i};
    shortName = erase(varName, 'FIcalc.fitless.');
    
    y = filteredTable.(varName);
    if iscell(y); y = cell2mat(y); end
    
    valid = ~isnan(y);
    y_clean = y(valid);
    g_clean = group_base(valid);
    
    n_v_pos = sum(g_clean == "With Virus");
    n_v_neg = sum(g_clean == "No Virus");
    
    if n_v_pos == 0 || n_v_neg == 0, continue; end
    
    [p_val, tbl_res, stats_res] = anova1(y_clean, g_clean, 'off');
    P.(shortName) = p_val;
    TBL.(shortName) = tbl_res;
    STATS.(shortName) = stats_res;
    
    % --- ROBUST LABELING (Single Line) ---
    l_neg = sprintf('No Virus (n=%d)', n_v_neg);
    l_pos = sprintf('With Virus (n=%d)', n_v_pos);
    
    g_final = strings(size(g_clean));
    g_final(g_clean == "No Virus") = l_neg;
    g_final(g_clean == "With Virus") = l_pos;
    g_final = categorical(g_final, {l_neg, l_pos});
    
    ax = nexttile;
    boxplot(ax, y_clean, g_final);
    
    % Force horizontal labels and clean formatting
    set(ax, 'XTickLabelRotation', 0); 
    title(ax, sprintf('p = %.4f', p_val));
    
    unitStr = unitsMap(shortName);
    ylabelStr = shortName;
    if ~isempty(unitStr); ylabelStr = sprintf('%s %s', shortName, unitStr); end
    ylabel(ax, ylabelStr, 'Interpreter', 'none', 'FontWeight', 'bold');
    grid(ax, 'on');
end

% Info tile
nexttile(9); axis off;
text(0.05, 0.5, 'Filter: WKY, Neurons+Glia, Control Only', 'FontWeight', 'bold');

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