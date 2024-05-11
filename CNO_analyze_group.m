function [burstT, singT, filesthatworkedcount] = CNO_analyze_group(dirname, tempDir, sweepsvec, outputfilename)

%FOR ONE SECTION

%Description: Performs automatic AP/AHP analysis on one specified section (washout, control, treatment)
%separately for all abf files in tempdata folder, and give the information in 3 tables. includes burst analysis
%(for spikes within bursts, AHP properties are not determined since most of them don't have AHP).

%can be used for single file or batch analysis.

%tempdir = path to temp folder, which contains all the data files to
%analyze
%sweepsvec =sweep numbers for this particular group (e.g. [1:5] to select
%sweeps 1-5 for the controls).

%outputfilename = name (.xlsx) of excel output file for this group
%(treatmnet, control or washout)

%sectiontype = control, treatment, or washout

%OUTPUTS:
% An excel file with:
% sheet 1 = burst properties



% Created by Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Last modified: 5/11/2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filenameExcelDocC = fullfile(dirname, filesep, outputfilename); %default file name

addpath('analysis_scripts_iclamp/')  
savepath


 % Start loading files
    filesNotWorking = []; % List of files with errors
    list = dir(fullfile(tempDir, '*.abf'));
    file_names = {list.name}; % List of all abf file names in the directory

    for i = 1:numel(file_names)
        file_names{i} = fullfile(tempDir, file_names{i});
    end

   
    %table for summarizing burst properties
    myVarnamesBursts = {'cell name', 'threshold(mV)', 'average_ISI(ms)', 'AP_frequency(Hz)', 'total_AP_count_in_cell', 'count_of_bursts', 'count_of_singletAPs', 'average_burst_duration(ms)', 'freq_bursts(Hz)'};

    burstsTable= zeros(0,numel(myVarnamesBursts));
    burstsTableRow = zeros(0, numel(myVarnamesBursts));
    burstT= array2table(burstsTable, 'VariableNames', myVarnamesBursts); %stores info from all the sweeps in an abf file


    %table for summarizing average of singlet AP properties from each cell
    myVarnamesSing= {'threshold(mV)', 'duration(ms)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'peak value(mV)',  'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)'};

    %MAKE A TABLE WITH EMPTY VALUES BUT WITH HEADERS
    % Define headers
    headersSingT = {'spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)', 'AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)'};
    variableTypes = {'double', 'double', 'double', 'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double' , 'double' , 'double' }; % Adjust the data types as needed

    % Create an empty table with headers
    singT = table('Size', [0, numel(headersSingT)], 'VariableNames', headersSingT, 'VariableTypes', variableTypes);
    singT(:,[1,7]) = []; %delete irrelevant columns for averaged data
    filesNotWorking = [];

    for n=1:size(file_names,2)
 
        filename = string(file_names{n});
        disp([int2str(n) '. Working on: ' filename])

        %analyze control, treatment, and washout groups separately for this
        %file
        try
            [sar, T] = CMA_burst_analysis_selectedsweeps(filename, sweepsvec); %get burst and singlet analysis for thsi cell
            burstT = [burstT; T];
            singT = [singT; sar]; %for singlets
          

        catch
            fprintf('Invalid data in iteration %s, skipped.\n', filename);
            filesNotWorking = [filesNotWorking;filename];
        end

    end

    %add cell name column to singT
    newcolumn = burstT(:,1); %first column of burstT
    singT = [newcolumn, singT];
     filesthatworkedcount = size(file_names,2) - size(filesNotWorking, 1);
       disp(filesthatworkedcount + " out of " + size(file_names,2) + " files analyzed successfully.") 

      writetable(burstT, filenameExcelDocC, 'Sheet', 1); %export summary table for bursts to excel
    writetable(singT, filenameExcelDocC, 'Sheet', 2); %export summary table for singlets to excel


end