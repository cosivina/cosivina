% GaussStimulus3D (COSIVINA toolbox)
%   Creates a Gaussian stimulus over a three-dimensional space (consistent
%   with Matlab convention, the first dimension of the feature space is
%   designated with the letter y, the second with x, and the third with z
%   in the naming of the parameters).
%
% Constructor call:
% GaussStimulus3D(label, size, sigmaY, sigmaX, sigmaZ, amplitude, ...
%     positionY, positionX, positionZ, circularY, circularX, circularZ, ...
%     normalized)
%   label - element label
%   size - size of the created stimulus (as a three-element vector)
%   sigmaY, sigmaX, sigmaZ - width parameter of the Gaussian along the
%     first, second and third dimension of the feature space
%   amplitude - amplitude of the Gaussian
%   positionY, positionX, positionZ - position of the Gaussian's center
%   circularY, circularX, circularZ - flags indicating whether Gaussian is
%     defined circularly (default value is true for all three)
%   normalized - flag indicating whether Gaussian is normalized before
%     scaling with amplitude (default value is false)



classdef GaussStimulus3D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'sigmaX', ParameterStatus.InitRequired, ...
      'sigmaY', ParameterStatus.InitRequired, 'sigmaZ', ParameterStatus.InitRequired, ...
      'amplitude', ParameterStatus.InitRequired, 'positionX', ParameterStatus.InitRequired, ...
      'positionY', ParameterStatus.InitRequired, 'positionZ', ParameterStatus.InitRequired, ...
      'circularX', ParameterStatus.InitRequired, 'circularY', ParameterStatus.InitRequired, ...
      'circularZ', ParameterStatus.InitRequired, 'normalized', ParameterStatus.InitRequired);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    sigmaX = 1;
    sigmaY = 1;
    sigmaZ = 1;
    amplitude = 0;
    positionX = 1;
    positionY = 1;
    positionZ = 1;
    circularX = true;
    circularY = true;
    circularZ = true;
    normalized = false;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = GaussStimulus3D(label, size, sigmaY, sigmaX, sigmaZ, amplitude, ...
        positionY, positionX, positionZ, circularY, circularX, circularZ, normalized)
      if nargin > 0
        obj.label = label;
        obj.size = size;
      end
      if nargin >= 5
        obj.sigmaY = sigmaY;
        obj.sigmaX = sigmaX;
        obj.sigmaZ = sigmaZ;
      end
      if nargin >= 6
        obj.amplitude = amplitude;
      end
      if nargin >= 9
        obj.positionY = positionY;
        obj.positionX = positionX;
        obj.positionZ = positionZ;
      end
      if nargin >= 12
        obj.circularY = circularY;
        obj.circularX = circularX;
        obj.circularZ = circularZ;
      end
      if nargin >= 13
        obj.normalized = normalized;
      end
      
      if numel(obj.size) ~= 3
        error('GaussStimulus3D:Constructor:invalidArgument', 'Argument size must be a three-element vector.');
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      % nothing to do
    end
    
    
    % initialization
    function obj = init(obj)
      if obj.circularX
        gx = circularGauss(1:obj.size(2), obj.positionX, obj.sigmaX);
      else
        gx = gauss(1:obj.size(2), obj.positionX, obj.sigmaX);
      end
      
      if obj.circularY
        gy = circularGauss(1:obj.size(1), obj.positionY, obj.sigmaY);
      else
        gy = gauss(1:obj.size(1), obj.positionY, obj.sigmaY);
      end
      
      if obj.circularZ
        gz = circularGauss(1:obj.size(3), obj.positionZ, obj.sigmaZ);
      else
        gz = gauss(1:obj.size(3), obj.positionZ, obj.sigmaZ);
      end
      
      if obj.normalized && any(gx) && any(gy) && any(gz)
        obj.output = repmat(((obj.amplitude / (sum(gx) * sum(gy) * sum(gz))) * gy') * gx, [1, 1, obj.size(3)]) ...
          .* repmat(reshape(gz, [1, 1, obj.size(3)]), [obj.size(1:2), 1]);
      else
        obj.output = repmat((obj.amplitude * gy') * gx, [1, 1, obj.size(3)]) ...
          .* repmat(reshape(gz, [1, 1, obj.size(3)]), [obj.size(1:2), 1]);
      end
    end
  end
  
end
