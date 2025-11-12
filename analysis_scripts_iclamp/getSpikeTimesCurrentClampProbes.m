function results = getSpikeTimesCurrentClampProbes(session_folder)
%GETSPIKETIMESCURRENTCLAMPPROBES Detects spiketimes from current-clamp traces.
%
% results = getSpikeTimesCurrentClampProbes(session_folder)
%
% INPUT:
%   session_folder : path to NDI session
%
% OUTPUT:
%   results : struct array with fields:
%       - probeID
%       - spikeTimes (cell array per sweep)
%       - spikeTable (table of [Epoch, SpikeCount, SpikeTimes])

    % --- Open session ---
    S = ndi.session.dir(session_folder);

    % --- Get all patch-Vm probes ---
    p_all = S.getprobes('type', 'patch-Vm');
    
    %display all subjects
    sT = ndi.fun.docTable.subject(S);
    display(sT)

    % --- Define current clamp heuristic (>40 mV swing = spikes) ---
    checkIfCurrentClamp = @(d) range(d) > 40;

    % --- Filter probes ---
    p_cc = {};
    for i = 1:numel(p_all)
        et = p_all{i}.epochtable();
        if isempty(et), continue; end
        try
            [d, ~] = p_all{i}.readtimeseries(1,-inf,inf);
            if ~isempty(d) && checkIfCurrentClamp(d)
                fprintf('Probe %d accepted as CURRENT CLAMP\n', i);
                p_cc{end+1} = p_all{i};
            else
                fprintf('Probe %d skipped (not current clamp)\n', i);
            end
        catch ME
            warning('Probe %d skipped: %s', i, ME.message);
        end
    end

    % --- Loop through current-clamp probes ---
    results = struct();

    for P = 1:numel(p_cc)
        et = p_cc{P}.epochtable();
        numSweeps = numel(et);

        spikeTimesAll = cell(numSweeps,1);
        Epoch = [];
        SpikeCount = [];
        SpikeTimesStr = {};

        for e = 1:numSweeps
            [d, t] = p_cc{P}.readtimeseries(e,-inf,inf);

            if isempty(d) || isempty(t)
                warning('Probe %s Epoch %d has no data. Skipping.', p_cc{P}.id(), e);
                continue;
            end

            % Spike detection (helper function must be in path)
            [~, spiketimes] = getSpikeTimesSingleSweep(d,t);

            spikeTimesAll{e} = spiketimes;

            % Collect row for in-memory table
            Epoch(end+1,1) = e;
            SpikeCount(end+1,1) = numel(spiketimes);
            SpikeTimesStr{end+1,1} = strjoin(arrayfun(@num2str, spiketimes,'UniformOutput',false), ',');
        end

        % Save in results struct
        results(P).probeID    = p_cc{P}.id();
        results(P).spikeTimes = spikeTimesAll;
        results(P).spikeTable = table(Epoch, SpikeCount, SpikeTimesStr);

        % Print table to command window
        fprintf('\n=== Probe %s Spike Table ===\n', results(P).probeID);
        disp(results(P).spikeTable);
    end

    % --- Final summary ---
    fprintf('\nSpike detection complete: %d current clamp probes analyzed.\n', numel(results));
end
