% Launcher to illustrate coupling between fields of different
% dimensionality. The architecture consists of a one-dimensional field f, a
% two-dimensional field s, and a three-dimensional field v (to which the other
% two fields are coupled bidirectionally). Activation in the three-dimensional
% field is illustrated in a TilePlot, showing all possible 2D cuts through
% the 3D feature space. The architecture can be used in an analogous
% fashion as the one in launcherCoupling, but now with two spatial
% dimensions.

%% setting up the simulator

% shared parameters
sizeX = 50; sizeY = 50; sizeZ = 25;
sigmaExcXY = 4; sigmaInhXY = 8;
sigmaExcZ = 2; sigmaInhZ = 4;

% create simulator
sim = Simulator();

% create inputs
sim.addElement(GaussStimulus1D('stim c', sizeZ, sigmaExcZ, 0, 10, true));
sim.addElement(GaussStimulus2D('stim s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, 10, 15, false, false));
sim.addElement(GaussStimulus3D('stim v1', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, 30, 40, 10, ...
  false, false, true));
sim.addElement(GaussStimulus3D('stim v2', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, 10, 15, 20, ...
  false, false, true));

% create neural fields
sim.addElement(NeuralField('field c', sizeZ, 10, -5, 4), 'stim c');
sim.addElement(NeuralField('field s', [sizeY, sizeX], 10, -5, 4), 'stim s');
sim.addElement(NeuralField('field v', [sizeY, sizeX, sizeZ], 10, -5, 4), {'stim v1', 'stim v2'});

% add lateral interactions
sim.addElement(LateralInteractions1D('c -> c', sizeZ, sigmaExcZ, 0, sigmaInhZ, 0, 0, true), 'field c', [], 'field c');
sim.addElement(LateralInteractions2D('s -> s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, sigmaInhXY, sigmaInhXY, 0, 0, ...
  false, false), 'field s', [], 'field s');
sim.addElement(KernelFFT('v -> v', [sizeY, sizeX, sizeZ], [sigmaExcXY, sigmaExcXY, sigmaExcZ], 0, ...
  2*[sigmaExcXY, sigmaExcXY, sigmaExcZ], 0, 0, [false, false, true]), 'field v', [], 'field v');

% interactions between field v and field c
sim.addElement(SumDimension('sum v (color)', [1, 2], sizeZ), 'field v');
sim.addElement(GaussKernel1D('v -> c', sizeZ, sigmaExcZ, 0, true), 'sum v (color)', [], 'field c');
sim.addElement(GaussKernel1D('c -> v', sizeZ, sigmaExcZ, 0, true), 'field c');
sim.addElement(ExpandDimension('expand c -> v', sizeZ, [sizeY, sizeX, sizeZ], 3), 'c -> v', [], 'field v');

% interactions between field v and field s
sim.addElement(SumDimension('sum v (spatial)', 3, [sizeY, sizeX]), 'field v');
sim.addElement(GaussKernel2D('v -> s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, false, false), ...
  'sum v (spatial)', [], 'field s');
sim.addElement(GaussKernel2D('s -> v', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, false, false), 'field s');
sim.addElement(ExpandDimension('expand s -> v', [sizeY, sizeX], [sizeY, sizeX, sizeZ], [1, 2]), ...
  's -> v', [], 'field v');


%% setting up the GUI
gui = StandardGUI(sim, [100, 100, 1250, 600], 0.01, [0.025, 0.0, 0.625, 1.0], [3, 4], [0.015, 0.04], ...
  [0.65, 0.0, 0.35, 1.0], [29, 2]);

gui.addVisualization(TilePlot('field v', 'activation', [sizeY, sizeX, sizeZ], [5, 5], [-10, 10], {}, {}, ...
  'visual field (space-color)', 'within tile: spatial position, across tiles: color value'), [1, 2], [3, 3]);
gui.addVisualization(MultiPlot({'field c', 'field c', 'stim c'}, {'activation', 'output', 'output'}, [1, 10, 1], ...
  'horizontal', {'XLim', [0, sizeZ], 'YLim', [-10, 10]}, { {'b'}, {'r'}, {'g'} }, 'color field', 'color value', ...
  'activation'), [1.5, 1], [0.5, 1]);
gui.addVisualization(ScaledImage('field s', 'activation', [-10, 10], {}, {}, 'spatial field', 'horizontal position', ...
  'vertical position'), [2.5, 1]);


% add sliders
gui.addVisualization(StaticText('color field (1D)'), [1, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field c', 'h', [-10, 0], '%0.1f', 1, ...
  'resting level of field s'), [2, 1]);
gui.addControl(ParameterSlider('c_gl', 'c -> c', 'amplitudeGlobal', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition in field c'), [2, 2]);
gui.addControl(ParameterSlider('c_exc', 'c -> c', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field c'), [3, 1]);
gui.addControl(ParameterSlider('c_inh', 'c -> c', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition in field c'), [3, 2]);

gui.addControl(ParameterSlider('a_c', 'stim c', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus for field c'), [4, 1]);
gui.addControl(ParameterSlider('p_c', 'stim c', 'position', [0, sizeZ], '%0.1f', 1, ...
  'color value of stimulus for field c'), [4, 2]);


gui.addVisualization(StaticText('spatial field (2D)'), [6, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field s', 'h', [-10, 0], '%0.1f', 1, ...
  'resting level of field s'), [7, 1]);
gui.addControl(ParameterSlider('c_gl', 's -> s', 'amplitudeGlobal', [0, 0.25], '%0.2f', -1, ...
  'strength of global inhibition in field s'), [7, 2]);
gui.addControl(ParameterSlider('c_exc', 's -> s', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field s'), [8, 1]);
gui.addControl(ParameterSlider('c_inh', 's -> s', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition in field s'), [8, 2]);

gui.addControl(ParameterSlider('a_s', 'stim s', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus for field s'), [9, 1]);
gui.addControl(ParameterSlider('p_sx', 'stim s', 'positionX', [0, sizeX], '%0.1f', 1, ...
  'horizontal position of stimulus for field s'), [10, 1]);
gui.addControl(ParameterSlider('p_sy', 'stim s', 'positionY', [0, sizeY], '%0.1f', 1, ...
  'vertical amplitude of stimulus for field s'), [10, 2]);


gui.addVisualization(StaticText('visual field (space-color, 3D)'), [12, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field v', 'h', [-10, 0], '%0.1f', 1, ...
  'resting level of field v'), [13, 1]);
gui.addControl(ParameterSlider('c_gl', 'v -> v', 'amplitudeGlobal', [0, 0.1], '%0.3f', -1, ...
  'strength of global inhibition in field v'), [13, 2]);
gui.addControl(ParameterSlider('c_exc', 'v -> v', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field v'), [14, 1]);
gui.addControl(ParameterSlider('c_inh', 'v -> v', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
  'strength of lateral inhibition in field v'), [14, 2]);

gui.addControl(ParameterSlider('a_s1', 'stim v1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1 for field v'), [15, 1]);
gui.addControl(ParameterSlider('p_sc1', 'stim v1', 'positionZ', [0, sizeZ], '%0.1f', 1, ...
  'color value of stimulus 1 for field v'), [15, 2]);
gui.addControl(ParameterSlider('p_sx1', 'stim v1', 'positionX', [0, sizeX], '%0.1f', 1, ...
  'horizontal position of stimulus 1 for field v'), [16, 1]);
gui.addControl(ParameterSlider('p_sy1', 'stim v1', 'positionY', [0, sizeY], '%0.1f', 1, ...
  'vertical position of stimulus 1 for field v'), [16, 2]);

gui.addControl(ParameterSlider('a_s2', 'stim v2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2 for field v'), [17, 1]);
gui.addControl(ParameterSlider('p_sc2', 'stim v2', 'positionZ', [0, sizeZ], '%0.1f', 1, ...
  'color value of stimulus 2 for field v'), [17, 2]);
gui.addControl(ParameterSlider('p_sx2', 'stim v2', 'positionX', [0, sizeX], '%0.1f', 1, ...
  'horizontal position of stimulus 2 for field v'), [18, 1]);
gui.addControl(ParameterSlider('p_sy2', 'stim v2', 'positionY', [0, sizeY], '%0.1f', 1, ...
  'vertical position of stimulus 2 for field v'), [18, 2]);


gui.addVisualization(StaticText('projections between fields'), [20, 1], [1, 2], 'control');
gui.addControl(ParameterSlider('v->c', 'v -> c', 'amplitude', [0, 1], '%0.2f', 1, ...
  'projection strength from field v to field c'), [21, 1]);
gui.addControl(ParameterSlider('c->v', 'c -> v', 'amplitude', [0, 10], '%0.1f', 1, ...
  'projection strength from field c to field v'), [21, 2]);
gui.addControl(ParameterSlider('v->s', 'v -> s', 'amplitude', [0, 10], '%0.1f', 1, ...
  'projection strength from field v to field s'), [22, 1]);
gui.addControl(ParameterSlider('s->v', 's -> v', 'amplitude', [0, 20], '%0.1f', 1, ...
  'projection strength from field s to field v'), [22, 2]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [24, 2]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [25, 2]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [26, 2]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [27, 2]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [28, 2]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [29, 2]);


%% run the simulator in the GUI

gui.run(inf);


