classdef XYPlot < Visualization
  properties
    nPlots = 0;
    
    isConstData = [];
    plotElementHandles = {};
    plotElementLabels = {};
    plotComponents = {};
    plotData = {};
       
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
    
    connected = false;
  end
  
  methods
    % Constructor    
    function obj = XYPlot(plotElementsX, plotComponentsOrDataX, plotElementsY, plotComponentsOrDataY, ...
        axesProperties, plotProperties, title, xlabel, ylabel, position)
      if nargin >= 4 && ~isempty(plotComponentsOrDataX) && ~isempty(plotComponentsOrDataY)
        if ~iscell(plotElementsX)
          plotElementsX = {plotElementsX};
        end
        if ~iscell(plotElementsY)
          plotElementsY = {plotElementsY};
        end
        if ~iscell(plotComponentsOrDataX)
          plotComponentsOrDataX = {plotComponentsOrDataX};
        end
        if ~iscell(plotComponentsOrDataY)
          plotComponentsOrDataX = {plotComponentsOrDataY};
        end
        
        if numel(plotElementsX) ~= numel(plotComponentsOrDataX) ...
          || numel(plotElementsY) ~= numel(plotComponentsOrDataY) ...
          || numel(plotElementsX) ~= numel(plotElementsY);
        
          error('XYPlot:XYPlot:inconsistentArguments', ...
            ['Arguments ''plotElementsX'', ''plotComponentsOrDataX'', ''plotElementsY'', and ' ...
            '''plotComponentsOrDataY'' must all have the same number of elements.']);
        end
        obj.nPlots = numel(plotElementsX);
        
        obj.isConstData = false(obj.nPlots, 2);
        obj.plotElementLabels = cell(obj.nPlots, 2);
        obj.plotElementHandles = cell(obj.nPlots, 2);
        obj.plotComponents = cell(obj.nPlots, 2);
        obj.plotData = cell(obj.nPlots, 2);
                
        for i = 1 : obj.nPlots
          if isempty(plotElementsX{i})
            obj.isConstData(i, 1) = true;
            obj.plotData{i, 1} = plotComponentsOrDataX{i};
          else
            obj.plotElementLabels{i, 1} = plotElementsX{i};
            obj.plotComponents{i, 1} = plotComponentsOrDataX{i};
          end
          if isempty(plotElementsY{i})
            obj.isConstData(i, 2) = true;
            obj.plotData{i, 2} = plotComponentsOrDataY{i};
          else
            obj.plotElementLabels{i, 2} = plotElementsY{i};
            obj.plotComponents{i, 2} = plotComponentsOrDataY{i};
          end
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
        for j = 1 : 2
          if obj.isConstData(i, j)
            if isempty(obj.plotData{i, j}) || ~isnumeric(obj.plotData{i, j})
              error('MultiPlot:connect:invalidData', ...
                'Non-empty numeric array must be provided as constant data for plot if no element is specified as source.');
            end
          else
            if simulatorHandle.isElement(obj.plotElementLabels{i, j})
              obj.plotElementHandles{i, j} = simulatorHandle.getElement(obj.plotElementLabels{i, j});
              if isempty(obj.plotComponents{i, j}) || ~ischar(obj.plotComponents{i, j})
                error('MultiPlot:connect:invalidComponent', ...
                  'Component for element %s must be specified by label (string).', obj.plotElementLabels{i, j});
              end
              if ~obj.plotElementHandles{i, j}.isComponent(obj.plotComponents{i, j}) ...
                  && ~obj.plotElementHandles{i, j}.isParameter(obj.plotComponents{i, j})
                error('MultiPlot:connect:invalidComponent', ...
                  'Invalid component %s for element %s in simulator object.', ...
                  obj.plotComponents{i, j}, obj.plotElementLabels{i, j});
              end
            else
              error('MultiPlot:connect:elementNotFound', 'No element %s in simulator object.', ...
                obj.plotElementLabels{i, j});
            end
          end
        end
      end
      
      obj.connected = true;
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position, 'nextPlot', 'add', obj.axesProperties{:});
      
      plotDataTmp = cell(1, 2);
      for i = 1 : obj.nPlots
        for j = 1 : 2
          if obj.isConstData(i, j)
            plotDataTmp{j} = obj.plotData{i, j};
          else
            plotDataTmp{j} = obj.plotElementHandles{i, j}.(obj.plotComponents{i, j});
          end
        end
        
        if isempty(plotDataTmp{1}) && isempty(plotDataTmp{2})
          obj.plotHandles(i) = plot(obj.axesHandle, NaN, NaN, obj.plotProperties{i}{:});
        else
          obj.plotHandles(i) = plot(obj.axesHandle, plotDataTmp{1}, plotDataTmp{2}, obj.plotProperties{i}{:});
        end
        set(obj.plotHandles(i), 'XDataMode', 'manual'); % this is a crutch; can't set it at plot creation
      end

      if ~isempty(obj.title)
        obj.titleHandle = title(obj.title); %#ok<PROP,CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.xlabel); %#ok<PROP,CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.ylabel); %#ok<PROP,CPROP>
      end
    end
    
    
    % update
    function obj = update(obj)
      for i = 1 : obj.nPlots
        if ~obj.isConstData(i, 1)
          set(obj.plotHandles(i), 'XData', obj.plotElementHandles{i, 1}.(obj.plotComponents{i, 1}));
        end
        if ~obj.isConstData(i, 2)
          set(obj.plotHandles(i), 'YData', obj.plotElementHandles{i, 2}.(obj.plotComponents{i, 2}));
        end
      end
    end
    
    
%     % add new plot
%     function obj = addPlot(obj, plotElementX, plotComponentX, plotElementY, plotComponentY, plotProperties)
%       if obj.connected
%         error('MultiPlot:addPlot:noAddAfterConnect', ...
%           'Cannot add plots after MultiPlot object has been connected to a simulator (e.g. by adding it to a GUI).');
%       end
%       
%       obj.plotElementLabels{end+1} = plotElement;
%       obj.plotComponents{end+1} = plotComponent;
%       if nargin >= 4
%         obj.plotScales(end+1) = scale;
%       else
%         obj.plotScales(end+1) = 1;
%       end
%       if nargin >= 5
%         obj.plotProperties{end+1} = plotProperties;
%       else 
%         obj.plotProperties{end+1} = {};
%       end
%       
%       
%       obj.nPlots = obj.nPlots + 1;
%       obj.plotHandles(end+1) = 0;
%     end
  end
    
  
end