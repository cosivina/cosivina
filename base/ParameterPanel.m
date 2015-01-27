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
    refElementHandles
    
    simulatorHandle
    
    nParams
    parameters
    paramChangeStatus
    
    selectorHandle
    buttonHandle
    classNameHandle
    captionHandles
    editHandles
    nEditFields
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
      obj.refElementHandles = cell(obj.nElementGroups, 1);
      obj.nElementsInGroups = nan(obj.nElementGroups, 1);
      for i = 1 : obj.nElementGroups
        if ~iscell(obj.elementsInGroups{i})
          obj.elementsInGroups{i} = obj.elementsInGroups(i);
        end
        obj.nElementsInGroups(i) = numel(obj.elementsInGroups{i});
      end
      
      if simulatorHandle ~= 0
        connect(obj, simulatorHandle);
      end
    end
    
    
    % connect to a simulator object
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      for i = 1 : obj.nElementGroups
        for j = 1 : obj.nElementsInGroups(i)
          if ~isElement(simulatorHandle, obj.elementsInGroups{i}{j});
            error('ParameterPanel:connect:elementNotFound', ...
              'Element ''%s'' listed for grouping in the parameter panel not found in simulator object.', ...
              obj.elementsInGroups{i}{j});
          end
        end
        obj.refElementHandles{i} = getElement(simulatorHandle, obj.elementsInGroups{i}{1});
        elementClass = class(obj.refElementHandles{i});
        for j = 2 : obj.nElementsInGroups(i)
          if ~strcmp(elementClass, class(getElement(simulatorHandle, obj.elementsInGroups{i}{j})))
            error('ParameterPanel:connect:classMismatch', ...
              'Elements ''%s'' and ''%s'' listed for grouping in the parameter panel are not of the same class.', ...
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
      
      obj.figureHandle = figure('Position', obj.figurePosition, 'MenuBar', 'none', ...
        'NumberTitle', 'off', 'Name', 'Parameters');
      drawnow;
      obj.figurePosition = get(obj.figureHandle, 'Position');
      cellHeightRel = obj.cellHeightAbs / obj.figurePosition(4);
      
      obj.selectorHandle = uicontrol('Parent', obj.figureHandle, ...
        'Style', 'popupmenu', 'Units', 'norm', 'Position', [0, 1-cellHeightRel, 1, cellHeightRel], ...
        'String', obj.elementGroups, 'Value', obj.currentSelection);
      obj.buttonHandle = uicontrol('Parent', obj.figureHandle, ...
        'Style', 'togglebutton', 'Units', 'norm', 'Position', [0, 0, 1, cellHeightRel], ...
        'String', 'Apply', 'Value', 0);
      obj.classNameHandle = uicontrol('Parent', obj.figureHandle, 'Style', 'text', 'Units', 'norm', ...
        'String', '', 'Position', [0, 1-2*cellHeightRel, 1, cellHeightRel]);

      obj.nParams = 0;
      obj.nEditFields = 0;
      obj.captionHandles = [];
      obj.editHandles = {};
      
      obj.panelOpen = true;
      obj.updateSelection();
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
      if ~ishandle(obj.figureHandle)
        return;
      end
      
      obj.currentSelection = get(obj.selectorHandle, 'Value');
      
      % remove old parameter display
      delete(obj.captionHandles);
      for i = 1 : obj.nEditFields
        delete(obj.editHandles{i});
      end
      
      % update class indicator and sizes of permanent graphics elements
      cellHeightRel = obj.cellHeightAbs / obj.figurePosition(4);
      set(obj.selectorHandle, 'Position', [0, 1-cellHeightRel, 1, cellHeightRel]);
      set(obj.classNameHandle, 'String', class(obj.refElementHandles{obj.currentSelection}), ...
        'Position', [0, 1-2*cellHeightRel, 1, cellHeightRel]);
      set(obj.buttonHandle, 'Position', [0, 0, 1, cellHeightRel]);
      
      % get parameters of selected element
      obj.parameters = obj.refElementHandles{obj.currentSelection}.getParameterList();
      obj.nParams = numel(obj.parameters);
      
      % create new parameter display
      obj.paramChangeStatus = zeros(1, obj.nParams);
      obj.captionHandles = zeros(obj.nParams, 1);
      obj.editHandles = cell(obj.nParams, 1);
      obj.nEditFields = obj.nParams;
            
      vOffset = 1;
      for i = 1 : obj.nParams
        captionVPos = 1 - (vOffset+2)*cellHeightRel;
        obj.captionHandles(i) = uicontrol('Parent', obj.figureHandle, 'Style', 'text', 'Units', 'norm', 'String', ...
          obj.parameters{i}, 'Position', [0, captionVPos, 1-obj.editWidthRel, cellHeightRel]);

        obj.paramChangeStatus(i) = ...
          obj.refElementHandles{obj.currentSelection}.getParamChangeStatus(obj.parameters{i});
        
        if ParameterStatus.isMatrix(obj.paramChangeStatus(i)) && ParameterStatus.isChangeable(obj.paramChangeStatus(i))
          % create matrix of edit fields for matrix parameters
          sz = size(obj.refElementHandles{obj.currentSelection}.(obj.parameters{i}));
          nRows = sz(1) + ParameterStatus.rowsVariable(obj.paramChangeStatus(i));
          nCols = sz(2) + ParameterStatus.columnsVariable(obj.paramChangeStatus(i));
          
          obj.editHandles{i} = zeros(nRows, nCols);
          colWidth = obj.editWidthRel/nCols;
          for r = 1 : nRows
            for c = 1 : nCols
              obj.editHandles{i}(r, c) = uicontrol('Parent', obj.figureHandle, 'Style', 'edit', 'Units', 'norm', ...
                'String', '', 'Enable', 'on', 'BackgroundColor', 'w', 'Position', ...
                [1 - obj.editWidthRel + (c-1)*colWidth, 1 - (vOffset+2)*cellHeightRel, colWidth, cellHeightRel]);
            end
            vOffset = vOffset + 1;
          end
        else
          obj.editHandles{i} = uicontrol('Parent', obj.figureHandle, 'Style', 'edit', 'Units', 'norm', 'String', ...
            '', 'Position', [ 1 - obj.editWidthRel, 1 - (vOffset+2)*cellHeightRel, obj.editWidthRel, cellHeightRel]);
          
          if ParameterStatus.isChangeable(obj.paramChangeStatus(i))
            set(obj.editHandles{i}, 'Enable', 'on', 'BackgroundColor', 'w');
          else
            set(obj.editHandles{i}, 'Enable', 'off');
          end
          
          vOffset = vOffset + 1;
        end
        
        if (vOffset+3)*cellHeightRel > 1 % not enough space to show all parameters
          set(obj.captionHandles(i), 'String', 'some parameters not shown', ...
            'Position', [0, captionVPos, 1, cellHeightRel]);
          obj.captionHandles = obj.captionHandles(1:i);
          delete(obj.editHandles{i});
          obj.editHandles = obj.editHandles(1:i-1);
          obj.nEditFields = i-1;
          break;
        end   
        
      end
      
      obj.update();
    end
    
    
    % check parameter panel for button press and update parameter values of
    % elements
    function changed = check(obj)
      changed = false;
      
      if ~ishandle(obj.figureHandle)
        changed = obj.panelOpen; % if panel was supposed to be open, change is true (to set updateControls true)
        obj.panelOpen = false;
        return;
      end
      
      if get(obj.buttonHandle, 'Value')
        iParametersSettable = find(ParameterStatus.isChangeable(obj.paramChangeStatus(1:obj.nEditFields)));
        nParametersSettable = numel(iParametersSettable);
        parametersSettable = obj.parameters(iParametersSettable);
        newValues = cell(1, nParametersSettable);
        
        invalidValue = 0;
        
        for i = 1 : nParametersSettable
          s = obj.paramChangeStatus(iParametersSettable(i));
          if ParameterStatus.isMatrix(s)
            h = obj.editHandles{iParametersSettable(i)};
            m = zeros(size(h));
            
            for j = 1 : numel(h)
              m(j) = str2double(get(h(j), 'String'));
            end
            
            % prune empty rows and columns if matrix size is variable
            if ParameterStatus.rowsVariable(s)
              m = m(~all(isnan(m), 2), :);
            end
            if ParameterStatus.columnsVariable(s)
              m = m(:, ~all(isnan(m), 1));
            end
            
            if any(any(isnan(m)))
              newValues{i} = nan;
            else
              newValues{i} = m;
            end
          else
            newValues{i} = str2double(get(obj.editHandles{iParametersSettable(i)}, 'String'));
          end
          
          if isnan(newValues{i})
            invalidValue = i;
            break;
          end
        end
        
        if invalidValue
          warndlg(['Invalid value for parameter ' parametersSettable{invalidValue} '. No changes were applied.'], ...
            'Warning');
        else
          for m = 1 : obj.nElementsInGroups(obj.currentSelection)
            setElementParameters(obj.simulatorHandle, obj.elementsInGroups{obj.currentSelection}{m}, ...
              parametersSettable, newValues);
          end
          changed = true;
          obj.updateSelection();
        end
        set(obj.buttonHandle, 'Value', false);
      end
      
      currentPos = get(obj.figureHandle, 'Position');
      if get(obj.selectorHandle, 'Value') ~= obj.currentSelection || any(currentPos(3:4) ~= obj.figurePosition(3:4))
        obj.updateSelection();
        obj.figurePosition = currentPos;
      end
    end
    
    
    % update values in panel (e.g. after change of parameters via sliders)
    function obj = update(obj)
      if ~ishandle(obj.figureHandle)
        return;
      end
      
      for i = 1 : obj.nEditFields
        paramValue = obj.refElementHandles{obj.currentSelection}.(obj.parameters{i});
        if ParameterStatus.isChangeable(obj.paramChangeStatus(i))
          if ParameterStatus.isMatrix(obj.paramChangeStatus(i))
            nRows = min(size(paramValue, 1), size(obj.editHandles{i}, 1));
            nCols = min(size(paramValue, 2), size(obj.editHandles{i}, 2));
            for r = 1 : nRows
              for c = 1 : nCols
                set(obj.editHandles{i}(r, c), 'String', num2str(paramValue(r, c)));
              end
            end
          else
            set(obj.editHandles{i}, 'String', num2str(paramValue));
          end
        else
          if isnumeric(paramValue) && size(paramValue, 1) == 1 && size(paramValue, 2) <= 4
            set(obj.editHandles{i}, 'String', num2str(paramValue));
          else
            set(obj.editHandles{i}, 'String', class(paramValue));
          end
        end
      end
    end
    
  end
  
end

