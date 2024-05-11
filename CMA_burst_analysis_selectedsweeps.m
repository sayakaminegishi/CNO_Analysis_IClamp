function [singletAnalysisRow, T] = CMA_burst_analysis_selectedsweeps(filename1, sweepvec)
% uses /MATLAB Drive/continuous2_APfocused/cma_individual_file.m
%analyzes an abf file from a particular directory to find their freq, interspike interval (isi), and
%analysis of bursts and singlet APs. Analysis for a SINGLE CELL (i.e. ABF
%file).
% T = table with burst properties for this cell
%filename1 = name of abf file


% a peak is defined as an AP if it satisfies dV_thresh criteria for minimum
% slope change, AND its peak amplitude is at least 40mV above baseline.


% created by Sayaka (Saya) Minegishi
% contact: minegishis@brandeis.edu
% date: 5/11/2024


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myVarnames = {'cell name', 'threshold(mV)', 'average_ISI(ms)', 'AP_frequency(Hz)', 'total_AP_count_in_cell', 'count_of_bursts', 'count_of_singletAPs', 'average_burst_duration(ms)', 'freq_bursts(Hz)'};

multipleVariablesTable= zeros(0,size(myVarnames, 2));
multipleVariablesRow = zeros(0,size(myVarnames, 2));
T= array2table(multipleVariablesTable, 'VariableNames', myVarnames); %stores info from all the sweeps in an abf file


%%%%%%%%% EXTRACT AND CLEAN DATA %%%%%%%%

[dataallsweeps, si, h] =abf2load(filename1); %get si and h values from this abf file

si_actual = 1e-6 * si; %in sec. original si is in usec


%COMBINE SWEEPS into a single array. THIS IS OUR DATA TO USE!!!!!!!
combinedsweep = combine_sweeps(dataallsweeps, sweepvec); %combine the data for the whole trace in 1 single sweep (array)

b = 1;


% % %%%%%%%%%%%%% CMA analysis %%%%%%%%%%%%%%

numspikes = 0;

onems = si * 10^-3; %ms/sample
dV_thresh_mVms = 10; % in mV/ms

dV_thresh = dV_thresh_mVms*onems; % in mV/sample 



isi_list = []; %array of interspike intervals from all sweeps
freq_list = []; %stores count of APs in each sweep, stores it in an array to represent data from all sweeps
total_count_Aps = 0; %total count of APs in this file
thresh_list = []; %list of threshold from each sweep

sweepofinterest = b; %the sweep that we want to examine
data = combinedsweep;

dataold = data; 

%data = detrend(data, 1) + data(1); %Correct baseline - detrend shifts baseline to 0



x_axis_samples = 1:size(data,1);
x_axis_actual = sampleunits_to_ms(si, x_axis_samples);

%threshold minimum



alloweddeviation = 40;%if 30, anything within 30mV of resting potential (first value in trace) is deemed as noise

minimumAmp = data(1) + alloweddeviation; %anything within 40mV of resting potential (first value in trace) is deemed as noise

all_dV = find(diff(data) > dV_thresh);  %list of locations at which slope > threshold

%filter
all_dV_filtered = [];
k = 1;
for i = 1:numel(all_dV)
    if (data(all_dV(i))>= minimumAmp)
        all_dV_filtered(k) = all_dV(i);
        k = k + 1;
    end 
end

%set threshold for noise
if(isempty(all_dV_filtered))
    error = "No action potentials identified in this trace.";
    display(error); %error message.
