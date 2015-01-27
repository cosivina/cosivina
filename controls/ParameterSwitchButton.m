% ParameterSwitchButton (COSIVINA toolbox)
%   Control that creates a labeled toggle button (i.e. the button toggles
%   between pressed and not pressed when clicked). This control can switch
%   the values of one or more parameter between two predefined values.
% 
% Constructor call:
% ParameterSwitchButton(controlLabel, elementLabels, parameterNames,
%   offValues, onValues, toolTip, pressedOnInit, position)
% 
% Arguments:
% controlLabel - label of the control displayed on the button
% elementLabels - string or cell array of strings specifying the
%   labels of elements controlled by this button
% parameterNames - string or cell array of strings specifying the names of
%   the element parameters controlled by this button; arguments
%   elementLabels and parameterNames must have the same size, with each
%   pair of entries fully specifying one controlled parameter
% offValues - single scalar value or cell array specifying for every 
%   connected element parameter the value it should take while the button
%   is not pressed
% onValues - single scalar value or cell array specifying for every
%   connected element parameter the value it should take while the button
%   is pressed
% tooltip - tooltip displayed when hovering over the control with the mouse
%   (optional)
% pressedOnInit - specifies whether the button should be in the pressed or
%   not pressed state on initialization of the GUI (default is false)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addControl function)
%
% Example:
% h = ParameterSwitchButton('stimuli on', {'stimulus A', 'stimulus B'}, ...
%   {'amplitude', 'amplitude'}, {0, 0}, {6, 6}, ...
%   'toggle stimuli on/off', false);


classdef ParameterSwitchButton < Control
  properties
    controlLabel
    elementLabels
    parameterNames
    onValues
    offValues
    toolTip
    
    nParameters
    simulatorHandle
    buttonHandle
    
    lastValue = false;
  end
  
  methods
    % constructor
    function obj = ParameterSwitchButton(controlLabel, elementLabels, parameterNames, offValues, onValues, toolTip, ...
        pressedOnInit, position)
      obj.controlLabel = controlLabel;
      obj.elementLabels = elementLabels;
      obj.parameterNames = parameterNames;
      obj.offValues = offValues;
      obj.onValues = onValues;
      
      if nargin >= 6 && ~isempty(toolTip)
        obj.toolTip = toolTip;
      else
        obj.toolTip = obj.controlLabel;
      end
      if nargin >= 7 && ~isempty(pressedOnInit)
        obj.lastValue = pressedOnInit;
      end
      if nargin >= 8
        obj.position = position;
      else
        obj.position = [];
      end
      
      if ~iscell(obj.elementLabels)
        obj.elementLabels = {obj.elementLabels};
      end
      if ~iscell(obj.parameterNames)
        obj.parameterNames = {obj.parameterNames};
      end
      
      obj.nParameters = length(obj.parameterNames);
      
      if ~iscellstr(obj.elementLabels) || ~iscellstr(obj.parameterNames) ...
          || numel(obj.elementLabels) ~= obj.nParameters || numel(obj.offValues) ~= obj.nParameters ...
          || numel(obj.onValues) ~= obj.nParameters;
        error('ParameterSlider:ParameterSlider:invalidArguments', ...
          ['Arguments elementLabels and parameterNames must be strings or cell arrays of strings ' ...
          'with equal number of elements, and arguments offValues and onValues must be vectors of that same size']);
      end
      
      if ~iscell(obj.offValues)
        obj.offValues = num2cell(obj.offValues);
      end
      if ~iscell(obj.onValues)
        obj.onValues = num2cell(obj.onValues);
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      for i = 1 : obj.nParameters
        tmpElementHandle = simulatorHandle.getElement(obj.elementLabels{i});
        if isempty(tmpElementHandle) || ~tmpElementHandle.isParameter(obj.parameterNames{i})
          error('ParameterSlider:connect:invalidParameter', ...
            'No element ''%s'' with parameter ''%s'' in simulator object', obj.elementLabels{i}, obj.parameterNames{i});
        end
        if ~ParameterStatus.isChangeable(tmpElementHandle.getParamChangeStatus(obj.parameterNames{i}))
          error('ParameterSlider:connect:parameterFixed', ...
            'Parameter ''%s'' in element ''%s'' has change status ''Fixed'' and cannot be changed by a GUI control.', ...
            obj.parameterNames{i}, obj.elementLabels{i});
        end
      end
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle)
      obj.buttonHandle = uicontrol('Parent', figureHandle, 'Style', 'togglebutton', 'Units', 'norm', ...
        'Position', obj.position, 'String', obj.controlLabel, 'ToolTip', obj.toolTip, 'Value', obj.lastValue);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      if get(obj.buttonHandle, 'Value') ~= obj.lastValue
        changed = true;
        obj.lastValue = ~obj.lastValue;
        if obj.lastValue
          setElementParameters(obj.simulatorHandle, obj.elementLabels, obj.parameterNames, obj.onValues);
        else
          setElementParameters(obj.simulatorHandle, obj.elementLabels, obj.parameterNames, obj.offValues);
        end
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control element
      % state of ParameterSwitchButton is not updated on external parameter change
    end

  end
end