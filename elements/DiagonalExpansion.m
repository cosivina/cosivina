% DiagonalExpansion (COSIVINA toolbox)
%   Expands a 1D input diagonally into a square matrix.
%
% Constructor call:
% DiagonalExpansion(label, inputSize, amplitude)
%   inputSize - size of the input (must be odd)
%   amplitude - scalar value that is multiplied with the input before
%     expansion

classdef DiagonalExpansion < Element
  
  properties (Constant)
    parameters = struct('inputSize', ParameterStatus.Fixed, 'amplitude', ParameterStatus.Changeable);
    components= {'output'};
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
  end
  
  methods
    % constructor
    function obj = DiagonalExpansion(label, inputSize, amplitude)
      if nargin > 0
        obj.label = label;
        obj.inputSize = inputSize;
      end
      if nargin >= 3
        obj.amplitude = amplitude;
      end      

      if numel(obj.inputSize) == 1
        obj.inputSize = [1, obj.inputSize];
      end
      if obj.inputSize(1) ~= 1 || mod(obj.inputSize(2), 2) ~= 1 || numel(obj.inputSize) > 2
        error('DiagonalExpansion:Constructor:invalidInputSize', ...
          'Input must be a row vector with an odd number of elements (inputSize must have the form 2*N+1 or [1, 2*N+1]).');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1})(obj.indexMap);
    end
    
    
    % initialization
    function obj = init(obj)
      outputSize = (obj.inputSize(2)+1)/2;
      [X Y] = meshgrid(1 : outputSize);
      obj.indexMap = X + Y - 1;
      obj.output = zeros(outputSize);
    end
  end
end


