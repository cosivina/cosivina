% DiagonalSum (COSIVINA toolbox)
%   Element that forms a sum diagonally from a NxN matrix to yield a vector
%   of size 2*N-1.
%
% Constructor call:
% DiagonalSum(label, inputSize, amplitude)
%   inputSize - size of the square input matrix
%   amplitude - scalar value that is multiplied with the formed sum


classdef DiagonalSum < Element
  
  properties (Constant)
    parameters = struct('inputSize', ParameterStatus.Fixed, 'amplitude', ParameterStatus.Changeable);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    amplitude = 0;
    inputSize = [1, 1];
    
    % accessible structures
    output
  end
  
  properties (SetAccess = private)
    indexMap = [];
    validPositions = [];
  end
  
  methods
    % constructor
    function obj = DiagonalSum(label, inputSize, amplitude)
      if nargin > 0
        obj.label = label;
        obj.inputSize = inputSize;
      end
      if nargin >= 3
        obj.amplitude = amplitude;
      end      

      if numel(obj.inputSize) > 1 && obj.inputSize(1) ~= obj.inputSize(2)
        error('DiagonalSum:Constructor:invalidInputSize', ...
          'Input must be a square matrix (elements of inputSize must be equal.');
      elseif numel(obj.inputSize) == 1
        obj.inputSize = repmat(obj.inputSize, [1, 2]);
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.amplitude ...
        * sum(obj.inputElements{1}.(obj.inputComponents{1})(obj.indexMap) .* obj.validPositions, 1);
    end
    
    
    % initialization
    function obj = init(obj)
      [X Y] = meshgrid(-obj.inputSize(1) + 1 : obj.inputSize(1) - 1, 1:obj.inputSize(1));
      XX = X + flipud(Y);
      obj.validPositions = (XX >= 1) & (XX <= obj.inputSize(1));
      obj.indexMap = sub2ind(obj.inputSize, Y, max(min(XX, obj.inputSize(1)), 1));
      obj.output = zeros(1, 2*obj.inputSize(1) - 1);
    end
      
  end
end


