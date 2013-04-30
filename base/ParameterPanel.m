% ParameterPanel (COSIVINA toolbox)
%   Parameter panel provided in the StandardGUI.


classdef ParameterPanel < handle
  properties
    connected = false;
    
    panelOpen = false;
    currentSelection = 1;
    
    figureHandle
    figurePosition
    cellHeightAbs = 25;
    editWidthRel = 0.5;

    nElementGroups
    elementGroups
    nElementsInGroups
    elementsInGroups
    elementHandlesInGroups
    
    nParams
    parameters
    paramChangeStatus
    
    selectorHandle
    buttonHandle
    nCells
    captionHandles
    editHandles
  end
  
  methods
    function obj = ParameterPanel(simulatorHandle, elementGroups, elementsInGroups, guiFigurePosition)
      obj.elementGroups = elementGroups;
      obj.elementsInGroups = elementsInGroups;
      
      obj.figurePosition = [guiFigurePosition(1) + guiFigurePosition(3), ...
        guiFigurePosition(2), 200, guiFigurePosition(4)];
      
      % prepare element groups and get element handles
      if isempty(elementGroups) || isempty(elementsInGroups)
        obj.elementGroups = simulatorHandle.elementLabels;
        obj.elementsInGroups = simulatorHandle.elementLabels;
      end
      
      obj.nElementGroups = numel(obj.elementGroups);
      obj.elementHandlesInGroups = cell(obj.nElementGroups, 1);
      obj.nElementsInGroups = nan(obj.nElementGroups, 1);
      for i = 1 : obj.nElementGroups
        if ~iscell(obj.elementsInGroups{i})
          obj.elementsInGroups{i} = obj.elementsInGroups(i);
        end
        obj.elementHandlesInGroups{i} = cell(1, numel(obj.elementsInGroups{i}));
        obj.nElementsInGroups(i) = numel(obj.elementsInGroups{i});
      end
      
      if simulatorHandle ~= 0
        connect(obj, simulatorHandle);
      end
    end
    
    
    % connect to a simulator object
    function obj = connect(obj, simulatorHandle)
      for i = 1 : obj.nElementGroups
        for j = 1 : obj.nElementsInGroups(i)
          obj.elementHandlesInGroups{i}{j} = simulatorHandle.getElement(obj.elementsInGroups{i}{j});
          if isempty(obj.elementHandlesInGroups{i}{j})
            error('ParameterPanel:contructor:elementNotFound', ...
              'Element ''%s'' listed for grouping in the parameter panel not found in simulator object.', ...
              obj.elementsInGroups{i}{j});
          end
        end
      end
      obj.connected = true;
    end
    
    
    % open and initialize parameter panel
    function obj = open(obj)
      if isempty(obj.elementGroups) || obj.panelOpen
        return;
      end
      
      if ~obj.connected
        error('ParameterPanel:open:notConnected', ...
          'Cannot open parameter panel before it has been connected to a Simulator object');
      end
      
      obj.figureHandle = figure('Position', obj.figurePosition, 'MenuBar', 'none', 'Name', 'Parameter panel');
      cellHeightRel = obj.cellHeightAbs / obj.figurePosition(4);
      
      obj.selectorHandle = uicontrol('Parent', obj.figureHandle, ...
        'Style', 'popupmenu', 'Units', 'norm', 'Position', [0, 1-cellHeightRel, 1, cellHeightRel], ...
        'String', obj.elementGroups, 'Value', obj.currentSelection);
      obj.buttonHandle = uicontrol('Parent', obj.figureHandle, ...
        'Style', 'togglebutton', 'Units', 'norm', 'Position', [0, 0, 1, cellHeightRel], ...
        'String', 'Apply', 'Value', 0);

      obj.nCells = 0;
      obj.captionHandles = [];
      obj.editHandles = [];
      
      obj.updateSelection();
      obj.panelOpen = true;
    end
    
    
    % close parameter panel
    function obj = close(obj)
      if ishandle(obj.figureHandle)
        delete(obj.figureHandle);
      end
      obj.panelOpen = false;
    end
    
    
    % update element selection
    function obj = updateSelection(obj)
      obj.parameters = obj.elementHandlesInGroups{obj.currentSelection}{1}.getParameterList();
      obj.nParams = numel(obj.parameters);
      
      cellHeightRel = obj.cellHeightAbs / obj.figurePosition(4);
      
      % remove all cells
      for i = 1 : obj.nCells
        delete(obj.captionHandles(i));
        delete(obj.editHandles(i));
      end
      
      obj.captionHandles = ...
        [obj.captionHandles(1:min(obj.nParams, obj.nCells)); zeros(max(obj.nParams-obj.nCells, 0), 1)];
      obj.editHandles = [obj.editHandles(1:min(obj.nParams, obj.nCells)); zeros(max(obj.nParams-obj.nCells, 0), 1)];
      
      % create new cells if necessary
      for i = 1 : obj.nParams
        obj.captionHandles(i) = uicontrol('Parent', obj.figureHandle, 'Style', 'text', 'Units', 'norm', ...
          'String', '', 'Position', [0, 1 - (i+1)*cellHeightRel, 1-obj.editWidthRel, cellHeightRel]);
        obj.editHandles(i) = uicontrol('Parent', obj.figureHandle, 'Style', 'edit', 'Units', 'norm', ...
          'String', '', 'Position', [ 1 - obj.editWidthRel, 1 - (i+1)*cellHeightRel, obj.editWidthRel, cellHeightRel]);
      end
      
      obj.nCells = obj.nParams;
      obj.paramChangeStatus = zeros(1, obj.nParams);
      
      for i = 1 : obj.nParams
        obj.paramChangeStatus(i) = ...
          obj.elementHandlesInGroups{obj.currentSelection}{1}.getParamChangeStatus(obj.parameters{i});
        set(obj.captionHandles(i), 'String', obj.parameters{i});
        if obj.paramChangeStatus(i) == ParameterStatus.Fixed
          set(obj.editHandles(i), 'Enable', 'off');
        else
          set(obj.editHandles(i), 'Enable', 'on', 'BackgroundColor', 'w');
        end
      end
      obj.update();
    end
    
    
    % check parameter panel for button press and update parameter values of
    % elements
    function changed = check(obj)
      
      if ~ishandle(obj.figureHandle)
        changed = obj.panelOpen; % if panel was supposed to be open, change is true (to updateControls)
        obj.panelOpen = false;
        return;
      end
      
      if get(obj.buttonHandle, 'Value')
        for m = 1 : obj.nElementsInGroups(obj.currentSelection)
          init = false;
          for i = 1 : obj.nParams
            if obj.paramChangeStatus(i) ~= ParameterStatus.Fixed
              obj.elementHandlesInGroups{obj.currentSelection}{m}.(obj.parameters{i}) = ...
                str2double(get(obj.editHandles(i), 'String'));
              init = init || obj.paramChangeStatus(i) == ParameterStatus.InitRequired;
            end
          end
          if init
            obj.elementHandlesInGroups{obj.currentSelection}{m}.init();
          end
        end
        set(obj.buttonHandle, 'Value', false);
        changed = true;
      else
        changed = false;
      end
      
      obj.figurePosition = get(obj.figureHandle, 'Position');
      
      if get(obj.selectorHandle, 'Value') ~= obj.currentSelection
        obj.currentSelection = get(obj.selectorHandle, 'Value');
        obj.updateSelection();
      end
    end
    
    
    % update values in panel (e.g. after change of parameters via sliders)
    function obj = update(obj)
      if obj.panelOpen
        for i = 1 : obj.nParams
          if obj.paramChangeStatus(i) == ParameterStatus.Fixed 
            s = size(obj.elementHandlesInGroups{obj.currentSelection}{1}.(obj.parameters{i}));
            if isnumeric(obj.elementHandlesInGroups{obj.currentSelection}{1}.(obj.parameters{i})) ...
                && s(1) == 1 && s(2) <= 4
              set(obj.editHandles(i), 'String', ...
                num2str(obj.elementHandlesInGroups{obj.currentSelection}{1}.(obj.parameters{i})));
            else
              set(obj.editHandles(i), 'String', ...
                class(obj.elementHandlesInGroups{obj.currentSelection}{1}.(obj.parameters{i})));
            end
          else
            set(obj.editHandles(i), 'String', ...
              num2str(obj.elementHandlesInGroups{obj.currentSelection}{1}.(obj.parameters{i})));
          end
        end
      end
    end
    
  end
end