function plotNakaRushtonThresh(c, t, Rm, b)
%PLOTFIT(C, T, RM, B)
%   Plots the fitted function R(c) = rectify(c-t) .* Rm * (c-t) ./(b+(c-t))
%   over the range of the input data 'c', and overlays the original data points.
%
%   Input:
%       c:  predictor data, assumed to be a column vector.
%       t:  parameter t of the model.
%       Rm:  parameter Rm of the model (Rm > 0).
%       b:  parameter b of the model (b > 0).
%
%   Output:
%       None (displays a plot).
%
%   Example:
%       c = [1; 2; 3; 4; 5];
%       r = [0.1; 0.2; 0.5; 0.8; 1.2];
%       [fitresult, gof] = createFit(c, r); % Use the function from before
%       coeffs = coeffvalues(fitresult);
%       t = coeffs(3);
%       Rm = coeffs(1);
%       b = coeffs(2);
%       plotFit(c, t, Rm, b);
%
%   See also CREATEFIT.

% Ensure c is a column vector
c = c(:);

% Check for valid input parameters
if Rm <= 0
    error('Rm must be greater than 0.');
end
if b <= 0
    error('b must be greater than 0.');
end

% Generate points for the fitted curve.  Use a finer spacing than the
% original data to make the curve look smooth.
c_fit = linspace(min(c), max(c), 100)'; % Use a column vector

% Calculate the fitted R values.
r_fit = rectify(c_fit-t) .* Rm ./ (b + rectify(c_fit-t));

% Create the plot.
%figure;  % Open a new figure window.
%plot(c, r, 'o', 'DisplayName', 'Data'); % Plot the original data as circles.
hold on; %  Prevent the next plot from erasing the current one.
plot(c_fit, r_fit, 'ro-', 'DisplayName', 'Fit'); % Plot the fitted curve as a line.
hold off; %  Allow subsequent plots to erase this one.

% Add labels and a title.
xlabel('c');
ylabel('R(c)');
title(sprintf('Fit: R(c) = rectify(c-%.2f) .* %.2f * (c-%.2f) ./ (%.2f+(c-%.2f))', t, Rm, t, b, t));
legend; % Show the legend to distinguish data and fit.
grid on; % Add a grid for easier reading.
end

function b = rectify(x)
    b = x;
    b(x<0)=0;
end
