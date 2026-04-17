function [stats, g, subTable] = wkyVsShr_NeuronsOnly_FICurve(biggestTable)
% WKYVSSHR_NEURONSONLY_FICURVE
% Plot averaged FI curves for control neurons-only cultures on the same axes:
%   WKY vs SHR
%
% Uses:
%   X = FIcalc.TC.current
%   Y = FIcalc.TC.mean

    arguments
        biggestTable table
    end

    %% 1) Select control cells only
    subTable = biggestTable;
    subTable = subTable(strip(string(subTable.virus_OntologyName)) == "", :);
    subTable = subTable(strip(string(subTable.DrugTreatmentLocationOntology)) == "", :);

    if isempty(subTable)
        error('wkyVsShr_NeuronsOnly_FICurve:EmptySubset', ...
            'Control selection matched zero rows.');
    end

    %% 2) Keep neurons-only cultures
    culture = strip(string(subTable.Treatment_CultureFromCellTypeOntology));
    culture(ismissing(culture)) = "";

    culture(culture == "CL:0011103") = "Neurons-only";
    culture(culture == "CL:0011103, CL:0000516") = "Neurons-Glia";

    keepCulture = (culture == "Neurons-only");
    subTable = subTable(keepCulture, :);

    if isempty(subTable)
        error('wkyVsShr_NeuronsOnly_FICurve:NoNeuronsOnlyRows', ...
            'No neurons-only rows were found.');
    end

    %% 3) Keep only WKY and SHR
    strain = strip(string(subTable.StrainName));
    strain(ismissing(strain)) = "";

    keepStrain = (strain == "WKY") | (strain == "SHR");
    subTable = subTable(keepStrain, :);
    strain = strain(keepStrain);

    if isempty(subTable)
        error('wkyVsShr_NeuronsOnly_FICurve:NoValidStrains', ...
            'No WKY or SHR neurons-only rows were found.');
    end

    subTable.StrainGroup = categorical(strain, ["WKY","SHR"], 'Ordinal', true);

    %% 4) Extract FI data
    nRows = height(subTable);
    xCell = cell(nRows,1);
    yCell = cell(nRows,1);
    validRow = false(nRows,1);

    varNames = string(subTable.Properties.VariableNames);
    hasDirectCurrent = any(varNames == "FIcalc.TC.current");
    hasDirectMean    = any(varNames == "FIcalc.TC.mean");
    hasFIcalcColumn  = any(varNames == "FIcalc");

    fprintf('Rows after filtering: %d\n', nRows);
    fprintf('Found direct current column: %d\n', hasDirectCurrent);
    fprintf('Found direct mean column: %d\n', hasDirectMean);
    fprintf('Found FIcalc column: %d\n', hasFIcalcColumn);

    for r = 1:nRows
        try
            x = [];
            y = [];

            % Case 1: direct table columns
            if hasDirectCurrent && hasDirectMean
                xRaw = getRowVar(subTable, r, "FIcalc.TC.current");
                yRaw = getRowVar(subTable, r, "FIcalc.TC.mean");

                x = forceNumericRowVector(xRaw);
                y = forceNumericRowVector(yRaw);
            end

            % Case 2: nested FIcalc column
            if (isempty(x) || isempty(y)) && hasFIcalcColumn
                fiEntry = getRowVar(subTable, r, "FIcalc");

                xRaw = deepGet(fiEntry, {'TC','current'});
                yRaw = deepGet(fiEntry, {'TC','mean'});

                x = forceNumericRowVector(xRaw);
                y = forceNumericRowVector(yRaw);
            end

            if ~isempty(x) && ~isempty(y) && numel(x) == numel(y)
                xCell{r} = x;
                yCell{r} = y;
                validRow(r) = true;
            end
        catch
            % leave invalid
        end
    end

    fprintf('Valid FI rows found: %d / %d\n', sum(validRow), nRows);

    %% 5) Remove invalid rows
    subTable = subTable(validRow, :);
    xCell = xCell(validRow);
    yCell = yCell(validRow);

    if isempty(subTable)
        error('wkyVsShr_NeuronsOnly_FICurve:NoValidFIData', ...
            'No readable FI rows were found.');
    end

    %% 6) Keep only the most common current-step protocol
    xStrings = cellfun(@(x) mat2str(x, 6), xCell, 'UniformOutput', false);
    [uniqueX, ~, groupIdx] = unique(xStrings);
    counts = accumarray(groupIdx, 1);

    fprintf('\nUnique FI current protocols found:\n');
    for k = 1:numel(uniqueX)
        fprintf('Protocol %d: n = %d\n%s\n\n', k, counts(k), uniqueX{k});
    end

    [~, mostCommonIdx] = max(counts);
    keepRows = groupIdx == mostCommonIdx;

    subTable = subTable(keepRows, :);
    xCell = xCell(keepRows);
    yCell = yCell(keepRows);

    if isempty(subTable)
        error('wkyVsShr_NeuronsOnly_FICurve:NoConsistentProtocol', ...
            'No rows remained after restricting to the most common FI current-step protocol.');
    end

    xSteps = xCell{1};
    fprintf('Keeping %d rows with the most common current-step protocol.\n', numel(xCell));

    %% 7) Make figure on same axes
    groups = categories(subTable.StrainGroup);
    colors = [0.20 0.20 0.20;
              0.85 0.33 0.10];

    g = figure('Color', 'w', 'Name', 'Averaged FI Curves: WKY vs SHR Neurons-only');
    hold on;

    stats = struct();

    for i = 1:numel(groups)
        grpName = groups{i};
        idx = subTable.StrainGroup == grpName;
        nSize = sum(idx);

        if nSize == 0
            continue
        end

        grpY = vertcat(yCell{idx});
        avgCurve = mean(grpY, 1, 'omitnan');
        semCurve = std(grpY, 0, 1, 'omitnan') ./ sqrt(nSize);

        errorbar(xSteps, avgCurve, semCurve, 'o-', ...
            'Color', colors(i,:), ...
            'LineWidth', 1.8, ...
            'MarkerFaceColor', colors(i,:), ...
            'MarkerSize', 5, ...
            'CapSize', 0, ...
            'DisplayName', sprintf('%s (n=%d)', char(grpName), nSize));

        safeName = matlab.lang.makeValidName(char(grpName));
        stats.(safeName).N = nSize;
        stats.(safeName).x = xSteps;
        stats.(safeName).mean = avgCurve;
        stats.(safeName).sem = semCurve;
    end

    xlabel('Injected Current (pA)');
    ylabel('Firing Rate (Hz)');
    title('Neurons-only: Averaged FI Curves for WKY vs SHR');
    legend('Location', 'best');
    grid on;
    box off;
    set(gca, 'TickDir', 'out');

    allY = vertcat(yCell{:});
    maxY = max(allY(:), [], 'omitnan');
    if isempty(maxY) || isnan(maxY)
        maxY = 1;
    end
    ylim([0 maxY * 1.1]);
