function [stats, g, subTable] = virusDrugStrain(biggestTable)
% VIRUSDRUGSTRAIN - Comparative analysis of StrainName in Co-Culture populations.
%
%   [STATS, G, SUBTABLE] = blt.analyses.virusDrugStrain(BIGGESTTABLE)
%
%   NARRATIVE:
%   This analysis isolates the intrinsic physiological differences between
%   genetic strains by filtering for a standardized "control" state. By
%   removing viral and pharmacological variables, we characterize the
%   baseline response properties of the co-culture model.
%
%   TRACEABILITY:
%   Beyond the ANOVA, this function utilizes the 'stats.groupRows' lookup
%   table to map statistical groups back to individual trial rows in the
%   returned SUBTABLE. This facilitates deep-dives into individual cell
%   physiology or outlier identification.
%
%   LOGIC:
%   - SELECTS: Records where virus and drug treatments are null/empty.
%   - CONTEXT: Co-culture cell types (CL:0011103, CL:0000516).
%   - ANALYZES: Peak Response (Dependent) vs. Strain Name (Factor).

    arguments
        biggestTable table
    end

    % 1. Define Population Selection
    Selection = struct();
    Selection.virus_OntologyName = "";
    Selection.DrugTreatmentLocationOntology = "";
    Selection.Treatment_CultureFromCellTypeOntology = "CL:0011103, CL:0000516";

    % 2. Define Analysis Variables
    Factors = "StrainName";
    Measurement = "FIcalc.fitless.peakResponse";

    % 3. Execution
    [stats, g, subTable] = blt.stats.anovaTool(biggestTable, ...
        Measurement, Selection, Factors, ...
        'FigureTitle', "Analysis: Peak Response by Strain (Co-Culture Controls)");

    %% 4. Traceability Summary + Sample Size Storage
    % Adds sample sizes and group means into the returned stats struct.

    if ~isempty(stats.groupRows)

        numGroups = height(stats.groupRows);

        % Containers in stats for convenient downstream access
        stats.sampleSize = struct();
        stats.groupMean  = struct();

        fprintf('\n--- Analysis Summary: %s ---\n', Measurement);

        for i = 1:numGroups

            % Convert to string to ensure fprintf compatibility
            currentStrain = string(stats.groupRows.StrainName(i));

            % Sample size
            nSize = stats.groupRows.N(i);

            % Row indices in subTable for this group
            rowIdx = stats.groupRows.RowIndices{i};

            % Calculate group-specific mean from subTable
            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            % Store inside stats (fieldnames must be valid MATLAB identifiers)
            safeName = matlab.lang.makeValidName(currentStrain);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            % Print summary
            fprintf('Strain: %-12s | N = %3d | Mean = %6.2f\n', ...
                currentStrain, nSize, groupMean);
        end

        fprintf('-----------------------------------------------------\n');
    end
end