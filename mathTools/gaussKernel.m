% creates a symmetrical, normalized gaussian kernel with one positive and one negative mode and an 
%   optional global component
% 
% if widthMultiplier is positive, it is used to determine the kernel range up to the given maxRange
%   (set maxRange to inf if you never want the range cut off)
% if widthMultiplier is negative, the kernel range is always set to maxRange

function [kernel, range] = gaussKernel(c_exc, sigma_exc, c_inh, sigma_inh, g_inh, ...
  maxRange, widthMultiplier, fieldResolution)

  % default values for optional parameters
  defaultResolution = 1;
  defaultMultiplier = 5;
  defaultMaxRange = inf;

  % set optional parameters to default values if not set explicitly
  if nargin < 8
    fieldResolution = defaultResolution;
  end
  if nargin == 6
    widthMultiplier = -1;
  end
  if nargin < 6
    widthMultiplier = defaultMultiplier;
    maxRange = defaultMaxRange;
  end
  if nargin < 5
    g_inh = 0;
  end
  if nargin < 3
    c_inh = 0;
    sigma_inh = 0;
  end
  
  if widthMultiplier < 0
    widthMultiplier = inf;
  end
  
  if maxRange < 0 || (widthMultiplier == inf && maxRange == inf)
    error(['Invalid range parameters for kernel: either maxRange or widthMultiplier must be a',...
      'positive, non-infinite value.'])
  else
    
    % determine kernel range
    range = min(ceil(widthMultiplier * max(sigma_exc, sigma_inh) * fieldResolution), floor(maxRange));
    
    % calculate kernel
    kernel = c_exc * gaussNorm(-range:range, 0, sigma_exc * fieldResolution) ...
      - c_inh * gaussNorm(-range:range, 0, sigma_inh * fieldResolution) - g_inh / fieldResolution;
  end
  
end

