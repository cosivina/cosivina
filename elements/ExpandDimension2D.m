% ExpandDimension2D (COSIVINA toolbox)
%   Element that expands a 1D input into a 2D matrix. The input is automatically
%   transposed if necessary.
%   
%   Note: In more recent versions of Matlab, it is no longer necessary for
%   matrices to have the same size in order to be added; they only need to have
%   compatible sizes and are automatically expanded as necessary. As a
%   consequence of this, ExpandDimension2D elements can often be omitted or
%   replaced with a faster Transpose element.
%
% Constructor call:
% ExpandDimension2D(label, expandDimension, outputSize)
%   expandDimension - dimension (1 or 2) along which input is expanded
%   outputSize - size of the matrix resulting from the expansion


classdef ExpandDimension2D < Element
  
  properties (Constant)
    parameters = struct('expandDimension', ParameterStatus.Fixed, 'size', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    expandDimension = 1;
    size = [1, 1];
    
    % accessible structures
    output
  end
  
  properties (SetAccess = private)
    reshapeSize
    repmatSize
  end
  
  methods
    % constructor
    function obj = ExpandDimension2D(label, expandDimension, outputSize)
      if nargin > 0
        obj.label = label;
        obj.expandDimension = expandDimension;
        obj.size = outputSize;
      end

      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = repmat(reshape(obj.inputElements{1}.(obj.inputComponents{1}), obj.reshapeSize), obj.repmatSize);
    end
    
    
    % initialization
    function obj = init(obj)
      if obj.expandDimension == 1
        obj.reshapeSize = [1, obj.size(2)];
        obj.repmatSize = [obj.size(1), 1];
      elseif obj.expandDimension == 2
        obj.reshapeSize = [obj.size(1), 1];
        obj.repmatSize = [1, obj.size(2)];
      end
      obj.output = zeros(obj.size);
    end
      
  end
end


