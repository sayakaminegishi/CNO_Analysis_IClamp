% Analysis of AP % AHP properties between WKY and SHR neurons for the LAST
% SWEEP
% Created by Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Last Updated: 3/31/2024

close all
clear all

% Define the headers for the table
headers = {'Property', 'p-val', 'alpha', 'Result'};

% Create the table
sumtable= zeros(0,numel(headers));
summaryTable = array2table(sumtable, 'VariableNames', headers);




%%%% load data from excel spreadsheets

SHRTable = readtable("/Users/sayakaminegishi/Documents/AP analysis packages Saya M/ANALYSES_March 2024/APR3ANALYSIS/Apr3SHREVOKED.xlsx","TextType","string");
WKYTable = readtable("/Users/sayakaminegishi/Documents/AP analysis packages Saya M/ANALYSES_March 2024/APR3ANALYSIS/Apr3WKYEVOKED.xlsx","TextType","string");

strain = ["WKYN", "SHRN"];

alpha = 0.05;
%%%%%%%% compare thesholds %%%%%%%%%%%%%%

shr_threshold= str2double(SHRTable.threshold_mV_); %SHR threshold values for 1st AP detected
wky_threshold = str2double(WKYTable.threshold_mV_); 

[h,p,ci,stats] = ttest2(shr_threshold,wky_threshold,'Vartype','unequal')

% Interpret the results
if h == 1
    str = 'The mean threshold differs significantly between the two strains.';
else
    str = 'There is no significant difference in the mean threshold between the two strains.';
end

