%deletes outliers from a given Csv file table obtained in
%firingRateAnalyzer2.m


addpath('/Users/sayakaminegishi/MATLAB/Projects/vhlab-toolbox-matlab')

%%%%%%%%%% ENTER INFO BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%48h10umCNO-SHR_25sw, 48h10umCNO-WKY_25sw, WKYN_Only, SHRN_Only
outputCsvName = 'SHRN_Only_CLEANED.csv'; 


data = readtable('SHRN_Only_NEW.csv');

% identify outliers in a specific column
outliers_FR = isoutlier(data.maxFiringRate);
% Delete rows with outliers
data(outliers_FR, :) = [];

outliers_Rm = isoutlier(data.Rm);
data(outliers_Rm, :) = [];

outliers_Rb = isoutlier(data.Rb);
data(outliers_Rb, :) = [];

outliers_Threshold = isoutlier(data.Threshold);
data(outliers_Threshold, :) = [];


disp(data)

writetable(data, 'SHRN_Only_NEW_CLEANED.csv');