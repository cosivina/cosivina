% StandardGUI (COSIVINA toolbox)
%   Creates customized graphical user interfaces to show evolution of
%   activation patterns in neurodynamic architectures and change element
%   parameters online.
%
% Constructor call:
% StandardGUI(simulatorHandle, figurePosition, pauseDuration, ...
%   visGridPosition, visGridSize, visGridPadding, ...
%   controlGridPosition, controlGridSize, elementGroups, ...
%   elementsInGroups, figureTitle)
%   
% Arguments (all optional except for the first two):
%   simulatorHandle - handle to the simulator object which should be run in
%     the GUI (maybe 0, then simulator has to be connected at a later time)
%   figurePosition - screen position and size of the GUI main window in the
%     form [posX, posY, width, height]
%   pauseDuration - duration of pause for every simulation step (default =
%     0.1, should be set to zero for computationally costly simulations)
%   visGridPosition - position of the visualizations grid in the GUI window
%     in the format [posX, posY, width, height], in normalized coordinates
%     (relative to figure size)
%   visGridSize - grid size of the visualizations grid in the form 
%     [rows, cols]
%   visGridPadding - padding around each visualization element in grid,
%     relative to figure size, as scalar or vector [padHor, padVert]
%   controlGridPosition - relative position of the controls grid in the GUI
%     window in the form [posX, posY, width, height]
%   controlGridSize - grid size of the controls grid in the form 
%     [rows, cols]
%   elementGroups - labels for elements or groups of elements listed in the
%     parameter panel dropdown menu as cell array of strings
%   elementsInGroups - elements accessed by each list item in the parameter
%     panel dropdown menu; each list item may access a single element or a
%     group of elements of the same type that share parameters; given as
%     cell array of strings or cell array of cell arrays of strings
%   figureTitle - character string that is displayed in the GUI window's
%     title bar
%
% Methods to design the GUI:
% addVisualization(visualization, positionInGrid, sizeInGrid,
%     gridSelection) - adds a new visualization element to the GUI at
%   positionInGrid (two-element vector [row, col]) that extends over
%   sizeInGrid (two-element vector [rows, cols]; optional, default is [1,
%   1]); optional parameter gridSelection allows selection of a grid for
%   positioning, either 'visualization' (default) or 'control'; position
%   may also be specified explicitly in the visualization element itself,
%   then all other arguments may be omitted
% addControl(visualization, positionInGrid, sizeInGrid, gridSelection) -
%   adds a new control element to the GUI (by default in the controls
%   grid), analogous to addVisualization
%
% Methods to prepare the GUI for use:
% connect(simulatorHandle) - connect GUI with a simulator object (if not
%   done during creation, or to change connected simulator object)
% 
% Methods to run the GUI (online mode):
% run(tMax, initializeSimulator, closeSimulator, simulatorHandle) - runs
%   the simulation in the GUI until simulation time tMax (optional, default
%   is inf) is reached or GUI is quit manually; optional boolean argument
%   initializeSimulator forces re-initialization of the simulator at the
%   start of the GUI, optional boolean argument closeSimulator adds call to
%   simulator close method upon closing GUI, optional argument
%   simulatorHandle can specify the simulator object that is run in the GUI
%   (if not specified at creation)
% 
% Methods to use the GUI in offline mode:
% init() - initializes the GUI, creating the main figure window with
%   visualizations and controls
% step() - performs a single simulation step in the simulator object,
%   updates all visualizations, checks the controls and applies changes,
%   checks control flags (for actions like pause, save, and quit) and
%   performs the associated actions
% updateVisualizations() - update all visualizations to reflect current
%   state of the connected simulator object
% checkAndUpdateControls - check all controls for changes and apply these,
%   update state of control elements (like slider positions); NOTE: Control
%   buttons (like pause, save, and quit) will set the appropriate flags in
%   the StandardGUI object, but have no further effects; effects have to be
%   implemented manually in the code calling this method


