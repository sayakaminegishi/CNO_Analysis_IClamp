%%%%%% t-test frequency analysis between WKY Treated and Control
%%%%%% conditions FROM SEPARATE, UNMODIFIED EXCEL DOCS 
%%%%%% (average row is still included at the bottom)

% Created by Sayaka (Saya) Minegishi
% Jun 9 2025
% minegishis@brandeis.edu

close all
clear all

% INSERT DIRECTORIES FOR THE EXCEL FILES

filename_WKYControl = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYNG_Only.xlsx';
filename_WKYTreated = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYNDG_Only.xlsx';

%%%%%% Load Data for WKY %%%%%%

% Read full tables
T_WKY_Control = readtable(filename_WKYControl);
T_WKY_Treated = readtable(filename_WKYTreated);

% Extract and clean current injection headers (skip ID column, exclude final 'Average')
varNames = T_WKY_Control.Properties.VariableNames(2:end-1);
cleanLabels = regexprep(varNames, '–|—', '-');         % Replace en/em dash with minus
cleanLabels = regexprep(cleanLabels, '[^\d.-]', '');   % Remove non-numeric characters except - and .

current_steps = str2double(cleanLabels);

% Extract numeric data, excluding average row
data_WKY_Control = table2array(T_WKY_Control(1:end-1, 2:end-1));
data_WKY_Treated = table2array(T_WKY_Treated(1:end-1, 2:end-1));

% Sanity check: remove invalid current step columns (non-numeric)
validIdx = ~isnan(current_steps);
current_steps = current_steps(validIdx);
data_WKY_Control = data_WKY_Control(:, validIdx);
data_WKY_Treated = data_WKY_Treated(:, validIdx);

% Remove the first 4 current steps from analysis
current_steps = current_steps(5:end);
data_WKY_Control = data_WKY_Control(:, 5:end);
data_WKY_Treated = data_WKY_Treated(:, 5:end);
nSteps = length(current_steps);

% Get sample sizes (n) for each group
n_Control = size(data_WKY_Control, 1);
n_Treated = size(data_WKY_Treated, 1);

fprintf('\nSample sizes:\n');
fprintf('n (Control) = %d\n', n_Control);
fprintf('n (Treated) = %d\n', n_Treated);

%%%%%% Step-by-step t-tests and effect size %%%%%%
p_values = zeros(1, nSteps);
cohens_d = zeros(1, nSteps);
direction = strings(1, nSteps);

fprintf('\nStep-wise comparison:\n');
fprintf('Current (pA)\tp-value\tCohen''s d\tDirection\n');
fprintf('---------------------------------------------------\n');

for i = 1:nSteps
    control_vals = data_WKY_Control(:, i);
    treated_vals = data_WKY_Treated(:, i);

    % t-test
    [~, p] = ttest2(treated_vals, control_vals);
    p_values(i) = p;

    % Cohen's d
    pooled_std = sqrt((std(control_vals)^2 + std(treated_vals)^2) / 2);
    cohens_d(i) = (mean(treated_vals) - mean(control_vals)) / pooled_std;

    % Direction
    if p < 0.05
        if mean(treated_vals) > mean(control_vals)
            direction(i) = "Treated > Control";
        else
            direction(i) = "Control > Treated";
        end
    else
        direction(i) = "n.s.";
    end

    fprintf('%d\t\t%.4f\t%.3f\t\t%s\n', current_steps(i), p, cohens_d(i), direction(i));
end

%%%%%% Plotting mean ± SEM with significance markers %%%%%%

mean_control = mean(data_WKY_Control);
sem_control = std(data_WKY_Control) / sqrt(n_Control);

mean_treated = mean(data_WKY_Treated);
sem_treated = std(data_WKY_Treated) / sqrt(n_Treated);

x = current_steps;

figure;
hold on;

% Plot with small offset to separate lines
errorbar(x - 2, mean_control, sem_control, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Control');
errorbar(x + 2, mean_treated, sem_treated, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Treated');

% Add significance markers
for i = 1:nSteps
    if p_values(i) < 0.05
        y_max = max([mean_control(i) + sem_control(i), mean_treated(i) + sem_treated(i)]);
        text(x(i), y_max + 0.5, '*', 'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'k');
    end
end

xlabel('Current Injection (pA)');
ylabel('Firing Frequency (Hz)');
title(sprintf('WKY: Frequency vs Current Injection\n(n = %d Control, %d Treated)', n_Control, n_Treated));
legend('Location', 'NorthWest');
grid on;
xlim([min(x) - 10, max(x) + 10]);
ylim([0, max([mean_control + sem_control, mean_treated + sem_treated], [], 'all') + 2]);

hold off;
