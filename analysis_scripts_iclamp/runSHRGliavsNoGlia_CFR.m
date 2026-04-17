close all
addpath(genpath('/Users/sayakaminegishi/MATLAB/Projects/NDIcalc-birren-matlab'), '-begin');
[stats, g, subTable] = shrGliavsNoGlia_c50(bT)

%FIcalc.TC.current    FIcalc.TC.mean  
%modify current functions to compute average FI - figure with mean and Std
%error
%of the firing rate vs current curves