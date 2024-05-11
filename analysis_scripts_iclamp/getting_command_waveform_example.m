filepath = "/Users/sayakaminegishi/Documents/AP analysis packages Saya M/data/command_new.mat"

S = load(filepath)
figure(1);
plot(S.command_waveform)