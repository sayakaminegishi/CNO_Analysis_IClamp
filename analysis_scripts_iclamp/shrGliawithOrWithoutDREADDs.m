function [stats, g, subTable] = shrGliaVsDREADDs(biggestTable)
% SHRGLIAVSDREADDS - Compare SHR neurons+glia without vs with DREADDs.
%
% Groups compared:
%   1) SHR + Neurons-Glia + no virus + no drug
%   2) SHR + Neurons-Glia + virus present + no drug
%
% Measurement:
%   FIcalc.fitless.peakResponse

    arguments
        biggestTable table
    end

    %% 1) Start with full table
    subTable = biggestTable;

    % SHR only
    subTable = subTable(strip(string(subTable.StrainName)) == "SHR", :);

    % No drug only
    drug = strip(string(subTable.DrugTreatmentLocationOntology));
    drug(ismissing(drug)) = "";
    subTable = subTable(drug == "", :);

    if isempty(subTable)
        error("shrGliaVsDREADDs:EmptySubset", ...
            "No SHR + no-drug rows found.");
    end

    %% 2) Keep only neurons+glia culture condition
    culture = strip(string(subTable.Treatment_CultureFromCellTypeOntology));
    culture(ismissing(culture)) = "";

    % Keep only neurons + glia
    keepCulture = culture == "CL:0011103, CL:0000516";
    subTable = subTable(keepCulture, :);
    culture = culture(keepCulture);

    if isempty(subTable)
        error("shrGliaVsDREADDs:NoGliaGroup", ...
            "No SHR neurons+glia rows found.");
    end

    %% 3) Create DREADDs grouping variable from virus column
    virus = strip(string(subTable.virus_OntologyName));
    virus(ismissing(virus)) = "";

    % No virus = Control
    % Any non-empty virus entry = DREADDs
    dreadsGroup = strings(height(subTable), 1);
    dreadsGroup(virus == "") = "No DREADDs";
    dreadsGroup(virus ~= "") = "DREADDs";

    % Keep only those two groups explicitly
    keep = (dreadsGroup == "No DREADDs") | (dreadsGroup == "DREADDs");
    subTable = subTable(keep, :);
    dreadsGroup = dreadsGroup(keep);

    if isempty(subTable)
        error("shrGliaVsDREADDs:NoComparisonGroups", ...
            "No rows matched No DREADDs or DREADDs groups.");
    end

    % Add factor column for ANOVA/plotting
    subTable.DREADDsCondition = categorical(dreadsGroup, ...
        ["No DREADDs", "DREADDs"], 'Ordinal', true);

    %% 4) ANOVA setup
    Measurement = "FIcalc.fitless.peakResponse";
    Factors     = "DREADDsCondition";

    [stats, g, subTable] = blt.stats.anovaTool(subTable, ...
        Measurement, struct(), Factors, ...
        'FigureTitle', "Peak Response in SHR Neurons+Glia: No DREADDs vs DREADDs");

    %% 5) Traceability Summary + Sample Size Storage
    if isfield(stats, 'groupRows') && ~isempty(stats.groupRows)

        stats.sampleSize = struct();
        stats.groupMean  = struct();

        fprintf('\n--- Analysis Summary: %s ---\n', Measurement);

        for i = 1:height(stats.groupRows)

            currentGroup = string(stats.groupRows.DREADDsCondition(i));
            nSize = stats.groupRows.N(i);
            rowIdx = stats.groupRows.RowIndices{i};

            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            safeName = matlab.lang.makeValidName(currentGroup);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            fprintf('Group: %-12s | N = %3d | Mean = %6.2f\n', ...
                currentGroup, nSize, groupMean);
        end

        fprintf('-----------------------------------------------------\n');
    end
end