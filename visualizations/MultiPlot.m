classdef MultiPlot < Visualization
  properties
    nPlots = 0;
    plotElementHandles = {};
    plotElementLabels = {};
    plotComponents = {};
    plotScales = [];
    
    axesHandle = 0;
    axesProperties = {};
    
    plotHandles = [];
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
    
    vertical = false;
    dataProperty = 'YData';
    
    connected = false;
  end
  
  methods
    % Constructor    
    function obj = MultiPlot(plotElements, plotComponents, scales, orientation, axesProperties, plotProperties, ...
        title, xlabel, ylabel, position)
      if nargin >= 2 && ~isempty(plotElements) && ~isempty(plotComponents)
        obj.plotElementLabels = plotElements;
        obj.plotComponents = plotComponents;
        
        if ischar(obj.plotElementLabels)
          obj.plotElementLabels = cellstr(obj.plotElementLabels);
        end
        if ischar(obj.plotComponents)
          obj.plotComponents = cellstr(obj.plotComponents);
        end
        if numel(obj.plotElementLabels) ~= numel(obj.plotComponents)
          error('MultiPlot:MultiPlot:inconsistentArguments', ...
            'Arguments ''plotElements'' and ''plotComponents'' must have the same number of elements.');
        end
        obj.nPlots = numel(obj.plotElementLabels);
      end
      if nargin >= 3 && ~isempty(scales)
        obj.plotScales = scales;
      else
        obj.plotScales = ones(obj.nPlots, 1);
      end
      if nargin >= 4 && ~isempty(orientation)
        if strncmpi(orientation, 'vertical', length(orientation))
          obj.vertical = true;
        elseif ~strncmpi(orientation, 'horizontal', length(orientation))
          warning('MultiPlot:MultiPlot:invalidValue', ...
            'Argument ''orientation'' should be either ''horizontal'' (default) or ''vertical''.');
        end
      end
      if nargin >= 5 && ~isempty(axesProperties)
        obj.axesProperties = axesProperties;
      end
      if nargin >= 6 && ~isempty(plotProperties)
        obj.plotProperties = plotProperties;
      else
        obj.plotProperties = cell(obj.nPlots, 1);
        [obj.plotProperties{:}] = deal(cell(0));
      end
      if nargin >= 7 && ~isempty(title)
        obj.title = title;
      end
      if nargin >= 8 && ~isempty(xlabel)
        obj.xlabel = xlabel;
      end
      if nargin >= 9 && ~isempty(ylabel)
        obj.ylabel = ylabel;
      end
      if nargin >= 10
        obj.position = position;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      for i = 1 : obj.nPlots
        if simulatorHandle.isElement(obj.plotElementLabels{i})
          obj.plotElementHandles{i} = simulatorHandle.getElement(obj.plotElementLabels{i});
          if ~obj.plotElementHandles{i}.isComponent(obj.plotComponents{i}) ...
              && ~obj.plotElementHandles{i}.isParameter(obj.plotComponents{i})
            error('MultiPlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
              obj.plotComponents{i}, obj.plotElementLabels{i});
          end
        else
          error('MultiPlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabels{i});
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, 'nextPlot', 'add', obj.axesProperties{:});
      if obj.vertical % vertical plots
        for i = 1 : obj.nPlots
          obj.plotHandles(i) = plot(obj.axesHandle, ...
            obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}), ...
            1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{i}{:});
        end
        obj.dataProperty = 'XData';
      else % horizontal plot
        for i = 1 : obj.nPlots
          obj.plotHandles(i) = plot(obj.axesHandle, obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}), ...
            obj.plotProperties{i}{:});
          set(obj.plotHandles(i), 'XDataMode', 'manual'); % this is a crutch; can't set it at plot creation
        end
        obj.dataProperty = 'YData';
      end
      
      if ~isempty(obj.title)
        obj.titleHandle = title(obj.title); %#ok<CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.xlabel); %#ok<CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.ylabel); %#ok<CPROP>
      end
      
    end
    
    
    % update
    function obj = update(obj)
      for i = 1 : obj.nPlots
        set(obj.plotHandles(i), obj.dataProperty, obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i}));
      end
    end
    
    
    % add new plot
    function obj = addPlot(obj, plotElement, plotComponent, scale, plotProperties)
      if obj.connected
        error('MultiPlot:addPlot:noAddAfterConnect', ...
          'Cannot add plots after MultiPlot object has been connected to a simulator (e.g. by adding it to a GUI).');
      end
      
      obj.plotElementLabels{end+1} = plotElement;
      obj.plotComponents{end+1} = plotComponent;
      if nargin >= 4
        obj.plotScales(end+1) = scale;
      else
        obj.plotScales(end+1) = 1;
      end
      if nargin >= 5
        obj.plotProperties{end+1} = plotProperties;
      else 
        obj.plotProperties{end+1} = {};
      end
      
      
      obj.nPlots = obj.nPlots + 1;
      obj.plotHandles(end+1) = 0;
    end
  end
    
  
end