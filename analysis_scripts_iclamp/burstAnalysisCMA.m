
%analyzes a given abf file to find its freq, isi.
% created by Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: 9/26/23

close all
clf 
clear 

filenameExcelDoc = "burst_analysis21.xlsx"; %name of excel output table

filename1 = "Pvalb_PFC_example.abf";

myVarnames = {'cell name', 'average_threshold(mV)', 'average_ISI(ms)', 'AP_frequency(avg counts of AP per sweep)', 'total_AP_count_in_cell'};

multipleVariablesTable= zeros(0,size(myVarnames, 2));
multipleVariablesRow = zeros(0,size(myVarnames, 2));
T= array2table(multipleVariablesTable, 'VariableNames', myVarnames); %stores info from all the sweeps in an abf file

cleandata = clean_trace(filename1); 
[dataallsweeps, si, h] =abf2load(filename1); %loads the abf file of interest. si =  the sampling interval in us
totalsweeps=size(dataallsweeps,3); %the total number of sweeps to be analyzed (25)

%dataallsweeps d (first output) gives 3d array of size (data pts per sweep) x (no. of channels) x (no.of
%sweeps).
numpointspersweep = size(dataallsweeps, 1); %size of first column, which is the total no. of points per sweep in this ABF file


numspikes = 0;
dV_thresh = 3; %THRESHOLD SLOPE

isi_list = []; %array of interspike intervals from all sweeps
freq_list = []; %stores count of APs in each sweep, stores it in an array to represent data from all sweeps
total_count_Aps = 0; %total count of APs in this file
thresh_list = []; %list of threshold from each sweep

% itereate through 

