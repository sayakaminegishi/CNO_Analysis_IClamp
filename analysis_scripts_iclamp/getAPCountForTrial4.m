function [apCounts] = getAPCountForTrial4(filename1)
% Returns an array `apCounts` with the count of APs in each sweep of a single trial file.
% The length of `apCounts` corresponds to the number of sweeps in the file.

% Created by Sayaka (Saya) Minegishi, with some advice from ChatGPT.
% minegishis@brandeis.edu
% 2/26/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[dataallsweeps, si, h] = abf2load(filename1); % Load ABF file data


numSweeps = size(dataallsweeps, 3); % Total number of sweeps
apCounts = zeros(1, numSweeps); % Initialize AP count storage

si_actual = 1e-6 * si; % Convert sampling interval to seconds

% ASK USER PULSE START TIME AND DURATION FOR THIS CELL
prompt_start="Input pulse start time in ms after start of recording: ";
starttime_ms= input(prompt_start); %start time in ms

prompt_duration = "Enter the duration of the pulse (ms): ";
duration_ms = input(prompt_duration);

%convert to indices
starttime_idx = ms_to_sampleunits(si, starttime_ms);
duration_idx = ms_to_sampleunits(si, duration_ms);
endtime_idx = starttime_idx + duration_idx;


for sweep = 1:numSweeps
    % Extract data for the current sweep

    data = dataallsweeps(starttime_idx, endtime_idx, sweep); %extract only the part subjected to a pulse
    
    % Set AP detection parameters
    dV_thresh_mVms = 10; % AP threshold in mV/ms
    onems = si * 10^-3;  % ms/sample
    dV_thresh = dV_thresh_mVms * onems; % Convert threshold to mV/sample
    allowedDeviation = 40; % Noise filter threshold=40mv. 

    % Set minimum amplitude for AP detection
    minAmp = data(1) + allowedDeviation;

    % Detect spikes
    [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 5);

    % Store the count of detected APs
    apCounts(sweep) = numel(spikeLocations);
end

end
