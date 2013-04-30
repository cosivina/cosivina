% Interpolation1D (COSIVINA toolbox)
%   Element that computes its outputs by interpolating at specified
%   positions from the input.
%
% Constructor call:
% Interpolation1D(label, interpolationPoints, method, extrapValue)
%   label - element label
%   interpolationPoints - positions in the input array for which value
%      should be interpolated
%   method - interpolation method (from MATLAB interp1 function)
%   extrapValue - value with which input is padded for extrapolations


classdef Interpolation1D < Element
  
  properties (Constant)
    parameters = struct('size', ParameterStatus.Fixed, 'interpolationPoints', ParameterStatus.Fixed, ...
      'method', ParameterStatus.Fixed, 'extrapValue', ParameterStatus.Changeable);
    components = {'output'};
    defaultOutputComponent = 'output';
  end
  
  properties
    % parameters
    size = [1, 1];
    interpolationPoints = [];
    method = 'linear';
    extrapValue = 0;
    
    % accessible structures
    output
  end
  
  methods
    % constructor
    function obj = Interpolation1D(label, interpolationPoints, method, extrapValue)
      if nargin > 0
        obj.label = label;
        obj.interpolationPoints = interpolationPoints;
      end
      if nargin >= 3
        obj.method = method;
      end
      if nargin >= 4
        obj.extrapValue = extrapValue;
      end
      
      obj.size = [1, length(interpolationPoints)];
      
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      obj.output = interp1(obj.inputElements{1}.(obj.inputComponents{1}), obj.interpolationPoints, obj.method, ...
        obj.extrapValue);
    end
    
    
    % initialization
    function obj = init(obj)
      obj.output = zeros(obj.size);
    end

  end
end


