% Example C: Using a GUI for visualization only
% (see the documentation for detailed explanation of the script)

% create object sim by constructor call
sim = Simulator();


% shared element parameters
fieldSize = 100;


% timing parameters
tMax = 200;
tStimOn = 25;
tBoost = 100;


% add elements
sim.addElement(NeuralField('field u', fieldSize, 10, -5, 4));
sim.addElement(LateralInteractions1D('u -> u', fieldSize, 4, 15, 10, 0, -0.6), ...
  'field u', 'output', 'field u', 'output');
sim.addElement(TimedGaussStimulus1D('stim A', fieldSize, 5, 4, 25, [tStimOn, inf]), ...
  [], [], 'field u');
sim.addElement(TimedGaussStimulus1D('stim B', fieldSize, 5, 4, 75, [tStimOn, inf]), ...
  [], [], 'field u');
sim.addElement(TimedCustomStimulus('boost', 2, [tBoost, inf]), [], [], 'field u');
sim.addElement(NormalNoise('noise', fieldSize, 0.5), [], [], 'field u');


% create the gui object
gui = StandardGUI(sim, [50, 50, 700, 400], 0.05, ...
  [0.0, 0.1, 1.0, 0.9], [1, 1], 0.1, ...
  [0.0, 0.0, 1.0, 0.1], [1, 3]);


% add a plot of field u (with activation, output, and inputs)
gui.addVisualization(MultiPlot({'field u', 'field u', 'stim A', 'stim B'}, ...
  {'activation', 'output', 'output', 'output'}, [1, 10, 1, 1], 'horizontal', ...
  {'YLim', [-12.5, 12.5], 'Box', 'on'}, ...
  {{'b', 'LineWidth', 2}, {'r'}, {'g'}, {'g'}}, ...
  'field u', 'field position', 'activation/ouput/input'), ...
  [1, 1]);


% add text-based visualization (placed in the controls grid)
gui.addVisualization(TimeDisplay(), [1, 3], [1, 1], 'control');


% initialize simulator and GUI
sim.init();
gui.init();

% run and visualize simulation manually step by step
while sim.t < tMax
  sim.step();
  gui.updateVisualizations();
  pause(0.05);
  
  act = sim.getComponent('field u', 'activation');
  if any(act > 5)
    [nPeaks, peakPositions] = singleLinkageClustering(act > 0, 3, 'circular');
    break;
  end
end




