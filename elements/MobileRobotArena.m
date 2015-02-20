% MobileRobotArena (COSIVINA toolbox)
%   Provides a simulation of a mobile robot moving in an arena. The robot
%   can detect targets in the arena with an array of directed sensors. The
%   element can receive one or two inputs: The first one is the rate of
%   change of the robot's heading direction; the optional second one is a
%   forward speed. If the second input is provided, it is scaled with the
%   parameter forwardSpeed, otherwise forwardSpeed is taken directly as the
%   robot's speed. The element provides as components the robot's position
%   (a two-element vector), its orientation robotPhi, the raw values of the
%   sensor array, and these values projected onto the orientation space
%   (with a Gaussian profile of fixed width scaled with the sensor output
%   for each sensor). Number and direction of sensors can be adjusted by
%   manually changing the parameter sensorAngles (requires initalization).
% 
% Constructor call:
% MobileRobotArena(label, sensorOutputSize, sensorOutputZeroPosition, ...
%     flipSensorOutput, robotPoseInit, sensorNoiseLevel))
%   label - element label
%   sensorOutputSize - size of component sensorOutput
%   sensorOutputZeroPosition - position in the array sensorOutput that
%     corresponds to the forward direction of the robot
%   flipSensorOutput - boolean indicating whether sensorOutput should be
%     flipped
%   robotPoseInit - initial pose of the robot (three-element vector
%     specifying position and orientation)
%   sensorNoiseLevel - level of random noise added to the sensor responses


