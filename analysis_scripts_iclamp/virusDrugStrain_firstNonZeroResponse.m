function [stats, g, subTable] = virusDrugStrain_firstNonZeroResponse(biggestTable)
% VIRUSDRUGSTRAIN - Comparative analysis of StrainName in Co-Culture populations.
%
% ANALYZES:
%   FIcalc.fitless.currentAtFirstNonZeroResponse vs StrainName
%
% LOGIC:
%   - SELECTS: virus = none, drug = none
%   - CONTEXT: neurons + glia co-culture
%   - FACTOR: StrainName

    arguments
        biggestTable table
    end

    %% 1. Define Population Selection
    Selection = struct();
    Selection.virus_OntologyName = "";
    Selection.DrugTreatmentLocationOntology = "";
    Selection.Treatment_CultureFromCellTypeOntology = "CL:0011103, CL:0000516";

    %% 2. Define Analysis Variables
    Factors = "StrainName";
    Measurement = "FIcalc.fitless.currentAtFirstNonZeroResponse";

    %% 3. Run ANOVA
    [stats, g, subTable] = blt.stats.anovaTool(biggestTable, ...
        Measurement, Selection, Factors, ...
        'FigureTitle', "Current at First Non-Zero Response by Strain (Co-Culture Controls)");

    %% 4. Traceability Summary
    if ~isempty(stats.groupRows)

        numGroups = height(stats.groupRows);

        stats.sampleSize = struct();
        stats.groupMean  = struct();

        fprintf('\n--- Analysis Summary: %s ---\n', Measurement);

        for i = 1:numGroups

            currentStrain = string(stats.groupRows.StrainName(i));
            nSize = stats.groupRows.N(i);

            rowIdx = stats.groupRows.RowIndices{i};

            groupMean = mean(subTable.(Measurement)(rowIdx), 'omitnan');

            safeName = matlab.lang.makeValidName(currentStrain);
            stats.sampleSize.(safeName) = nSize;
            stats.groupMean.(safeName)  = groupMean;

            fprintf('Strain: %-12s | N = %3d | Mean = %6.2f\n', ...
                currentStrain, nSize, groupMean);
        end

        fprintf('-----------------------------------------------------\n');
    end
end