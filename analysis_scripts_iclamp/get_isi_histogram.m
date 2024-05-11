function isi_histogram = get_isi_histogram(int_sp_intv, binwidth)
% this function returns a histogram object for interspike interval, and
% plots the histogram.
% int_sp_intv = array containing ISI interval values between consecutive
% spikes (could be found using find_isi.m)
% binwidth = desired binwidth of histogram (eg. 1ms based on Selinger)
% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Aug 25 2023
isi_histogram = histogram(int_sp_intv, 'BinWidth', binwidth); %make an ISI histogram and view properties
display(isi_histogram); %plot ISI histogram and display its properties
title('Inter-spike interval histogram for the sweep');
xlabel('Interspike interval (ms)'); 
ylabel('Count of spikes');
    
end