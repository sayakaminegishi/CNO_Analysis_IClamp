function [stats, g, subTable] = wkyVsShrNeuronsOnly_currentAtFirstNonZeroResponse(biggestTable)
% WKYVSSHRNEURONSONLY_CURRENTATFIRSTNONZERORESPONSE
% Comparative analysis of WKY vs SHR in neurons-only cultures.
%
%   [STATS, G, SUBTABLE] = ...
%       wkyVsShrNeuronsOnly_currentAtFirstNonZeroResponse(BIGGESTTABLE)
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
%   - ANALYZES: currentAtFirstNonZeroResponse vs. Strain Name.
%
%   DEPENDENT VARIABLE:
%   FIcalc.fitless.currentAtFirstNonZeroResponse

    arguments
        biggestTable table
    end

    %% 1. Define Population Selection
    Selection = struct();
    Selection.virus_OntologyName = "";
    Selection.DrugTreatmentLocationOntology = "";
    Selection.Treatment_CultureFromCellTypeOntology = "CL:0011103";   % neurons only

    %% 2. Define Analysis Variables
    Factors = "StrainName";
    Measurement = "FIcalc.fitless.currentAtFirstNonZeroResponse";

    %% 3. Execution
    [stats, g, subTable] = blt.stats.anovaTool(biggestTable, ...
        Measurement, Selection, Factors, ...
        'FigureTitle', "Analysis: Current at First Non-Zero Response by Strain (Neurons Only Controls)");

    %% 4. Optional: restrict subTable to WKY and SHR only
    if ~isempty(subTable) && ismember("StrainName", string(subTable.Properties.VariableNames))
        keepRows = ismember(string(subTable.StrainName), ["WKY", "SHR"]);
        subTable = subTable(keepRows, :);
    end

    %% 5. Traceability Summary + Sample Size Storage
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

            % Guard against invalid row indices after subTable restriction
            rowIdx = rowIdx(rowIdx <= height(subTable));

            % Calculate group-specific mean
            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            % Store inside stats using valid field names
            safeName = matlab.lang.makeValidName(currentStrain);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            % Print summary
            fprintf('Strain: %-12s | N = %3d | Mean = %8.3f\n', ...
                currentStrain, nSize, groupMean);
        end

        fprintf('---------------------------------------------------------------\n');
    end
end