% SumDimension (COSIVINA toolbox)
%   Element that computes the sum over one or more dimensions of its input.
%   Optionally, the result can be scaled with a fixed amplitude, and the
%   order of dimensions in the formed sum can be changed.
% 
% Constructor call:
% SumDimension(label, sumDimensions, outputSize, amplitude, dimensionOrder)
%   sumDimensions - dimension(s) of the input over which the sum is computed
%     (either a single integer value or a vector of integers)
%   outputSize - size of the resulting output
%   amplitude (optional) - scalar value that is multiplied with the formed
%     sum (default is 1)
%   dimensionOrder (optional) - order in which the non-singleton dimensions
%     of the formed sum should appear in the output; must be a vector
%     containing the integers [1, ..., nDim] exactly once, where nDim is
%     the number of dimensions specified in outputSize; this argument has
%     no effect if the output is a vector (the argument outputSize can then
%     be used to determine whether the output is a row or column vector);
%     default is [1, ..., nDim])
% 
% Examples:
% SumDimension('vertical sum', 1, [1, 100]) - creates an element that sums
%   over the first (vertical) dimension of a two-dimensional input and
%   yields a column vector of size [1, 100]; no scaling is used
% SumDimension('full sum', [1, 2], [1, 1], -0.02) - creates an element
%   that sums over both dimensions of a two-dimensional input and scales
%   the result with a factor of -0.02, yielding a single scalar value (this
%   can be used to compute global inhibition in a two-dimensional field)
% SumDimension('complicated sum', [2, 4], [100, 50], 0.25, [2, 1]) -
%   creates an element that sums over the second and fourth dimension of a
%   four-dimensional input, then flips the remaining two dimensions (so
%   that the third dimension in the input is the first in the output, and
%   the first dimension in the input is the second in the output), and
%   scales the result with a factor of 0.25
% 
% Note: The SumDimension element will reshape the result (after
%   re-arranging the dimensions if required) to match outputSize, without
%   checking that the coherence of dimensions is retained in this
%   reshaping. Consistency must be ensured manually when setting the
%   parameters.


classdef SumDimension < Element
  
  properties (Constant)
    parameters = struct('sumDimensions', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed, ...
      'amplitude', ParameterStatus.Changeable, 'dimensionOrder', ParameterStatus.Fixed); 
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    sumDimensions = 1;
    amplitude = 1.0;
    size = [1, 1];
    dimensionOrder = [1, 2];
        
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = SumDimension(label, sumDimensions, outputSize, amplitude, dimensionOrder)
      if nargin > 0
        obj.label = label;
        obj.sumDimensions = sumDimensions;
        obj.size = outputSize;
      end
      if nargin >= 4
        obj.amplitude = amplitude;
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
      
      if nargin >= 5
        obj.dimensionOrder = dimensionOrder;
      else
        obj.dimensionOrder = 1:numel(obj.size);
      end
      if numel(obj.dimensionOrder) ~= numel(obj.size)
        error('SumDimension:Constructor:argumentMismatch', ...
          ['Size of argument dimensionOrder must match number of dimensions in argument outputSize ' ...
          '(if the output is a vector, dimensionOrder must have size two).']);
      end
      if ~isempty(setdiff(1:numel(obj.size), obj.dimensionOrder))
        error('SuDimension:Constructor:invalidArgument', ...
          ['The argument dimensionOrder must include all numbers from one to nDim exactly once, ' ...
          'where nDims is the numer of dimensions in the argument outputSize.']);
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      tmpSum = sum(obj.inputElements{1}.(obj.inputComponents{1}), obj.sumDimensions(1));
      for i = 2 : numel(obj.sumDimensions)
        tmpSum = sum(tmpSum, obj.sumDimensions(i));
      end
      obj.output = obj.amplitude * reshape(permute(squeeze(tmpSum), obj.dimensionOrder), [obj.size]);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
      
  end
end


