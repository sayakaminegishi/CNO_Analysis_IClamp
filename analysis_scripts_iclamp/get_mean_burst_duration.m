function avgduration = get_mean_burst_duration(burstTimesMatrix)
% calculates average duration of a burst, in sample units.

% Original script by: Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: Aug 27 2023


duration_list = burstTimesMatrix(:,2) - burstTimesMatrix(:,1);

avgduration = sum(duration_list)/numel(duration_list); %in sample units
end