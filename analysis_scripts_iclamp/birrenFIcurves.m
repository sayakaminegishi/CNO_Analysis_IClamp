function [currentInjections, FR, counts] = birrenFIcurves(spikeTimes, type)
% birrenFIcurves calculates F-I curve parameters from spike time data
%
% INPUTS:
%   spikeTimes : cell array, where each cell contains spike times (in seconds)
%                for one sweep
%   type       : 1 = 25-sweep protocol, 2 = 28-sweep protocol
%
% OUTPUTS:
%   currentInjections : array of injected current steps (pA)
%   FR                : array of firing rates (Hz)
%   counts            : number of spikes per sweep

    % Define current injection steps based on type
    if type == 1
        % 25-sweep version
        currentInjections = [-50, -35, -20, -5, 10, 25, 40, 55, 70, 85, 100, 115, ...
                             130, 145, 160, 175, 190, 205, 220, 235, 250, 265, 280, 295, 310];
    elseif type == 2
        % 28-sweep version
        currentInjections = [-20, -10, 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, ...
                             100, 110, 120, 130, 140, 150, 160, 170, 180, 190, ...
                             200, 210, 220, 230, 240, 250];
    else
        error("Type not valid. Use 1 for 25 sweeps or 2 for 28 sweeps.");
    end

    % Initialize arrays
    numSweeps = length(spikeTimes);
    counts = zeros(1, numSweeps);
    FR = zeros(1, numSweeps);

    % Compute spike counts and firing rates
    for i = 1:numSweeps
        if isempty(spikeTimes{i})
            counts(i) = 0;
            FR(i) = 0;
        else
            counts(i) = numel(spikeTimes{i});
            sweepDuration = max(spikeTimes{i}) - min(spikeTimes{i}); % seconds
            if sweepDuration > 0
                FR(i) = counts(i) / sweepDuration; % Hz
            else
                FR(i) = 0;
            end
        end
    end
end
