function si = fit2saturationindex(currentInjections, responses, referenceCurrent)
% CONTRASTFIT2SATURATIONINDEX - Compute Saturation Index 
%
%   SI = ndi.vis.contrast.contrastfit2saturationindex(CONTRAST, RESPONSE)
%
%  Given contrast in 1 percent steps in CONTRAST, this function
%  computes the "saturation index" that is defined as:
%
%  SI = (Rmax - R(100)) / (Rmax - R(0))
%
%  This is the amount of "super saturation" at 100% contrast.
%
%  Units of contrast can be percent or from 0 to 1.
%
%  If Rmax == R(0), then the measure is undefined and the index that is
%  returned is NaN.
%
%  This index is called MI in Peirce 2007 (JoV)


referenceIndex = vlt.data.findclosest(currentInjections,referenceCurrent); %which points has the reference current


zero = vlt.data.findclosest(currentInjections,0);

Rmax = max(responses(zero:referenceIndex));

si = (Rmax-responses(referenceIndex))/(Rmax-responses(zero));

if isinf(si), si = NaN; 
end;