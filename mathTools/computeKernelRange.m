% determine the range for an interaction kernel
% returns a two-element vector [rangeLeft, rangeRight]
% default range is sigma * cutoffFactor, but limited by fieldSize

function r = computeKernelRange(sigma, cutoffFactor, fieldSize, circular)
  if nargin < 4 || circular
    r = min(ceil(sigma * cutoffFactor), [floor((fieldSize-1)/2), ceil((fieldSize-1)/2)]);
  else
    r = repmat(min(ceil(sigma * cutoffFactor), (fieldSize - 1)), [1, 2]);
  end
end