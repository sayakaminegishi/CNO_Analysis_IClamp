function c50 = halfMaxInterpolated(currentInjections, responses)
% CONTRASTFIT2C50- Compute Half maximum
%
%   C50 = vis.contrast.indexes.contrastfit2c50(CONTRAST, RESPONSE)
%
%  Given contrast in 1 percent steps in CONTRAST, this function
%  computes the half maximum value that is defined as:
%
%  value of C such that R(C50) = 0.5 * max(R)
%
%  Units of contrast can be percent or from 0 to 1.
%  responses should be a row vector
%  
%  Note that this empirical C50 does not equal the C50 of a Naka-Rushton equation.
%
%  See Heimel et al. 2005 (Journal of Neurophysiology)


zero = vlt.data.findclosest(currentInjections,0);

responses = responses - responses(zero); %respoose due to current injections

Rmax = max(responses(zero:end));

[dummy,currentIndex] = find(responses>=0.5*Rmax,1);

c50 = currentInjections(currentIndex);