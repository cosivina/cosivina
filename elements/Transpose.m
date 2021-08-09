% Transpose (COSIVINA toolbox)
%   Connective element that transposes its input.
%   
%   Note: In more recent versions of Matlab, it is no longer necessary for
%   matrices to have the same size in order to be added; they only need to have
%   compatible sizes and are automatically expanded as necessary. As a
%   consequence of this, ExpandDimension2D elements can often be omitted or
%   replaced with a faster Transpose element.
%
% Constructor call:
% Transpose(label, outputSize)
%   outputSize - size of the matrix that results from the transposition


classdef Transpose < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
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
    function obj = Transpose(label, outputSize)
      if nargin > 0
        obj.label = label;
        obj.size = outputSize;
      end

      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = obj.inputElements{1}.(obj.inputComponents{1})';
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
      
  end
end


