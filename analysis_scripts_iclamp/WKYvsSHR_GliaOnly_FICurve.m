function [stats, g, subTable] = WKYvsSHR_GliaOnly_FICurve(biggestTable)
% WKYVSSHR_GLIAONLY_FICURVE
% Plot averaged FI curves for neurons co-cultured with glia:
%   1) WKY Neurons-Glia
%   2) SHR Neurons-Glia
%
% Tries to extract:
%   X = FIcalc.TC.current
%   Y = FIcalc.TC.mean
%
% Also supports direct table variables named:
%   "FIcalc.TC.current"
%   "FIcalc.TC.mean"

    arguments
        biggestTable table
    end

    %% 1) Select control cells only
    subTable = biggestTable;
    subTable = subTable(strip(string(subTable.virus_OntologyName)) == "", :);
    subTable = subTable(strip(string(subTable.DrugTreatmentLocationOntology)) == "", :);

    if isempty(subTable)
        error('WKYvsSHR_GliaOnly_FICurve:EmptySubset', ...
            'Control selection matched zero rows.');
    end

    %% 2) Map culture conditions and keep glia co-culture only
    culture = strip(string(subTable.Treatment_CultureFromCellTypeOntology));
    culture(ismissing(culture)) = "";

    culture(culture == "CL:0011103") = "Neurons-only";
    culture(culture == "CL:0011103, CL:0000516") = "Neurons-Glia";

    keepCulture = (culture == "Neurons-Glia");
    subTable = subTable(keepCulture, :);

    if isempty(subTable)
        error('WKYvsSHR_GliaOnly_FICurve:NoGliaRows', ...
            'No neurons-glia rows were found.');
    end

    %% 3) Keep only WKY and SHR
    strain = strip(string(subTable.StrainName));
    strain(ismissing(strain)) = "";

    keepStrain = (strain == "WKY") | (strain == "SHR");
    subTable = subTable(keepStrain, :);
    strain = strain(keepStrain);

    if isempty(subTable)
        error('WKYvsSHR_GliaOnly_FICurve:NoValidStrains', ...
            'No WKY or SHR glia-cocultured rows were found.');
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

            % Case 2: nested under FIcalc
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
        error('WKYvsSHR_GliaOnly_FICurve:NoValidFIData', ...
            ['No readable FI rows were found. Run these commands to inspect the structure:' newline ...
             'disp(biggestTable.Properties.VariableNames'')' newline ...
             'class(biggestTable.FIcalc)' newline ...
             'biggestTable.FIcalc(1)' newline ...
             'try, biggestTable.FIcalc{1}, catch ME, disp(ME.message), end']);
    end

    %% 6) Restrict to the most common current-step protocol
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
        error('WKYvsSHR_GliaOnly_FICurve:NoConsistentProtocol', ...
            'No rows remained after restricting to the most common FI current-step protocol.');
    end

    xSteps = xCell{1};
    fprintf('Keeping %d rows with the most common current-step protocol.\n', numel(xCell));

    %% 7) Prepare figure on same axes
    groups = categories(subTable.StrainGroup);
    colors = [0.15 0.15 0.15;   % WKY
              0.85 0.33 0.10];  % SHR

    g = figure('Color', 'w', 'Name', 'Averaged FI Curves: WKY vs SHR Glia');
    hold on;

    stats = struct();

    allY = vertcat(yCell{:});
    maxY = max(allY(:), [], 'omitnan');
    if isempty(maxY) || isnan(maxY)
        maxY = 1;
    end
    maxY = maxY * 1.1;

    %% 8) Plot both groups on the same axes
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
            'LineWidth', 2, ...
            'MarkerSize', 5, ...
            'CapSize', 0, ...
            'DisplayName', sprintf('%s (n=%d)', char(grpName), nSize));

        safeName = matlab.lang.makeValidName(char(grpName));
        stats.(safeName).N = nSize;
        stats.(safeName).x = xSteps;
        stats.(safeName).mean = avgCurve;
        stats.(safeName).sem = semCurve;
    end

    %% 9) Formatting
    xlabel('Injected current (pA)', 'FontSize', 12);
    ylabel('Firing rate (Hz)', 'FontSize', 12);
    title('Neurons co-cultured with glia: WKY vs SHR', 'FontSize', 13, 'FontWeight', 'normal');
    legend('Location', 'northwest', 'Box', 'off');
    ylim([0 maxY]);

    ax = gca;
    ax.FontSize = 11;
    ax.LineWidth = 1;
    ax.TickDir = 'out';
    ax.Box = 'off';

    grid off;
end

%% ========================= Helper functions =========================

function val = getRowVar(tbl, r, varName)
% Safely get one row's value from a table variable, whether it is numeric,
% cell, struct-like, or object-like.

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
% Recursively extract nested content from cells/structs/objects/tables.

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
% Convert nested/cell/scalar content into a numeric row vector if possible.

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