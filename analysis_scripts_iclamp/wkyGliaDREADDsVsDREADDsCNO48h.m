function [stats, g, subTable] = wkyGliaDREADDsVsDREADDsCNO48h(biggestTable)
% Compare:
%   1) WKY + neurons/glia + DREADDs
%   2) WKY + neurons/glia + DREADDs + CNO

    arguments
        biggestTable table
    end

    %% 1) WKY only
    subTable = biggestTable;
    subTable = subTable(strcmp(strtrim(string(subTable.StrainName)), "WKY"), :);

    %% 2) Neurons + Glia only
    culture = strtrim(string(subTable.Treatment_CultureFromCellTypeOntology));
    culture(ismissing(culture)) = "";

    isGlia = strcmp(culture, "CL:0011103, CL:0000516");
    subTable = subTable(isGlia, :);

    %% 3) Keep only DREADDs rows (virus present)
    virus = strtrim(string(subTable.virus_OntologyName));
    virus(ismissing(virus)) = "";

    subTable = subTable(virus ~= "", :);

    %% 4) Create treatment groups
    drug = strtrim(string(subTable.DrugTreatmentLocationOntology));
    drug(ismissing(drug)) = "";

    group = strings(height(subTable),1);

    % DREADDs only
    group(drug == "") = "DREADDs";

    % DREADDs + CNO
    isCNO = contains(lower(drug), "cno");
    group(isCNO) = "DREADDs_CNO";

    %% 5) Keep only those two groups
    keep = (group == "DREADDs") | (group == "DREADDs_CNO");
    subTable = subTable(keep,:);
    group = group(keep);

    if isempty(subTable)
        error("No rows matched DREADDs vs DREADDs+CNO.");
    end

    %% 6) Add grouping variable
    subTable.Group = categorical(group, ...
        ["DREADDs","DREADDs_CNO"], 'Ordinal', true);

    %% 7) Run ANOVA
    Measurement = 'FIcalc.fitless.peakResponse';
    Factors     = 'Group';

    [stats, g, subTable] = blt.stats.anovaTool(subTable, ...
        Measurement, struct(), Factors, ...
        'FigureTitle', 'WKY Neurons+Glia+DREADDs vs +CNO');

end