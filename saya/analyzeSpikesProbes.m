% === Integrated version: NDI + firing rate analyzer (with spike times) ===
addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab');

%% === Setup session ===
steve = false;
if steve
    session_folder = '/Users/vanhoosr/data/saya';
else
    session_folder = '/Users/sayakaminegishi/MATLAB/Projects/CNO_Analysis_IClamp2025/saya';
end

S = ndi.session.dir(session_folder);

%% === Get the probes that are patch recordings ===
p = S.getprobes('type','patch-Vm');

%% === Parameters ===
strainName = 'SHR';
cno = 1; % 1 = treatment, 0 = control
outputCsvName = 'NDI_FiringRateFits_autoCurrent.csv';
outputMatName = 'NDI_FiringRateDetailed.mat';

%% === Containers for results ===
summaryResults = {};
detailedResults = struct(); % store spike times, FRs, currents for each cell

%% === Loop through probes (cells) ===
for P = 1:numel(p)
    et = p{P}.epochtable();
    cellName = p{P}.id(); % or another identifier

    % Containers
    currents_pA = nan(numel(et),1);
    firingRates = nan(numel(et),1);
    spikeTimesAll = cell(numel(et),1);

    for e = 1:numel(et)
        % --- Read sweep ---
        [d, t] = p{P}.readtimeseries(e,-inf,inf);

        % --- Spike detection ---
        [apcount, spiketimes] = getSpikeTimesSingleSweep(d,t);

        % --- Store spike times ---
        spikeTimesAll{e} = spiketimes;

        % --- Compute firing rate (Hz) ---
        sweepDur_s = t(end)-t(1);
        if sweepDur_s > 0
            firingRates(e) = apcount / sweepDur_s;
        end

        % --- Try to extract injected current from metadata ---
        try
            epochdoc = p{P}.getepochdocument(e);
            stim = epochdoc.document_properties.stimulus;
            if isfield(stim,'amplitude')
                I_pA = stim.amplitude * 1e12; % A → pA
            elseif isfield(stim,'current')
                I_pA = stim.current * 1e12;
            else
                I_pA = NaN;
                warning('No current metadata for %s epoch %d', cellName, e);
            end
        catch
            I_pA = NaN;
            warning('Failed to read current metadata for %s epoch %d', cellName, e);
        end
        currents_pA(e) = I_pA;
    end

    % === Remove NaNs before fitting ===
    validIdx = ~isnan(currents_pA) & ~isnan(firingRates);
    C_pA = currents_pA(validIdx);
    Y = firingRates(validIdx);

    % === Fit Naka-Rushton threshold model ===
    try
        [fitresult, ~] = nakaRushtonThreshFit2(C_pA, Y);
        Rm = fitresult.Rm;
        Rb = fitresult.b;
        tVal = fitresult.t;
        c_max = max(C_pA);
        maxFR = max(0, c_max - tVal) * Rm / (Rb + max(0, c_max - tVal));
    catch ME
        warning('Fit failed for cell %s: %s', cellName, ME.message);
        Rm = nan; Rb = nan; tVal = nan; maxFR = nan;
    end

    % === Store summary results ===
    summaryResults = [summaryResults; {cellName, strainName, cno, Rm, Rb, tVal, maxFR}];

    % === Store detailed results ===
    detailedResults(P).cellName = cellName;
    detailedResults(P).currents_pA = currents_pA;
    detailedResults(P).firingRates = firingRates;
    detailedResults(P).spikeTimes = spikeTimesAll;
    detailedResults(P).fitParams = struct('Rm',Rm,'Rb',Rb,'Threshold',tVal,'maxFiringRate',maxFR);

    % === Plot raw FI curve + fit ===
    figure;
    plot(C_pA, Y, 'bo','MarkerSize',4); hold on;
    if ~isnan(Rm)
        c_fit = linspace(min(C_pA), max(C_pA), 100);
        fit_y = max(0, c_fit - tVal) .* Rm ./ (Rb + max(0, c_fit - tVal));
        plot(c_fit, fit_y, 'r-','LineWidth',1.2);
    end
    xlabel('Current (pA)'); ylabel('Hz');
    title(['FI curve: ', cellName],'Interpreter','none');
end

%% === Export summary (CSV) ===
T = cell2table(summaryResults, ...
    'VariableNames', {'CellName','strain','treatment','Rm','Rb','Threshold','maxFiringRate'});
disp(T);
writetable(T, outputCsvName);

%% === Save detailed results (MAT file) ===
save(outputMatName,'detailedResults');
