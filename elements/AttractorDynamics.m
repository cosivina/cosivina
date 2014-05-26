% AttractorDynamics (COSIVINA toolbox)
%   Forms a one-dimensional dynamical system from space-coded input, with
%   attractors in regions of strongest activation in the input.
% 
% Constructor call:
% AttractorDynamics(label, inputSize, amplitude)
%   label - element label
%   inputSize - size of space coded input
%   amplitude - scaling factor for output (rate of change of dynamical
%     variable)


classdef AttractorDynamics < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'amplitude', ParameterStatus.Changeable, ...
      'zeroPosition', ParameterStatus.InitRequired);
    components = {'phiDot', 'phiDotAll'};
    defaultOutputComponent = 'phiDot';
  end
  
  properties
    % parameters
    size = [1, 1];
    amplitude = 0;
    zeroPosition
        
    % accessible structures
    phiDot = 0;
    phiDotAll = [];
  end
  
  properties (SetAccess = protected)
    rangePhi = [];
    sineDiffPhi = [];
  end
  
  methods
    % constructor
    function obj = AttractorDynamics(label, inputSize, amplitude, zeroPosition)
      if nargin > 0
        obj.label = label;
        obj.size = inputSize;
      end
      if numel(obj.size) == 1
        obj.size = [1, obj.size];
      end
      
      if nargin >= 3
        obj.amplitude = amplitude;
      end
      if nargin >= 4
        obj.zeroPosition = zeroPosition;
      else
        obj.zeroPosition = obj.size(2)/2;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      % obj.rangePhi = (1:obj.size(2)) * (2*pi/obj.size(2)) - pi - pi/obj.size(2);
      obj.rangePhi = ((1:obj.size(2)) - obj.zeroPosition) * 2*pi / obj.size(2);
      obj.sineDiffPhi = sin(repmat(obj.rangePhi, [obj.size(2), 1]) - repmat(obj.rangePhi', [1, obj.size(2)]));
      
      obj.phiDotAll = zeros(obj.size);
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.phiDot = -obj.amplitude * sum(obj.inputElements{1}.(obj.inputComponents{1}) ...
        .* sin( obj.inputElements{2}.(obj.inputComponents{2}) - obj.rangePhi) );
      obj.phiDotAll = -obj.amplitude ...
        * sum(repmat(obj.inputElements{1}.(obj.inputComponents{1})', obj.size) .* obj.sineDiffPhi);
    end

  end
end


