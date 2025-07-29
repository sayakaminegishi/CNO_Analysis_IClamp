
function spike_indices = detect_spikes(d, dd)
% DETECT_SPIKES detects spikes in phase-space data using the winding number method.
% it maps the trajectory (V, dV/dt) in phase space, computes the winding
% angle around the mean center point, and whenever the trajectory completes
% a full clockwise loop, it is considered a spike. 
% The index where the full rotation completes is stored and is plotted as a red circle. 
%
%   spike_indices = DETECT_SPIKES(d, dd) takes two vectors, voltage (d) and
%   the rate of change of voltage (dd), and returns a vector containing the
%   indices at which a full clockwise spike cycle is completed.
%
%   Arguments:
%   d  - A 1D vector of voltage values.
%   dd - A 1D vector of the rate of change of voltage.
%
%   Returns:
%   spike_indices - A vector of indices where spikes are detected. Returns
%                   an empty array if no spikes are found.

    % Ensure inputs are column vectors
    d = d(:);
    dd = dd(:);

    if isempty(d) || numel(d) < 2
        spike_indices = [];
        return;
    end

    % 1. Calculate the reference point (centroid)
    center_d = mean(d);
    center_dd = mean(dd);

    % 2. Initialize variables
    cumulative_angle = 0;
    spike_indices = [];
    
    % Calculate the angle of the first point
    last_angle = atan2(dd(1) - center_dd, d(1) - center_d);

    % 3. Iterate through data points from the second point
    for i = 2:numel(d)
        % Calculate the angle of the current point relative to the centroid
        current_angle = atan2(dd(i) - center_dd, d(i) - center_d);

        % Calculate the change in angle from the last point
        delta_angle = current_angle - last_angle;

        % Correct for the wrap-around from +pi to -pi (or vice-versa)
        if delta_angle > pi
            delta_angle = delta_angle - 2 * pi;
        elseif delta_angle < -pi
            delta_angle = delta_angle + 2 * pi;
        end

        % Add the corrected angle change to the cumulative total
        cumulative_angle = cumulative_angle + delta_angle;

        % 4. Check if a full clockwise rotation (-2*pi) has been completed
        if cumulative_angle <= -2 * pi
            spike_indices = [spike_indices; i]; % Record the index of spike completion
            cumulative_angle = cumulative_angle + 2 * pi; % Reset to detect the next spike
        end
        
        % Update the last angle for the next iteration
        last_angle = current_angle;
    end
end
