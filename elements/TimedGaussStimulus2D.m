% GaussStimulus2D (COSIVINA toolbox)
%   Creates a two-dimensional Gaussian stimulus that is active at specified
%   periods in simulation time.
%
% Constructor call:
% TimedGaussStimulus2D(label, size, sigmaY, sigmaX, amplitude, ...
%     positionY, positionX, onTimes, circularY, circularX, normalized)
%   label - element label
%   size - size of the output matrix
%   sigmaY, sigmaX - vertical and horizontal width parameter of the Gaussian
%   amplitude - amplitude of the Gaussian
%   positionY, positionX - vertical and horizontal center of the Gaussian
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     stimulus is on at simulation time t if tStartK <= t <= tEndK for
%     any K
%   circularY, circularX - flags indicating whether Gaussian is defined
%     circularly (default value is true)
%   normalized - flag indicating whether Gaussian is normalized before
%     scaling with amplitude (default value is false)


classdef TimedGaussStimulus2D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaX', ParameterStatus.InitStepRequired, ...
      'sigmaY', ParameterStatus.InitStepRequired, 'amplitude', ParameterStatus.InitStepRequired, ...
      'positionX', ParameterStatus.InitStepRequired, 'positionY', ParameterStatus.InitStepRequired, ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix), ...
      'circularX', ParameterStatus.InitStepRequired, 'circularY', ParameterStatus.InitStepRequired, ...
      'normalized', ParameterStatus.InitStepRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaX = 1;
    sigmaY = 1;
    amplitude = 0;
    positionX = 1;
    positionY = 1;
    onTimes = zeros(0, 2);
    circularX = true;
    circularY = true;
    normalized = false;
    
    on = false;
    stimulusPattern = [];
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = TimedGaussStimulus2D(label, stimulusSize, sigmaY, sigmaX, amplitude, positionY, positionX, onTimes, ...
        circularY, circularX, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = stimulusSize;
      end
      if nargin >= 4
        obj.sigmaY = sigmaY;
        obj.sigmaX = sigmaX;
      end
      if nargin >= 5
        obj.amplitude = amplitude;
      end
      if nargin >= 7
        obj.positionY = positionY;
        obj.positionX = positionX;
      end
      if nargin >= 8
        obj.onTimes = onTimes;
      end
      if nargin >= 10
        obj.circularY = circularY;
        obj.circularX = circularX;
      end
      if nargin >= 11
        obj.normalized = normalized;
      end
      
      if size(obj.onTimes, 2) ~= 2 %#ok<CPROP>
        error('TimedGaussStimulus2D:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      shouldBeOn = any(time >= obj.onTimes(:, 1) & time <= obj.onTimes(:, 2));
      if ~obj.on && shouldBeOn
        obj.output = obj.stimulusPattern;
        obj.on = true;
      elseif obj.on && ~shouldBeOn
        obj.output(:) = 0;
        obj.on = false;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.stimulusPattern = circularGauss2d(1:obj.size(1), 1:obj.size(2), obj.positionY, obj.positionX, ...
        obj.sigmaY, obj.sigmaX, [], obj.circularY, obj.circularX);
      if obj.normalized && any(any(obj.output)) > 0
        obj.stimulusPattern = (obj.amplitude / sum(sum(obj.output))) * obj.stimulusPatttern;
      else
        obj.stimulusPattern = obj.amplitude * obj.stimulusPattern;
      end
      obj.output = zeros(obj.size);
      obj.on = false;
    end
  end
  
end
