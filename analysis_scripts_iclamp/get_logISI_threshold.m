function ln_ISI_thresh = get_logISI_threshold(log_isi_hist)

% finds the ln(ISI) threshold for burst detection. Each series of spikes
% whose ln(ISI) are less than the threshold is a burst. A new burst starts
% after an interval above the threshold.

% Original Script by: Sayaka (Saya) Minegishi / minegishis@brandeis.edu 
% Aug 26 2023
% created based on an algorithm by Jonathan V. Selinger et al. (2007) and with inspirations
% from Steven Lord
% https://www.mathworks.com/matlabcentral/answers/536931-is-there-s-a-way-to-automatically-find-peaks-in-an-histogram.



%%%%%%%% find ln(ISI) properties %%%%%%%%%%%%

V = log_isi_hist.Values;
E = log_isi_hist.BinEdges;
% Use islocalmax
L = islocalmax(V); %puts a 1 corresponding to index of any local maximums!!!
% Find the centers of the bins that islocalmax identified as peaks
left = E(L);
right = E([false L]);
center = (left + right)/2; %center values, in ln(ISI), for the time-scale peaks

% Plot markers on those peak bins
hold on
plot(center, V(L), 'o') %plot peak pts

intraburst_lnISI = mean(center(1:end-1));% ln(ISI) within bursts. if more than 1 intraburst peak found, take avg.
interburst_lnISI = center(end); % ln(ISI) between bursts

% %find the value of E (bin edge) corresponding to min value between two peaks
display(left)
display(right)
% ind1 = find(E==left); %first peak index
% ind2 = find(E==right); %last peak index
% 
% display(ind1)
%display(ind2)

[minVal, minValLoc] = min(V(left:right));
minValLoc= minValLoc + left; %the actual index at which min occurs

ln_ISI_thresh = E(minValLoc); %LOG THRESHOLD

end