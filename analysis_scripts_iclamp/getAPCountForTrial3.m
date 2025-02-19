function [apCounts] = getAPCountForTrial3(filename1)
% Returns an array `apCounts` with the count of APs in each sweep of a single trial file.
% The length of `apCounts` corresponds to the number of sweeps in the file.

% Created by Sayaka (Saya) Minegishi, with some advice from ChatGPT.
% minegishis@brandeis.edu
% 2/18/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[dataallsweeps, si, h] = abf2load(filename1); % Load ABF file data


numSweeps = size(dataallsweeps, 3); % Total number of sweeps
apCounts = zeros(1, numSweeps); % Initialize AP count storage

si_actual = 1e-6 * si; % Convert sampling interval to seconds

for sweep = 1:numSweeps
    % Extract data for the current sweep
    data = dataallsweeps(:, :, sweep); 
    
    % Set AP detection parameters
    dV_thresh_mVms = 10; % AP threshold in mV/ms
    onems = si * 10^-3;  % ms/sample
    dV_thresh = dV_thresh_mVms * onems; % Convert threshold to mV/sample
    allowedDeviation = 40; % Noise filter threshold

    % Set minimum amplitude for AP detection
    minAmp = data(1) + allowedDeviation;

    % Detect spikes
    [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 5);

    % Store the count of detected APs
    apCounts(sweep) = numel(spikeLocations);
end

end
