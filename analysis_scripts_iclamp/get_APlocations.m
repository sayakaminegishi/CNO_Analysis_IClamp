function [numAPs, aplocations] = get_APlocations(trace, threshold_slope)

% This function identifies all the peak locations in the given trace
% waveform. It identifies the peaks from APs.


% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 31, 2023


k = 250; %minimum peak distance between 2 spikes
all_dV = find(diff(trace) > threshold_slope);  %list of locations at which slope > threshold

%threshold_value = trace(all_dV(1)); 

threshold_value = trace(1) + 30; %baseline + 30 is amplitude criteria for AP detection 

[numAPs,aplocations] = findpeaks(trace,'MinPeakHeight', threshold_value, "MinPeakDistance", k, 'MinPeakProminence',5); %find peak values and their locations for all peaks above spike threshold

end