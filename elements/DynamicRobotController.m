% DynamicRobotController (COSIVINA toolbox)
%   Element to provide connection to an E-Puck robot and control change of
%   its orientation (requires additional mex files to connect to hardware).
% 
% Constructor call:
% DynamicRobotController(label, minWheelVelocity, maxWheelVelocity)
%   label - element label
%   minWheelVelocity, maxWheelVelocity - range within which wheel
%     velocities (absolute) are set


classdef DynamicRobotController < Element
  
  properties (Constant)
    parameters = struct('maxWheelVelocity', ParameterStatus.Changeable, 'minWheelVelocity', ParameterStatus.Changeable);
    components = {'position', 'orientation'};
    defaultOutputComponent = 'orientation';
    
    wheelbase = 53; % mm
    pulse = 0.13; % mm
  end
  
  properties
    % parameters
    minWheelVelocity = 0;
    maxWheelVelocity = inf;
    
    % accessible structures
    position = [0, 0];
    orientation = 0;
  end
  
  properties (SetAccess = protected)
    robotHandle = 0;
    
    lastEncoderValues = [0; 0];
  end
  
  
  methods
    % constructor
    function obj = DynamicRobotController(label, minWheelVelocity, maxWheelVelocity)
      if nargin > 0
        obj.label = label;
      end
      if nargin >= 2 && ~isempty(minWheelVelocity)
        obj.minWheelVelocity = minWheelVelocity;
      end
      if nargin >= 3 && ~isempty(maxWheelVelocity)
        obj.maxWheelVelocity = maxWheelVelocity;
      end
    end
    
    
    % initialization
    function obj = init(obj)
      obj.position = [0, 0];
      obj.orientation = 0;
      
      if obj.robotHandle == 0
        obj.robotHandle = kOpenPort();
      else
        kStop(obj.robotHandle);
      end
      
%       kSetEncoders(obj.robotHandle, 0, 0);
      obj.lastEncoderValues = kGetEncoders(obj.robotHandle);
    end
    
    
    % step function
    function obj = step(obj, time, deltaT) %#ok<INUSD>
      newEncoderValues = kGetEncoders(obj.robotHandle);
      if any(size(newEncoderValues) ~= [2, 1])
        disp('failed to read encoder values');
        return;
      end
      deltaEncoderValues = newEncoderValues - obj.lastEncoderValues;
      obj.lastEncoderValues = newEncoderValues;
      
      newPosition = integrateForwardKinematics(deltaEncoderValues * DynamicRobotController.pulse, ...
        [obj.position, obj.orientation], obj.wheelbase/2);
      obj.position = [newPosition(1), newPosition(2)];
      obj.orientation = mod(newPosition(3) + pi, 2*pi) - pi;

      if obj.nInputs >= 1
        v = 1/obj.pulse * obj.inputElements{1}.(obj.inputComponents{1}) * obj.wheelbase/2;
        v = max(min(v, obj.maxWheelVelocity), -obj.maxWheelVelocity);
        if abs(v) < obj.minWheelVelocity
          v = 0;
        end
        kSetSpeed(obj.robotHandle, -v, v);
      end
    end
    
    function obj = close(obj)
      kStop(obj.robotHandle);
      if obj.robotHandle ~= 0
        kClose(obj.robotHandle);
      end
    end
  end
end


