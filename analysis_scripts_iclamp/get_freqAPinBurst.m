function freq = get_freqAPinBurst(APsInEachBurst_Matrix)

% calculates the average frequency of AP firing per burst from a sweep
% Original script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% date: september 16 2023

freqlist = []; %stores ap frequencies for each burst
%go through each row (burst)
for i = 1:size(APsInEachBurst_Matrix, 1)
    row = APsInEachBurst_Matrix{i, 3}; %gets the AP peak times from this particular burst
    
    numap =size(row,2); %get the number of APs observed from this burst
    display(APsInEachBurst_Matrix{i, 2})

    if isa(class(APsInEachBurst_Matrix{i, 2}), 'double') && isa(class(APsInEachBurst_Matrix{i,1}), 'double') %if not a cell
        display("entered if statement because both values are double")
        display(APsInEachBurst_Matrix{i, 2} - APsInEachBurst_Matrix{i, 1})
        duration1 = APsInEachBurst_Matrix{i, 2} - APsInEachBurst_Matrix{i, 1}; %total duration of burst, approximated since some non-AP spikes in burst lack AHP
        apfreq = numap/duration1; %no. of APs per unit of time (in units of samples)
        freqlist = [freqlist, apfreq];
    end
   


end

freq = mean(freqlist); %average frequency
end