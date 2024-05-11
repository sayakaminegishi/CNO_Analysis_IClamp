%this script identifies action potentials and bursts in cleaned data (with
%sweeps). 
% It takes in cleaned data (i.e. electrophysiological recording
%with the first transient spike removed at the beginnign of each sweep),
%and the threshold slope for AP to be detected.


%Outputs:
% single_AP_matrix = stores the peak locations of all spikes that
%are not part of a burst in the particular trace.
% burst_AP_matrix = stores the peak locations of all spikes that is the
% first spike in a burst.
% burst_times_matrix_out = matrix where the first column stores the first
% spike peak time for a burst and the second column stores the spike peak
% time for the last spike in a burst.

%Original script by: Sayaka (Saya) Minegishi
%Contact: minegishis@brandeis.edu
%Date: AUG  22 2023

function [singleAPTimes, first_peak_burst, burst_times_matrix] = classify_spikes(sweep_data,dV_thresh)
w = 1500; %average width of an AP

AP_list = [];
burst_AP_matrix = []; %first peak location of a burst

burst_times_matrix = [];

%In each sweep, identify all spikes, and categorize them as single AP or a
%part of a burst.
data = sweep_data;
    
burst_times = zeros(1,2); %numbursts x 2 matrix that stores first spiketime and final spiketime in each burstin this sweep
singleAPTimes = zeros(1); %stores all the locations where there is a single AP (i.e. APs that are not part of a burst)
first_peak_burst = zeros(1);

all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold. USED TO DISTINGUISH AP SPIKES FROM BURST SPIKES

threshold_value = data(all_dV(1)); 


spikeTimes = get_spikelocations(data); %gives the number of spikes and the time locations of spikes INCLUDING BOTH BURST SPIKES AND AP
numberOfSpikes = numel(spikeTimes);
first_spiketime_marker = -1; %-1 if the previous spike analyzed wasn't part of a burst

idx_f = 1;
idx_l = 1;
idx_AP = 1;

AP_list(idx_AP) = spikeTimes(1); %we treat the first spike of the data as an AP at all times
idx_AP = 2;
singleidx = 1; %keeps track of how many single APs there are
boostcounter = 1;

%identify bursts
for k = 2:numberOfSpikes
    
    if(spikeTimes(k) - spikeTimes(k-1) < w) %if the two spikes are a part of a burst
        if first_spiketime_marker == -1
            first_spiketime_b(idx_f) = spikeTimes(k-1); %time of first peak
            idx_f = idx_f + 1;
        end
        
        last_spiketime_b(idx_l) = spikeTimes(k); %time of last peak in burst
        idx_l= idx_l+1;
    else
        if(ismember(spikeTimes(k), all_dV) == 1)
            first_spiketime_marker = -1;
            AP_list(idx_AP) = spikeTimes(k); %count it as an AP if it's not part of a burst AND is part of all_dV
            idx_AP = idx_AP +1;
        end
    end
end

if (idx_f ~= 1 & idx_l ~= 1)

    for m = 1:idx_f-1
        burst_times(m, 1) = first_spiketime_b(m); %first peak time
        burst_times(m, 2) = last_spiketime_b(m); %last peak time
    end
end



% store APs that are part of a burst in an array different from the
% %APs that are not at the begining of bursts


for c = 2:numberOfSpikes-1
    if((abs(spikeTimes(c) -spikeTimes(c-1))>w)  & (abs(spikeTimes(c+1) -spikeTimes(c)) > w)) 
        singleAPTimes(singleidx) = spikeTimes(c);
        singleidx = singleidx + 1;
    end
end
%consider last spike as a single AP if distance to the second last
%spike is greater than w.
if(spikeTimes(numberOfSpikes) - spikeTimes(numberOfSpikes - 1) > w)
    singleAPTimes(singleidx) = spikeTimes(numberOfSpikes);
    singleidx = singleidx + 1;
end

%TODO: create an array to store APs that are part of a burst. for
%elements in AP_list_matrix that are not also in singleAPTimes matrix,
%put the elements in burst_AP_matrix.
% for d = 1:numel(AP_list)
%     if()



first_peak_burst = burst_times(:,1); %stores time locations of all the 1st spike in a burst TODO: Or should I define Action potentials by AHP? by going through each spike in trace and identifying those that are a part of a burst AND meets AHP presence condition?
burst_times_matrix = [burst_times_matrix; burst_times];%search how to best separate matrices from different sweeps



%the function was initially returning AP_list_matrix and
%burst_times_matrix.
end


