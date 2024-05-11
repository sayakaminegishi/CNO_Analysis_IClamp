function [log_isi_histogram] = get_log_isi_histogram(int_sp_intv, bw)

%TODO: change to [log_isi_histogram, intraburst_dist, interburst_dist, avg_spikes_per_burst] = get_log_isi_histogram(int_sp_intv, nbins)
 
% this function returns a histogram object for the (natural) log of interspike interval, and
% plots the logarithmic ISI histogram.
% int_sp_intv = array containing ISI interval values between consecutive
% spikes (could be found using find_isi.m)
% bw = binwidth
%intraburst_dist = interval within bursts
% interburst_dist = interval between bursts.  

% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Oct 2 2023


%resources used: https://www.researchgate.net/publication/322949789_Burst_detection_methods

log_isi_histogram = histogram(log(int_sp_intv), BinWidth = bw); %make an ISI histogram and view properties

display(log_isi_histogram); %plot log(ISI) histogram and display its properties
title('Logarithmic inter-spike interval histogram for the sweep');
xlabel('ln(Interspike interval)'); %in number of sample points. TODO: CLARIFY TIME SCALE
ylabel('Count of spikes');

    
end