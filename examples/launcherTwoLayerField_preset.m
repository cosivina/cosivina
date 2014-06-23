% Launcher for a two-layer neural field simulator.
% The scripts sets up an architecture with two one-dimensional neural
% fields: an excitatory field, u, and an inhibitory field, v. Field u
% features local self-excitation and excites field v, which in turn
% inhibits field u. The script then creates a GUI for this architecture and
% runs that GUI.
% Hover over sliders and buttons to see a description of their function.


%% setting up the simulator

% shared parameters
fieldSize = 100;
sigma_exc = 5;
sigma_inh = 10;

% create simulator object
sim = Simulator();

% create inputs (and sum for visualization)
sim.addElement(GaussStimulus1D('stimulus 1', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
sim.addElement(GaussStimulus1D('stimulus 2', fieldSize, sigma_exc, 0, round(1/2*fieldSize), true, false));
sim.addElement(GaussStimulus1D('stimulus 3', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));
sim.addElement(SumInputs('stimulus sum', fieldSize), {'stimulus 1', 'stimulus 2', 'stimulus 3'});

% create neural field
sim.addElement(NeuralField('field u', fieldSize, 20, -5, 4), 'stimulus sum');
sim.addElement(NeuralField('field v', fieldSize, 5, -5, 4));

% shifted input sum (for plot)
sim.addElement(SumInputs('shifted stimulus sum', fieldSize), {'stimulus sum', 'field u'}, {'output', 'h'});

% create interactions
sim.addElement(GaussKernel1D('u -> u', fieldSize, sigma_exc, 0, true, true), 'field u', 'output', 'field u');
sim.addElement(GaussKernel1D('u -> v', fieldSize, sigma_exc, 0, true, true), 'field u', 'output', 'field v');
sim.addElement(GaussKernel1D('v -> u (local)', fieldSize, sigma_inh, 0, true, true), 'field v', 'output', 'field u');
sim.addElement(SumDimension('v -> u (global)', 2, 1, 0), 'field v', 'output', 'field u');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise u', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel u', fieldSize, 0, 1.0, true, true), 'noise u', 'output', 'field u');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel v', fieldSize, 0, 1.0, true, true), 'noise v', 'output', 'field v');


%% setting up the GUI

elementGroupLabels = {'field u', 'field v', 'kernel u -> u', 'kernel u -> v', 'kernel v -> u (local)', ...
  'projection v -> u (global)', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'noise kernel u', 'noise kernel v'};
elementGroups = {'field u', 'field v', 'u -> u', 'u -> v', 'v -> u (local)', ...
  'v -> u (global)', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'noise kernel u', 'noise kernel v'};

gui = StandardGUI(sim, [50, 50, 1000, 720], 0.01, [0.0, 1/4, 1.0, 3/4], [2, 1], 0.06, [0.0, 0.0, 1.0, 1/4], [7, 4], ...
  elementGroupLabels, elementGroups);

gui.addVisualization(MultiPlot({'field u', 'field u', 'shifted stimulus sum'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}, {'Color', [0, 0.75, 0], 'LineWidth', 2}}, ...
  'field u', 'feature space', 'activation / input / output'), [1, 1]);
gui.addVisualization(MultiPlot({'field v', 'field v'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'field v', 'feature space', 'activation / output'), [2, 1]);

% add sliders
% resting level and noise
gui.addControl(ParameterSlider('h_u', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
gui.addControl(ParameterSlider('h_v', 'field v', 'h', [-10, 0], '%0.1f', 1, 'resting level of field v'), [1, 2]);
gui.addControl(ParameterSlider('q_u', 'noise kernel u', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field u'), [2, 1]);
gui.addControl(ParameterSlider('q_v', 'noise kernel v', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field v'), [2, 2]);
% lateral interactions
gui.addControl(ParameterSlider('c_uu', 'u -> u', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field u'), [3, 1]);
gui.addControl(ParameterSlider('c_vu', 'u -> v', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of excitation from field u to field v'), [3, 2]);
gui.addControl(ParameterSlider('c_uv_loc', 'v -> u (local)', 'amplitude', [0, 50], '%0.1f', -1, ...
  'strength of local inhibition from field v to field u'), [3, 3]);
gui.addControl(ParameterSlider('c_uv_glob', 'v -> u (global)', 'amplitude', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition from field v to field u'), [4, 3]);
% stimuli
gui.addControl(ParameterSlider('w_s1', 'stimulus 1', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 1'), [5, 1]);
gui.addControl(ParameterSlider('p_s1', 'stimulus 1', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 1'), [5, 2]);
gui.addControl(ParameterSlider('a_s1', 'stimulus 1', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 1'), [5, 3]);
gui.addControl(ParameterSlider('w_s2', 'stimulus 2', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 2'), [6, 1]);
gui.addControl(ParameterSlider('p_s2', 'stimulus 2', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 2'), [6, 2]);
gui.addControl(ParameterSlider('a_s2', 'stimulus 2', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 2'), [6, 3]);
gui.addControl(ParameterSlider('w_s3', 'stimulus 3', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 3'), [7, 1]);
gui.addControl(ParameterSlider('p_s3', 'stimulus 3', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 3'), [7, 2]);
gui.addControl(ParameterSlider('a_s3', 'stimulus 3', 'amplitude', [0, 20], '%0.1f', 1, ...
  'amplitude of stimulus 3'), [7, 3]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
% gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
% gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(PresetSelector('Select', gui, '', ...
  {'presetTwoLayerField_noInteractions.json', 'presetTwoLayerField_stabilized.json', ...
  'presetTwoLayerField_selection.json', 'presetTwoLayerField_memory.json'}, ...
  {'no interactions', 'stabilized', 'selection', 'memory'}, ...
  'Load pre-defined parameter settings'), [4, 4], [2, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);


%% run the simulator in the GUI

gui.run(inf);


