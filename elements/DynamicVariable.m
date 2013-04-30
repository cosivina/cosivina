% DynamicVariable (COSIVINA toolbox)
%   Creates a matrix of dynamic variables. The input is interpreted as a
%   rate of change, which is scaled with a time constant to change the
%   state of the dynamic variables.
% 
% Constructor call:
% DynamicVariable(label, matrixSize, tau, initialState)
%   label - element label
%   matrixSize - size of the matrix of dynamic variables
%   tau - time constant (default = 10)
%   initialState - state of the dynamic variables at initialization
%     (default = zeros(matrixSize))


classdef DynamicVariable < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'tau', ParameterStatus.Changeable, ...
      'initialState', ParameterStatus.Fixed);
    components = {'state', 'initialState'};
    defaultOutputComponent = 'state';
  end
  
  properties
    % parameters
    size = [1, 1];
    tau = 10;
    initialState = 0;
    
    % accessible structures
    state
  end
  
  methods
    % constructor
    function obj = DynamicVariable(label, matrixSize, tau, initialState)
      if nargin > 0
        obj.label = label;
        obj.size = matrixSize;
        if numel(obj.size) == 1
          obj.size = [1, obj.size];
        end
      end
      if nargin >= 3
        obj.tau = tau;
      end
      if nargin >= 4
        obj.initialState = initialState;
      else
        obj.initialState = zeros(obj.size);
      end
      
      if ~ismatrix(obj.initialState) || any(size(obj.initialState) ~= obj.size) %#ok<CPROP>
        error('DynamicVariable:constructor:sizeMismatch', ...
          'The size of the argument initialState must match the element''s size parameter');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      input = 0;
      for i = 1 : obj.nInputs
        input = input + obj.inputElements{i}.(obj.inputComponents{i});
      end
      obj.state = obj.state + deltaT/obj.tau * input;
    end
    
    
    % intialization
    function obj = init(obj)
      obj.state = obj.initialState;
    end
  end
end


