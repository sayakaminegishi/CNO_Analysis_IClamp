%cleans the traces for each sweep stored in filename by getting rid of the
%transient spike at the beginning of each sweep. outputs a matrix called
%cleandata, where each row corresponds to the cleaned trace for a sweep (sweepnumber corresponds to the row number of the matrix).


%THIS CODE WORKS

%Originally created by: Sayaka (Saya) Minegishi
%Contact: minegishis@brandeis.edu
%Date: Sept 27 2023

function cleandata = clean_trace(filename)
    
    dataallsweeps=abf2load(filename); %loads the abf file of interest
    totalsweeps=size(dataallsweeps,3);
    transient_duration = 0.078 * (103224/10.3224); %the length of the transient. in sample units. Cuts off the first 0.078 seconds of sweep.


    numpointspersweep = size(dataallsweeps, 1); %size of first column, which is the total no. of points per sweep in this ABF file
    cleandata = zeros(totalsweeps, numpointspersweep - transient_duration); %matrix to store the cleaned sweeps
    % itereate through 
    
    for a = 1:totalsweeps
        
        data=dataallsweeps(:,1,a); %select sweep to analyze....data=dataallsweeps(:,1,9). this is the trace.
        clean_sweep = data(transient_duration + 1:numpointspersweep); %array to store the waveform of the cleaned sweep
        
        for b = 1:size(clean_sweep)
            cleandata(a, b) = clean_sweep(b); %store each element of clean_sweep to the overall matrix
        end
    end
end
       
        