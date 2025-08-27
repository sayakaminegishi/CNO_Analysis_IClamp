function apCounts = getAPCountUsingDvDt_peakspike(filename1)
% GETAPCOUNTUSINGDVDT Detects and counts action potentials in each sweep of an ABF file 
% using phase-plane analysis. 
% Red dots are placed at the first dV/dt = 0 after threshold (AP peak) in both voltage trace and phase plot.

    % Load ABF file data
    [dataallsweeps, si, h] = abf2load(filename1);

    numSweeps = size(dataallsweeps, 3); % Total number of sweeps
    apCounts = zeros(1, numSweeps);     % Initialize AP count storage

    % Convert sampling interval to seconds
    si_actual = 1e-6 * si;

    % Define analysis window (ms)
    starttime_ms = 138;
    duration_ms  = 500;
    endtime_ms   = starttime_ms + duration_ms;

    % Convert to sample indices
    starttime_idx = round(starttime_ms / (si * 1e-3));
    duration_idx  = round(duration_ms  / (si * 1e-3));
    endtime_idx   = starttime_idx + duration_idx;

    % Refractory period for spike detection
    minISI_ms = 3;
    minISI_samples = round(minISI_ms / (si * 1e-3));

    % Threshold for initial spike detection
    threshold = 0;  % adjust based on your data

    for sweep = 1:numSweeps
        % Extract voltage trace for this sweep
        data = squeeze(dataallsweeps(starttime_idx:endtime_idx, 1, sweep));

        % Compute dV/dt
        dvdt = diff(data) / si_actual;
        v_trimmed = data(1:end-1); % Align with dvdt

        % --- Detect spikes using threshold (candidate indices) ---
        spike_indices = find(v_trimmed(1:end-1) < threshold & v_trimmed(2:end) >= threshold) + 1;

        % Apply minimum ISI to avoid double-counting
        if ~isempty(spike_indices)
            isi = [inf; diff(spike_indices(:))]; % ensure column vectors
            spike_indices = spike_indices(isi >= minISI_samples);
        end

        % --- Find first dv/dt = 0 after threshold (AP peak) ---
        peak_indices = [];
        for i = 1:length(spike_indices)
            idx_start = spike_indices(i);
            idx_end   = length(dvdt);
            for j = idx_start:idx_end-1
                if dvdt(j) > 0 && dvdt(j+1) <= 0
                    peak_indices(end+1,1) = j;  % make column vector
                    break
                end
            end
        end

        % Store spike count
        apCounts(sweep) = numel(peak_indices);

        % Plot this sweep
        time_ms = linspace(starttime_ms, endtime_ms, length(data));
        figure('Name', ['Sweep ' num2str(sweep)], 'NumberTitle', 'off');

        % --- Voltage trace with red dots at AP peaks ---
        subplot(2,1,1);
        plot(time_ms, data, 'k'); hold on;
        if ~isempty(peak_indices)
            plot(time_ms(peak_indices), data(peak_indices), 'ro', 'MarkerFaceColor', 'r');
        end
        xlabel('Time (ms)');
        ylabel('Membrane Potential (mV)');
        title(['Sweep ' num2str(sweep) ' Voltage Trace']);
        grid on;

        % --- Phase plot with red dots at AP peaks ---
        subplot(2,1,2);
        plot(v_trimmed, dvdt, 'k'); hold on;
        if ~isempty(peak_indices)
            plot(data(peak_indices), dvdt(peak_indices), 'ro', 'MarkerFaceColor', 'r');
        end
        xlabel('Membrane Potential (mV)');
        ylabel('dV/dt (mV/s)');
        title(['Sweep ' num2str(sweep) ' Phase Plot']);
        grid on;
    end
end
