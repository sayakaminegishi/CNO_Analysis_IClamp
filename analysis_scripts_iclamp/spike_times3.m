function [N ,out1] = spike_times3(trace,threshold1)
%   This function detects and locates the time points of action potentials in a trace of 
%   membrane potential as a function of time in a neuron. The trace should represent
%   a current clamp recording from a neuron.
%   Input: 
%   "trace" is the membrane voltage array of the neuron
%   "Theshold" is the value for the spike to cross to be detected.
%   Output:
%   N - the number of spikes detected
%   out1 - array of sample numbers (i.e. times) of spikes detected
%
%   Example:
% 
%   [numberOfSpikes, spikeTimes] = spike_times2(d,-10);
%
%   assuming "d" contains trace loaded previously, and -10 mV was chosen as
%   action potential threshold. 
% 
%   Original script by: 
%   Rune W. Berg 2006 / rune@berg-lab.net / www.berg-lab.net
%   Modified by: Rune W. Berg, May 2015
%   Modified by: Roman E. Popov, June 2016. (rpopov@uvm.edu)
%   Modified by: Sayaka (Saya) Minegishi, August 2023 (minegishis@brandeis.edu)


 gim=trace;
    clear('set_crossgi')
    % find indices of samples above the threshold:
    set_crossgi=find(gim(1:end) > threshold1)  ; 
    clear('index_shift_neggi');clear('index_shift_pos');
    
% if there is at least one sample above the threshold:
if isempty(set_crossgi) < 1  
    clear('set_cross_plusgi');clear('set_cross_minus')
    % first index posgi = 1st sample above the threshold:
    index_shift_posgi(1)=min(set_crossgi);
    % set last index neggi to the last sample above the threshold:
    index_shift_neggi(length(set_crossgi))=max(set_crossgi);
    for i=1:length(set_crossgi)-1
        % this line detects when there is a discontinuous jump in the
        % indices, thus -> shift from one spike to another. Example: 
        % a) continuous indices: set_crossgi(i+1)=721 > set_crossgi(i)+1 =
        % 720 + 1; therefore, 721 = 721, not true, 0, skip the clause.
        % b) discontinuous, set_crossgi(i+1)= 1000 > set_crossgi(i)+1 =
        % 721+1 = 1000 > 722, true -> record the indices
        if set_crossgi(i+1) > set_crossgi(i)+1 ; 
            % index of the right end of the spike interval
            index_shift_posgi(i+1)=i;
            index_shift_neggi(i)=i;
        end
    end
    % ^^^ Code extracts indices of the "above treshold" samples
    %Identifying up and down slopes:
    % Here indices of the truncated "above the threshold" trace are
    % converted into sample indices of the original trace:
    set_cross_plusgi=  set_crossgi(find(index_shift_posgi));   % find(x) returns nonzero arguments.
    set_cross_minusgi=  set_crossgi(find(index_shift_neggi));   % find(x) returns nonzero arguments.
    set_cross_minusgi(length(set_cross_plusgi))= set_crossgi(end);
    
    nspikes= length(set_cross_plusgi); % Number of pulses, i.e. number of windows.
    
    % Getting the spike coords
    spikemax = zeros(1, nspikes);
    spikemaxCorrected = zeros(1, nspikes);
    
    for i=1: nspikes
            % identify a potential spike:
            spikemax(i)=min(find(gim(set_cross_plusgi(i):set_cross_minusgi(i)) == max(gim(set_cross_plusgi(i):set_cross_minusgi(i))))) +set_cross_plusgi(i)-1;
            
    end
else
    spikemax=[];
    spikemaxCorrected = [];
    display('no spikes in trace')
end

% plot:
figure; plot(trace); hold on; plot(spikemax, trace(spikemax),'or');hold off
 
N=length(spikemax) ;
out1=spikemax;
