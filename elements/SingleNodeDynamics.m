% SingleNodeDynamics (COSIVINA toolbox)
%   Creates a single dynamic node and computes rates of change for all
%   possible activation states within a specified range. (Note: This
%   class is mainly for visualization and analysis; if you just want
%   the basic behavior of a dynamic node, use NeuralField class instead.)
% 
% Constructor call:
% SingleNodeDynamics(label, tau, h, beta, selfExcitation, range, resolution)
%   label - element label
%   tau - time constant
%   h - resting level
%   beta - steepness of sigmoid output function
%   selfExcitation - amplitude of self-excitation (negative values yield
%      inhibition)
%   noiseLevel - strength of Gaussian noise
%   range - range of activation values for which rates of 
%     change is computed
%   resolution - step size with which range is sampled


classdef SingleNodeDynamics < Element
  
  properties (Constant)
    parameters = struct('tau', ParameterStatus.Changeable, 'h', ParameterStatus.Changeable, ...
      'beta', ParameterStatus.Changeable, 'selfExcitation', ParameterStatus.Changeable, ...
      'noiseLevel', ParameterStatus.Changeable, ...
      'range', ParameterStatus.Fixed, 'resolution', ParameterStatus.Fixed);
    components = {'input', 'activation', 'output', 'h', 'rateOfChange', 'samplingPoints', 'sampledRatesOfChange', ...
      'attractorStates', 'attractorRatesOfChange', 'repellorStates', 'repellorRatesOfChange'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    tau = 10;
    h = -5;
    beta = 4;
    selfExcitation = 0;
    noiseLevel = 0;
    range = [-10, 10];
    resolution = 0.1;
    
    % accessible structures
    input
    activation
    output
    rateOfChange
    samplingPoints
    sampledRatesOfChange
    attractorStates
    attractorRatesOfChange
    repellorStates
    repellorRatesOfChange
  end
  
  methods
    % constructor
    function obj = SingleNodeDynamics(label, tau, h, beta, selfExcitation, noiseLevel, range, resolution)
      if nargin > 0
        obj.label = label;
      end
      if nargin >= 2
        obj.tau = tau;
      end
      if nargin >= 3
        obj.h = h;
      end
      if nargin >= 4
        obj.beta = beta;
      end
      if nargin >= 5
        obj.selfExcitation = selfExcitation;
      end
      if nargin >= 6
        obj.noiseLevel = noiseLevel;
      end
      if nargin >= 7
        obj.range = range;
      end
      if nargin >= 8
        obj.resolution = resolution;
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSL>
      obj.input = 0;
      for i = 1 : obj.nInputs
        obj.input = obj.input + obj.inputElements{i}.(obj.inputComponents{i});
      end
      
      obj.activation = obj.activation + deltaT * obj.rateOfChange + sqrt(deltaT) * obj.noiseLevel * randn;
      obj.output = sigmoid(obj.activation, obj.beta, 0);
      obj.rateOfChange = 1/obj.tau * (-obj.activation + obj.h + obj.selfExcitation * obj.output + obj.input);
      
      obj.sampledRatesOfChange = 1/obj.tau * ...
        (-obj.samplingPoints + obj.h + obj.selfExcitation * sigmoid(obj.samplingPoints, obj.beta, 0) + obj.input);
      
      iAttractor = find(diff(obj.sampledRatesOfChange < 0) == 1);
      y1 = obj.sampledRatesOfChange(iAttractor);
      y2 = obj.sampledRatesOfChange(iAttractor+1);
      obj.attractorStates = obj.samplingPoints(iAttractor) - (y1 * obj.resolution) ./ (y2 - y1);
      obj.attractorRatesOfChange = 1/obj.tau * ...
        (-obj.attractorStates + obj.h + obj.selfExcitation * sigmoid(obj.attractorStates, obj.beta, 0) + obj.input);
      
%       iRepellor = find(diff(obj.sampledRatesOfChange > 0) == 1);
      obj.repellorStates = obj.samplingPoints(diff(obj.sampledRatesOfChange > 0) == 1) + obj.resolution * 0.5;
      obj.repellorRatesOfChange = 1/obj.tau * ...
        (-obj.repellorStates + obj.h + obj.selfExcitation * sigmoid(obj.repellorStates, obj.beta, 0) + obj.input);
    end
    
    
    % intialization
    function obj = init(obj)
      obj.input = 0;
      obj.activation = obj.h;
      obj.output = sigmoid(obj.activation, obj.beta, 0);
      obj.rateOfChange = 1/obj.tau * (-obj.activation + obj.h + obj.selfExcitation * obj.output + obj.input);
      
      obj.samplingPoints = obj.range(1) : obj.resolution : obj.range(2);
      obj.sampledRatesOfChange = 1/obj.tau * ...
        (-obj.samplingPoints + obj.h + obj.selfExcitation * sigmoid(obj.samplingPoints, obj.beta, 0) + obj.input);
      
      iAttractor = find(diff(obj.sampledRatesOfChange < 0) == 1);
      obj.attractorStates = obj.samplingPoints(iAttractor+1) + obj.resolution * 0.5;
      obj.attractorRatesOfChange = 1/obj.tau * ...
        (-obj.attractorStates + obj.h + obj.selfExcitation * sigmoid(obj.attractorStates, obj.beta, 0) + obj.input);
      
      iRepellor = find(diff(obj.sampledRatesOfChange > 0) == 1);
      obj.repellorStates = obj.samplingPoints(iRepellor+1) + obj.resolution * 0.5;
      obj.repellorRatesOfChange = 1/obj.tau * ...
        (-obj.repellorStates + obj.h + obj.selfExcitation * sigmoid(obj.repellorStates, obj.beta, 0) + obj.input);
    end
  end
end


