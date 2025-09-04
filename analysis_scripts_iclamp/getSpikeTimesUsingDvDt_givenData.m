function [spikeTimes, spikeCount] = getSpikeTimesUsingDvDt_givenData(timepoints, data)
% GETSPIKETIMESUSINGDVDT Detects spikes from a single sweep using dV/dt analysis.
%
%   INPUTS:
%       timepoints : vector of time values (e.g. ms) for one sweep
%       data       : vector of voltage values (same length as timepoints)
%
%   OUTPUTS:
%       spikeTimes : times (ms) of detected AP peaks
%       spikeCount : number of detected spikes
%
%   Method:
%       - Detects threshold crossings
%       - Finds the first dV/dt = 0 after threshold (AP peak)
%       - Applies refractory period (min ISI)

    % --- Check input ---
    if length(timepoints) ~= length(data)
        error('timepoints and data must have the same length');
    end

    % Sampling interval (assumes uniform spacing)
    si = mean(diff(timepoints)); % in ms
    si_s = si * 1e-3;            % convert ms -> s for dV/dt

    % Compute dV/dt
    dvdt = diff(data) / si_s;
    v_trimmed = data(1:end-1); % align with dvdt

    % Parameters
    threshold = 0;       % voltage threshold for initial detection (adjust if needed)
    minISI_ms = 3;       % minimum ISI in ms
    minISI_samples = round(minISI_ms / si);

    % --- Step 1: Find threshold crossings ---
    spike_indices = find(v_trimmed(1:end-1) < threshold & v_trimmed(2:end) >= threshold) + 1;

    % Apply refractory period
    if ~isempty(spike_indices)
        isi = [inf; diff(spike_indices(:))]; % ensure column
        spike_indices = spike_indices(isi >= minISI_samples);
    end

    % --- Step 2: Find AP peaks (dv/dt = 0 after threshold) ---
    peak_indices = [];
    for i = 1:length(spike_indices)
        idx_start = spike_indices(i);
        idx_end   = length(dvdt);
        for j = idx_start:idx_end-1
            if dvdt(j) > 0 && dvdt(j+1) <= 0
                peak_indices(end+1,1) = j; % collect peaks
                break
            end
        end
    end

    % --- Step 3: Convert indices to times and count ---
    spikeTimes = timepoints(peak_indices);
    spikeCount = numel(spikeTimes);

    % --- Optional plotting ---
    figure;
    subplot(2,1,1);
    plot(timepoints, data, 'k'); hold on;
    if ~isempty(peak_indices)
        plot(timepoints(peak_indices), data(peak_indices), 'ro', 'MarkerFaceColor', 'r');
    end
    xlabel('Time (ms)');
    ylabel('Membrane Potential (mV)');
    title(sprintf('Voltage Trace with %d Spikes', spikeCount));
    grid on;

    subplot(2,1,2);
    plot(v_trimmed, dvdt, 'k'); hold on;
    if ~isempty(peak_indices)
        plot(data(peak_indices), dvdt(peak_indices), 'ro', 'MarkerFaceColor', 'r');
    end
    xlabel('Membrane Potential (mV)');
    ylabel('dV/dt (mV/s)');
    title('Phase Plot with Spike Peaks');
    grid on;

end
