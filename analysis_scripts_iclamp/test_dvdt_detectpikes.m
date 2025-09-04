
filename1 = "/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata/SHR/SHRN+glia/2023_02_01_01_0006.abf";

%this script gets AP counts and spike times using
%getSpikeTimesUsingDvDt)givenData.m by testing on the file filename1

% Load ABF file data
[dataallsweeps, si, h] = abf2load(filename1);  % or abfload(filename1)

% Create time vector (ms)
numSamples = size(dataallsweeps, 1);
timepoints = (0:numSamples-1) * si * 1e3; % convert sampling interval to ms

% Run AP detection
apCounts = getSpikeTimesUsingDvDt_givenData(dataallsweeps, timepoints) %gets AP counts and spike times using getSpikeTimesUsingDvDt)givenData.m

% Display results
disp(['AP counts for each sweep:']);
disp(apCounts);
