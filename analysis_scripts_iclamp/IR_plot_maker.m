%%%%%% frequency analysis between SHR and WKY chronic CNO - IR curve

filename = '/Users/sayakaminegishi/Documents/Birren Lab/2025/results/cellCountAvg2.xlsx';

%%%%%% Load Data for SHR %%%%%%
% SHR Control
sheet_SHR_Control = 'SHRN_Only';  
T_SHR_Control = readtable(filename, 'Sheet', sheet_SHR_Control);
%freq_SHR_Control = mean(T_SHR_Control{:, 2:end})' / 0.5; 
freq_SHR_Control = T_SHR_Control{:, 2:end}' / 0.5;

% SHR Treated (Chronic CNO 10uM)
sheet_SHR_Treated = '48h10umCNO-SHR_25sw';  
T_SHR_Treated = readtable(filename, 'Sheet', sheet_SHR_Treated);
%freq_SHR_Treated = mean(T_SHR_Treated{:, 2:end})' / 0.5; 
freq_SHR_Treated = T_SHR_Treated{:, 2:end}' / 0.5; 

%%%%%% Load Data for WKY %%%%%%
% WKY Control
sheet_WKY_Control = 'WKYN_Only';  
T_WKY_Control = readtable(filename, 'Sheet', sheet_WKY_Control);
%freq_WKY_Control = mean(T_WKY_Control{:, 2:end})' / 0.5; 
freq_WKY_Control = T_WKY_Control{:, 2:end}' / 0.5; 

% WKY Treated (Chronic CNO 10uM)
sheet_WKY_Treated = '48h10umCNO-WKY_25sw';  
T_WKY_Treated = readtable(filename, 'Sheet', sheet_WKY_Treated);
%freq_WKY_Treated = mean(T_WKY_Treated{:, 2:end})' / 0.5; 
freq_WKY_Treated = T_WKY_Treated{:, 2:end}' / 0.5; 

current_25sw = -50:15:310;

% Make IR PLOT
figure;
hold on

% Plot first points with labels for the legend
scatter(current_25sw(1), freq_SHR_Treated(1), 'r', 'DisplayName', 'SHR Treated');
scatter(current_25sw(1), freq_WKY_Treated(1), 'b', 'DisplayName', 'WKY Treated');
scatter(current_25sw(1), freq_WKY_Control(1), 'g', 'DisplayName', 'WKY Control');
scatter(current_25sw(1), freq_SHR_Control(1), 'c', 'DisplayName', 'SHR Control');

% Plot remaining points without labels
scatter(current_25sw, freq_SHR_Treated, 'r', 'HandleVisibility', 'off');
scatter(current_25sw, freq_WKY_Treated, 'b', 'HandleVisibility', 'off');
scatter(current_25sw, freq_WKY_Control, 'g', 'HandleVisibility', 'off');
scatter(current_25sw, freq_SHR_Control, 'c', 'HandleVisibility', 'off');

xlabel('Current (pA)')
ylabel('Firing rate (Hz)')
title('IR Plot for Treatment Group: WKY vs SHR')
legend('Location', 'best') % Automatically places the legend at the best position
hold off

% 
% %%%%%%%%% DATA SORTING FOR TWO-WAY ANOVA %%%%%%%%%%%%
% % Create group labels
% group_strain = [repmat({'SHR'}, length(freq_SHR_Control) + length(freq_SHR_Treated), 1); 
%                 repmat({'WKY'}, length(freq_WKY_Control) + length(freq_WKY_Treated), 1)];
% 
% group_treatment = [repmat({'Control'}, length(freq_SHR_Control), 1); 
%                    repmat({'Treated'}, length(freq_SHR_Treated), 1);
%                    repmat({'Control'}, length(freq_WKY_Control), 1); 
%                    repmat({'Treated'}, length(freq_WKY_Treated), 1)];
% 
% % Combine all frequencies into a single vector
% freq_all = [freq_SHR_Control; freq_SHR_Treated; freq_WKY_Control; freq_WKY_Treated];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
