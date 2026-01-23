%%%%%% freqAnalyzer Area Under Curve - t-test AUC (area under curve) analysis between WKY Treated and Control
%%%%%% conditions FROM SEPARATE, UNMODIFIED EXCEL DOCS
%%%%%% (average row is still included at the bottom)

% Created by Sayaka (Saya) Minegishi
% Jan 20 2026
% minegishis@brandeis.edu

close all
clear all

% INSERT DIRECTORIES FOR THE EXCEL FILES
filename_WKYControl = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6_Results/WKYNG_Only.xlsx';
filename_WKYTreated = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6_Results/WKYNDG_48hCNO.xlsx'; %48h CNO

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

% IMPORTANT: ensure x is increasing for trapz
[current_steps, sortIdx] = sort(current_steps(:)');  % row vector
data_WKY_Control = data_WKY_Control(:, sortIdx);
data_WKY_Treated = data_WKY_Treated(:, sortIdx);

nSteps = length(current_steps);

% Get sample sizes (n) for each group
n_Control = size(data_WKY_Control, 1);
n_Treated = size(data_WKY_Treated, 1);

fprintf('\nSample sizes:\n');
fprintf('n (Control) = %d\n', n_Control);
fprintf('n (Treated) = %d\n', n_Treated);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% AUC per cell + group comparison %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% AUC for each cell (trapz integrates over current_steps)
auc_control = zeros(n_Control, 1);
auc_treated = zeros(n_Treated, 1);

for r = 1:n_Control
    y = data_WKY_Control(r, :);
    auc_control(r) = trapz(current_steps, y);
end

for r = 1:n_Treated
    y = data_WKY_Treated(r, :);
    auc_treated(r) = trapz(current_steps, y);
end

% t-test on AUC (single comparison)
[~, p_auc] = ttest2(auc_treated, auc_control);

% Cohen's d for AUC
pooled_std_auc = sqrt((std(auc_control)^2 + std(auc_treated)^2) / 2);
cohens_d_auc = (mean(auc_treated) - mean(auc_control)) / pooled_std_auc;

fprintf('\nAUC comparison (frequency vs current):\n');
fprintf('Mean AUC (Control) = %.3f\n', mean(auc_control));
fprintf('Mean AUC (Treated) = %.3f\n', mean(auc_treated));
fprintf('t-test p-value     = %.4g\n', p_auc);
fprintf('Cohen''s d          = %.3f\n', cohens_d_auc);

if p_auc < 0.05
    if mean(auc_treated) > mean(auc_control)
        fprintf('Direction          = Treated > Control\n');
    else
        fprintf('Direction          = Control > Treated\n');
    end
else
    fprintf('Direction          = n.s.\n');
end

%%%%%% Plot AUC (box + points) %%%%%%
figure;
hold on;

% Simple boxplot
group = [repmat({'Control'}, n_Control, 1); repmat({'Treated'}, n_Treated, 1)];
auc_all = [auc_control; auc_treated];
boxplot(auc_all, group);

% Overlay points with jitter
x1 = 1 + 0.08*randn(n_Control,1);
x2 = 2 + 0.08*randn(n_Treated,1);
plot(x1, auc_control, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);
plot(x2, auc_treated, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 4);

ylabel('AUC (Hz·pA)');
title(sprintf('WKY: AUC of FI Curve (n=%d Control, n=%d Treated)\np=%.4g, d=%.3f', ...
    n_Control, n_Treated, p_auc, cohens_d_auc));
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% (Optional) Keep your step-wise FI plot below %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Step-wise t-tests (unchanged)
p_values = zeros(1, nSteps);
cohens_d = zeros(1, nSteps);
direction = strings(1, nSteps);

fprintf('\nStep-wise comparison:\n');
fprintf('Current (pA)\tp-value\tCohen''s d\tDirection\n');
fprintf('---------------------------------------------------\n');

for i = 1:nSteps
    control_vals = data_WKY_Control(:, i);
    treated_vals = data_WKY_Treated(:, i);

    [~, p] = ttest2(treated_vals, control_vals);
    p_values(i) = p;

    pooled_std = sqrt((std(control_vals)^2 + std(treated_vals)^2) / 2);
    cohens_d(i) = (mean(treated_vals) - mean(control_vals)) / pooled_std;

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

% Plot mean ± SEM
mean_control = mean(data_WKY_Control);
sem_control  = std(data_WKY_Control) / sqrt(n_Control);

mean_treated = mean(data_WKY_Treated);
sem_treated  = std(data_WKY_Treated) / sqrt(n_Treated);

x = current_steps;

figure;
hold on;

errorbar(x - 2, mean_control, sem_control, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Control');
errorbar(x + 2, mean_treated, sem_treated, 'ro-', 'LineWidth', 1.5, 'MarkerSize', 6, 'DisplayName', 'Treated');

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
