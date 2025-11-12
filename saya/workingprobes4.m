%detects the spiketimes of only current clamp traces

addpath '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/analysis_scripts_iclamp'
%% === Setup session ===
steve = false;

if steve
    session_folder = '/Users/vanhoosr/data/saya';
else
    session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';
end

% Open or create NDI session
S = ndi.session.dir(session_folder);

%% === Get all patch-Vm probes ===
p_all = S.getprobes('type', 'patch-Vm');

%% === Helper function to check if a probe is current clamp ===
checkIfCurrentClamp = @(d) range(d) > 40;  % heuristic: >40 mV swing = spikes

%% === Filter only current clamp probes ===
p_cc = {};  % current-clamp probes
for i = 1:numel(p_all)
    et = p_all{i}.epochtable();
    if isempty(et), continue; end
    try
        [d, t] = p_all{i}.readtimeseries(1, -inf, inf); % read first epoch
        if ~isempty(d) && checkIfCurrentClamp(d)
            fprintf('Probe %d accepted as CURRENT CLAMP\n', i);
            p_cc{end+1} = p_all{i};
        else
            fprintf('Probe %d skipped (not current clamp or empty)\n', i);
        end
    catch ME
        warning('Probe %d could not be read: %s', i, ME.message);
    end
end

%% === Initialize results storage ===
results = struct();
csvRows = {};  % container for CSV export

%% === Loop through current-clamp probes ===
for P = 1:numel(p_cc)
    et = p_cc{P}.epochtable();
    numSweeps = numel(et);
    
    % Determine subplot grid size
    numRows = ceil(sqrt(numSweeps));
    numCols = ceil(numSweeps / numRows);

    f = figure('Name', sprintf('Probe %s', p_cc{P}.id()), 'NumberTitle','off');
    spikeTimesAll = cell(numSweeps,1);
    firingRates = nan(numSweeps,1);

    for e = 1:numSweeps
        subplot(numRows, numCols, e);
        hold on;

        % Read sweep
        [d, t] = p_cc{P}.readtimeseries(e,-inf,inf);

        % Skip if data or time is empty
        if isempty(d) || isempty(t)
            warning('Probe %s Epoch %d has no data. Skipping.', p_cc{P}.id(), e);
            continue;
        end

        % Spike detection
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);

        % Store results
        spikeTimesAll{e} = spiketimes;
        sweepDur = t(end) - t(1);
        if sweepDur > 0
            firingRates(e) = apcount / sweepDur; % Hz
        else
            firingRates(e) = NaN;
        end

        % Plot voltage trace
        plot(t,d,'k');
        xlabel('Time (s)');
        ylabel('Voltage (mV)');
        title(sprintf('Epoch %d: %d spikes, %.2f Hz', e, apcount, firingRates(e)));
        grid on;

        % Mark spikes
        if ~isempty(spiketimes)
            plot(spiketimes, ones(size(spiketimes))*max(d)*0.9, 'ro', 'MarkerFaceColor','r');
        end

        % Prepare CSV row
        csvRows{end+1,1} = p_cc{P}.id();                     % ProbeID
        csvRows{end,2} = e;                                  % Epoch
        csvRows{end,3} = apcount;                            % SpikeCount
        csvRows{end,4} = firingRates(e);                     % FiringRate_Hz
        csvRows{end,5} = strjoin(arrayfun(@num2str, spiketimes,'UniformOutput',false), ','); % SpikeTimes
    end

    % Save results for this probe
    results(P).probeID = p_cc{P}.id();
    results(P).spikeTimes = spikeTimesAll;
    results(P).frequencies = firingRates;
end

%% === Export results ===
% Save MATLAB struct
outputMatName = 'CurrentClampSpikeResults.mat';
save(outputMatName,'results');
fprintf('Results saved to %s\n', outputMatName);

% Export CSV
outputCsvName = 'CurrentClampSpikeResults.csv';
T = cell2table(csvRows, 'VariableNames', {'ProbeID','Epoch','SpikeCount','FiringRate_Hz','SpikeTimes'});
writetable(T, outputCsvName);
fprintf('CSV saved to %s\n', outputCsvName);

%% === Display summary ===
disp('Spike detection summary for current clamp probes:');
for P = 1:numel(results)
    fprintf('Probe %s:\n', results(P).probeID);
    for e = 1:numel(results(P).spikeTimes)
        fprintf('  Epoch %d: %d spikes, %.2f Hz, Spike times [s]: %s\n', ...
            e, numel(results(P).spikeTimes{e}), results(P).frequencies(e), ...
            mat2str(results(P).spikeTimes{e},3));
    end
end

