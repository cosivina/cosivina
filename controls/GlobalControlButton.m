classdef GlobalControlButton < Control
  properties
    controlLabel
    propertyName
    onValue
    offValue
    resetAfterPress
    toolTip
    
    controlledObjectSpecified
  end
    
  properties (SetAccess = protected)
    controlledObjectHandle
    
    buttonHandle
    lastValue
  end
  
  methods
    % constructor
    function obj = GlobalControlButton(controlLabel, controlledObject, propertyName, onValue, offValue, ...
        resetAfterPress, toolTip, position)
      obj.controlLabel = controlLabel;
      obj.controlledObjectHandle = controlledObject;
      obj.propertyName = propertyName;
      obj.onValue = onValue;
      obj.offValue = offValue;
      obj.resetAfterPress = resetAfterPress;
      
      if nargin >= 7 && ~isempty(toolTip)
        obj.toolTip = toolTip;
      else
        obj.toolTip = obj.controlLabel;
      end
      if nargin >= 8
        obj.position = position;
      else
        obj.position = [];
      end
      
      if isempty(obj.controlledObjectHandle)
        obj.controlledObjectSpecified = false;
      else
        obj.controlledObjectSpecified = true;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      if ~obj.controlledObjectSpecified
        obj.controlledObjectHandle = simulatorHandle;
      end
      if ~isvalid(obj.controlledObjectHandle)
        error('GlobalControlButton:connect:invalidHandle', ...
          'The handle to the object to be controlled by this button is invalid.');
      end
      if ~any(strcmp(obj.propertyName, properties(obj.controlledObjectHandle)))
        error('GlobalControlButton:connect:invalidProperty', ...
          ['No public property ''%s'' in the object specified to be controlled by this button ' ...
          '(by default, the simulator object).'], obj.propertyName);
      end
    end
    
    
    % initialize control object
    function obj = init(obj, figureHandle)
      if obj.resetAfterPress
        obj.lastValue = false;
      else
        obj.lastValue = (obj.controlledObjectHandle.(obj.propertyName) == obj.onValue);
      end
      obj.buttonHandle = uicontrol('Parent', figureHandle, 'Style', 'togglebutton', 'Units', 'norm', ...
        'String', obj.controlLabel, 'Position', obj.position, 'Tooltip', obj.toolTip, 'Value', obj.lastValue);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      if get(obj.buttonHandle, 'Value') ~= obj.lastValue
        changed = true;
        obj.lastValue = ~obj.lastValue;
        if obj.lastValue
          obj.controlledObjectHandle.(obj.propertyName) = obj.onValue;
          if obj.resetAfterPress
            obj.lastValue = 0;
            set(obj.buttonHandle, 'Value', 0);
          end
        else
          obj.controlledObjectHandle.(obj.propertyName) = obj.offValue;
        end
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control eleme
      if obj.resetAfterPress
        % resetting buttons are by default always "off"
        obj.lastValue = false;
      else
        % set button to "on" if property value matches onValue, otherwise button is "off"
        obj.lastValue = (obj.controlledObjectHandle.(obj.propertyName) == obj.onValue);
      end
      set(obj.buttonHandle, 'Value', obj.lastValue);
    end

  end
end


