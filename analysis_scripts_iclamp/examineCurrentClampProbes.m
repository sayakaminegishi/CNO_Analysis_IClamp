function results=examineCurrentClampProbes(session_folder)
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

    results=sT;
end