classdef StandardGUI < handle
  
  properties (SetAccess = protected)
    connected = false;
    
    simulatorHandle = 0;
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
    figureTitle = 'Simulation';
    pauseDuration = 0.01;
    pauseDurationWhilePaused = 0.1;

    visGridPosition = [0, 1/3, 1, 2/3];
    visGridSize = [2, 1];
    visGridPadding = [0.05, 0.05];
    
    controlGridPosition = [0, 0, 1, 1/3];
    controlGridSize = [5, 4];
    
    % these flags can be set via GUI controls (like buttons)
    pauseSimulation = false; % should remain true as long as simulator should remain paused
    quitSimulation = false; % set to true once, is automatically reset at initialization
    resetSimulation = false; % set to true once, is automatically reset after simulator is re-initialized
    saveParameters = false; % set to true once, is automatically reset after parameters are saved
    loadParameters = false; % set to true once, is automatically reset after parameters are loaded
    paramPanelRequest = false; % should remain true as long as panel should remain active
    loadFile = ''; % file name from which presets are loaded, empty when no preset is loaded
  end
  
  methods
    % constructor
    function obj = StandardGUI(simulatorHandle, figurePosition, pauseDuration, ...
        visGridPosition, visGridSize, visGridPadding, controlGridPosition, controlGridSize, ...
        elementGroups, elementsInGroups, figureTitle)
      
      if ~isempty(simulatorHandle) && simulatorHandle ~= 0
        obj.simulatorHandle = simulatorHandle;
        obj.connected = true;
      end
      obj.figurePosition = figurePosition;
      
      if nargin >= 3
        obj.pauseDuration = pauseDuration;
      end
      if nargin >= 6
        obj.visGridPosition = visGridPosition;
        obj.visGridSize = visGridSize;
        obj.visGridPadding = visGridPadding;
        if numel(obj.visGridPadding) == 1
          obj.visGridPadding = repmat(obj.visGridPadding, [1, 2]);
        end
      end
      if nargin >= 8
        obj.controlGridPosition = controlGridPosition;
        obj.controlGridSize = controlGridSize;
      end
      if nargin < 10 || isempty(elementGroups) && isempty(elementsInGroups)
        elementGroups = {};
        elementsInGroups = {};
      end
      if nargin >= 11
        obj.figureTitle = figureTitle;
      end
      
      obj.paramPanelHandle = ParameterPanel(simulatorHandle, elementGroups, elementsInGroups, obj.figurePosition);
    end
    
    
    % destructor
    function delete(obj)
      obj.simulatorHandle = [];
      obj.paramPanelHandle = [];
    end
    
    
    % connect to a simulator obj
    function obj = connect(obj, simulatorHandle)
      obj.simulatorHandle = simulatorHandle;
      
      connect(obj.paramPanelHandle, simulatorHandle);
      for i = 1 : obj.nVisualizations
        connect(obj.visualizations{i}, obj.simulatorHandle);
      end
      for i = 1 : obj.nControls
        connect(obj.controls{i}, obj.simulatorHandle);
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj)
      if ~obj.connected || ~obj.simulatorHandle.initialized
        error('StandardGUI:init:notConnected', ...
          ['Cannot initialize StandardGUI object if it is not connected to a Simulator object, ' ...
          'or if Simulator object is not initialized.']);
      end
      
      obj.quitSimulation = false;
      obj.figureHandle = figure('Position', obj.figurePosition, 'Color', 'w', 'NumberTitle', 'off', ...
        'Name', obj.figureTitle);
      for i = 1 : obj.nVisualizations
        init(obj.visualizations{i}, obj.figureHandle);
      end
      for i = 1 : obj.nControls
        init(obj.controls{i}, obj.figureHandle);
      end
    end
    
    
    % close all figure windows
    function obj = close(obj)
      if obj.paramPanelActive
        obj.paramPanelHandle.close();
        obj.paramPanelActive = false;
        obj.paramPanelRequest = false;
      end
      if ishandle(obj.figureHandle)
        delete(obj.figureHandle);
      end
      for i = 1 : obj.nControls
        close(obj.controls{i});
      end
    end
    
    
    % run simulation in GUI
    function obj = run(obj, tMax, initializeSimulator, closeSimulator, simulatorHandle)      
      if nargin < 2 || isempty(tMax)
        tMax = inf;
      end
      if nargin < 3 || isempty(initializeSimulator)
        initializeSimulator = false;
      end
      if nargin < 4 || isempty(closeSimulator)
        closeSimulator = false;
      end
      if nargin >= 5
        connect(obj, simulatorHandle);
      end
      
      if ~obj.connected
        warning('StandardGUI:run:notConnected', ...
          'Cannot run StandardGUI object before it has been connected to a Simulator object');
        return;
      end
      
      if initializeSimulator || ~obj.simulatorHandle.initialized
        init(obj.simulatorHandle);
      end
      
      obj.init();
      
      while ~obj.quitSimulation && obj.simulatorHandle.t < tMax
        if ~ishandle(obj.figureHandle)
          break;
        end
        
        obj.step();
      end
      
      % close everything
      if closeSimulator
        close(obj.simulatorHandle);
      end
      close(obj);
    end
    
    
    % perform a single step in the GUI (perform simulation step, update
    % visualizations and controls, check flags for pause, save, quit etc.)
    function obj = step(obj)
      if ~obj.connected || ~obj.simulatorHandle.initialized
        error('StandardGUI:step:notInitialized', ...
          'Cannot perform GUI step when GUI is not open or not connected to an initialized simulator object.');
      end
      
      if ~ishghandle(obj.figureHandle)
        obj.quitSimulation = true;
        return;
      end
      
      % checking for changes in controls and param panel
      updateControls = false;
      if obj.paramPanelActive
        updateControls = check(obj.paramPanelHandle);
      end
      for i = 1 : obj.nControls
        updateControls = check(obj.controls{i}) || updateControls;
      end
      
      % opening and closing param panel
      if obj.paramPanelActive && ~obj.paramPanelHandle.panelOpen % panel figure was closed manually
        obj.paramPanelActive = false;
        obj.paramPanelRequest = false;
      end
      if obj.paramPanelRequest && ~obj.paramPanelActive
        open(obj.paramPanelHandle);
        obj.paramPanelActive = true;
      elseif ~obj.paramPanelRequest && obj.paramPanelActive
        close(obj.paramPanelHandle);
        obj.paramPanelActive = false;
      end
      
      % reset
      if obj.resetSimulation
        obj.simulatorHandle.init();
        obj.resetSimulation = false;
      end
      
      % save
      if obj.saveParameters
        saveParametersToFile(obj);
        obj.saveParameters = false;
      end
      
      % load
      if obj.loadParameters
        if loadParametersFromFile(obj);
          init(obj.simulatorHandle);
          updateControls = true;
        end
        obj.loadParameters = false;
      end
      
      % the actual simulation step
      if ~obj.pauseSimulation
        step(obj.simulatorHandle);
      end
      
      % updating visualizations, controls and panel
      for i = 1 : obj.nVisualizations
        update(obj.visualizations{i});
      end
      if updateControls
        if obj.paramPanelActive
          update(obj.paramPanelHandle);
        end
        for i = 1 : obj.nControls
          update(obj.controls{i});
        end
      end
      
      drawnow;
      if obj.pauseSimulation
        pause(obj.pauseDurationWhilePaused);
      else
        pause(obj.pauseDuration);
      end
      
      % close GUI on quit
      if obj.quitSimulation
        close(obj);
      end
    end
    
    
    % update all visualizations (for operation of the GUI from code)
    function obj = updateVisualizations(obj)
      if ~obj.connected || ~obj.simulatorHandle.initialized || ~ishghandle(obj.figureHandle)
        error('StandardGUI:updateVisualizations:notInitialized', ...
          'Cannot update visualizations when GUI is not open or not connected to an initialized simulator object.');
      end
      
      for i = 1 : obj.nVisualizations
        update(obj.visualizations{i});
      end
      
      drawnow;
    end
    
    
    % check all controls, then update them (for operation of the GUI from
    % code)
    function obj = checkAndUpdateControls(obj)
      if ~obj.connected || ~obj.simulatorHandle.initialized || ~ishghandle(obj.figureHandle)
        error('StandardGUI:updateVisualizations:notInitialized', ...
          'Cannot check controls when GUI is not open or not connected to initialized simulator object.');
      end
      
      for i = 1 : obj.nControls
        check(obj.controls{i});
      end
      for i = 1 : obj.nControls
        update(obj.controls{i});
      end
      
      drawnow;
    end
    
    
    % add visualization object
    function obj = addVisualization(obj, visualization, positionInGrid, sizeInGrid, gridSelection)
      obj.visualizations{end+1} = visualization;
      obj.nVisualizations = obj.nVisualizations + 1;
      
      if obj.connected
        connect(obj.visualizations{end}, obj.simulatorHandle);
      end
      if nargin < 4 || isempty(sizeInGrid)
        sizeInGrid = [1, 1];
      end
      if nargin < 5 || isempty(gridSelection)
        gridSelection = 'v';
      elseif ~(strncmp(gridSelection, 'visualization', length(gridSelection)) ...
          || strncmp(gridSelection, 'control', length(gridSelection)))
        error('StandardGUI:addVisualization:invalidGridSelection', ...
          'Argument gridSelection must be either ''control'' or ''visualization'' (default).');
      end
      
      if nargin >= 3 && ~isempty(positionInGrid)
        obj.visualizations{end}.position = obj.gridToRelPosition(gridSelection, positionInGrid, sizeInGrid);
      end
      if isempty(obj.visualizations{end}.position)
        error('StandardGUI:addVisualization:noPosition', ...
          'Position must be specified for each visualization, either in the element itself or via its grid position');
      end
    end
    
    
    % add control object and connect it to the simulator object
    function obj = addControl(obj, control, positionInGrid, sizeInGrid, gridSelection)
      obj.controls{end+1} = control;
      obj.nControls = obj.nControls + 1;
      
      if obj.connected
        connect(obj.controls{end}, obj.simulatorHandle);
      end
      if nargin < 4 || isempty(sizeInGrid)
        sizeInGrid = [1, 1];
      end
      if nargin < 5 || isempty(gridSelection)
        gridSelection = 'c';
      elseif ~(strncmp(gridSelection, 'visualization', length(gridSelection)) ...
          || strncmp(gridSelection, 'control', length(gridSelection)))
        error('StandardGUI:addVisualization:invalidGridSelection', ...
          'Argument gridSelection must be either ''control'' or ''visualization'' (default).');
      end
      
      if nargin >= 3
        obj.controls{end}.position = obj.gridToRelPosition(gridSelection, positionInGrid, sizeInGrid);
      end
      if isempty(obj.controls{end}.position)
        error('StandardGUI:addControl:noPosition', ...
          'Position must be specified for each control element, either in the element itself or via its grid position');
      end
    end
    
    
    % save current simulator parameters to file (opens dialogue)
    function success = saveParametersToFile(obj)
      success = false;
      if exist('savejson', 'file') ~= 2
        warndlg(['Cannot save parameters to file: File SAVEJSON.M not found. ' ...
          'Install JSONLAB and add it to the Matlab path to be able to save parameters to file.']);
      else
        [paramFile, paramPath] = uiputfile('*.json', 'Save parameter file');
        if ~(length(paramFile) == 1 && paramFile == 0)
          if ~saveSettings(obj.simulatorHandle, [paramPath paramFile])
            warndlg('Could not write to file. Saving of parameters failed.');
          else
            success = true;
          end
        end
      end
      
    end
    
    
    % load parameters for simulator from file (uses property loadFile or
    % opens dialogue)
    function success = loadParametersFromFile(obj)
      success = false;
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
          success = true;
        end
        obj.loadFile = '';
      end
    end
    
    
    % compute relative position in figure from grid position (result is in
    % format [x, y, w, h], with origin at the lower left corner of the
    % figure window / graphics element)
    function relPosition = gridToRelPosition(obj, type, positionInGrid, sizeInGrid)
      n = length(type);
      if n > 0 && strncmp(type, 'control', n)
        gridSize = obj.controlGridSize;
        gridPosition = obj.controlGridPosition;
        padding = [0, 0];
      elseif n > 0 && strncmp(type, 'visualization', n)
        gridSize = obj.visGridSize;
        gridPosition = obj.visGridPosition;
        padding = obj.visGridPadding;
      else
        error('StandardGUI:gridToRelPosition:invalidArgument', ...
          'Argument TYPE must be either ''control'' or ''visualization''.');
      end
      
      cellSize = [gridPosition(3)/gridSize(2), gridPosition(4)/gridSize(1)]; % [x, y]
      relPosition = [gridPosition(1) + (positionInGrid(2) - 1) * cellSize(1) + padding(1), ...
        gridPosition(2) + gridPosition(4) - (positionInGrid(1) + sizeInGrid(1) - 1) * cellSize(2) + padding(2), ...
        sizeInGrid(2) * cellSize(1) - 2*padding(1), sizeInGrid(1) * cellSize(2) - 2*padding(2)];
    end
    
  end
  
end

