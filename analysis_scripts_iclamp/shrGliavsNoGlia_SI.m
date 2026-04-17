function [stats, g, subTable] = shrGliavsNoGlia_SI(biggestTable)
% shrGLIAVSNOGLIA - Compare shr neurons with vs without glia (controls only).

    arguments
        biggestTable table
    end

    %% 1) Selection (controls + shr only)
    subTable = biggestTable;

    % Controls: no virus, no drug
    subTable = subTable( strip(string(subTable.virus_OntologyName)) == "", :);
    subTable = subTable( strip(string(subTable.DrugTreatmentLocationOntology)) == "", :);

    % shr only
    subTable = subTable( strip(string(subTable.StrainName)) == "SHR", :);

    if isempty(subTable)
        error("shrGliavsNoGlia:EmptySubset", "Selection criteria matched zero rows.");
    end

    %% 2) Create readable culture condition labels
    culture = strip(string(subTable.Treatment_CultureFromCellTypeOntology));
    culture(ismissing(culture)) = "";

    % Map ontology -> readable labels
    culture(culture == "CL:0011103") = "Neurons-only";
    culture(culture == "CL:0011103, CL:0000516") = "Neurons-Glia";

    % Keep only the two groups we care about
    keep = (culture == "Neurons-only") | (culture == "Neurons-Glia");
    subTable = subTable(keep, :);

    if isempty(subTable)
        error("shrGliavsNoGlia:NoCultureGroups", ...
            "No rows matched Neurons-only or Neurons-Glia after mapping.");
    end

    % Add as factor column for ANOVA/plotting
    subTable.CultureCondition = categorical(culture(keep), ...
        ["Neurons-only","Neurons-Glia"], 'Ordinal', true);

    %% 3) ANOVA setup
    Measurement = "FIcalc.fitless.suppressionIndex";
    Factors     = "CultureCondition";

    % Run ANOVA on the already-filtered subTable (Selection is empty now)
    [stats, g, subTable] = blt.stats.anovaTool(subTable, ...
        Measurement, struct(), Factors, ...
        'FigureTitle', "Suppression Index for shr Neurons: ± Glia (Controls)");

    %% 4) Traceability Summary + Sample Size Storage
    if ~isempty(stats.groupRows)

        stats.sampleSize = struct();
        stats.groupMean  = struct();

        fprintf('\n--- Analysis Summary: %s ---\n', Measurement);

        for i = 1:height(stats.groupRows)

            currentGroup = string(stats.groupRows.CultureCondition(i));
            nSize = stats.groupRows.N(i);
            rowIdx = stats.groupRows.RowIndices{i};

            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            safeName = matlab.lang.makeValidName(currentGroup);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            fprintf('Group: %-14s | N = %3d | Mean = %6.2f\n', ...
                currentGroup, nSize, groupMean);
        end

        fprintf('-----------------------------------------------------\n');
    end
end