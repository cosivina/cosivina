% GaussStimulus1D (COSIVINA toolbox)
%   Creates a one-dimensional Gaussian stimulus.
%
% Constructor call:
% GaussStimulus1D(label, size, sigma, amplitude, position, circular, normalized)
%   label - element label
%   size - size of the output vector
%   sigma - width parameter of the Gaussian
%   amplitude - amplitude of the Gaussian
%   position - center of the Gaussian
%   circular - flag indicating whether Gaussian is circular (default value
%     is true)
%   normalized - flag indicating whether Gaussian is normalized before
%     scaling with amplitude (default value is false)


classdef GaussStimulus1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigma', ParameterStatus.InitRequired, ...
      'amplitude', ParameterStatus.InitRequired, 'position', ParameterStatus.InitRequired, ...
      'circular', ParameterStatus.InitRequired, 'normalized', ParameterStatus.InitRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigma = 1;
    amplitude = 0;
    position = 1;
    circular = true;
    normalized = false;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = GaussStimulus1D(label, size, sigma, amplitude, position, circular, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = size;
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
        obj.circular = circular;
      end
      if nargin >= 7
        obj.normalized = normalized;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj)
      if obj.circular
        obj.output = circularGauss(1 : obj.size(2), obj.position, obj.sigma);
      else
        obj.output = gauss(1 : obj.size(2), obj.position, obj.sigma);
      end
      if obj.normalized && sum(obj.output) > 0
        obj.output = obj.amplitude * obj.output / sum(obj.output);
      else
        obj.output = obj.amplitude * obj.output;
      end
    end
  end
  
end
