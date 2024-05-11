function [maxISI, minISI, meanISI, STD_ISI, medianISI, cumulativeHist, CMA] = get_ISI_properties(isi, isi_histogram, allSpikeTimes)

% inspired by InterSpikeInformation.m written by Kapucu et al.
% isi = interspike intervals for consecutive spikes in the sweep
% allSpikeTimes = array that stores the peak time locations of all spikes
% in sweep of interest
%data = waveform of the sweep of interest

%maximum isi
maxISI = max(isi);

%minimum isi
minISI = min(isi);

%mean isi
meanISI = mean(isi);

%std
STD_ISI = std(isi);

%median isi
medianISI = median(isi);

%cumulative sum
[counts, bins] = histcounts(isi);
cumulativeHist = cumsum(counts); %area


%CMA - cumulative moving average
CMA = cumulativeHist ./numel(allSpikeTimes); %average spike count




end