else

    threshold_value = data(all_dV_filtered(1)); %threshold for AP detection
    allSpikeSamples = get_spikelocations(data,threshold_value); %get AP spike times
    
    %allSpikeTimes = si_actual * allSpikeSamples; %all the spike locations in ms!!!!
    allSpikeTimes = sampleunits_to_ms(si, allSpikeSamples);
    
    int_sp_intv = find_isi(allSpikeSamples); %get an array of interspike intervals for the sweep, in sample units
     
   
    %convert each element in int_sp_intv to ms
    for i = 1:numel(int_sp_intv)
        int_sp_intv(i) = sampleunits_to_ms(si, int_sp_intv(i));
    end
    
    isi_list = cat(2, isi_list, int_sp_intv); % concatenate arrays to add the new ISIs from this sweep to isi_list
    
    
    % FREQUENCY OF AP IN THIS SWEEP (in terms of counts of AP per
    % sweep)
    
    frequency1 = numel(allSpikeSamples); 
    
    total_count_Aps = total_count_Aps + numel(allSpikeSamples); %update total count of APs detected from this cell
    
    % % convert all output variables from sample units to ms
    % dV_thresh = dV_thresh * 1/(si * 0.001); %threshold slope, in mV/ms
    
    % summarize info in separate arrays for each property
    freq_list = frequency1;
    thresh_list= threshold_value;
    
    % frequency of action potentials in Hz (counts of peaks / sec)
    %si = sampling interval in microseconds
    %totalduration_sec = si * 10^(-6) * numel(data); %total duration of the recording in sec for the whole trace, minus the transients
    
    totalduration_sec = sampleunits_to_ms(si, numel(data)) * 10^(-3); %total duration of the recording in sec for the whole trace, minus the transients
    
    freq_in_hz = total_count_Aps/totalduration_sec;
  
    % ISI histogram
    figure;
    %binwidth_hist = 100;  % do 1 for 1ms bin width, based on Selinger et al. ADJUST THIS VALUE AS NECESSARY!!!
    binwidth_hist = 30;  % do 1 for 1ms bin width, based on Selinger et al. ADJUST THIS VALUE AS NECESSARY!!!
    
    isi_histogram = get_isi_histogram(isi_list, binwidth_hist); 
    
    % Retrieve some properties from the histogram - based on code by Steven Lord 2020 https://www.mathworks.com/matlabcentral/answers/536931-is-there-s-a-way-to-automatically-find-peaks-in-an-histogram
    V = isi_histogram.Values;
    E = isi_histogram.BinEdges;
    % Use islocalmax
    L = islocalmax(V);
    % Find the centers of the bins that islocalmax identified as peaks
    left = E(L);
    right = E([false L]);
    center = (left + right)/2;
    % % Plot markers on those bins
    % hold on
    % plot(center, V(L), 'o') %V(L) are the count of spikes (y values of the histogram)
    % hold off
    %%% sort the V(L) values to find the two highest peaks
    
    %%%%%%%%%%%%% CMA BASED ON KAPUCU ET AL PAPER %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
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
    
    
    
    %find maximum value of CMA (CMAm)
    CMAm = max(CMA_list); 
    
    %find the ISI value/binvalue that gives CMAm
    m = find(CMA_list == CMAm); %find the index of the bin of interest. This point represents the maximum that the average spike count reaches
    
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
    
    ISI_interburst_CMA = alpha1 * CMAm; %average (cumulative moving) spike count at threshold 
    % FIND bin center CLOSEST TO ISI_interburst_CMA.
    
    [ISI_interburst_thresh_idx,~] = find_nearest_value(ISI_interburst_CMA, CMA_list);
    ISI_interburst_thresh = Ibins_centered(ISI_interburst_thresh_idx);
    
    
    %find ISI threshold for burst-related spikes
    ISI_brelated_CMA = alpha2 * CMAm;
    % FIND bin center closest
    
    [ISI_brelated_thresh_idx,~] = find_nearest_value(ISI_brelated_CMA, CMA_list);
    ISI_brelated_thresh = Ibins_centered(ISI_brelated_thresh_idx); %find the ISI corresponding to this nearest value of CMA
    
   
    
    %%%%%%%%%%%%%% 
    % burst times and singlet AP times (measured as location of peak)
    %TODO: convert ISI_interburst_thresh into sample units first!!!
    ISI_intBthresh_sampleunits = ms_to_sampleunits(si, ISI_interburst_thresh);
    
    %[singletTimesMatrix, burstTimesMatrix] = find_burstMatrix2(data, allSpikeSamples, ISI_interburst_thresh);
    [singletTimesMatrix, burstTimesMatrix] = find_burstMatrix2(data, allSpikeSamples, ISI_intBthresh_sampleunits);
    burstTimesMatrix_insamples = burstTimesMatrix; %in sample units
    singletTimesMatrix_insamples = singletTimesMatrix; %in sample units

    burstTimesMatrix = sampleunits_to_ms(si,burstTimesMatrix); %in ms
    singletTimesMatrix = sampleunits_to_ms(si,singletTimesMatrix); %in ms

    %plot corrected burst times and singlet AP times
    
    %plot burst start andend times
    if ~isempty(burstTimesMatrix_insamples)
        figg = figure;
        
        plot(x_axis_actual(1,:), data(:,1)) %x axis in sample units
        hold on
        
        plot(burstTimesMatrix(:,1), data(burstTimesMatrix_insamples(:,1)), 'ro')
        plot(burstTimesMatrix(:,2), data(burstTimesMatrix_insamples(:,2)), 'rdiamond')
        
        %plot singlet spikes
        plot(singletTimesMatrix, data(singletTimesMatrix_insamples), 'k*')
        
        %label graph
        legend({'Data', 'Burst Start Times','Burst End Times', 'Singlet APs'}, 'FontSize', 5, 'Location', 'southeast')

        xlabel('Time (ms)') 
        ylabel('Membrane potential (mV)') 

        %set viewing window for x and y
        x1= x_axis_actual;
        x1lim = x1(end);
        
        % y1 = data();
        % y1lim = y1(end);

        xlim([0 x1lim])
       
        hold off
    else
        % If no burst data, return an empty plot handle
        figg = gobjects(0);
        
    end
    
    %find count of bursts from burstTimesMatrix
    numbursts = size(burstTimesMatrix, 1); % no. of rows in burstTimesMatrix
    
    %find average burst duration
    burstdurationlist = zeros(numbursts,1); %array to store each burst duration
    display("btm= " + burstTimesMatrix)
    for i = 1:numbursts
        dur = burstTimesMatrix(i, 2) - burstTimesMatrix(i, 1); %duration of this particular burst
        burstdurationlist(i) = dur;
    end
    display("bdlist =" + burstdurationlist)
    avg_burst_duration = mean(burstdurationlist); %mean burst duration in ms (DOUBLE CHECK)
    display("avg bd= " + avg_burst_duration)
   %avg_burst_duration = double(avg_burst_duration(:,1));
    count_singletAPs = size(singletTimesMatrix, 1);
    freq_burst_in_Hz = numbursts(1)/totalduration_sec;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    avg_isi = sum(isi_list)/numel(isi_list); %avg ISI across all sweeps, in ms
    
    %create table row for the cell
    
    multipleVariablesRow= [filename1(1), threshold_value(1), avg_isi(1), freq_in_hz(1), total_count_Aps(1), numbursts(1), count_singletAPs(1), avg_burst_duration(1), freq_burst_in_Hz(1)];
    multipleVariablesRow = fillmissing(multipleVariablesRow,'constant',"");
    
    size(multipleVariablesRow)
    size(myVarnames)
    M= array2table(multipleVariablesRow, 'VariableNames', myVarnames);
    
    T = [T; M]; %store in a bigger table with all other files for comparison
    
    
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %analysis of singlet APs

       %analysis of singlet APs
    if(isempty(singletTimesMatrix_insamples))
          %MAKE A TABLE WITH EMPTY VALUES BUT WITH HEADERS
          % Define headers
          headers = {'spike_location(ms)', 'threshold(mV)', 'amplitude(mV)', 'AHP_amplitude(mV)', 'trough value (mV)', 'trough location(ms)', 'peak value(mV)', 'peak location(ms)', 'half_width(ms)', 'AHP_30_val(mV)', 'AHP_50_val(mV)', 'AHP_70_val(mV)', 'AHP_90_val(mV)', 'half_width_AHP(ms)', 'AHP_width_10to10%(ms)', 'AHP_width_30to30%(ms)', 'AHP_width_70to70%(ms)', 'AHP_width_90to90%(ms)', 'AHP_width_90to30%(ms)', 'AHP_width_10to90%(ms)'};
          variableTypes = {'double', 'double', 'double', 'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double',  'double' , 'double',  'double' }; % Adjust the data types as needed

          % Create an empty table with headers
          singletAnalysisTable = table('Size', [0, numel(headers)], 'VariableNames', headers, 'VariableTypes', variableTypes);

    else
        singletAnalysisTable = singletSpikeAnalysis5(data, singletTimesMatrix_insamples, all_dV_filtered, dV_thresh, si);
    end
        %display(singletAnalysisTable);
    
   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % prepare data for batch analysis
        singletAnalysisRow = mean(singletAnalysisTable); %avg of singlet properties
        singletAnalysisRow(:,[1,7]) = []; %delete irrelevant columns for averaged data
        
        
end
end


