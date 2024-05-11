function spikesPerBurst = get_SpikesPerBurst(log_isi_hist)
%%%%%%%% find ln(ISI) properties %%%%%%%%%%%%

% this function calculates the average number of spikes per burst

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Aug 27 2023



% Calculate average number of spikes per burst
V = log_isi_hist.Values;
E = log_isi_hist.BinEdges;
% Use islocalmax
L = islocalmax(V); %puts a 1 corresponding to index of any local maximums!!!
% Find the centers of the bins that islocalmax identified as peaks
left = E(L);
w = log_isi_hist.BinWidth; %width of a bar

areasOfPeaks = w * V(L); %areas of first and second peaks, respectively.
%ratio of peak areas = av number of spikes per burst, according to Selinger et al.
display(areasOfPeaks)
spikesPerBurst = areasOfPeaks(2)/areasOfPeaks(1);



end