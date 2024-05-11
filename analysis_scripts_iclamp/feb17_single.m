
% burst and singlet analysis on a specific abf file
% performs linear ADJUSTMENT of baseline 

% Created by Sayaka (Saya) Minegishi 
% minegishis@brandeis.edu
% Feb 17 2024

%start loading files
close all
clf 
clear 
%start loading files
filesNotWorking = []; %list of files with errors

filenameExcelDoc = strcat('single_luther_1.xlsx');

multipleVariablesTable= zeros(0,23);
multipleVariablesRow = zeros(0, 23);


myVarnames1 = {'cell name', 'AP_frequency(Hz)', 'threshold (mV)', 'amplitude (mV)', 'AHP amplitude (mV)', 'first trough value (mV)', 'first trough location(ms)', 'first spike peak value(mV)', 'first spike location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)', 'AHP_width_90to30%(ms)', 'AHP_10to90%(ms)', 'Avg_ISI_first_half_of_data(ms)', 'Avg_ISI_last_half_of_data(ms)'};
T1= array2table(multipleVariablesTable, 'VariableNames', myVarnames1); %stores info from all the sweeps in an abf file


filename1 = "2016_09_08_03_0003.abf";


[dataallsweeps, si, h] =abf2load(filename1); %get si and h values from this abf file


totalsweeps=size(dataallsweeps,3); %the total number of sweeps to be analyzed (25)

%THRESHOLD SLOPE
dV_thresh = 40/ms_to_sampleunits(si, 1); %10mV/ms.  marian: 4

data = combine_sweeps(dataallsweeps); %combine the data for the whole trace in 1 single sweep (array)
x_axis_actual = sampleunits_to_ms(si, 1:numel(data)); %in ms

%plot graph
figure(10)
plot(x_axis_actual, data)
hold on
xlabel('time (ms)')
ylabel('membrane potential (mV)')
hold off

%[singletAnalysisRow, T]= CMA_burst_analysis_Nov22(filename1);
[singletAnalysisRow, T]= CMA_burst_analysis_feb17(filename1);


singletAnalysisRow %analysis of the first AP from this trace
T %burst and spike properties, for whole trace.
