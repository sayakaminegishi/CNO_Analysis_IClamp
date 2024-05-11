function averageduration = find_mean_burst_duration_exact(burstTimesMatrix, data)

% calculates average duration of a burst, in sample units. 



% Original script by: Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: Aug 31 2023


%the start pt is where first spike reaches non-AP spike
% threshold, and the end pt is where the last spike reaches non-AP spike
% threshold for the first time after peak time. the duration is the
% distance between the start pt and the end pt. 


% baseline_thresh is the threshold for any spike detection (whether it be
% AP or nonAP)
baseline_thresh = 10 + data(1);

burst_duration_list = []; %stores the duration of each burst in this sweep

lastspikeendpt = 1; %location where last burst ended



for i = 1:size(burstTimesMatrix,1) %go through each burst
    startpeaktime = burstTimesMatrix(i, 1); %peak location for first spike in burst
    finalpeaktime = burstTimesMatrix(i, 2); % peak location for last spike in burst
    
    %start time of next burst
    if i ~= size(burstTimesMatrix,1)
        nextstarttime = burstTimesMatrix(i+1,1);
    else
        nextstarttime = numel(data); %end of trace
    end

    %find exact start pt
    [~, ind_start] = min(abs(data(lastspikeendpt:startpeaktime)-baseline_thresh));
    ind_start = ind_start + lastspikeendpt -1; 

    %find exact end pt
    [~, ind_end] = min(abs(data(finalpeaktime:nextstarttime)-baseline_thresh));
    ind_end = ind_end + finalpeaktime -1; 

    lastspikeendpt = ind_end; %update last spike end pt

    %find burst duration
    burst_dur = ind_end - ind_start;

    burst_duration_list = [burst_duration_list; burst_dur]; %add the new burst duration to the collection


end

%calculate average burst duration



averageduration = mean(burst_duration_list);




end