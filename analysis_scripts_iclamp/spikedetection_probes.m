 S = ndi.session.dir('/Users/sayakaminegishi/MATLAB/Projects/saya2');
 p = S.getprobes();

 e = S.getelements('element.type','spikes'); 

 % check 30 neurons

blt.spikes.auditSpikes(e{1})