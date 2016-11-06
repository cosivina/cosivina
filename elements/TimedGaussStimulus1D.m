% TimedGaussStimulus1D (COSIVINA toolbox)
%   Creates a one-dimensional Gaussian stimulus that is active at specified
%   periods in simulation time.
%
% Constructor call:
% TimedGaussStimulus1D(label, size, sigma, amplitude, position, onTimes,
%     circular, normalized)
%   label - element label
%   size - size of the output vector
%   sigma - width parameter of the Gaussian
%   amplitude - amplitude of the Gaussian
%   position - center of the Gaussian
%   onTimes - Nx2 matrix of the form [tStart1, tEnd1; ...; tStartN, tEndN];
%     stimulus is on at simulation time t if tStartK <= t <= tEndK for
%     any K
%   circular - flag indicating whether Gaussian is circular (default value
%     is true)
%   normalized - flag indicating whether Gaussian is normalized before
%     scaling with amplitude (default value is false)


classdef TimedGaussStimulus1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigma', ParameterStatus.InitStepRequired, ...
      'amplitude', ParameterStatus.InitStepRequired, 'position', ParameterStatus.InitStepRequired, ...
      'onTimes', bitor(ParameterStatus.Changeable, ParameterStatus.VariableRowsMatrix), ...
      'circular', ParameterStatus.InitStepRequired, 'normalized', ParameterStatus.InitStepRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigma = 1;
    amplitude = 0;
    position = 1;
    onTimes = zeros(0, 2);
    circular = true;
    normalized = false;
    
    on = false;
    stimulusPattern = [];
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = TimedGaussStimulus1D(label, stimulusSize, sigma, amplitude, position, onTimes, circular, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = stimulusSize;
      end
      if nargin >= 3
        obj.sigma = sigma;
      end
      if nargin >= 4
        obj.amplitude = amplitude;
      end
      if nargin >= 5
        obj.position = position;
      end
      if nargin >= 6
        obj.onTimes = onTimes;
      end
      if nargin >= 7
        obj.circular = circular;
      end
      if nargin >= 8
        obj.normalized = normalized;
      end
      
      if size(obj.onTimes, 2) ~= 2 %#ok<CPROP>
        error('TimedGaussStimulus1D:constructor:invalidArgument', 'Argument onTimes must be an Nx2 matrix.');
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
      if obj.circular
        obj.stimulusPattern = circularGauss(1 : obj.size(2), obj.position, obj.sigma);
      else
        obj.stimulusPattern = gauss(1 : obj.size(2), obj.position, obj.sigma);
      end
      if obj.normalized && any(obj.output) > 0
        obj.stimulusPattern = (obj.amplitude / sum(obj.output)) * obj.stimulusPattern;
      else
        obj.stimulusPattern = obj.amplitude * obj.stimulusPattern;
      end
      obj.output = zeros(obj.size);
      obj.on = false;
    end
  end
  
end
