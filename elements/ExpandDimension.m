% ExpandDimension (COSIVINA toolbox)
%   Element that expands a lower-dimensional input into a
%   higher-dimensional matrix. Corresponding dimensions in input and output
%   can be specified freely.
%
% Constructor call:
% ExpandDimension(label, inputSize, outputSize, dimensionMaping)
%   inputSize - size of the input matrix
%   outputSize - size of the desired output matrix
%   dimensionMapping - vector of integers specifying which dimension in
%     the input matrix should be mapped to which dimension in the output
%     matrix; the size of this vector must match the number of dimensions
%     in the input matrix; The i-th entry determines to which dimension in
%     the output the i-th dimension of the input is mapped; if the input is
%     a vector, this argument may be either a single integer, or a
%     two-element vector (since vectors are treated as two-dimensional
%     matrcies in Matlab); singleton dimensions in the input may be mapped
%     to arbitrary dimensions in the output
%
% Examples:
% ExpandDimension('vertical', 100, [50, 100], 2) - expands a row-vector
%   into a matrix by repeating it over the vertical dimension
% ExpandDimension('vertical', [1, 100], [50, 100], [1, 2]) - the same as
%   above, but treating the row vector as a 1x100 matrix
% ExpandDimension('horizontal', 100, [100, 50], 1) - maps a row vector to
%   the vertical dimension of a matrix and repeats it over the horizontal
%   dimension
% ExpandDimension('complicated', [10, 1, 15], [15, 5, 5, 10], [4, 2, 1]) 
%   - maps a three-dimensional input matrix (with singleton second
%   dimension) onto a four-dimensional output; the first dimension of the
%   input is mapped to the fourth dimension of the output, the third
%   dimension of the input is mapped to the first dimension of the output;
%   the mapping of the singleton second dimension is arbitrary


classdef ExpandDimension < Element
  
  properties (Constant)
    parameters = struct('inputSize', ParameterStatus.Fixed, 'outputSize', ParameterStatus.Fixed, ...
      'dimensionMapping', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    dimensionMapping = 2;
    inputSize = [1, 1];
    outputSize = [1, 1];
    
    % accessible structures
    output
  end
  
  properties (SetAccess = private)
    permuteOrder
    reshapeSize
    repmatSize
  end
  
  methods
    % constructor
    function obj = ExpandDimension(label, inputSize, outputSize, dimensionMapping)
      if nargin > 0
        obj.label = label;
        obj.inputSize = inputSize;
        obj.outputSize = outputSize;
        obj.dimensionMapping = dimensionMapping;
      end
      
      if numel(obj.inputSize) == 1
        obj.inputSize = [1, obj.inputSize];
      end
      if numel(obj.outputSize) == 1
        obj.outputSize = [1, obj.outputSize];
      end
      
      % automatically fill in entries of dimensionMapping for vector/scalar
      % input
      if all(obj.inputSize == 1)
        obj.dimensionMapping = 1 : numel(obj.inputSize);
      elseif numel(obj.dimensionMapping) == 1 && numel(obj.inputSize) == 2 && any(obj.inputSize) == 1
        tmpMapping = [1, 1];
        tmpMapping(obj.inputSize > 1) = obj.dimensionMapping;
        if obj.dimensionMapping == 1
          tmpMapping(obj.inputSize == 1) = 2;
        end
        obj.dimensionMapping = tmpMapping;
      end
      
      if numel(obj.dimensionMapping) ~= numel(obj.inputSize) ...
          || any(obj.dimensionMapping > numel(obj.outputSize))
        error('ExpandDimension:Constructor:invalidArgument', ...
          ['Argument dimensionMapping must have one entry for every dimension in the input array that specifies ' ...
          'one dimension in the output array to which it is mapped.']);
      end
      
      nonSingleton = obj.inputSize > 1;
      if any(obj.inputSize(nonSingleton) ~= obj.outputSize(obj.dimensionMapping(nonSingleton)))
        error('ExpandDimension:Constructor:argumentMismatch', ...
          ['Each non-singleton dimension in the input (as specified by argument inputSize) must be mapped to ' ...
          'a dimension of equal size in the output (as specified by argument outputSize).']); 
      end
      
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = repmat(reshape(permute(obj.inputElements{1}.(obj.inputComponents{1}), obj.permuteOrder), ...
        obj.reshapeSize), obj.repmatSize);
    end
    
    
    % initialization
    function obj = init(obj)
      [x, obj.permuteOrder] = sort(obj.dimensionMapping); %#ok<ASGLU>
      
      obj.reshapeSize = ones(1, numel(obj.outputSize));
      obj.reshapeSize(obj.dimensionMapping) = obj.inputSize;
      obj.repmatSize = obj.outputSize ./ obj.reshapeSize;
      
      obj.output = zeros(obj.outputSize);
    end
    
  end
end


