
%This will print a table showing each strain–subject–treatment combination
%with the number of rows (entries) for that condition.%

% Load Excel file
filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/total_dataset_updated FINAL.xlsx';
T = readtable(filename);

% Group by strain, subject, and treatment
[G, strain, subject, treatment] = findgroups(T.strain, T.subject, T.treatment);

% Count entries for each condition
counts = splitapply(@numel, T.strain, G);

% Make results table
results = table(strain, subject, treatment, counts);

% Sort results
results = sortrows(results, {'strain','subject','treatment'});

% Display in command window
disp(results);

% --- Visualization ---
% Create condition labels like "WKY | N_Glia | control"
labels = strcat(string(results.strain), " | ", ...
                string(results.subject), " | ", ...
                string(results.treatment));

% Bar plot
figure;
bar(counts);
set(gca, 'XTick', 1:numel(labels), 'XTickLabel', labels, 'XTickLabelRotation', 45);
ylabel('Number of Entries');
title('Entries per Strain-Subject-Treatment Condition');
grid on;

% --- Export results to Excel ---
outputFile = 'Condition_Counts.xlsx';
writetable(results, outputFile);

fprintf('Results exported to %s\n', outputFile);