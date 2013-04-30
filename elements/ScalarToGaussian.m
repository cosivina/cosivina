% ScalarToGaussian (COSIVINA toolbox)
%   Element that creates a Gaussian activation pattern centered on a scalar
%   input value (scaled and shifed if necessary);
%
% Constructor call:
% ScalarToGaussian(label, size, inputScale, inputOffset, sigma, ...
%     amplitude, circular, normalized)
%   label - element label
%   size - size of the output pattern
%   inputScale - scalar factor applied to the input value
%   inputOffset - constant offset added to the scaled input
%   sigma - width parameter of Gaussian
%   amplitude - amplitude of Gaussian
%   circular - flag indicating whether Gaussian is defined circularly
%   normalized - flag indicating whether Gaussian is normalized before
%     scaling with amplitude


classdef ScalarToGaussian < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'inputScale', ParameterStatus.Changeable, ...
      'inputOffset', ParameterStatus.Changeable, 'sigma', ParameterStatus.Changeable, ...
      'amplitude', ParameterStatus.Changeable, 'circular', ParameterStatus.Changeable, ...
      'normalized', ParameterStatus.Changeable);
    components = {'output', 'position'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    inputScale = 1;
    inputOffset = 0;
    size = [1, 1];
    sigma = 1;
    amplitude = 0;
    circular = true;
    normalized = false;
    
    % accessible structures
    output
    position
  end
  
  methods
    % constructor
    function obj = ScalarToGaussian(label, size, inputScale, inputOffset, sigma, amplitude, circular, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 3
        obj.inputScale = inputScale;
      end
      if nargin >= 4
        obj.inputOffset = inputOffset;
      end
      if nargin >= 5
        obj.sigma = sigma;
      end
      if nargin >= 6
        obj.amplitude = amplitude;
      end
      if nargin >= 7
        obj.circular = circular;
      end
      if nargin >= 8
        obj.normalized = normalized;
      end
      
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.position = obj.inputScale * obj.inputElements{1}.(obj.inputComponents{1}) + obj.inputOffset;
      
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
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end
  end
  
end
