function alpha1 = find_alpha1(skewness_val)

% this function returns the alpha 1 value corresponding to a particular
% skewnewss of an ISI histogram of interest. The scale was formed by Kapucu
% et al. Alpha1 value is multiplied by ISI_burst_threshold_prelim (from
% cnoscript.m) to find the interburst ISI threshold.

% Original Script by: Sayaka (Saya) Minegishi
% Contact: minegishis@brandeis.edu
% Date: Oct 6 2023

if (skewness_val < 1)
    alpha1 = 1;
elseif (skewness_val >= 1 & skewness_val < 4)
    alpha1 = 0.7;
elseif (skewness_val >= 4 & skewness_val < 9)
    alpha1 = 0.5;
else
    alpha1 = 0.3;
end

end