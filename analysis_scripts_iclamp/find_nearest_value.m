function [closestIndex, closestValue] = find_nearest_value(target_val, data)
% returns element value in 'data' array that is closest to target_val

% code with repmat based on: https://www.mathworks.com/matlabcentral/answers/152301-find-closest-value-in-array#answer_336210
% Modified by Sayaka Minegishi (minegishis@brandeis.edu)
% Date: Oct 7 2023


% % display(target_val)
% for k = 1:numel(data)-1
%     if(target_val >= data(k+1) & target_val< data(k))
%         %the target is between these 2 bins, find the closest bin center
%         if (abs(target_val - data(k+1)) >= abs(target_val - data(k)))
% 
%             closestValue= data(k);
%             closestIndex = k;
%         else
% 
%             closestValue = data(k+1);
%             closestIndex = k+1;
%         end
% 
% 
%     end
% end




A = repmat(data,[1 length(target_val)]);
[minValue,closestIndex] = min(abs(data-target_val));
closestValue = data(closestIndex) 

end