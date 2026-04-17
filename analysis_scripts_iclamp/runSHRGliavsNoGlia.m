%run [stats, g, subTable] = shrGliavsNoGlia(biggestTable)
close all
addpath(genpath('/Users/sayakaminegishi/MATLAB/Projects/NDIcalc-birren-matlab'), '-begin');
[stats, g, subTable] = shrGliavsNoGlia_c50(bT)