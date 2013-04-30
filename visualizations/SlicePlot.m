classdef SlicePlot < Visualization
  properties (Constant)
    Horizontal = 0;
    Vertical = 1;
  end
  
  properties
    nSources = 0;
    plotElementHandles = {};
    plotElementLabels = {};
    plotComponents = {};
    plotSlices = {};
    sliceOrientations = {};
    plotScales = [];
    
    plotSlicesAll = [];
    plotsToSources = [];
    
    axesHandle = 0;
    axesProperties = {};
    
    nPlots = 0;
    plotHandles = [];
    plotProperties = {};
    
    orientation = SlicePlot.Horizontal;
    dataProperty = 'YData';
    
    connected = false;
  end
  
  methods
    % Constructor    
    function obj = SlicePlot(plotElements, plotComponents, plotSlices, sliceOrientations, scales, plotOrientation, ...
        axesProperties, plotProperties, position)
      if nargin >= 4 && ~isempty(plotElements)
        obj.plotElementLabels = plotElements;
        obj.plotComponents = plotComponents;
        obj.plotSlices = plotSlices;
               
        if ischar(obj.plotElementLabels)
          obj.plotElementLabels = cellstr(obj.plotElementLabels);
        end
        if ischar(obj.plotComponents)
          obj.plotComponents = cellstr(obj.plotComponents);
        end
        if isnumeric(obj.plotSlices)
          obj.plotSlices = {plotSlices};
        end
        if ischar(sliceOrientations)
          sliceOrientations = cellstr(sliceOrientations);
        end
        obj.nSources = numel(obj.plotElementLabels);
        
        if numel(obj.plotComponents) ~= obj.nSources || numel(obj.plotSlices) ~= obj.nSources ...
            || numel(sliceOrientations) ~= obj.nSources
          error('SlicePlot:SlicePlot:inconsistentArguments', ...
            'Arguments plotElements, plotComponents, plotSlices, and sliceOrientations must have the same size.');
        end
        
        obj.sliceOrientations = repmat(SlicePlot.Horizontal, [1, obj.nSources]);
        for i = 1 : obj.nSources
          if strncmpi(sliceOrientations{i}, 'vertical', length(sliceOrientations{i}))
            obj.sliceOrientations(i) = SlicePlot.Vertical;
          elseif ~strncmpi(sliceOrientations{i}, 'horizontal', length(sliceOrientations{i}))
            warning('SlicePlot:SlicePlot:unknownIdentifier', ...
              'Each entry in argument ''sliceOrientation'' should be either ''horizontal'' (default) or ''vertical''.');
          end
        end
        
        for i = 1 : obj.nSources
          obj.nPlots = obj.nPlots + numel(obj.plotSlices{i});
          obj.plotSlicesAll = [obj.plotSlicesAll, reshape(obj.plotSlices{i}, [1, numel(obj.plotSlices{i})])];
          obj.plotsToSources = [obj.plotsToSources, repmat(i, [1, numel(obj.plotSlices{i})])];
        end
      end
      if nargin >= 5 && ~isempty(scales)
        obj.plotScales = scales;
      else
        obj.plotScales = ones(obj.nSources, 1);
      end
      if nargin >= 6 && ~isempty(plotOrientation)
        if strncmpi(plotOrientation, 'vertical', length(plotOrientation))
          obj.orientation = SlicePlot.Vertical;
        elseif ~strncmpi(plotOrientation, 'horizontal', length(plotOrientation))
          warning('SlicePlot:SlicePlot:unknownIdentifier', ...
            'Argument ''plotOrientation'' should be either ''horizontal'' (default) or ''vertical''.');
        end
      end
      if nargin >= 7 && ~isempty(axesProperties)
        obj.axesProperties = axesProperties;
      end
      if nargin >= 8 && ~isempty(plotProperties)
        obj.plotProperties = plotProperties;
      else
        obj.plotProperties = cell(obj.nPlots, 1);
        [obj.plotProperties{:}] = deal(cell(0));
      end
      if nargin >= 9
        obj.position = position;
      end
    end
       
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      for i = 1 : obj.nSources
        if simulatorHandle.isElement(obj.plotElementLabels{i})
          obj.plotElementHandles{i} = simulatorHandle.getElement(obj.plotElementLabels{i});
          if ~obj.plotElementHandles{i}.isComponent(obj.plotComponents{i}) ...
              && ~obj.plotElementHandles{i}.isParameter(obj.plotComponents{i})
            error('SlicePlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
              obj.plotComponents{i}, obj.plotElementLabels{i});
          end
        else
          error('SlicePlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabels{i});
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, 'nextPlot', 'add', obj.axesProperties{:});
      
      obj.plotHandles = zeros(1, obj.nPlots);
      plotIndex = 1;
      % horizontal plots
      for i = 1 : obj.nSources
        for j = 1 : numel(obj.plotSlices{i})
          if obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Horizontal
            obj.plotHandles(plotIndex) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(obj.plotSlices{i}(j), :), ...
              obj.plotProperties{plotIndex}{:});
            set(obj.plotHandles(i), 'XDataMode', 'manual');
          elseif obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Vertical
            obj.plotHandles(plotIndex) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(:, obj.plotSlices{i}(j)), ...
              obj.plotProperties{plotIndex}{:});
            set(obj.plotHandles(i), 'XDataMode', 'manual');
          elseif obj.orientation == SlicePlot.Horizontal && obj.sliceOrientations(i) == SlicePlot.Vertical
            obj.plotHandles(i) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(obj.plotSlices{i}(j), :), ...
              1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{plotIndex}{:});
          else
            obj.plotHandles(i) = plot(obj.axesHandle, ...
              obj.plotScales(i) * obj.plotElementHandles{i}.(obj.plotComponents{i})(:, obj.plotSlices{i}(j)), ...
              1 : length(obj.plotElementHandles{i}.(obj.plotComponents{i})), obj.plotProperties{plotIndex}{:});
          end
          plotIndex = plotIndex + 1;
        end
      end
      
      if obj.orientation == SlicePlot.Horizontal
        obj.dataProperty = 'YData';
      else
        obj.dataProperty = 'XData';
      end
    end
    
    
    % update
    function obj = update(obj)
      for i = 1 : obj.nPlots
        j = obj.plotsToSources(i);
        if obj.sliceOrientations(j) == SlicePlot.Horizontal
          set( obj.plotHandles(i), obj.dataProperty, ...
            obj.plotScales(j) * obj.plotElementHandles{j}.(obj.plotComponents{j})(obj.plotSlicesAll(i), :) );
        else
          set( obj.plotHandles(i), obj.dataProperty, ...
            obj.plotScales(j) * obj.plotElementHandles{j}.(obj.plotComponents{j})(:, obj.plotSlicesAll(i)) );
        end
      end
    end
    
    
%     % add new plot
%     function obj = addPlot(obj, plotElement, plotComponent, plotProperties, scale)
%       if obj.connected
%         error('SlicePlot:addPlot:noAddAfterConnect', ...
%           'Cannot add plots after SlicePlot object has been connected to a simulator (e.g. by adding it to a GUI).');
%       end
%       
%       obj.plotElementLabels{end+1} = plotElement;
%       obj.plotComponents{end+1} = plotComponent;
%       if nargin >= 4
%         obj.plotProperties{end+1} = plotProperties;
%       else 
%         obj.plotProperties{end+1} = {};
%       end
%       if nargin >= 5
%         obj.plotScales(end+1) = scale;
%       else
%         obj.plotScales(end+1) = 1;
%       end
%       
%       obj.nPlots = obj.nPlots + 1;
%       obj.plotHandles(end+1) = 0;
%     end
  end
    
  
end