clear
clf

filenameExcelDoc = "cno_analysis3_example.xlsx"; %name of excel output table


myVarnames = {'cell name', 'average_threshold(mV)', 'average_ISI(ms)', 'AP_frequency(avg counts of AP per sweep)', 'total_AP_count_in_cell'};

multipleVariablesTable= zeros(0,size(myVarnames, 2));
multipleVariablesRow = zeros(0,size(myVarnames, 2));
T= array2table(multipleVariablesTable, 'VariableNames', myVarnames); %stores info from all the sweeps in an abf file

 
    filename1 = '2023_03_21_02_0008.abf'; %file to work on


    cleandata = clean_trace(filename1); 
    [dataallsweeps, si, h] =abf2load(filename1); %loads the abf file of interest. si =  the sampling interval in us
    totalsweeps=size(dataallsweeps,3); %the total number of sweeps to be analyzed (25)
   
    %dataallsweeps d (first output) gives 3d array of size (data pts per sweep) x (no. of channels) x (no.of
    %sweeps).
    numpointspersweep = size(dataallsweeps, 1); %size of first column, which is the total no. of points per sweep in this ABF file
    
   
    numspikes = 0;
    dV_thresh = 3; %THRESHOLD SLOPE

    mean_isi_list = [];
    mean_freq_list = [];
    total_count_Aps = 0; %total count of APs in this file
    thresh_list = []; %list of threshold from each sweep
    
    % itereate through 
    
    for b = 1:10
        
        sweepofinterest = b; %the sweep that we want to examine

        dV_thresh = 3;
       
        data = cleandata(sweepofinterest, :); %load sweep data. this is the trace for sweep
        plot(data)
        
        all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold

        if (numel(all_dV) ~= 0 & all_dV(1) < 5910) %if an action potential is detected, analyze the SWEEP
           
            threshold_value = data(all_dV(1)); %threshold for AP detection
            allSpikeTimes = get_spikelocations(data, threshold_value); %get AP spike times
            
            %plot AP spike times 
            plot(data)
            hold on
            plot(allSpikeTimes, data(allSpikeTimes), 'r*')
            hold off

            int_sp_intv = find_isi(allSpikeTimes); %get an array of interspike intervals for the sweep
         
            mean_isi = mean(int_sp_intv); % MEAN ISI FOR THIS SWEEP
           
            % FREQUENCY OF AP IN THIS SWEEP
            [pks,locs] = findpeaks(data,MinPeakDistance=250);

            frequency1 = 1/numel(locs); 
            frequency = sampleunits_to_ms(si, frequency1); %convert to ms
           
            total_count_Aps = total_count_Aps + numel(locs); %update total count of APs detected from this cell
            
            % convert all output variables from sample units to ms
            dV_thresh = dV_thresh * 1/(si * 0.001); %threshold slope, in mV/ms
            mean_isi = sampleunits_to_ms(si, mean_isi); %mean interspike interval, in ms
            
            % summarize info in separate arrays for each property

            mean_isi_list(b) = mean_isi;
            mean_freq_list(b) = frequency;
            thresh_list(b)= threshold_value;

        end
    end
    
    %find the average of the properties for this particular cell
    avg_threshold_value = mean(thresh_list, 'omitnan'); %average threshold value across sweeps
    avg_isi = mean(mean_isi_list, 'omitnan'); %avg ISI across all sweeps (average of the average of isi from each sweep)
    avg_frequency = mean(mean_freq_list, 'omitnan');

    %create table row for the cell
    
    multipleVariablesRow= [filename1, avg_threshold_value, avg_isi, avg_frequency, total_count_Aps];
    M= array2table(multipleVariablesRow, 'VariableNames', myVarnames);
    
    T = [T; M]; %store in a bigger table with all other files for comparison


    display(T)
    writetable(T, filenameExcelDoc, 'Sheet', 1); %export summary table to excel