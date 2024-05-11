function [singleAP_SpikeTimes_final, refinedBurstMatrix_final] = refined_burstMatrix(burstMatrix, data, threshold_value, allSpikeTimes)

% this function studies each burst found using find_burstMatrix and
% filters each 'burst' interval to what is truly a burst and a list of
% single APs.
% threshold_value is the value of AP threshold, in mV

% refinedBurstMatrix is a n x 2 matrix where n = number of true bursts,
% first value is the spike peak time of the first spike in the burst, and second
% value is the spike peak time of the last spike in the burst.

% singleAP_SpikeTimes is a list containing the spike peak times of singlet
% APs in the trace that are not part of a burst. 

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Aug 30 2023


singleAP_SpikeTimes = [];
refinedBurstMatrix = [];

%condition for sngle APs: end of last burst interval == start of next
% burst interval

% see if first spike is a singlet or in a burst

if burstMatrix(1,2) == burstMatrix(2,1)
    singleAP_SpikeTimes = [singleAP_SpikeTimes; burstMatrix(1,1)]; %this is a singlet AP
else
    refinedBurstMatrix = [refinedBurstMatrix; [burstMatrix(1,1), burstMatrix(2,1)]];
end

% see if a particular spike is a singlet or in a burst
for n = 2:size(burstMatrix,1)-1
    burststart = burstMatrix(n,1);
    burstend = burstMatrix(n,2);

    if burststart == burstMatrix(n-1,2) || burstend == burstMatrix(n+1,1)
        singleAP_SpikeTimes = [singleAP_SpikeTimes; burststart]; %this is a singlet AP
    else
        refinedBurstMatrix = [refinedBurstMatrix; [burststart, burstend]]; %ask how to not shift values

    end

end

% see if last spike is a singlet or in a burst

if burstMatrix(end-1,2) == burstMatrix(end,1)
    singleAP_SpikeTimes = [singleAP_SpikeTimes; burstMatrix(end,1)]; %this is a singlet AP
else
    refinedBurstMatrix = [refinedBurstMatrix; [burstMatrix(end,1), burstMatrix(end,2)]];
end


% filter out any non-AP spikes from singleAP_SpikeTimes
singleAP_SpikeTimes_final = [];
for k = 1:numel(singleAP_SpikeTimes)
    if data(singleAP_SpikeTimes(k)) >= threshold_value
        singleAP_SpikeTimes_final = [singleAP_SpikeTimes_final;singleAP_SpikeTimes(k)]; %true singlet AP
    end
end

refinedBurstMatrix_final = refinedBurstMatrix;

% % filter out any bursts that don't have an AP in it
% refinedBurstMatrix_final = [];
% 
% 
% for j = 1:size(refinedBurstMatrix, 1) %go through each burst
% 
% 
%     starttime = refinedBurstMatrix(j,1); % peak time of initial spike in burst
%     endtime = refinedBurstMatrix(j,2);% peak time of final spike in burst
% 
% 
%     %find the elements in allSpikeTimes that are between starttime and
%     %endtime
%     beginidx = threshold_crossings(allSpikeTimes, starttime); %index for allSpikeTimes
%     finishidx = threshold_crossings(allSpikeTimes, endtime);
% 
%     for i = beginidx:finishidx
%         if data(allSpikeTimes(i)) >= threshold_value
%             refinedBurstMatrix_final= [refinedBurstMatrix_final; [starttime, endtime]]; %this is a true burst
%             return
%         end
% 
%     end
% 
% end