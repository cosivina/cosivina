classdef ParameterSlider < Control
  properties
    controlLabel
    elementLabels
    parameterNames
    sliderRange
    valueFormat
    scalingFactor
    toolTip
    
    nParameters
    elementHandles
    sliderHandle
    captionHandle
    
    relCaptionWidth % size of the slider caption relative to 
    relPaddingWidth % padding on both sides of the caption
    
    lastValue
  end
  
  methods
    % constructor
    function obj = ParameterSlider(controlLabel, elementLabels, parameterNames, sliderRange, ...
        valueFormat, scalingFactor, toolTip, position)
      obj.controlLabel = controlLabel;
      obj.elementLabels = elementLabels;
      obj.parameterNames = parameterNames;
      obj.sliderRange = sliderRange;
      if nargin >= 5 && ~isempty(valueFormat)
        obj.valueFormat = valueFormat;
      else
        obj.valueFormat = '%0.1f';
      end
      if nargin >= 6 && ~isempty(scalingFactor)
        obj.scalingFactor = scalingFactor;
      else
        obj.scalingFactor = 1;
      end
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
      
      if ~iscell(obj.elementLabels)
        obj.elementLabels = {obj.elementLabels};
      end
      if ~iscell(obj.parameterNames)
        obj.parameterNames = {obj.parameterNames};
      end
      
      if ~iscellstr(obj.elementLabels) || ~iscellstr(obj.parameterNames) ...
          || numel(obj.elementLabels) ~= numel(obj.parameterNames)
        error('ParameterSlider:ParameterSlider:invalidArguments', ...
          'Arguments elementLabels and parameter names must be strings or cell arrays of strings with equal number of elements');
      end
      
      obj.nParameters = length(obj.parameterNames);
      obj.relCaptionWidth = 0.3;
      obj.relPaddingWidth = 0.025;
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
      captionPosition = [obj.position(1) + obj.relPaddingWidth * obj.position(3), obj.position(2), ...
        obj.position(3) * obj.relCaptionWidth, obj.position(4)];
      sliderPosition = [obj.position(1) + (obj.relCaptionWidth + 2*obj.relPaddingWidth) * obj.position(3), ...
        obj.position(2), (1 - obj.relCaptionWidth - 2*obj.relPaddingWidth) * obj.position(3), obj.position(4)];
      obj.lastValue = obj.scalingFactor * obj.elementHandles{1}.(obj.parameterNames{1});
      
      obj.captionHandle = uicontrol('Parent', figureHandle, 'Style', 'text', 'Units', 'norm', ...
        'HorizontalAlignment', 'left', 'String', [obj.controlLabel '=' num2str(obj.lastValue, obj.valueFormat)], ...
        'Position', captionPosition, 'Tooltip', obj.toolTip, 'BackgroundColor', 'w');
      obj.sliderHandle = uicontrol('Parent', figureHandle, 'Style', 'slider', 'Units', 'norm', ...
        'Position', sliderPosition, 'Min', obj.sliderRange(1), 'Max', obj.sliderRange(2), ...
        'ToolTip', obj.toolTip, 'Value', obj.lastValue);
    end
    
    
    % check control object and update simulator object if required
    function changed = check(obj)
      
      if get(obj.sliderHandle, 'Value') ~= obj.lastValue
        changed = true;
        obj.lastValue = get(obj.sliderHandle, 'Value');
        set(obj.captionHandle, 'String', sprintf(['%s=' obj.valueFormat], obj.controlLabel,  obj.lastValue));
        for i = 1 : obj.nParameters
          obj.elementHandles{i}.(obj.parameterNames{i}) = 1/obj.scalingFactor * obj.lastValue;
          
          if obj.elementHandles{i}.getParamChangeStatus(obj.parameterNames{i}) == ParameterStatus.InitRequired
            obj.elementHandles{i}.init();
            obj.elementHandles{i}.step();
          end
        end
      else
        changed = false;
      end
    end
    
    
    % update control object (e.g. after parameters have been changed in parameter panel)
    function obj = update(obj) % updates the control eleme
      obj.lastValue = obj.scalingFactor * obj.elementHandles{1}.(obj.parameterNames{1});
      set(obj.captionHandle, 'String', sprintf(['%s=' obj.valueFormat], obj.controlLabel,  obj.lastValue));
      set(obj.sliderHandle, 'Value', min(max(obj.lastValue, obj.sliderRange(1)), obj.sliderRange(2)));
    end

  end
end