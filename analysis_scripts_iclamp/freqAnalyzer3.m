%%%%%% Two-way ANOVA for each sweep in a single window %%%%%%
filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx';

%%%%%% Load Data for SHR %%%%%%
% SHR Control
sheet_SHR_Control = 'SHRN_Only';  
T_SHR_Control = readtable(filename, 'Sheet', sheet_SHR_Control);
freq_SHR_Control = T_SHR_Control{:, 2:end} / 0.5;  

% SHR Treated (Chronic CNO 10uM)
sheet_SHR_Treated = '48h10umCNO-SHR_25sw';  
T_SHR_Treated = readtable(filename, 'Sheet', sheet_SHR_Treated);
freq_SHR_Treated = T_SHR_Treated{:, 2:end} / 0.5;  

%%%%%% Load Data for WKY %%%%%%
% WKY Control
sheet_WKY_Control = 'WKYN_Only';  
T_WKY_Control = readtable(filename, 'Sheet', sheet_WKY_Control);
freq_WKY_Control = T_WKY_Control{:, 2:end} / 0.5;  

% WKY Treated (Chronic CNO 10uM)
sheet_WKY_Treated = '48h10umCNO-WKY_25sw';  
T_WKY_Treated = readtable(filename, 'Sheet', sheet_WKY_Treated);
freq_WKY_Treated = T_WKY_Treated{:, 2:end} / 0.5;  

%%%%%% Perform Two-Way ANOVA for Each Sweep & Plot in One Window %%%%%%
num_sweeps = size(freq_SHR_Control, 2);  % Number of sweeps
p_values = zeros(num_sweeps, 3);  % Store p-values for Strain, Treatment, and Interaction

% Determine subplot grid size
num_cols = ceil(sqrt(num_sweeps));  % Number of columns in subplot grid
num_rows = ceil(num_sweeps / num_cols);  % Number of rows

figure; % Create a single figure for all plots
set(gcf, 'Position', [100, 100, 1500, 900]);  % Adjust figure size for better visualization

for i = 1:num_sweeps
    % Extract frequency data for the current sweep
    freq_sweep = [freq_SHR_Control(:, i); freq_SHR_Treated(:, i); freq_WKY_Control(:, i); freq_WKY_Treated(:, i)];

    % Define two grouping factors: Strain and Treatment
    strain = [repmat({'SHR'}, size(freq_SHR_Control, 1) + size(freq_SHR_Treated, 1), 1);
              repmat({'WKY'}, size(freq_WKY_Control, 1) + size(freq_WKY_Treated, 1), 1)];

    treatment = [repmat({'Control'}, size(freq_SHR_Control, 1), 1);
                 repmat({'Treated'}, size(freq_SHR_Treated, 1), 1);
                 repmat({'Control'}, size(freq_WKY_Control, 1), 1);
                 repmat({'Treated'}, size(freq_WKY_Treated, 1), 1)];

    % Perform Two-Way ANOVA
    [p, ~, ~] = anovan(freq_sweep, {strain, treatment}, 'model', 'interaction', ...
                        'varnames', {'Strain', 'Treatment'}, 'display', 'off');  % Suppress table output

    % Store p-values
    p_values(i, :) = p;  % (Strain, Treatment, Interaction)

    % Plot Boxplot in Subplot
    subplot(num_rows, num_cols, i);  % Arrange in a grid
    boxplot(freq_sweep, {strain, treatment}, 'FactorSeparator', 1);
    title(sprintf('Sweep %d', i));
    ylabel('Frequency (Hz)');
    xlabel('Group (Strain-Treatment)');
end

%%%%%% Display p-values for each sweep %%%%%%
p_table = array2table(p_values, 'VariableNames', {'Strain_p', 'Treatment_p', 'Interaction_p'});
fprintf('Sweep-wise Two-Way ANOVA p-values:\n');
disp(p_table);


%%%%%% Identify Significant Sweeps %%%%%%
alpha = 0.05; % Significance threshold
significant_sweeps = array2table(p_values, 'VariableNames', {'Strain_p', 'Treatment_p', 'Interaction_p'});
significant_sweeps.Sweep = (1:num_sweeps)'; % Add sweep numbers

% Mark significance
significant_sweeps.Strain_Sig = p_values(:,1) < alpha;
significant_sweeps.Treatment_Sig = p_values(:,2) < alpha;
significant_sweeps.Interaction_Sig = p_values(:,3) < alpha;

% Display results
fprintf('Summary of Significant Sweeps:\n');
disp(significant_sweeps(:, {'Sweep', 'Strain_Sig', 'Treatment_Sig', 'Interaction_Sig'}));

% Count total number of significant sweeps
num_strain_sig = sum(significant_sweeps.Strain_Sig);
num_treatment_sig = sum(significant_sweeps.Treatment_Sig);
num_interaction_sig = sum(significant_sweeps.Interaction_Sig);

fprintf('Total significant sweeps:\n');
fprintf('  - Strain Effect: %d/%d\n', num_strain_sig, num_sweeps);
fprintf('  - Treatment Effect: %d/%d\n', num_treatment_sig, num_sweeps);
fprintf('  - Interaction Effect: %d/%d\n', num_interaction_sig, num_sweeps);
