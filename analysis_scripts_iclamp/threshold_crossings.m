function [ index_values ] = threshold_crossings( input, threshold )

%THRESHOLD_CROSSINGS Detect thershold crossings in data

% 

%  INDEX_VALUES = dasw.signal.threshold_crossings(INPUT, THRESHOLD)

%

%  Finds all places where the data INPUT crosses the threshold

%  THRESHOLD.  The index values where this occurs are returned in

%  INDEX_VALUES.

% Source: https://dataclass.vhlab.org/labs/lab-3-1-time-series-correlation-feature-detection-rates
% 

index_values = 1+find( input(1:end-1)<threshold & input(2:end) >= threshold);