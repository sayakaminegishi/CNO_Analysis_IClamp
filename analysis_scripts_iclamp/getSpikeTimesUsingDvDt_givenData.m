function apCounts = getSpikeTimesUsingDvDt_givenData(dataallsweeps, timepoints)
% GETSPIKETIMESUSINGDVDT_GIVENDATA Detects and counts action potentials in each sweep
% using phase-plane analysis.
%
% Inputs:
%   dataallsweeps : voltage data [samples x channels x sweeps]
%   timepoints    : time vector corresponding to the samples (ms)
%
% Output:
%   apCounts     : number of detected spikes per sweep

% Hardcoded parameters
threshold = 0;    % voltage threshold for spike detection (mV)
minISI_ms = 3;    % minimum interspike interval (ms)

numSweeps = size(dataallsweeps, 3); % number of sweeps
apCounts = zeros(1, numSweeps);

% Compute sampling interval from timepoints
si_actual = mean(diff(timepoints)) * 1e-3; % convert ms to seconds
minISI_samples = round(minISI_ms / mean(diff(timepoints))); % convert ms to samples

for sweep = 1:numSweeps
    % Extract voltage trace for this sweep (assuming first channel)
    data = squeeze(dataallsweeps(:,1,sweep));
    
    % Compute dV/dt
    dvdt = diff(data) / si_actual;
    v_trimmed = data(1:end-1); % Align with dvdt
    
    % --- Detect threshold crossings (candidate spikes) ---
    spike_indices = find(v_trimmed(1:end-1) < threshold & v_trimmed(2:end) >= threshold) + 1;
    
    % Apply minimum ISI to avoid double-counting
    if ~isempty(spike_indices)
        isi = [inf; diff(spike_indices(:))]; % column vector
        spike_indices = spike_indices(isi >= minISI_samples);
    end
    
    % --- Find first dv/dt = 0 after threshold (AP peak) ---
    peak_indices = [];
    for i = 1:length(spike_indices)
        idx_start = spike_indices(i);
        for j = idx_start:length(dvdt)-1
            if dvdt(j) > 0 && dvdt(j+1) <= 0
                peak_indices(end+1,1) = j; % store peak index
                break
            end
        end
    end
    
    % Store spike count
    apCounts(sweep) = numel(peak_indices);
    
    % --- Plot voltage and phase plots ---
    figure('Name', ['Sweep ' num2str(sweep)], 'NumberTitle', 'off');
    
    % Voltage trace
    subplot(2,1,1);
    plot(timepoints, data, 'k'); hold on;
    if ~isempty(peak_indices)
        plot(timepoints(peak_indices), data(peak_indices), 'ro', 'MarkerFaceColor', 'r');
    end
    xlabel('Time (ms)'); ylabel('Membrane Potential (mV)');
    title(['Sweep ' num2str(sweep) ' Voltage Trace']); grid on;
    
    % Phase plot
    subplot(2,1,2);
    plot(v_trimmed, dvdt, 'k'); hold on;
    if ~isempty(peak_indices)
        plot(data(peak_indices), dvdt(peak_indices), 'ro', 'MarkerFaceColor', 'r');
    end
    xlabel('Membrane Potential (mV)'); ylabel('dV/dt (mV/s)');
    title(['Sweep ' num2str(sweep) ' Phase Plot']); grid on;
end
end
