% RobotArenaControlPanel (COSIVINA toolbox)
%   Control element specifically designed to control and visualize a
%   MobileRobotArena element. The panel opens in separate window, showing a
%   top-down view of a robot arena with a mobile and sensor targets.
%   Targets can be added or removed using the provided buttons.
% 
% Constructor call:
% RobotArenaControlPanel(elementLabel, figurePosition, figureTitle)
% 
% Arguments:
% elementLabel - label of a MobileRobotArena element
% figurePosition - position of the figure window on the screen
% figureTitle (optional) - title displayed on the figure window
%
% Example:
% h = RobotArenaControlPanel('arena', [500, 50, 600, 720]);


classdef RobotArenaControlPanel < Control
  properties
    elementLabel
    figureTitle = 'Robot arena';
    simulatorHandle
    elementHandle
    
    % figure elements
    figureHandle
    arenaAxesHandle
    sensorAxesHandle
    sensorPlotHandle
    
    addTargetButtonHandle
    removeTargetButtonHandle
    
    targetPlotHandles
    robotPlotHandle
    
    targetPositions
    targetSize = 0.25;
  end
  
  methods
    % constructor
    function obj = RobotArenaControlPanel(elementLabel, figurePosition, figureTitle)
      obj.elementLabel = elementLabel;
      
      if nargin >= 2 && ~isempty(figurePosition) && numel(figurePosition) == 4
        obj.position = figurePosition;
      else
        obj.position = [200, 200, 500, 600];
      end
      if nargin >= 3 && ~isempty(figureTitle)
        obj.figureTitle = figureTitle;
      end
      
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      obj.elementHandle = simulatorHandle.getElement(obj.elementLabel);
      if ~isa(obj.elementHandle, 'MobileRobotArena')
        error('RobotArenaControlPanel:connect:invalidElementType', ...
          'The RobotArenaControlPanel can only be used to control an element of type SimulatedMobileRobotArena.');
      end
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle) %#ok<INUSD>
      obj.figureHandle = figure('Position', obj.position, 'Name', obj.figureTitle, 'NumberTitle', 'off', ...
        'MenuBar', 'none');
      
      padX = 0.05; padY = 0.04;
      hSensor = 0.1; hButtons = 0.05; hArena = 1 - hSensor - hButtons - 4*padY;
      w = 1 - 2*padX;
      
      % draw arena and sensor axes
      arenaSize = obj.elementHandle.arenaSize;
      obj.arenaAxesHandle = axes('Units', 'norm', 'Position', [padX, hButtons + 2*padY, w, hArena], ...
        'XLim', [0, arenaSize(1)], 'YLim', [0, arenaSize(2)], 'Color', [0.1, 0.1, 0.1], 'XTick', [], 'YTick', []);
      obj.sensorAxesHandle = axes('Units', 'norm', 'Position', [padX, hButtons + hArena + 3*padY, w, hSensor], ...
        'XLim', [-pi, pi], 'YLim', [0, 1], 'XTick', [-pi, -pi/2, 0, pi/2, pi], ...
        'XTickLabel', {'-pi', '-pi/2', '0', 'pi/2', 'pi'}, 'XDir', 'reverse', 'nextPlot', 'add');
      
      % create sensor plot
      obj.sensorPlotHandle = bar(obj.elementHandle.sensorAngles, zeros(size(obj.elementHandle.sensorAngles)), ...
        obj.elementHandle.sigmaSensor, 'FaceColor', 'r');
      
      % create buttons and speed slider
      obj.addTargetButtonHandle = uicontrol('Style', 'togglebutton', 'Units', 'norm', ...
        'Position', [padX, padY, w/2, hButtons], 'String', 'Add target', ...
        'ToolTip', 'add new target to arena (click inside arena to place target)');
      obj.removeTargetButtonHandle = uicontrol('Style', 'togglebutton', 'Units', 'norm', ...
        'Position', [w/2+padX, padY, w/2, hButtons], 'String', 'Remove target', ...
        'ToolTip', 'remove existing target from arena (click inside arena to select target)');

      % plot robot position in arena
      robotPosition = obj.elementHandle.robotPosition;
      robotSize = obj.elementHandle.robotSize;
      robotPhi = obj.elementHandle.robotPhi;
      
      obj.robotPlotHandle(1) = rectangle('Parent', obj.arenaAxesHandle, 'Curvature', [1, 1], ...
        'FaceColor', [0.75, 0.75, 0.75], 'EdgeColor', [0.75, 0.75, 0.75], ...
        'Position', [robotPosition - robotSize/2, robotSize, robotSize]);
      patchPointsRel = [cos(robotPhi) -sin(robotPhi); sin(robotPhi) cos(robotPhi)] ...
        * [0, -0.1, 0.1; 0.25, -0.25, -0.25] * robotSize;
      obj.robotPlotHandle(2) = patch(patchPointsRel(1, :)' + robotPosition(1), patchPointsRel(2, :)' + robotPosition(2), ...
        'k', 'Parent', obj.arenaAxesHandle);
      
      obj.targetPositions = zeros(0, 2);
      obj.targetPlotHandles = zeros(0, 1);
      
      update(obj);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      update(obj);
      
      if get(obj.addTargetButtonHandle, 'Value')
        axes(obj.arenaAxesHandle);
        [x, y, button] = ginput(1);
        if ~isempty(button) && button == 1
          addTarget(obj.elementHandle, [x, y]);
        end
        set(obj.addTargetButtonHandle, 'Value', false);
      end
      
      if get(obj.removeTargetButtonHandle, 'Value')
        axes(obj.arenaAxesHandle);
        [x, y, button] = ginput(1);
        if ~isempty(button) && button == 1
          removeTarget(obj.elementHandle, [x, y]);
        end
        set(obj.removeTargetButtonHandle, 'Value', false);
      end
      
      changed = false;
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control element
      % update sensor plot
      set(obj.sensorPlotHandle, 'YData', obj.elementHandle.rawSensorValues);
      
      % update robot plot
      robotPosition = obj.elementHandle.robotPosition;
      robotSize = obj.elementHandle.robotSize;
      robotPhi = obj.elementHandle.robotPhi;
      
      set(obj.robotPlotHandle(1), 'Position', [robotPosition - robotSize/2, robotSize, robotSize]);
      patchPointsRel = [cos(robotPhi) -sin(robotPhi); sin(robotPhi) cos(robotPhi)] ...
        * [0, -0.1, 0.1; 0.25, -0.25, -0.25] * robotSize;
      set(obj.robotPlotHandle(2), 'XData', patchPointsRel(1, :)' + robotPosition(1), ...
        'YData', patchPointsRel(2, :)' + robotPosition(2));
      
      % update targets if changed
      if size(obj.targetPositions, 1) ~= obj.elementHandle.nTargets ...
          || any(any(obj.targetPositions ~= obj.elementHandle.targetPositions)) ...
          || obj.targetSize ~= obj.elementHandle.targetSize
        delete(obj.targetPlotHandles);
        obj.targetPositions = obj.elementHandle.targetPositions;
        obj.targetSize = obj.elementHandle.targetSize;
        plotPositions = [obj.targetPositions - obj.targetSize/2, zeros(size(obj.targetPositions)) + obj.targetSize];
        nTargets = size(plotPositions, 1);
        obj.targetPlotHandles = zeros(nTargets, 1);
        for i = 1 : nTargets
          obj.targetPlotHandles(i) = rectangle('Parent', obj.arenaAxesHandle, 'Curvature', [1, 1], ...
            'FaceColor', 'r', 'EdgeColor', 'r', 'Position', plotPositions(i, :));
        end
      end
    end
    
    
    function obj = close(obj)
      delete(obj.figureHandle);
    end
    
  end
end