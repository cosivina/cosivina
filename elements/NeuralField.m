% NeuralField (COSIVINA toolbox)
%   Creates a dynamic neural field (or set of discrete dynamic nodes) of
%   arbitrary dimensionality with sigmoid (logistic) output function. The
%   field activation is updated according to the Amari equation.
% 
% Constructor call:
% NeuralField(label, size, tau, h, beta)
%   label - element label
%   size - field size
%   tau - time constant
%   h - resting level
%   beta - steepness of sigmoid output function


classdef NeuralField < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'tau', ParameterStatus.Changeable, ...
      'h', ParameterStatus.Changeable, 'beta', ParameterStatus.Changeable);
    components = {'input', 'activation', 'output', 'h'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    tau = 10;
    h = -5;
    beta = 4;
    
    % accessible structures
    input
    activation
    output
  end
  
  methods
    % constructor
    function obj = NeuralField(label, size, tau, h, beta)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.tau = tau;
      end
      if nargin >= 4
        obj.h = h;
      end
      if nargin >= 5
        obj.beta = beta;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      obj.input(:) = 0;
      for i = 1 : obj.nInputs
        obj.input = obj.input + obj.inputElements{i}.(obj.inputComponents{i});
      end
      obj.activation = obj.activation + deltaT/obj.tau * (- obj.activation + obj.h + obj.input);
      obj.output = sigmoid(obj.activation, obj.beta, 0);
    end
    
    
    % intialization
    function obj = init(obj)
      obj.input = zeros(obj.size);
      obj.activation = zeros(obj.size) + obj.h;
      obj.output = sigmoid(obj.activation, obj.beta, 0);
    end
  end
end