%make a new row in the table
newRow = {'AP_Threshold', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table

%%%%%%%% compare current injected to evoke first AP %%%%%%%%%%%%%%

shr_i= str2double(SHRTable.current_injected_pA_); %SHR threshold values for 1st AP detected
wky_i = str2double(WKYTable.current_injected_pA_); 

[h,p,ci,stats] = ttest2(shr_i,wky_i,'Vartype','unequal')

% Interpret the results
if h == 1
    str = 'The mean current injected differs significantly between the two strains.';
else
   str='There is no significant difference in the mean current injected between the two strains.';
end
%make a new row in the table
newRow = {'current_required_for_firstAP', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table

%%%%%%%% compare frequency evoked %%%%%%%%%%%%%%

shr_i= str2double(SHRTable.frequency_Hz_); %SHR threshold values for 1st AP detected
wky_i = str2double(WKYTable.frequency_Hz_); 

[h,p,ci,stats] = ttest2(shr_i,wky_i,'Vartype','unequal')

% Interpret the results
if h == 1
    str = 'The mean frequency_Hz_ differs significantly between the two strains.';
else
    str='There is no significant difference in the mean frequency_Hz_ between the two strains.';
end

%make a new row in the table
newRow = {'frequency_at_minimum_req_current', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table


%%%%%%%% compare frequency evoked  - one sided test %%%%%%%%%%%%%%

shr_freq= str2double(SHRTable.frequency_Hz_); %SHR threshold values for 1st AP detected
wky_freq = str2double(WKYTable.frequency_Hz_); 

[h,p,ci,stats] = ttest2(shr_freq,wky_freq,'Vartype','unequal', 'Tail', 'left') %test Ha: SHR freq < wky freq

% Interpret the results
if h == 1
    str = 'The mean frequency_Hz_ for SHRN is greater than the mean for WKYN.';
else
   str = 'There is no significant difference in the mean frequency_Hz_ between the two strains.';
end

% make side-by-side boxplot of the data
figure(1)
% Determine the number of data points in each dataset
num_shr = numel(shr_freq);
num_wky = numel(wky_freq);


% Determine the maximum number of data points
max_num_data = max(num_shr, num_wky);

% Pad the smaller dataset with NaN values to match the size of the larger dataset
if num_shr < max_num_data
    shr_freq = [shr_freq; nan(max_num_data - num_shr, 1)];
elseif num_wky < max_num_data
    wky_freq = [wky_freq; nan(max_num_data - num_wky, 1)];
end

% Combine the data into a single matrix
combined_data = [shr_freq, wky_freq];

% Create a new figure for the boxplot
figure(1);

% Plot the boxplot
boxplot(combined_data, 'Labels', {'SHR', 'WKY'});
title('Comparison of SHR and WKY Frequencies');
xlabel('Strain');
ylabel('Frequency (Hz)');

% Set the same y-axis limits for both boxplots
ylim([min(min(combined_data)), max(max(combined_data))]);

figure(2);
hist(shr_freq)
title('SHR Frequencies');
xlabel('Frequency (Hz)');
ylabel('cell count')

figure(3);
hist(wky_freq)
title('WKY Frequencies')
ylabel('cell count')
xlabel('Frequency (Hz)');
%%%%%%%%%%%%%% compare amplitude %%%%%%%%%%%%%
shr_amp= str2double(SHRTable.amplitude_mV_); %SHR threshold values for 1st AP detected
wky_amp = str2double(WKYTable.amplitude_mV_); 

[h,p,ci,stats] = ttest2(shr_amp,wky_amp,'Vartype','unequal')

% Interpret the results
if h == 1
    str='The mean AP amplitude differs significantly between the two strains.';
else
    str = 'There is no significant difference in the mean AP amplitude between the two strains.';
end

%make a new row in the table
newRow = {'AP_amplitude', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table


%%%%%%%%%%%%%% compare AHP amp %%%%%%%%%%%%%
shr_amp= str2double(SHRTable.AHP_amplitude_mV_); %SHR threshold values for 1st AP detected
wky_amp = str2double(WKYTable.AHP_amplitude_mV_); 

[h,p,ci,stats] = ttest2(shr_amp,wky_amp,'Vartype','unequal')

% Interpret the results
if h == 1
    str = ('The mean AHP amplitude differs significantly between the two strains.');
else
    str = ('There is no significant difference in the mean AHP amplitude between the two strains.');
end

%make a new row in the table
newRow = {'AHP_amplitude', p, alpha,str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table


%%%%%%%%%%%%%% compare AHP half width %%%%%%%%%%%%%
shr_ahw= str2double(SHRTable.half_width_AHP_ms_); %SHR threshold values for 1st AP detected
wky_ahw = str2double(WKYTable.half_width_AHP_ms_); 

[h,p,ci,stats] = ttest2(shr_ahw,wky_ahw,'Vartype','unequal')

% Interpret the results
if h == 1
    str=('The mean AHP half-width differs significantly between the two strains.');
else
    str=('There is no significant difference in the mean AHP half-width between the two strains.');
end

%make a new row in the table
newRow = {'AHP_half_width', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table



%%%%%%%%%%%%%% compare AP Half width %%%%%%%%%%%%%
shr_hw= str2double(SHRTable.half_width_ms_); %SHR threshold values for 1st AP detected
wky_hw = str2double(WKYTable.half_width_ms_); 

[h,p,ci,stats] = ttest2(shr_hw,wky_hw,'Vartype','unequal')

% Interpret the results
if h == 1
    str=('The mean AP half width differs significantly between the two strains.');
else
    str=('There is no significant difference in the mean AP half width between the two strains.');
end
%make a new row in the table
newRow = {'AP_half_width', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table



%%%%%%%%%%%%%% compare AHP 90-30% width %%%%%%%%%%%%%
shr_hw= str2double(SHRTable.AHP_width_90to30__ms_); %SHR threshold values for 1st AP detected
wky_hw = str2double(WKYTable.AHP_width_90to30__ms_); 

[h,p,ci,stats] = ttest2(shr_hw,wky_hw,'Vartype','unequal')

% Interpret the results
if h == 1
    str=('The mean AHP_width_90to30__ms_ differs significantly between the two strains.');
else
    str=('There is no significant difference in the mean AHP_width_90to30__ms_ between the two strains.');
end

%make a new row in the table
newRow = {'AHP_90-30%_width', p, alpha, str};
summaryTable = [summaryTable; newRow]; %add the new row to the summary table


%display summary data
summaryTable %show summary table

n_SHR = numel(shr_threshold); %no of SHR files
n_WKY = numel(wky_threshold); %no of WKY cells

numcells_eachgroup = ("Tested with " + n_SHR + " SHR cells and " + n_WKY + " WKY cells.");

display(numcells_eachgroup);

filenameExcelDoc = "summary_table_ttests_apr3.xlsx"
writetable(summaryTable, filenameExcelDoc, 'Sheet', 1); %export summary table to excel
writematrix(numcells_eachgroup, filenameExcelDoc, 'Sheet' ,2)