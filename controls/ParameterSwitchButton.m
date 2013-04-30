classdef ParameterSwitchButton < Control
  properties
    controlLabel
    elementLabels
    parameterNames
    onValues
    offValues
    toolTip
    
    nParameters
    elementHandles
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
          ['Arguments elementLabels and parameter names must be strings or cell arrays of strings' ...
          'with equal number of elements, and arguments offValues and onValues must be vectors of that same size']);
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      obj.elementHandles = cell(obj.nParameters, 1);
      for i = 1 : obj.nParameters
        obj.elementHandles{i} = simulatorHandle.getElement(obj.elementLabels{i});
        if isempty(obj.elementHandles{i}) || ~obj.elementHandles{i}.isParameter(obj.parameterNames{i})
          error('ParameterSlider:connect:invalidParameter', ...
            'No element ''%s'' with parameter ''%s'' in simulator object', obj.elementLabels{i}, obj.parameterNames{i});
        end
        if obj.elementHandles{i}.getParamChangeStatus(obj.parameterNames{i}) == ParameterStatus.Fixed
          error('ParameterSlider:connect:parameterFixed', ...
            'Parameter ''%s'' in element ''%s'' has change status ''Fixed'' and cannot be changed by a GUI control', ...
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
          for i = 1 : obj.nParameters
            obj.elementHandles{i}.(obj.parameterNames{i}) = obj.onValues(i);
            
            if obj.elementHandles{i}.getParamChangeStatus(obj.parameterNames{i}) == ParameterStatus.InitRequired
              obj.elementHandles{i}.init();
              obj.elementHandles{i}.step();
            end
          end
        else
          for i = 1 : obj.nParameters
            obj.elementHandles{i}.(obj.parameterNames{i}) = obj.offValues(i);
            
            if obj.elementHandles{i}.getParamChangeStatus(obj.parameterNames{i}) == ParameterStatus.InitRequired
              obj.elementHandles{i}.init();
              obj.elementHandles{i}.step();
            end
          end
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