
%% CNO Experiment - Iclamp analysis

% Description: This script creates one excel file for controls, washout,
% and the treatment group, with each file containing the burst and average singlet
% AP properties of that section from all the files selected for analysis.

%Figures 2, 4 and 6 show the results for sections control, treatment and
%washout respectively.

%sheet 1 = burst properties for the particular section (control, washout
%etc)
%sheet 2 = singlet AP properties for the particular section

% Created by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: 5/11/2024

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all

% USER- FILL OUT THIS SECTION:

%DEFINE the sweeps corresponding to each condition type. e.g. [1:5] means
%the group (e.g. control group) stretches from sweeps 1 to 5 inclusive.
controlsweeps = [1:10]; %adjust these values as necessary!
expsweeps = [11:20];
washoutsweeps = [21:30];

%DEFINE the names of the control, treatmnet, and washout groups' output
%excel file names.
controlexcelfilename = "control_cno_may11summary.xlsx"; %control summary file name
treatmentexcelfilename = "treatment_cno_may11summary.xlsx"; %treatment summary file name
washoutexcelfilename = "washout_cno_may11summary.xlsx";%washout summary file name

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('analysis_scripts_iclamp/')  
savepath
mkdir tempdata %make a new folder to store the data files selected
    
dirname = pwd; %current working directory

disp(['Now working on directory ' dirname])

tempDir = fullfile(dirname, 'tempdata', filesep); % Folder to load data

get_files_from_user(dirname); %allow user to select files, then move the files to tempdata folder



%analyze each section

%controls
[burstTControl, singTControl, filesthatworkedcountControl] = CNO_analyze_group(dirname, tempDir, controlsweeps, controlexcelfilename) 

%treament group
[burstTTreatment, singTTreatment, filesthatworkedcountTreatment] = CNO_analyze_group(dirname, tempDir, expsweeps, treatmentexcelfilename)

%washout group
[burstTwash, singTwash, filesthatworkedcountwash] = CNO_analyze_group(dirname, tempDir,washoutsweeps, washoutexcelfilename)


%remove temp directory
rmdir(tempDir,'s')