classdef MobileRobotArena < Element
  
  properties (Constant)
    parameters = struct('arenaSize', ParameterStatus.Fixed, 'robotSize', ParameterStatus.Fixed, ...
      'targetSize', ParameterStatus.Fixed, 'robotPoseInit', ParameterStatus.Fixed, ...
      'sensorAngles', ParameterStatus.Fixed, 'sigmaSensor', ParameterStatus.Changeable, ...
      'sensorOutputSize', ParameterStatus.Fixed, 'sigmaOutput', ParameterStatus.Changeable, ...
      'forwardSpeed', ParameterStatus.Changeable, 'sensorNoiseLevel', ParameterStatus.Changeable, ...
      'sensorOutputZeroPosition', ParameterStatus.InitRequired);
    components = {'robotPosition', 'robotPhi', 'rawSensorValues', 'sensorOutput'};
    defaultOutputComponent = 'robotPhi';
  end
  
  properties
    % parameters
    arenaSize = [200, 200];
    robotSize = 10;
    targetSize = 5;
    robotPoseInit = [100, 20, 0];
    sensorAngles = -pi/2 : pi/8 : pi/2;
    sigmaSensor = pi/16;
    sensorOutputSize = 180;
    sensorOutputZeroPosition = 90;
    sigmaOutput = 0.25;
    forwardSpeed = 0;
    flipSensorOutput = true;
    sensorNoiseLevel = 0.1;
    speedInput
    
    % accessible structures
    robotPosition
    robotPhi
    rawSensorValues
    sensorOutput
  end
  
  properties (SetAccess = private)
    nSensors
    nTargets = 0;
    targetPositions = zeros(0, 2);
    velocityInput
    outputAngles
  end
  
  methods
    % constructor
    function obj = MobileRobotArena(label, sensorOutputSize, sensorOutputZeroPosition, ...
        flipSensorOutput, robotPoseInit, sensorNoiseLevel)
      if nargin > 0
        obj.label = label;
      end
      if nargin >= 2
        obj.sensorOutputSize = sensorOutputSize;
      end
      if nargin >= 3
        obj.sensorOutputZeroPosition = sensorOutputZeroPosition;
      end
      if nargin >= 4
        obj.flipSensorOutput = flipSensorOutput;
      end
      if nargin >= 5
        obj.robotPoseInit = robotPoseInit;
      end
      if nargin >= 6
        obj.sensorNoiseLevel = sensorNoiseLevel;
      end
      
      if numel(obj.sensorOutputSize) == 1
        obj.sensorOutputSize = [1, obj.sensorOutputSize];
      end
    end
    
    
    % step function
    function obj = step(obj, time, deltaT)  %#ok<INUSL>
      % determine robot speed
      s = obj.forwardSpeed;
      if obj.speedInput
        s = s * obj.inputElements{2}.(obj.inputComponents{2});
      end
      
      % determine new heading direction and position
      phi = mod(obj.robotPhi + obj.inputElements{1}.(obj.inputComponents{1}) + pi, 2*pi) - pi;
      newPos = obj.robotPosition + s * deltaT * [-sin(phi), cos(phi)];
      
      % update heading direction and position if no collision occurs
      obj.robotPhi = phi;
      [psiTarget, dTarget] = cart2pol(obj.targetPositions(:, 1) - newPos(1), obj.targetPositions(:, 2) - newPos(2));
      if all(newPos >= obj.robotSize/2) && all(newPos <= obj.arenaSize - obj.robotSize/2) ...
          && all(dTarget >= (obj.robotSize + obj.targetSize)/2)
        obj.robotPosition = newPos;
      end
      
      % determine sensor values
      dPhiTargetSensor = mod(repmat(psiTarget - pi/2 - phi, [1, obj.nSensors]) ...
        - repmat(obj.sensorAngles, [obj.nTargets, 1]) + pi, 2*pi) - pi;
      obj.rawSensorValues = sum(repmat(1./sqrt(dTarget), [1, obj.nSensors]) ...
        .* exp(-0.5 * dPhiTargetSensor.^2 / obj.sigmaSensor^2), 1);
      obj.rawSensorValues = obj.rawSensorValues + obj.sensorNoiseLevel * obj.rawSensorValues .* randn(1, obj.nSensors);
      dPhiSensorOutput = mod(repmat(obj.outputAngles, [obj.nSensors, 1]) ...
        - repmat(obj.sensorAngles' + phi, [1, obj.sensorOutputSize(2)]) + pi, 2*pi) - pi;
      obj.sensorOutput = sum(repmat(obj.rawSensorValues', [1, obj.sensorOutputSize(2)]) ...
        .* exp(-0.5 * (dPhiSensorOutput.^2 / obj.sigmaOutput^2)), 1);
    end
    
    
    % initialization
    function obj = init(obj)
      if obj.nInputs == 1
        obj.speedInput = false;
      elseif obj.nInputs == 2
        obj.speedInput = true;
      else
        error('MobileRobotArena:init:wrongNoInputs', 'Invalid number of inputs in element %s.', obj.label);
      end
      
      % initialize robot position and heading direction
      obj.robotPosition = [obj.robotPoseInit(1), obj.robotPoseInit(2)];
      obj.robotPhi = obj.robotPoseInit(3);
      
      % initialize sensor outputs
      obj.nSensors = numel(obj.sensorAngles);
      obj.rawSensorValues = zeros(1, numel(obj.sensorAngles));
      obj.sensorOutput = zeros(obj.sensorOutputSize);
      if obj.flipSensorOutput
        obj.outputAngles = (obj.sensorOutputZeroPosition - (1:obj.sensorOutputSize(2))) * 2*pi/obj.sensorOutputSize(2);
      else
        obj.outputAngles = ((1:obj.sensorOutputSize(2)) - obj.sensorOutputZeroPosition) * 2*pi/obj.sensorOutputSize(2);
      end
    end
    
    
    % add a target to the arena
    function obj = addTarget(obj, targetPosition)
      if all(targetPosition >= 0 & targetPosition <= obj.arenaSize)
        obj.targetPositions = [obj.targetPositions; targetPosition(1), targetPosition(2)];
        obj.nTargets = obj.nTargets + 1;
      end
    end
    
    
    % remove a target near a specified location from the arena
    function obj = removeTarget(obj, targetPosition)
      d = sum((obj.targetPositions - repmat(targetPosition, [obj.nTargets, 1])).^2, 2);
      [di, i] = min(d);
      if di < obj.targetSize
        obj.targetPositions = obj.targetPositions(1:obj.nTargets ~= i, :);
        obj.nTargets = obj.nTargets - 1;
      end
    end

  end
end


