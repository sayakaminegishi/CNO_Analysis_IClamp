%%%%%% two-way ANOVA frequency analysis between SHR and WKY chronic CNO
%%%%%% FROM SEPARATE, UMODIFIED EXCEL DOCS (so average row stil included at
%%%%%% the bottom)
% Created by Sayaka (Saya) Minegishi
% Jun 9 2025
% minegishis@brandeis.edu

%INSERT DIRECTORIES FOR THE EXCEL FILES CONTAINING CURRENT VS AP COUNT DATA
%FOR EACH CELL IN THE GROUP
filename_SHRControl='';
filename_SHRTreated='';
filename_WKYControl='/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYN_Only.xlsx';
filename_WKYTreated = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYN_48hCNO.xlsx';
%%%%%% Load Data for SHR %%%%%%
% SHR Control
T_SHR_Control = readtable(filename_SHRControl);
freq_SHR_Control = mean(T_SHR_Control{:, 2:end-1})' / 0.5;  %end-1 to account for the average_all row at the end of each doc

% SHR Treated (Chronic CNO 10uM)
T_SHR_Treated = readtable(filename_SHRTreated);
freq_SHR_Treated = mean(T_SHR_Treated{:, 2:end-1})' / 0.5; 

%%%%%% Load Data for WKY %%%%%%
% WKY Control
T_WKY_Control = readtable(filename_WKYControl);
freq_WKY_Control = mean(T_WKY_Control{:, 2:end-1})' / 0.5; 

% WKY Treated (Chronic CNO 10uM)

T_WKY_Treated = readtable(filename_WKYTreated);
freq_WKY_Treated = mean(T_WKY_Treated{:, 2:end-1})' / 0.5; 

%%%%%% Statistical Analysis %%%%%%

% Combine Data for ANOVA (SHR)
freq_SHR = [freq_SHR_Control; freq_SHR_Treated];
group_SHR = [repmat({'Control'}, length(freq_SHR_Control), 1); repmat({'Treated'}, length(freq_SHR_Treated), 1)];

% Combine Data for ANOVA (WKY)
freq_WKY = [freq_WKY_Control; freq_WKY_Treated];
group_WKY = [repmat({'Control'}, length(freq_WKY_Control), 1); repmat({'Treated'}, length(freq_WKY_Treated), 1)];

% Perform one-way ANOVA for SHR
[p_SHR, tbl_SHR, stats_SHR] = anova1(freq_SHR, group_SHR);
fprintf('ANOVA for SHR: p-value = %.4f\n', p_SHR);

% Perform one-way ANOVA for WKY
[p_WKY, tbl_WKY, stats_WKY] = anova1(freq_WKY, group_WKY);
fprintf('ANOVA for WKY: p-value = %.4f\n', p_WKY);

% Effect size (Cohen's d)
std_SHR = sqrt((std(freq_SHR_Control)^2 + std(freq_SHR_Treated)^2) / 2);
cohens_d_SHR = (mean(freq_SHR_Treated) - mean(freq_SHR_Control)) / std_SHR;

std_WKY = sqrt((std(freq_WKY_Control)^2 + std(freq_WKY_Treated)^2) / 2);
cohens_d_WKY = (mean(freq_WKY_Treated) - mean(freq_WKY_Control)) / std_WKY;

fprintf('Effect size (Cohen''s d) for SHR = %.4f\n', cohens_d_SHR);
fprintf('Effect size (Cohen''s d) for WKY = %.4f\n', cohens_d_WKY);

%%%%%% Plot Results %%%%%%
figure;
subplot(1,2,1);
boxplot(freq_SHR, group_SHR);
title('SHR: Control vs. Treated');
ylabel('Frequency (Hz)');

subplot(1,2,2);
boxplot(freq_WKY, group_WKY);
title('WKY: Control vs. Treated');
ylabel('Frequency (Hz)');
