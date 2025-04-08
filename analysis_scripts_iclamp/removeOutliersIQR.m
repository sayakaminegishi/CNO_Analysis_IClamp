% Define a function to remove outliers from a table
function cleanTable = removeOutliersIQR(tbl)
    cleanTable = tbl;
    numericVars = varfun(@isnumeric, tbl, 'OutputFormat', 'uniform');
    varNames = tbl.Properties.VariableNames(numericVars);
    
    for i = 1:length(varNames)
        col = tbl.(varNames{i});
        Q1 = quantile(col, 0.25);
        Q3 = quantile(col, 0.75);
        IQR = Q3 - Q1;
        lowerBound = Q1 - 1.5 * IQR;
        upperBound = Q3 + 1.5 * IQR;
        
        % Create logical index of rows within bounds
        inliers = (col >= lowerBound) & (col <= upperBound);
        
        % Keep only rows that are inliers for this variable
        cleanTable = cleanTable(inliers, :);
        
        % Update the table for the next variable
        tbl = cleanTable;
    end
end
