


S = ndi.session.dir(['/Users/vanhoosr/data/saya']);

p = S.getprobes('type','patch-Vm');

subjectTable = ndi.fun.docTable.subject(S);



for P=1:5
    f = figure;
    counter = 0;
    et = p{P}.epochtable();
    for e=1:numel(et)
        counter = counter + 1;
        supersubplot(f,4,4,counter);
        %[d,t] = p{P}.readtimeseries(e,-inf,inf);
        [apCount, spikeTimes] = getSpikeTimesSingleSweep(d, t);
        plot(t,d);
        hold on;
        plot(spikeTimes,1,'ko');
        ylabel('Voltage');
        xlabel('Time(s)')
    end
end

