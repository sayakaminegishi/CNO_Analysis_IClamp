function [fitresult, gof] = nakaRushtonThreshFit2(c, r)
% Custom thresholded Naka-Rushton fit without using external 'rectify'

% Ensure column vectors
c = c(:);
r = r(:);

% Remove NaNs
valid_idx = ~isnan(c) & ~isnan(r);
c = c(valid_idx);
r = r(valid_idx);

% Check input length
if numel(c) ~= numel(r)
    error('Vectors c and r must be the same length');
end

% Estimate upper bound for threshold
t_upper = median(c);

% Define the model using max() directly (no rectify)
modelFun = @(Rm, b, t, c) (max(0, c - t) .* Rm) ./ (b + max(0, c - t));

% Create fittype
ft = fittype(modelFun, ...
    'independent', 'c', ...
    'dependent', 'r', ...
    'coefficients', {'Rm', 'b', 't'});

% Fit options
opts = fitoptions('Method', 'NonlinearLeastSquares');
opts.StartPoint = [0.1, 0.1, t_upper / 2] + 0.05 * randn(1, 3);
opts.Lower = [0, 0, 0];
opts.Upper = [Inf, Inf, t_upper];

% Perform fit
[fitresult, gof] = fit(c, r, ft, opts);
end
