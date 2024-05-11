function spikelocations = get_spikelocations(trace,threshold_value)
% This function identifies all the AP peaks in a given trace
% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 22, 2023

[pks,spikelocations] = findpeaks(trace,'MinPeakHeight', threshold_value, 'MinPeakProminence',5); %find peak values and their locations for all peaks above spike threshold

end