% Create a sample table
T = array2table(rand(5,3), 'VariableNames', {'ID', 'A', 'B'});

% Compute the mean of all columns except the first column
meanValues = mean(T{:, 2:end});

% Create a new table with the original data
newTable = T;

% Convert the mean values into a table row
meanRow = array2table([NaN, meanValues], 'VariableNames', T.Properties.VariableNames);

% Append the mean row to the new table
newTable = [newTable; meanRow];

% Display the updated table
disp(newTable);