for b = 1:1 %limit number of sweeps
    int_sp_intv = [];
    sweepofinterest = b; %the sweep that we want to examine

    dV_thresh = 3;
   
    data = cleandata(sweepofinterest, :); %load sweep data. this is the trace for sweep
    %plot(data)
    
    all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold

    if (numel(all_dV) ~= 0 & all_dV(1) < 5910) %if an action potential is detected, analyze the SWEEP
       
        %set threshold for noise
        threshold_value = data(all_dV(1)); %threshold for AP detection
        allSpikeTimes = get_spikelocations(data); %get AP spike times
        
        %plot AP spike times 
        figure(b);
        plot(data)
        hold on
        plot(allSpikeTimes, data(allSpikeTimes), 'r*')
        hold off

        int_sp_intv = find_isi(allSpikeTimes); %get an array of interspike intervals for the sweep
        
        %convert each element in int_sp_intv to ms
        for i = 1:numel(int_sp_intv)
            int_sp_intv(i) = sampleunits_to_ms(si, int_sp_intv(i));
        end
        isi_list = cat(2, isi_list, int_sp_intv); % concatenate arrays to add the new ISIs from this sweep to isi_list
       
        % FREQUENCY OF AP IN THIS SWEEP (in terms of counts of AP per
        % sweep)
        
        frequency1 = numel(allSpikeTimes); 
        
        total_count_Aps = total_count_Aps + numel(allSpikeTimes); %update total count of APs detected from this cell
        
        % convert all output variables from sample units to ms
        dV_thresh = dV_thresh * 1/(si * 0.001); %threshold slope, in mV/ms
        
        
        % summarize info in separate arrays for each property
        freq_list(b) = frequency1;
        thresh_list(b)= threshold_value;


        % ISI histogram
        figure;
        isi_histogram = get_isi_histogram(isi_list, 1) % 1ms bin width, based on Selinger et al.
        %isi_histogram = get_isi_histogram(isi_list, 8) % 1ms bin width, based on Selinger et al.
        
        %%%%%%%%%%%%% CMA BASED ON KAPUCU ET AL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        H = histcounts(isi_list, 'BinWidth', 1); %histogram of isi_list
        CH = cumsum(H); %cumulative sum of the ISI histogram at Ith ISI bin
        
        numbins = isi_histogram.NumBins; %I values. Ith bin
        Ibins = isi_histogram.BinEdges; %bin edge values of the ISI histogram
        
        % store the bin values as the center value (midpoint) of the bin
        b = 1; %index to use in the for loop below
        Ibins_centered = zeros(numbins);
        toadd = double((isi_histogram.BinWidth)/2);
        for j = 1:numbins 
            Ibins_centered(j) = Ibins(b) + toadd; 
            b = b+1;
        end
        
        Ibins_centered = Ibins_centered(:,1);
        
        
        
        Ivals = zeros(numbins);
        %fill Ivals array
        for i = 1:numbins
            Ivals(i) = i;
        end
        
        %calculate CMA and store in array
        CMAarray = zeros(numbins);
        for k = 1:numbins
            CMA = (1/Ivals(k)) * CH(k);
            CMAarray(k) = CMA;
        end
        CMA_list = CMAarray(:,1); %this contains the data that we want
        
        figure;
        plot(CMA_list) %plot CMA
        title('CMA curve')
        xlabel('ISI (ms)') 
        ylabel('Average Spike Count, Cumulative') 
        
        %find maximum value of CMA (CMAm)
        CMAm = max(CMA_list);
        
        %find the ISI value/binvalue that gives CMAm
        m = find(CMA_list == CMAm); %find the index of the bin of interest
        Xm = Ibins_centered(m); %the center value of the mth bin, which contains the ISI that gives max CMA. Maximum value of CMA curve, CMAm, is reached at the ISI xm 
        
        %%% strengthen the accuracy of ISI burst threshold by incorporating alpha1
        %%% and alpha 2 values
        
        % calculate the skewness of ISI histogram
        skw = skewness(isi_histogram.Data); %skewness of interspike intervals in trace
        
        % find the alpha1 and alpha2 values based on the skewness
        
        alpha1 = find_alpha1(skw);
        alpha2 = find_alpha2(skw);
        
        % find inter-burst ISI threshold (i.e. ISI threshold for individual spikes)
        % "ISI threshold xt for bursting was found at the ISI corresponding to the
        % CMA value closest to α·CMAm" (Kapucu et al. 2012)
        
        ISI_interburst_CMA = alpha1 * CMAm %average (cumulative moving) spike count at threshold 
        % FIND bin center CLOSEST TO ISI_interburst_CMA.
        
        [ISI_interburst_thresh_idx,~] = find_nearest_value(ISI_interburst_CMA, CMA_list);
        ISI_interburst_thresh = Ibins_centered(ISI_interburst_thresh_idx);
        
        %find ISI threshold for burst-related spikes
        ISI_brelated_CMA = alpha2 * CMAm
        % FIND bin center closest
        
        [ISI_brelated_thresh_idx,~] = find_nearest_value(ISI_brelated_CMA, CMA_list);
        ISI_brelated_thresh = Ibins_centered(ISI_brelated_thresh_idx); %find the ISI corresponding to this nearest value of CMA
        
        display(ISI_interburst_thresh)
        display(ISI_brelated_thresh)
        

        
        %%%%%%%%%%%%%% 
        % burst times and singlet AP times (measured as location of peak)
        %[singletTimesMatrix, burstTimesMatrix] = find_burstMatrix2(allSpikeTimes, ISI_interburst_thresh)
        
        [singletTimesMatrix, burstTimesMatrix] = find_burstMatrix2(data, allSpikeTimes, ISI_interburst_thresh)

        %plot corrected burst times and singlet AP times
        figure;
        plot(data)
        hold on
        plot(singletTimesMatrix, data(singletTimesMatrix), 'ko')
        
        legend({'Data', 'Singlet APs'}, 'FontSize', 5, 'Location', 'southeast')
        hold off
        %picname = "sweep_"+ b+"_plot_" + filename1 + ".pdf"; %file name for the figure
        %saveas(gcf,picname)
        
        %plot burst start andend times
        if ~isempty(burstTimesMatrix)
            figure;
            plot(data)
            hold on
            plot(burstTimesMatrix(:,1), data(burstTimesMatrix(:,1)), 'ro')
            plot(burstTimesMatrix(:,2), data(burstTimesMatrix(:,2)), 'rdiamond')
            legend({'Data', 'Burst Start Times','Burst End Times'}, 'FontSize', 5, 'Location', 'southeast')
            hold off
            %picname = "sweep_"+ b+"_BURSTplot_" + filename1 + ".pdf"; %file name for the figure
            %saveas(gcf,picname)
        end
            
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    end
end

%find the average of the properties for this particular cell
avg_threshold_value = mean(thresh_list, 'omitnan'); %average threshold value across sweeps
avg_isi = sum(isi_list)/numel(isi_list); %avg ISI across all sweeps 

avg_frequency = mean(freq_list, 'omitnan');

%create table row for the cell

multipleVariablesRow= [filename1, avg_threshold_value, avg_isi, avg_frequency, total_count_Aps];
M= array2table(multipleVariablesRow, 'VariableNames', myVarnames);

T = [T; M]; %store in a bigger table with all other files for comparison


display(T)
writetable(T, filenameExcelDoc, 'Sheet', 1); %export summary table to excel