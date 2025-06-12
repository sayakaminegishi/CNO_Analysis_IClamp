%%%% DO NOT USE!!!!!!! %%%%%%%%%%%%%

%%%%%% Anova frequency analysis between WKY Treated and Control
%%%%%% conditions
%%%%%% FROM SEPARATE, UMODIFIED EXCEL DOCS (so average row stil included at
%%%%%% the bottom)

% Created by Sayaka (Saya) Minegishi
% Jun 9 2025
% minegishis@brandeis.edu

%INSERT DIRECTORIES FOR THE EXCEL FILES CONTAINING CURRENT VS AP COUNT DATA
%FOR EACH CELL IN THE GROUP

filename_WKYControl='/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYN_Only.xlsx';
filename_WKYTreated = '/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata_results/Jun6/WKYN_48hCNO.xlsx';

%%%%%% Load Data for WKY %%%%%%
% WKY Control
T_WKY_Control = readtable(filename_WKYControl);
freq_WKY_Control = mean(T_WKY_Control{:, 2:end-1})' / 0.5; 

% WKY Treated (Chronic CNO 10uM)

T_WKY_Treated = readtable(filename_WKYTreated);
freq_WKY_Treated = mean(T_WKY_Treated{:, 2:end-1})' / 0.5; 

%%%%%% Statistical Analysis %%%%%%

% Combine Data for ANOVA (WKY)
freq_WKY = [freq_WKY_Control; freq_WKY_Treated];
group_WKY = [repmat({'Control'}, length(freq_WKY_Control), 1); repmat({'Treated'}, length(freq_WKY_Treated), 1)];

%%%%%%%%%%%%%%%%%%%
% Perform one-way ANOVA for WKY
[p_WKY, tbl_WKY, stats_WKY] = anova1(freq_WKY, group_WKY);
fprintf('ANOVA for WKY: p-value = %.4f\n', p_WKY);

% Calculate effect size
std_WKY = sqrt((std(freq_WKY_Control)^2 + std(freq_WKY_Treated)^2) / 2);
cohens_d_WKY = (mean(freq_WKY_Treated) - mean(freq_WKY_Control)) / std_WKY;

fprintf('Effect size (Cohen''s d) for WKY = %.4f\n', cohens_d_WKY);

% Determine direction of significance
if p_WKY < 0.05
    if mean(freq_WKY_Treated) > mean(freq_WKY_Control)
        fprintf('Result is significant: Treated > Control (WKY)\n');
    elseif mean(freq_WKY_Treated) < mean(freq_WKY_Control)
        fprintf('Result is significant: Control > Treated (WKY)\n');
    else
        fprintf('Result is significant but means are equal.\n');
    end
else
    fprintf('Result is not statistically significant.\n');
end

%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%
% % OLD SCRIPT: Perform one-way ANOVA for WKY
% [p_WKY, tbl_WKY, stats_WKY] = anova1(freq_WKY, group_WKY);
% fprintf('ANOVA for WKY: p-value = %.4f\n', p_WKY);
% 
% std_WKY = sqrt((std(freq_WKY_Control)^2 + std(freq_WKY_Treated)^2) / 2);
% cohens_d_WKY = (mean(freq_WKY_Treated) - mean(freq_WKY_Control)) / std_WKY;
% 
% fprintf('Effect size (Cohen''s d) for WKY = %.4f\n', cohens_d_WKY);
% 
% subplot(1,2,2);
% boxplot(freq_WKY, group_WKY);
% title('WKY: Control vs. Treated');
% ylabel('Frequency (Hz)');
%%%%%%%%%%%%%%%%%%%