end

%% ========================= Helper functions =========================

function val = getRowVar(tbl, r, varName)
    col = tbl.(varName);

    if iscell(col)
        val = col{r};
        return
    end

    try
        val = tbl{r, varName};
        if iscell(val) && numel(val) == 1
            val = val{1};
        end
        return
    catch
    end

    try
        val = col(r,:);
        if numel(val) == 1
            val = val(1);
        end
    catch
        val = col(r);
    end
end

function out = deepGet(x, pathParts)
    out = x;

    while iscell(out) && numel(out) == 1
        out = out{1};
    end

    for k = 1:numel(pathParts)
        key = pathParts{k};

        if iscell(out) && numel(out) == 1
            out = out{1};
        end

        if isstruct(out)
            if isfield(out, key)
                out = out.(key);
            else
                out = [];
                return
            end

        elseif istable(out)
            vars = string(out.Properties.VariableNames);
            if any(vars == key)
                out = out.(key);
            else
                out = [];
                return
            end

        elseif isobject(out)
            try
                out = out.(key);
            catch
                out = [];
                return
            end

        else
            out = [];
            return
        end
    end

    while iscell(out) && numel(out) == 1
        out = out{1};
    end
end

function v = forceNumericRowVector(x)
    v = [];

    if isempty(x)
        return
    end

    while iscell(x) && numel(x) == 1
        x = x{1};
    end

    if isnumeric(x) || islogical(x)
        v = double(x(:))';
        return
    end

    if isstruct(x)
        f = fieldnames(x);
        for i = 1:numel(f)
            candidate = x.(f{i});
            while iscell(candidate) && numel(candidate) == 1
                candidate = candidate{1};
            end
            if isnumeric(candidate) || islogical(candidate)
                v = double(candidate(:))';
                return
            end
        end
    end
end