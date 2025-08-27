  function spike_indices = detect_spikes(d, dd, minISI_samples)
% DETECT_SPIKES detects spikes in phase-space data using the winding number method.
% It computes cumulative angular rotation around the centroid of the phase plot (V vs dV/dt),
% and detects a spike when a full clockwise loop (-2π) is completed.
% A refractory period is enforced to avoid multiple detections of the same AP.

% INPUTS:
%   d              - voltage values (1D vector)
%   dd             - derivative of voltage (dV/dt)
%   minISI_samples - minimum interval between spikes in samples (refractory period)
%
% OUTPUT:
%   spike_indices  - indices where spikes are detected

    % Ensure inputs are column vectors
    d = d(:);
    dd = dd(:);

    if isempty(d) || numel(d) < 2
        spike_indices = [];
        return;
    end

    % Compute the centroid of the phase plot
    center_d = mean(d);
    center_dd = mean(dd);

    % Initialize
    cumulative_angle = 0;
    spike_indices = [];
    last_angle = atan2(dd(1) - center_dd, d(1) - center_d);
    last_spike_idx = -inf;

    % Iterate through data points
    for i = 2:numel(d)
        current_angle = atan2(dd(i) - center_dd, d(i) - center_d);
        delta_angle = current_angle - last_angle;

        % Unwrap angle to avoid jumps at ±pi
        if delta_angle > pi
            delta_angle = delta_angle - 2 * pi;
        elseif delta_angle < -pi
            delta_angle = delta_angle + 2 * pi;
        end

        cumulative_angle = cumulative_angle + delta_angle;

        % Detect full clockwise loop (spike)
        if cumulative_angle <= -2 * pi
            if i - last_spike_idx >= minISI_samples
                search_win = 10;  % look back 10 samples from current index
                start_idx = max(1, i - search_win);
                [~, local_max_idx] = max(d(start_idx:i));
                spike_indices = [spike_indices; start_idx + local_max_idx - 1];

                last_spike_idx = i;
                cumulative_angle = cumulative_angle + 2 * pi;
            end
        end

        last_angle = current_angle;
    end
end
