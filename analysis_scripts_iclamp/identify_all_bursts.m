function burst_times = identify_all_bursts(allSpikeTimes)
%this function categorizes whether each spike (either AP or non-AP) is in a
%larger burst (composed of AP and/or non-AP spikes)

% allSpikeTimes = list of all spike locations to categorize 

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: August 22 2023

burst_allSpikeTimes = [];
burst_times = zeros(1,2);
w = 1000; 
n = 1000; %interspike interval 
countburst = 0;
countsingle = 0;
for i = 1:numel(allSpikeTimes)
    if(i == 1)
        if (allSpikeTimes(i + 1) - allSpikeTimes(i) < w)
           
            countburst = countburst + 1;
            burst_allSpikeTimes(countburst) = allSpikeTimes(i);
        else
           
            countsingle = countsingle + 1;
            single_allSpikeTimes(countsingle) = allSpikeTimes(i);
        end
    
   
    elseif(i >= 2 & i <numel(allSpikeTimes))
        if (allSpikeTimes(i + 1) - allSpikeTimes(i) < w) || (allSpikeTimes(i) - allSpikeTimes(i -1) < w)
            %spike is part of a burst with another spike
            countburst = countburst + 1;
            burst_allSpikeTimes(countburst) = allSpikeTimes(i);
        else
            %spike is single with respect to another spike
            countsingle = countsingle + 1;
            single_allSpikeTimes(countsingle) = allSpikeTimes(i);
        end

    else
        %if this is the last spike in allSpikeTimes
        if (allSpikeTimes(i) - allSpikeTimes(i -1) < w)
            
            countburst = countburst + 1;
            burst_allSpikeTimes(countburst) = allSpikeTimes(i);
        else
            
            countsingle = countsingle + 1;
            single_allSpikeTimes(countsingle) = allSpikeTimes(i);
        end
    end

end

%iterate through each loc in burst_allSpikeTimes and determine the start
%and end PEAK spike locs of each burst
%[PERHAPS USE CMA method]

first_spiketime_marker = -1; %-1 if the previous spike analyzed wasn't part of a burst
idx_f = 1;
idx_l = 1;


if(allSpikeTimes(2) - allSpikeTimes(1) < n) %if the two spikes are a part of a burst
    first_spiketime_b(idx_f) = allSpikeTimes(1); %time of first peak
    first_spiketime_marker = 1;
    idx_f = idx_f + 1;
end
       
%continue to identify bursts
for k = 2:numel(allSpikeTimes)
    if(allSpikeTimes(k) - allSpikeTimes(k-1) < n) %if the two spikes are a part of a burst
            if first_spiketime_marker == -1 %if previous spike wasn't a burst spike
                first_spiketime_marker = 1;
                first_spiketime_b(idx_f) = allSpikeTimes(k-1); %time of first peak
                idx_f = idx_f + 1;
            end
   
    else
        first_spiketime_marker = -1;
        last_spiketime_b(idx_l) = allSpikeTimes(k-1);
        idx_l = idx_l+1;
    end

    if (k==numel(allSpikeTimes) & first_spiketime_marker == 1)
        last_spiketime_b(idx_l) = allSpikeTimes(k);
    end

    
end



if (idx_f ~= 1 & idx_l ~= 1)

    for m = 1:idx_f-1
        burst_times(m, 1) = first_spiketime_b(m); %first peak time
        burst_times(m, 2) = last_spiketime_b(m); %last peak time
    end
end


end 