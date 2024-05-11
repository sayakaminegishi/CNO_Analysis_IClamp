function APspikelocations = get_APspikelocations(trace, threshold_value)
% This function identifies all the peak locations in the given trace
% waveform. It identifies the peaks from spikes an action potential. 
%threshold_value = threshold for AP detection


% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: September 26, 2023


k = 250; %minimum peak distance between 2 spikes

spike_threshold_val = threshold_value; %all spikes must be at least 10 mV above resting potential
x = numel(trace);
[pks,spikelocations] = findpeaks(trace,'MinPeakHeight', spike_threshold_val, "MinPeakDistance", k, 'MinPeakProminence',5); %find peak values and their locations for all peaks above spike threshold
% for i = 1:numel(spikelocations)
%     if()
end