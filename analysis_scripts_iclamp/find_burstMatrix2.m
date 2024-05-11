function [singleAP_SpikeTimes, refinedBurstMatrix_final] = find_burstMatrix2(data, allSpikeTimes, ISI_thresh)

% refinedBurstMatrix_final has the peak location of initial spike and the
% final spike in a burst. singleAP_SpikeTimes_final lists the peak times of
% all singlet APs (i.e. APs that are not part of bursts).

% data = trace
%allSpikeTimes = array containing all peak locations
% ISI thresh = threshold interspike interval 
%AP_thresh  = threshold in mV for AP detection


% Script created by Sayaka (Saya) Minegishi with guidance from Dr. Stephen Van
% Hooser
% Contact: minegishis@brandeis.edu
% Date: Aug 30 2023

burst_threshold = ISI_thresh;
spiketimes = allSpikeTimes;

isi = diff(spiketimes); %list of all interspike intervals in trace

in_burst = 0; %0 if spike is not a part of a burst
burst_matrix = [];

for i=2:numel(spiketimes)
    isi_here = spiketimes(i)-spiketimes(i-1); %current ISI

    if isi_here<burst_threshold
        if in_burst == 0
            burst_matrix(end+1,[1 2]) = [spiketimes(i-1) NaN];
        end
        in_burst = 1;
    else
        if in_burst
            burst_matrix(end,2) = spiketimes(i-1);
        else
            burst_matrix(end+1,[1 2]) = [spiketimes(i-1) NaN];
        end
        in_burst = 0;
    end
end

if in_burst 
    burst_matrix(end,2) = spiketimes(end);
end

% sort burst_matrix entries to singleAP_SpikeTimes_final and refinedBurstMatrix_final
singleAP_SpikeTimes = [];
refinedBurstMatrix_final = [];

for k = 1:size(burst_matrix, 1)
    if ~isnan(burst_matrix(k,2))
        refinedBurstMatrix_final = [refinedBurstMatrix_final; [burst_matrix(k,1),burst_matrix(k,2)]];
    else
        singleAP_SpikeTimes = [singleAP_SpikeTimes; burst_matrix(k,1)];
    end
end

end




