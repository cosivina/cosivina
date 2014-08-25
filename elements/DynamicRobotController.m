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
    position = [0; 0];
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
      obj.position = [0; 0];
      obj.orientation = 0;
      
      % connect to robot
      if obj.robotHandle == 0
        obj.robotHandle = kOpenPort();
      end
      if numel(obj.robotHandle) ~= 2
        error('DynamicRobotController:init:connectionFailure', ...
          'Failed to establish connection to robot.');
      end
      kStop(obj.robotHandle); % first command to robot is ignored
      
      % get initial encoder values
      encoderValues = 0;
      readAttempts = 0;
      while any(size(encoderValues) ~= [2, 1]) && readAttempts < 10
        encoderValues = kGetEncoders(obj.robotHandle);
        readAttempts = readAttempts + 1;
      end
      if any(size(encoderValues) ~= [2, 1])
        error('DynamicRobotController:init:connectionFailure', ...
          'Failed to read initial encoder values from robot.');
      end
      obj.lastEncoderValues = encoderValues;
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
      
      [obj.position, obj.orientation] = ...
        pathIntegrationDifferentialDrive(deltaEncoderValues * DynamicRobotController.pulse, ...
        obj.position, obj.orientation, obj.wheelbase);

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
      if obj.robotHandle ~= 0
        kStop(obj.robotHandle);
        kClose(obj.robotHandle);
        obj.robotHandle = 0;
      end
    end
  end
end


