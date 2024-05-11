function isi = find_isi(allSpikeTimes)
% isi = an array containing the inter-spike intervals for consecutive
% spikes in allSpikeTimes.
% allSpikeTimes is an array containign the spike times in a sweep.


% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 25 2023

numspikes = numel(allSpikeTimes); %number of spikes in sweep
isi = zeros(1,numspikes-1); %array to store inter-spike intervals for the sweep

idx = 1; %to be used in assigning values to isi array

for i = 2:numspikes
    isi(idx) = allSpikeTimes(i) - allSpikeTimes(i-1); %calculate ISI
    idx = idx + 1; 
end


end