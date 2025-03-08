function [apCounts] = getAPCountForCell(filename1, starttime_ms, duration_ms)

    % Load ABF file data
    [dataallsweeps, si, h] = abf2load(filename1); 
    
    numSweeps = size(dataallsweeps, 3); % Total number of sweeps
    apCounts = zeros(1, numSweeps); % Initialize AP count storage
    
    % Convert sampling interval to seconds
    si_actual = 1e-6 * si; 

    % Collect start time and duration once
while true
    userInput = input("Input pulse start time in ms after start of recording: ", 's');
    starttime_ms = str2double(userInput);
    if isnan(starttime_ms) || starttime_ms < 0
        disp('Invalid input. Please enter a positive numeric value.');
        continue;
    end
    break;
end

while true
    userInput = input("Enter the duration of the pulse in ms: ", 's');
    duration_ms = str2double(userInput);
    if isnan(duration_ms) || duration_ms <= 0
        disp('Invalid input. Please enter a positive numeric value.');
        continue;
    end
    break;
end


    % Convert to indices
    starttime_idx = round(starttime_ms / (si * 1e-3)); % Convert ms to samples
    duration_idx = round(duration_ms / (si * 1e-3));
    endtime_idx = starttime_idx + duration_idx;
    endtime_ms = starttime_ms + duration_ms;

    % Process each sweep
    for sweep = 1:numSweeps
        % Extract relevant data
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));
        
        % Set AP detection parameters
        allowedDeviation = 40; % Noise filter threshold
        minAmp = data(1) + allowedDeviation;

        % Detect spikes
        [pks, spikeLocations] = findpeaks(data, 'MinPeakHeight', minAmp, 'MinPeakProminence', 5);

        % Store the count of detected APs
        apCounts(sweep) = numel(spikeLocations);

        %%%%%%%%% PLOT %%%%%%%%%%%%
        time_ms = linspace(starttime_ms, endtime_ms, length(data));

        figure;
        plot(time_ms, data, 'b', 'LineWidth', 1.5); % Plot trace in blue
        hold on;
        plot(time_ms(spikeLocations), pks, 'ro', 'MarkerFaceColor', 'r'); % Red dots for detected APs
        xlabel('Time (ms)');
        ylabel('Membrane Potential (mV)');
        title(['Sweep ' num2str(sweep) ': Membrane Potential']);
        grid on;
        hold off;
    end
end
