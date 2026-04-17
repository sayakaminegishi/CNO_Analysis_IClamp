function [stats, g, subTable] = wkyVsShrNeuronsOnly_suppressionIndex(biggestTable)
% WKYVSSHRNEURONSONLY - Comparative analysis of StrainName in neurons-only populations.
%
%   [STATS, G, SUBTABLE] = wkyVsShrNeuronsOnly(BIGGESTTABLE)
%
%   NARRATIVE:
%   This analysis isolates intrinsic physiological differences between
%   WKY and SHR neurons under a standardized control condition.
%   By removing viral treatment, drug treatment, and glia co-culture,
%   this function compares strain differences in neurons-only cultures.
%
%   TRACEABILITY:
%   Beyond the ANOVA, this function utilizes the 'stats.groupRows' lookup
%   table to map statistical groups back to individual trial rows in the
%   returned SUBTABLE. This facilitates deep-dives into individual cell
%   physiology or outlier identification.
%
%   LOGIC:
%   - SELECTS: Records where virus and drug treatments are null/empty.
%   - CONTEXT: Neurons-only cell type (CL:0011103).
%   - ANALYZES: Suppression Index (Dependent) vs. Strain Name (Factor).

    arguments
        biggestTable table
    end

    % 1. Define Population Selection
    Selection = struct();
    Selection.virus_OntologyName = "";
    Selection.DrugTreatmentLocationOntology = "";
    Selection.Treatment_CultureFromCellTypeOntology = "CL:0011103";  % neurons only

    % 2. Define Analysis Variables
    Factors = "StrainName";
    Measurement = "FIcalc.fitless.suppressionIndex";

    % 3. Execution
    [stats, g, subTable] = blt.stats.anovaTool(biggestTable, ...
        Measurement, Selection, Factors, ...
        'FigureTitle', "Analysis: Suppression Index by Strain (Neurons Only Controls)");

    %% 4. Optional: keep only WKY and SHR if other strain labels exist
    if ~isempty(subTable) && ismember("StrainName", string(subTable.Properties.VariableNames))
        keepRows = ismember(string(subTable.StrainName), ["WKY", "SHR"]);
        subTable = subTable(keepRows, :);
    end

    %% 5. Traceability Summary + Sample Size Storage
    % Adds sample sizes and group means into the returned stats struct.

    if isfield(stats, 'groupRows') && ~isempty(stats.groupRows)

        numGroups = height(stats.groupRows);

        % Containers in stats for convenient downstream access
        stats.sampleSize = struct();
        stats.groupMean  = struct();

        fprintf('\n--- Analysis Summary: %s ---\n', Measurement);

        for i = 1:numGroups

            currentStrain = string(stats.groupRows.StrainName(i));
            nSize = stats.groupRows.N(i);
            rowIdx = stats.groupRows.RowIndices{i};

            % Guard against indexing mismatch
            rowIdx = rowIdx(rowIdx <= height(subTable));

            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            safeName = matlab.lang.makeValidName(currentStrain);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            fprintf('Strain: %-12s | N = %3d | Mean = %6.3f\n', ...
                currentStrain, nSize, groupMean);
        end

        fprintf('-----------------------------------------------------\n');
    end
end