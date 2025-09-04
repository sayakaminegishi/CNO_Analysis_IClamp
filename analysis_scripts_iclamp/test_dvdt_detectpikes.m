close all;
filename1 = "/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata/SHR/SHRN+glia/2023_02_01_01_0006.abf";

% This script gets AP counts and spike times for the 25th sweep
% using getSpikeTimesSingleSweep.m

% Load ABF file data
[dataallsweeps, si, h] = abf2load(filename1);  % or abfload(filename1)

% Create time vector (ms)
numSamples = size(dataallsweeps, 1);
timepoints = (0:numSamples-1) * si * 1e3; % convert sampling interval to ms

% Extract the 25th sweep (first channel)
data25 = squeeze(dataallsweeps(:, 1, 25));

% Run AP detection on the 25th sweep
[apCount, spikeTimes] = getSpikeTimesSingleSweep(data25, timepoints);

% Display results
disp(['AP count for sweep 25: ', num2str(apCount)]);
disp('Spike times (ms):');
disp(spikeTimes);




% filename1 = "/Users/sayakaminegishi/Documents/Birren Lab/2025/CNOdata/SHR/SHRN+glia/2023_02_01_01_0006.abf";
% 
% %this script gets AP counts and spike times using
% %getSpikeTimesUsingDvDt_givenData.m by testing on the file filename1
% 
% % Load ABF file data
% [dataallsweeps, si, h] = abf2load(filename1);  % or abfload(filename1)
% 
% % Create time vector (ms)
% numSamples = size(dataallsweeps, 1);
% timepoints = (0:numSamples-1) * si * 1e3; % convert sampling interval to ms
% 
% % Run AP detection
% %[apCounts, spiketimes]= getSpikeTimesUsingDvDt_givenData2(dataallsweeps, timepoints) %gets AP counts and spike times using getSpikeTimesUsingDvDt)givenData.m
% [apCounts, spiketimes]= getSpikeTimesSingleSweep(dataallsweeps, timepoints) %gets AP counts and spike times using getSpikeTimesUsingDvDt)givenData.m
% 
% % Display results
% disp(['AP counts for each sweep:']);
% disp(apCounts);
% disp(['spiketimes: '])
% disp(spiketimes);