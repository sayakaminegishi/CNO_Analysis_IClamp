%This script finds the firing properties of the FIRST AP ever detected in a
%sweep with at least 2 APs
%from each cell in the directory, and exports the summary table as an excel
%file.

% Created by: Sayaka (Saya) Minegishi
% minegishis@brandeis.edu
% Apr 8 2024

 %start loading files
close all
clf 
clear 
%start loading files
filesNotWorking = []; %list of files with errors
list = dir('*.abf');%This script finds the firing properties of the FIRST AP ever detected
%from each cell in the directory, and exports the summary table as an excel
%file.

% Created by: Sayaka (Saya) Minegishi
% minegishis@brandeis.edu
% Apr 3 2024

 %start loading files
close all
clf 
clear 
%start loading files
filesNotWorking = []; %list of files with errors
list = dir('*.abf');
file_names = {list.name}; %list of all abf file names in the directory 

filenameExcelDoc = strcat('apr8_wkylastsw.xlsx');
myVarnames1= {'cell_name', 'current_injected(pA)','frequency(Hz)','spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)','AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)','risetime(ms)', 'decaytime(ms)' };

multipleVariablesTable= zeros(0,numel(myVarnames1));
multipleVariablesRow1 = zeros(0, numel(myVarnames1));

T1= array2table(multipleVariablesTable, 'VariableNames', myVarnames1); %stores info from all the sweeps in an abf file

current_injected = [-50:15:310];

for n=1:size(file_names,2)
    
   try   
   filename = string(file_names{n});
    disp([int2str(n) '. Working on: ' filename{:}])
   
         
         M1= analyzeSingleEvokedApr8_lastsweep(filename, current_injected);
         T1 = [T1; M1];
            
              
             
   catch

     fprintf('Invalid data in iteration %s, skipped.\n', filename);
    filesNotWorking = [filesNotWorking;filename];
   end
   

end
display(T1)

display(filesNotWorking)
filesthatworkedcount = size(file_names,2) - size(filesNotWorking, 1);
display(filesthatworkedcount + " out of " + size(file_names,2) + " traces analyzed successfully.");

writetable(T1, filenameExcelDoc, 'Sheet', 1); %export summary table to excel


%%%%%%%%%%%
display("Amplitude = " + mean(double(T1.("amplitude(mV)"))))
display("half width = " + mean(double(T1.("half_width(ms)"))))
display("AHP amp = " + mean(double(T1.("AHP_amplitude(mV)"))))
display("half width ahp = " + mean(double(T1.("half_width_AHP(ms)"))))
display("ahpwidth 90-30% = " + mean(double(T1.("AHP_width_90to30%(ms)"))))
display("risetime AP = " + mean(double(T1.("risetime(ms)"))));
