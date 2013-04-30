classdef StandardGUI < handle
  
  properties (SetAccess = protected)
    simulatorHandle
    figureHandle
    paramPanelHandle
        
    nVisualizations = 0;
    visualizations = {};
        
    nControls = 0;
    controls = {};
    
    paramPanelActive = false;
  end
  
  properties (SetAccess = public)  
    figurePosition = [];
    pauseDuration = 0.01;
    
    controlGridPosition
    controlGridSize
    
    visGridPosition
    visGridSize
    visGridPadding
    
    % these flags can be set via GUI controls (like buttons)
    pauseSimulation = false; % should remain true as long as simulator should remain paused
    quitSimulation = false;
    resetSimulation = false; % set to true once, is automatically reset after simulator is re-initialized
    saveParameters = false; % set to true once, is automatically reset after parameters are saved
    loadParameters = false; % set to true once, is automaticallt reset after parameters are loaded
    paramPanelRequest = false; % should remain true as long as panel should remain active
    loadFile = ''; % file name from which presets are loaded, empty when no preset is loaded
  end
  
  methods
    % constructor
    function obj = StandardGUI(simulatorHandle, figurePosition, pauseDuration, ...
        visGridPosition, visGridSize, visGridPadding, controlGridPosition, controlGridSize, ...
        elementGroups, elementsInGroups)
      obj.simulatorHandle = simulatorHandle;
      obj.figurePosition = figurePosition;
      
      if nargin >= 3
        obj.pauseDuration = pauseDuration;
      end
      if nargin >= 6
        obj.visGridPosition = visGridPosition;
        obj.visGridSize = visGridSize;
        obj.visGridPadding = visGridPadding;
        if numel(visGridPadding) == 1
          obj.visGridPadding = repmat(obj.visGridPadding, [1, 2]);
        end
      else
        obj.visGridPosition = [0, 1/3, 1, 2/3];
        obj.visGridSize = [2, 1];
        obj.visGridPadding = 0.05;
      end
      if nargin >= 8
        obj.controlGridPosition = controlGridPosition;
        obj.controlGridSize = controlGridSize;
      else
        obj.controlGridPosition = [0, 0, 1, 1/3];
        obj.controlGridSize = [5, 4];
      end
      if nargin < 10
        elementGroups = {};
        elementsInGroups = {};
      end
      
      obj.paramPanelHandle = ParameterPanel(simulatorHandle, elementGroups, elementsInGroups, obj.figurePosition);
    end
    
    
    % destructor
    function delete(obj)
      obj.simulatorHandle = [];
      obj.paramPanelHandle = [];
    end
      
    
    % initialization
    function obj = init(obj)
      obj.figureHandle = figure('Position', obj.figurePosition, 'Color', 'w');
      for i = 1 : obj.nVisualizations
        obj.visualizations{i}.init(obj.figureHandle);
      end
      for i = 1 : obj.nControls
        obj.controls{i}.init(obj.figureHandle);
      end
    end
    
    
    % run simulation in GUI
    function obj = run(obj, tMax, initializeSimulation)
      if nargin < 2 || isempty(tMax)
        tMax = inf;
      end
      if nargin < 3 || isempty(initializeSimulation)
        initializeSimulation = false;
      end
      
      if initializeSimulation || ~obj.simulatorHandle.initialized
        obj.simulatorHandle.init();
      end
      
      obj.init();
      
      while ~obj.quitSimulation && obj.simulatorHandle.t < tMax
        
        if ~ishandle(obj.figureHandle)
          break;
        end
        
        % checking for changes in controls and param panel
        updatePanel = false;
        for i = 1 : obj.nControls
          updatePanel = obj.controls{i}.check() || updatePanel;
        end
        if obj.paramPanelActive
          updateControls = obj.paramPanelHandle.check();
        else
          updateControls = false;
        end
        
        % opening and closing param panel
        if obj.paramPanelActive && ~obj.paramPanelHandle.panelOpen % panel figure was closed manually
          obj.paramPanelActive = false;
          obj.paramPanelRequest = false;
        end
        if obj.paramPanelRequest && ~obj.paramPanelActive
          obj.paramPanelHandle.open();
          obj.paramPanelActive = true;
        elseif ~obj.paramPanelRequest && obj.paramPanelActive
          obj.paramPanelHandle.close();
          obj.paramPanelActive = false;
        end
        
        % reset, save, load
        if obj.resetSimulation
          obj.simulatorHandle.init();
          obj.resetSimulation = false;
        end
        if obj.saveParameters
          if exist('savejson', 'file') ~= 2
            warndlg(['Cannot save parameters to file: File SAVEJSON.M not found. ' ...
              'Install JSONLAB and add it to the Matlab path to be able to save parameters to file.']);
          else
            [paramFile, paramPath] = uiputfile('*.json', 'Save parameter file');
            if ~(length(paramFile) == 1 && paramFile == 0)
              if ~obj.simulatorHandle.saveSettings([paramPath paramFile])
                warndlg('Could not write to file. Saving of parameters failed.');
              end
            end
          end
          obj.saveParameters = false;
        end
        if obj.loadParameters
          if exist('loadjson', 'file') ~= 2
            warndlg(['Cannot load parameters from file: File LOADJSON.M not found. ' ...
              'Install JSONLAB and add it to the Matlab path to be able to load parameters from file.']);
          else
            if isempty(obj.loadFile)
              [paramFile, paramPath] = uigetfile('*.json', 'Load parameter file');
              if ~(length(paramFile) == 1 && paramFile == 0)
                obj.loadFile = fullfile(paramPath, paramFile);
              end
            end
            if ~isempty(obj.loadFile)
              if ~obj.simulatorHandle.loadSettings(obj.loadFile)
                warndlg(['Could not read file ' obj.loadFile '. Loading of parmeters failed.'], 'Warning');
              end
              obj.simulatorHandle.init();
              updateControls = true;
              updatePanel = true;
            end
            obj.loadFile = '';
          end
          obj.loadParameters = false;
        end
          
        % the actual simulation step
        if ~obj.pauseSimulation
          obj.simulatorHandle.step();
        end
        
        % updating visualizations, controls and panel
        for i = 1 : obj.nVisualizations
          obj.visualizations{i}.update();
        end
        if updatePanel && obj.paramPanelActive
          obj.paramPanelHandle.update();
        end
        if updateControls
          for i = 1 : obj.nControls
            obj.controls{i}.update();
          end
        end
        
        pause(obj.pauseDuration);
      end
      
      obj.quitSimulation = false;
      
      obj.simulatorHandle.close();
      if obj.paramPanelActive
        obj.paramPanelHandle.close();
      end
      if ishandle(obj.figureHandle)
        delete(obj.figureHandle);
      end
      
    end
    
    
    % add visualization object
    function obj = addVisualization(obj, visualization, positionInGrid, sizeInGrid)
      obj.visualizations{end+1} = visualization;
      obj.nVisualizations = obj.nVisualizations + 1;
      
      obj.visualizations{end}.connect(obj.simulatorHandle);
      if nargin < 4
        sizeInGrid = [1, 1];
      end
      if nargin >= 3 && ~isempty(positionInGrid)
        obj.visualizations{end}.position = obj.gridToRelPosition('visualization', positionInGrid, sizeInGrid);
      end
      if isempty(obj.visualizations{end}.position)
        error('StandardGUI:addVisualization:noPosition', ...
          'Position must be specified for each visualization, either in the element itself or via its grid position');
      end
    end
    
    
    % add control object and connect it to the simulator object
    function obj = addControl(obj, control, positionInGrid, sizeInGrid)
      obj.controls{end+1} = control;
      obj.nControls = obj.nControls + 1;
      
      obj.controls{end}.connect(obj.simulatorHandle);
      if nargin < 4
        sizeInGrid = [1, 1];
      end
      if nargin >= 3
        obj.controls{end}.position = obj.gridToRelPosition('control', positionInGrid, sizeInGrid);
      end
      if isempty(obj.controls{end}.position)
        error('StandardGUI:addControl:noPosition', ...
          'Position must be specified for each control element, either in the element itself or via its grid position');
      end
    end
    
   
    % compute relative position in figure from grid position
    function relPosition = gridToRelPosition(obj, type, positionInGrid, sizeInGrid)
      % note: position information is given in format [x, y, w, h], with origin at
      if strcmp(type, 'control')
        gridSize = obj.controlGridSize;
        gridPosition = obj.controlGridPosition;
        padding = [0, 0];
      elseif strcmp(type, 'vis') || strcmp(type, 'visualization')
        gridSize = obj.visGridSize;
        gridPosition = obj.visGridPosition;
        padding = obj.visGridPadding;
      else
        error('StandardGUI:gridToRelPosition', 'Argument TYPE must be either ''control'' or ''visualization''.');
      end
      
      cellSize = [gridPosition(3)/gridSize(2), gridPosition(4)/gridSize(1)]; % [x, y]
      relPosition = [gridPosition(1) + (positionInGrid(2) - 1) * cellSize(1) + padding(1), ...
        gridPosition(2) + gridPosition(4) - (positionInGrid(1) + sizeInGrid(1) - 1) * cellSize(2) + padding(2), ...
        sizeInGrid(2) * cellSize(1) - 2*padding(1), sizeInGrid(1) * cellSize(2) - 2*padding(2)];
    end
    
  end
  
end

