function P= APsInBurstMatrix(aplocations, burstTimesMatrix)
%stores AP spike peak times for each burst
%aplocations = locations of peak times of APs
%burstTimesMatrix = matrix with:
% 1st column: time location of peak for the first spike detected in a burst
% (the true start time of the burst is the time pt when the spike with this
% peak location first crosses lower/noise threshold).
% 2nd column: peak location of last spike detected in a particular burst (the true end time of the burst is the time pt when the spike with this
% peak location crosses lower/noise threshold for the final time before the next spike peak time).

% 3rd column: AP spike peak times detected in the burst range defined by
% columns 1 and 2 of the same row.

% Original script by: Sayaka Minegishi
% Contact: minegishis@brandeis.edu
% Date: September 16 2023


n = size(burstTimesMatrix,1); % no of rows in burstTimesMatrix, aka number of bursts
M= zeros(n, 2); %stores a n x 2 matrix where first column corresponds to a burst start time, 2nd column is burst endtime, and 3rd column contains peak times of APs from that burst. each cell stores a matrix.
C = cell(n, 1); %make an n x 1 cell array for storing ap spike times
P = cell(n, 3); %cell array matrix to store the final table

M(:,1) = burstTimesMatrix(:,1); %first column contains the burst time range
M(:,2) = burstTimesMatrix(:,2); %first column contains the burst time range

display(M)


for k = 1:n
    %loop through each burst range, find all AP spiketimes in that range
    starttime = burstTimesMatrix(k,1); %start time of burst (peak time of the first spike in burst)
    endtime = burstTimesMatrix(k,2); %end time of this particular burst
    J = []; %array to store the AP spike times found in this particular burst

    for a = 1:numel(aplocations)
        if (aplocations(a) <= endtime && aplocations(a) >= starttime)
            %this particular ap is in this particular burst range
            J = [J, aplocations(a)]; %add this AP to the list of APs in this burst
        end
    end
    C{k} = J; %array of AP peak times from kth burst
end

for i = 1:n
    P(i, :) = {M(i, 1), M(i, 2), C{i}}; %create new cell array to return
end

%return P, which contains burst range in first column (array 1x2) and AP
%times from that burst in an array.
 
%If a burst does not have an AP, omit that row from burstMatrix
for j = 1:n
    if isempty(P{j,3})
        P{j, 1} = {}; %delete row
        P{j, 2} = {};
        P{j,3} = {};
    end
end
   
