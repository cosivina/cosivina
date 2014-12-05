% SurfacePlot (COSIVINA toolbox)
%   Visualization that diplays two-dimensional data either as a mesh or a surface plot.
%
% Constructor call:
% SurfacePlot(plotElement, plotComponent, zLim, plotType, ...
%   axesProperties, plotProperties, title, xlabel, ylabel, position)
%
% Arguments:
% plotElements - string or cell array of strings (with one entry for each
%   plot) listing the labels of the elements whose components should be
%   plotted
% plotComponents - string or cell array of strings (with one entry for
%   each plot) listing the component names that should be plotted for the
%   specified elements; one pair of entries from plotElements and
%   plotComponents fully specifies the source data for one plot
% zLim - range of the plot's axes in the z-dimension
% plotType - either 'mesh' or 'surface' (default)
% axesProperties - cell array containing a list of valid axes settings
%   (as property/value pairs) that can be applied to the axes handle via
%   the set function (optional, see Matlab documentation on axes for 
%   further information)
% plotProperties - cell array containing a list of valid surface object
%   settings (as property/value pairs) that can be applied to the surface
%   handle via the set function (optional, see Matlab documentation on
%   the surface function for further information)
% title - string specifying an axes title (optional)
% xlabel - string specifying an x-axis label (optional)
% ylabel - string specifying a y-axis label (optional)
% zlabel - string specifying a y-axis label (optional)
% position - position of the control in the GUI figure window in relative
%   coordinates (optional, is overwritten when specifying a grid position
%   in the GUI's addVisualization function)
%
% Example:
% h = SurfacePlot('field u', 'activation', [-10, 10], {}, {}, ...
%   'perceptual field', 'position', 'color', 'activation');


classdef SurfacePlot < Visualization
  properties
    plotElementHandle = 0;
    plotElementLabel
    plotComponent
    
    meshPlot = false;
    zLim
    
    axesHandle = 0;
    axesProperties = {};
    
    plotHandle = 0;
    plotProperties = {};
    
    title = '';
    xlabel = '';
    ylabel = '';
    zlabel = '';
    
    titleHandle = 0;
    xlabelHandle = 0;
    ylabelHandle = 0;
    zlabelHandle = 0;
  end
  
  
  methods
    % Constructor
    function obj = SurfacePlot(plotElement, plotComponent, zLim, plotType, axesProperties, plotProperties, ...
        title, xlabel, ylabel, zlabel, position)
      obj.plotElementLabel = plotElement;
      obj.plotComponent = plotComponent;
      obj.zLim = zLim;
      obj.position = [];

      if nargin >= 4 && ~isempty(plotType)
        if strncmpi(plotType, 'mesh', length(plotType))
          obj.meshPlot = true;
        elseif ~strncmpi(plotType, 'surface', length(plotType))
          warning('SurfacePlot:SurfacePlot:invalidValue', ...
            'Argument ''plotType'' should be either ''surface'' (default) or ''mesh''.');
        end
      end
      if nargin >= 5
        obj.axesProperties = axesProperties;
      end
      if nargin >= 6
        obj.plotProperties = plotProperties;
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
      if nargin >= 10 && ~isempty(ylabel)
        obj.zlabel = zlabel;
      end
      if nargin >= 11
        obj.position = position;
      end
    end
    
    
    % connect to simulator object
    function obj = connect(obj, simulatorHandle)
      if simulatorHandle.isElement(obj.plotElementLabel)
        obj.plotElementHandle = simulatorHandle.getElement(obj.plotElementLabel);
        if ~obj.plotElementHandle.isComponent(obj.plotComponent) ...
            && ~obj.plotElementHandle.isParameter(obj.plotComponent)
          error('SurfacePlot:connect:invalidComponent', 'Invalid component %s for element %s in simulator object.', ...
            obj.plotComponent, obj.plotElementLabel);
        end
      else
        error('SurfacePlot:connect:elementNotFound', 'No element %s in simulator object.', obj.plotElementLabel);
      end
    end
    
    
    % initialization
    function obj = init(obj, figureHandle)
      obj.axesHandle = axes('Parent', figureHandle, 'Position', obj.position);
      if obj.meshPlot
        obj.plotHandle = mesh(obj.plotElementHandle.(obj.plotComponent), 'Parent', obj.axesHandle, ...
          obj.plotProperties{:});
      else
        obj.plotHandle = surf(obj.plotElementHandle.(obj.plotComponent), 'Parent', obj.axesHandle, ...
          obj.plotProperties{:});
      end
      set(obj.axesHandle, 'ZLim', obj.zLim, 'CLim', obj.zLim, obj.axesProperties{:});
      colormap(jet(256));
      
      if ~isempty(obj.title)
        obj.titleHandle = title(obj.axesHandle, obj.title); %#ok<CPROP>
      end
      if ~isempty(obj.xlabel)
        obj.xlabelHandle = xlabel(obj.axesHandle, obj.xlabel); %#ok<CPROP>
      end
      if ~isempty(obj.ylabel)
        obj.ylabelHandle = ylabel(obj.axesHandle, obj.ylabel); %#ok<CPROP>
      end
      if ~isempty(obj.zlabel)
        obj.zlabelHandle = zlabel(obj.axesHandle, obj.zlabel); %#ok<CPROP>
      end
      
    end
    
    
    % update
    function obj = update(obj)
      set(obj.plotHandle, 'ZData', obj.plotElementHandle.(obj.plotComponent));
    end
    
  end
  
end


