function Apr8_batchEVOKED(datadir,outputfile, last_only)

%This script finds the firing properties of the FIRST AP ever detected in a
%sweep with at least 2 APs
%from each cell in the directory, and exports the summary table as an excel
%file.

% Created by: Sayaka (Saya) Minegishi with support from Dr. Stephen Van
% Hooser
% minegishis@brandeis.edu
% Apr 12 2024

if nargin<3,
    last_only = 0;
end;

%  %start loading files - below commented script worked on VHlab computer
% close all
% 
% analysis_dir = [userpath filesep 'tools' filesep 'AP_AHP_Analysis_Iclamp_SayaMinegishi' filesep 'analyses'];
% 
% dirname = [userpath filesep 'tools' filesep 'AP_AHP_Analysis_Iclamp_SayaMinegishi' filesep 'data' filesep datadir];
% 
% disp(['Now working on directory ' dirname])
% 
% %start loading files
% filesNotWorking = []; %list of files with errors
% list = dir([dirname filesep '*.abf']);%This script finds the firing properties of the FIRST AP ever detected
% %from each cell in the directory, and exports the summary table as an excel
% %file.
% file_names = {list.name}; %list of all abf file names in the directory 
% for i=1:numel(file_names),
%     file_names{i} = [dirname filesep file_names{i}];
% end;
% 
% filenameExcelDoc = strcat([analysis_dir filesep outputfile]);

 %start loading files
close all

analysis_dir = fullfile(userpath, filesep, 'Projects', filesep, 'AP_AHP_Analysis_Iclamp_SayaMinegishi', filesep, 'analyses');

dirname = fullfile(userpath,filesep,  'Projects', filesep,'AP_AHP_Analysis_Iclamp_SayaMinegishi', filesep, 'data', filesep, datadir);


disp(['Now working on directory ' dirname])

%start loading files
filesNotWorking = []; %list of files with errors
list = dir(fullfile(dirname, filesep, '*.abf'));%This script finds the firing properties of the FIRST AP ever detected
%from each cell in the directory, and exports the summary table as an excel
%file.
file_names = {list.name}; %list of all abf file names in the directory 
for i=1:numel(file_names),
    file_names{i} = fullfile(dirname, filesep, file_names{i});
end;

filenameExcelDoc = fullfile(analysis_dir, filesep, outputfile);
myVarnames1= {'cell_name', 'current_injected(pA)','frequency(Hz)','spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)','AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)','risetime(ms)', 'decaytime(ms)' };

multipleVariablesTable= zeros(0,numel(myVarnames1));
multipleVariablesRow1 = zeros(0, numel(myVarnames1));

T1= array2table(multipleVariablesTable, 'VariableNames', myVarnames1); %stores info from all the sweeps in an abf file

current_injected = [-50:15:310];

for n=1:size(file_names,2)
    
  filename = string(file_names{n});
  disp([int2str(n) '. Working on: ' filename{:}])
   
   try
       M1= analyzeSingleEvokedApr8(filename, current_injected,last_only);
       if isempty(M1),
        fprintf('Invalid data in iteration %s, skipped.\n', filename);
        filesNotWorking = [filesNotWorking;filename];
       else,
           T1 = [T1; M1];
       end
       display(T1)
   catch
       %skip file if the file is invalid
       fprintf("invalid data in %s", filename)
       filesNotWorking = [filesNotWorking;filename];
   end

   

end

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
display("threshold = " + mean(double(T1.("threshold(mV)"))));
