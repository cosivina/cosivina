
clear classes;

% create architecture
sim = Simulator();

sizeX = 50; sizeY = 50; sizeZ = 25;
sigmaExcXY = 4; sigmaInhXY = 8;
sigmaExcZ = 2; sigmaInhZ = 4;

sim.addElement(GaussStimulus1D('stim c', sizeZ, sigmaExcZ, 0, 10, true));
sim.addElement(GaussStimulus2D('stim s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 8, 15, 20, false, false));

sim.addElement(GaussStimulus3D('stim v1', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, 24, 24, 10, ...
  false, false, true));
sim.addElement(GaussStimulus3D('stim v2', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, 5, 10, 20, ...
  false, false, true));

sim.addElement(NeuralField('field c', sizeZ, 10, -5, 4), 'stim c');
sim.addElement(NeuralField('field s', [sizeY, sizeX], 10, -5, 4), 'stim s');
sim.addElement(NeuralField('field v', [sizeY, sizeX, sizeZ], 10, -5, 4), {'stim v1', 'stim v2'});

sim.addElement(LateralInteractions1D('c -> c', sizeZ, sigmaExcZ, 0, sigmaInhZ, 0, 0, true), 'field c', [], 'field c');
sim.addElement(LateralInteractions2D('s -> s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, sigmaInhZ, sigmaInhZ, 0, 0, ...
  false, false), 'field s', [], 'field s');
sim.addElement(KernelFFT('v -> v', [sizeY, sizeX, sizeZ], [sigmaExcXY, sigmaExcXY, sigmaExcZ], 0, ...
  2*[sigmaExcXY, sigmaExcXY, sigmaExcZ], 0, 0), 'field v', [], 'field v');

sim.addElement(LateralInteractions3D('v -> v (alt)', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, ...
  sigmaInhZ, sigmaInhZ, sigmaInhZ, 0, 0, false, false, true),  ...
  'field v', [], 'field v');
% sim.addElement(MexicanHatKernel3D('v -> v (mh)', [sizeY, sizeX, sizeZ], sigmaExcXY, sigmaExcXY, sigmaExcZ, 0, sigmaInhZ, sigmaInhZ, sigmaInhZ, 0, false, false, true),  ...
%   'field v', [], 'field v');

sim.addElement(SumDimension('sum v (color)', [1, 2], sizeZ), 'field v');
sim.addElement(GaussKernel1D('v -> c', sizeZ, sigmaExcZ, 0, true), 'sum v (color)', [], 'field c');
sim.addElement(GaussKernel1D('c -> v', sizeZ, sigmaExcZ, 0, true), 'field c');
sim.addElement(ExpandDimension('expand c -> v', sizeZ, [sizeY, sizeX, sizeZ], 3), 'c -> v', [], 'field v');

sim.addElement(SumDimension('sum v (spatial)', 3, [sizeY, sizeX]), 'field v');
sim.addElement(GaussKernel2D('v -> s', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, false, false), ...
  'sum v (spatial)', [], 'field s');
sim.addElement(GaussKernel2D('s -> v', [sizeY, sizeX], sigmaExcXY, sigmaExcXY, 0, false, false), 'field s');
sim.addElement(ExpandDimension('expand s -> v', [sizeY, sizeX], [sizeY, sizeX, sizeZ], [1, 2]), ...
  's -> v', [], 'field v');


% create GUI object
gui = StandardGUI(sim, [100, 100, 1250, 600], 0.01, [0.0, 0.0, 0.65, 1.0], [3, 4], [0.015, 0.04], ...
  [0.65, 0.0, 0.35, 1.0], [29, 2]);

gui.addVisualization(TilePlot('field v', 'activation', [sizeY, sizeX, sizeZ], [5, 5], [-10, 10], {}, {}, ...
  'visual field (space-color)'), [1, 2], [3, 3]);
gui.addVisualization(MultiPlot({'field c', 'field c', 'stim c'}, {'activation', 'output', 'output'}, [1, 10, 1], ...
  'horizontal', {'XLim', [0, sizeZ], 'YLim', [-10, 10]}, { {'b'}, {'r'}, {'g'} }, 'color field'), [1.5, 1], [0.5, 1]);
gui.addVisualization(ScaledImage('field s', 'activation', [-10, 10], {}, {}, 'spatial field'), [2.5, 1]);


% add sliders
gui.addVisualization(StaticText('visual field (space-color, 3D)'), [1, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field v', 'h', [-10, 0], '%0.1f'), [2, 1]);
gui.addControl(ParameterSlider('c_gl', 'v -> v', 'amplitudeGlobal', [0, 0.1], '%0.3f', -1), [2, 2]);
gui.addControl(ParameterSlider('c_exc', 'v -> v', 'amplitudeExc', [0, 50], '%0.1f'), [3, 1]);
gui.addControl(ParameterSlider('c_inh', 'v -> v', 'amplitudeInh', [0, 50], '%0.1f'), [3, 2]);

gui.addControl(ParameterSlider('a_s1', 'stim v1', 'amplitude', [0, 20], '%0.1f'), [4, 1]);
gui.addControl(ParameterSlider('p_sc1', 'stim v1', 'positionZ', [0, sizeZ], '%0.1f'), [4, 2]);
gui.addControl(ParameterSlider('p_sx1', 'stim v1', 'positionX', [0, sizeX], '%0.1f'), [5, 1]);
gui.addControl(ParameterSlider('p_sy1', 'stim v1', 'positionY', [0, sizeY], '%0.1f'), [5, 2]);

gui.addControl(ParameterSlider('a_s2', 'stim v2', 'amplitude', [0, 20], '%0.1f'), [6, 1]);
gui.addControl(ParameterSlider('p_sc2', 'stim v2', 'positionZ', [0, sizeZ], '%0.1f'), [6, 2]);
gui.addControl(ParameterSlider('p_sx2', 'stim v2', 'positionX', [0, sizeX], '%0.1f'), [7, 1]);
gui.addControl(ParameterSlider('p_sy2', 'stim v2', 'positionY', [0, sizeY], '%0.1f'), [7, 2]);

gui.addControl(ParameterSwitchButton('width', 'v -> v', 'sigmaInh', {[3; 3; 3]}, {[8; 8; 8]}), [8, 1]);
% gui.addControl(ParameterSlider('c_exc', 'v -> v (alt)', 'amplitudeExc', [0, 50], '%0.1f'), [8, 1]);
% gui.addControl(ParameterSlider('c_inh', 'v -> v (alt)', 'amplitudeInh', [0, 50], '%0.1f'), [8, 2]);
% gui.addControl(ParameterSlider('c_gl', 'v -> v (alt)', 'amplitudeGlobal', [0, 0.1], '%0.3f', -1), [8, 2]);

gui.addVisualization(StaticText('spatial field (2D)'), [9, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field s', 'h', [-10, 0], '%0.1f'), [10, 1]);
gui.addControl(ParameterSlider('c_gl', 's -> s', 'amplitudeGlobal', [0, 0.5], '%0.2f', -1), [10, 2]);
gui.addControl(ParameterSlider('c_exc', 's -> s', 'amplitudeExc', [0, 50], '%0.1f'), [11, 1]);
gui.addControl(ParameterSlider('c_inh', 's -> s', 'amplitudeInh', [0, 50], '%0.1f'), [11, 2]);

gui.addControl(ParameterSlider('a_s', 'stim s', 'amplitude', [0, 20], '%0.1f'), [12, 1]);
gui.addControl(ParameterSlider('p_sx', 'stim s', 'positionX', [0, 20], '%0.1f'), [13, 1]);
gui.addControl(ParameterSlider('p_sy', 'stim s', 'positionY', [0, 20], '%0.1f'), [13, 2]);

gui.addVisualization(StaticText('color field (1D)'), [15, 1], [1, 2], 'control');

gui.addControl(ParameterSlider('h', 'field c', 'h', [-10, 0], '%0.1f'), [16, 1]);
gui.addControl(ParameterSlider('c_gl', 'c -> c', 'amplitudeGlobal', [0, 5], '%0.2f', -1), [16, 2]);
gui.addControl(ParameterSlider('c_exc', 'c -> c', 'amplitudeExc', [0, 50], '%0.1f'), [17, 1]);
gui.addControl(ParameterSlider('c_inh', 'c -> c', 'amplitudeInh', [0, 50], '%0.1f'), [17, 2]);

gui.addControl(ParameterSlider('a_s', 'stim c', 'amplitude', [0, 20], '%0.1f'), [18, 1]);
gui.addControl(ParameterSlider('p_s', 'stim c', 'position', [0, 20], '%0.1f'), [18, 2]);

gui.addVisualization(StaticText('projections between fields'), [20, 1], [1, 2], 'control');
gui.addControl(ParameterSlider('v->c', 'v -> c', 'amplitude', [0, 2], '%0.2f'), [21, 1]);
gui.addControl(ParameterSlider('c->v', 'c -> v', 'amplitude', [0, 10], '%0.1f'), [21, 2]);
gui.addControl(ParameterSlider('v->s', 'v -> s', 'amplitude', [0, 10], '%0.1f'), [22, 1]);
gui.addControl(ParameterSlider('s->v', 's -> v', 'amplitude', [0, 20], '%0.1f'), [22, 2]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [24, 2]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [25, 2]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [26, 2]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [27, 2]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [28, 2]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [29, 2]);


%% run the simulator in the GUI

gui.run(inf);


