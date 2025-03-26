%%%%%% two-way ANOVA frequency analysis between SHR and WKY chronic CNO

filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx';

%%%%%% Load Data for SHR %%%%%%
% SHR Control
sheet_SHR_Control = 'SHRN_Only';  
T_SHR_Control = readtable(filename, 'Sheet', sheet_SHR_Control);
freq_SHR_Control = mean(T_SHR_Control{:, 2:end})' / 0.5; 

% SHR Treated (Chronic CNO 10uM)
sheet_SHR_Treated = '48h10umCNO-SHR_25sw';  
T_SHR_Treated = readtable(filename, 'Sheet', sheet_SHR_Treated);
freq_SHR_Treated = mean(T_SHR_Treated{:, 2:end})' / 0.5; 

%%%%%% Load Data for WKY %%%%%%
% WKY Control
sheet_WKY_Control = 'WKYN_Only';  
T_WKY_Control = readtable(filename, 'Sheet', sheet_WKY_Control);
freq_WKY_Control = mean(T_WKY_Control{:, 2:end})' / 0.5; 

% WKY Treated (Chronic CNO 10uM)
sheet_WKY_Treated = '48h10umCNO-WKY_25sw';  
T_WKY_Treated = readtable(filename, 'Sheet', sheet_WKY_Treated);
freq_WKY_Treated = mean(T_WKY_Treated{:, 2:end})' / 0.5; 

% Create group labels
group_strain = [repmat({'SHR'}, length(freq_SHR_Control) + length(freq_SHR_Treated), 1); 
                repmat({'WKY'}, length(freq_WKY_Control) + length(freq_WKY_Treated), 1)];

group_treatment = [repmat({'Control'}, length(freq_SHR_Control), 1); 
                   repmat({'Treated'}, length(freq_SHR_Treated), 1);
                   repmat({'Control'}, length(freq_WKY_Control), 1); 
                   repmat({'Treated'}, length(freq_WKY_Treated), 1)];

% Combine all frequencies into a single vector
freq_all = [freq_SHR_Control; freq_SHR_Treated; freq_WKY_Control; freq_WKY_Treated];

% Perform two-way ANOVA
[p, tbl, stats] = anovan(freq_all, {group_strain, group_treatment}, ...
                         'model', 'interaction', ...
                         'varnames', {'Strain', 'Treatment'});

fprintf('Two-way ANOVA Results:\n');
fprintf('Strain Effect: p = %.4f\n', p(1));
fprintf('Treatment Effect: p = %.4f\n', p(2));
fprintf('Interaction Effect: p = %.4f\n', p(3));

%%%%%% Effect Size Calculation %%%%%%
% Pooled standard deviation
std_pooled = sqrt((std(freq_SHR_Control)^2 + std(freq_SHR_Treated)^2 + ...
                   std(freq_WKY_Control)^2 + std(freq_WKY_Treated)^2) / 4);

% Cohen's d for each comparison
d_SHR = (mean(freq_SHR_Treated) - mean(freq_SHR_Control)) / std_pooled;
d_WKY = (mean(freq_WKY_Treated) - mean(freq_WKY_Control)) / std_pooled;
d_between = (mean([freq_SHR_Control; freq_SHR_Treated]) - mean([freq_WKY_Control; freq_WKY_Treated])) / std_pooled;

fprintf('Effect size (Cohen''s d) - SHR (Treatment vs Control): %.4f\n', d_SHR);
fprintf('Effect size (Cohen''s d) - WKY (Treatment vs Control): %.4f\n', d_WKY);
fprintf('Effect size (Cohen''s d) - Between Strains: %.4f\n', d_between);

%%%%%% Plot Results %%%%%%
figure;
boxplot(freq_all, {group_strain, group_treatment});
title('Comparison of Frequency Across Strains and Treatment');
ylabel('Frequency (Hz)');
xlabel('Group (Strain & Treatment)');
grid on;