% Launcher for a three-layer neural field simulator.
% The scripts sets up an architecture with three one-dimensional neural
% fields: two excitatory fields, u and w, and a shared inhibitory field, v.
% Fields u and w feature local self-excitation and project to each other
% and to field v in a local excitatory fashion. Field v inhibits both
% excitatory fields, either locally or globally. 
% The script then creates a GUI for this architecture and
% runs that GUI. Hover over sliders and buttons to see a descrition of
% their function.


%% setting up the simulator

% shared parameters
fieldSize = 180;
sigma_exc = 5;
sigma_inh = 10;

% create simulator object
sim = Simulator();

% create inputs (and sum for visualization)
sim.addElement(GaussStimulus1D('stimulus 1', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
sim.addElement(GaussStimulus1D('stimulus 2', fieldSize, sigma_exc, 0, round(1/2*fieldSize), true, false));
sim.addElement(GaussStimulus1D('stimulus 3', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));
sim.addElement(SumInputs('stimulus sum', fieldSize), {'stimulus 1', 'stimulus 2', 'stimulus 3'});
sim.addElement(ScaleInput('stimulus scale w', fieldSize, 0), 'stimulus sum');

% create neural field
sim.addElement(NeuralField('field u', fieldSize, 20, -5, 4), 'stimulus sum');
sim.addElement(NeuralField('field v', fieldSize, 5, -5, 4));
sim.addElement(NeuralField('field w', fieldSize, 20, -5, 4), 'stimulus scale w');

% shifted input sum (for plot)
sim.addElement(SumInputs('shifted stimulus sum', fieldSize), {'stimulus sum', 'field u'}, {'output', 'h'});
sim.addElement(SumInputs('shifted stimulus sum w', fieldSize), {'stimulus scale w', 'field w'}, {'output', 'h'});

% create interactions
sim.addElement(GaussKernel1D('u -> u', fieldSize, sigma_exc, 0, true, true), 'field u', 'output', 'field u');
sim.addElement(GaussKernel1D('u -> v', fieldSize, sigma_exc, 0, true, true), 'field u', 'output', 'field v');
sim.addElement(GaussKernel1D('u -> w', fieldSize, sigma_exc, 0, true, true), 'field u', 'output', 'field w');

sim.addElement(GaussKernel1D('v -> u (local)', fieldSize, sigma_inh, 0, true, true), 'field v', 'output', 'field u');
sim.addElement(GaussKernel1D('v -> w (local)', fieldSize, sigma_inh, 0, true, true), 'field v', 'output', 'field w');
sim.addElement(SumDimension('sum v', 2, 1, 1), 'field v', 'output');
sim.addElement(ScaleInput('v -> u (global)', fieldSize, 0), 'sum v', 'output', 'field u');
sim.addElement(ScaleInput('v -> w (global)', fieldSize, 0), 'sum v', 'output', 'field w');

sim.addElement(GaussKernel1D('w -> u', fieldSize, sigma_exc, 0, true, true), 'field w', 'output', 'field u');
sim.addElement(GaussKernel1D('w -> v', fieldSize, sigma_exc, 0, true, true), 'field w', 'output', 'field v');
sim.addElement(GaussKernel1D('w -> w', fieldSize, sigma_exc, 0, true, true), 'field w', 'output', 'field w');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise u', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel u', fieldSize, 0, 2, true, true), 'noise u', 'output', 'field u');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel v', fieldSize, 0, 1, true, true), 'noise v', 'output', 'field v');
sim.addElement(NormalNoise('noise w', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel w', fieldSize, 0, 2, true, true), 'noise v', 'output', 'field w');


%% setting up the GUI

elementGroups = {'field u', 'field v', 'field w', 'u -> u', 'u -> v', 'u -> w', ...
  'v -> u (local)', 'v -> u (global)', 'v -> w (local)', 'v -> w (global)', ...
  'w -> u', 'w -> v', 'w -> w', 'stimulus scale w', ...
  'stimulus 1', 'stimulus 2', 'stimulus 3', 'noise kernel u', 'noise kernel v', 'noise kernel w'};

gui = StandardGUI(sim, [50, 50, 1000, 750], 0.0, [0.0, 1/4, 1.0, 3/4], [3, 1], 0.06, [0.0, 0.0, 1.0, 1/4], [9, 4], ...
  elementGroups, elementGroups);

gui.addVisualization(MultiPlot({'field u', 'field u', 'shifted stimulus sum'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}, {'Color', [0, 0.75, 0], 'LineWidth', 2}}, ...
  'field u', 'feature space', 'activation / input / output'), [1, 1]);
gui.addVisualization(MultiPlot({'field v', 'field v'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'field v', 'feature space', 'activation / output'), [2, 1]);
gui.addVisualization(MultiPlot({'field w', 'field w', 'shifted stimulus sum w'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}, {'Color', [0, 0.75, 0], 'LineWidth', 2}}, ...
  'field w', 'feature space', 'activation / input / output'), [3, 1]);

% add sliders
% resting level and noise
gui.addControl(ParameterSlider('h_u', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
gui.addControl(ParameterSlider('h_v', 'field v', 'h', [-10, 0], '%0.1f', 1, 'resting level of field v'), [1, 2]);
gui.addControl(ParameterSlider('h_w', 'field w', 'h', [-10, 0], '%0.1f', 1, 'resting level of field w'), [1, 3]);
gui.addControl(ParameterSlider('q_u', 'noise kernel u', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field u'), [2, 1]);
gui.addControl(ParameterSlider('q_v', 'noise kernel v', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field v'), [2, 2]);
gui.addControl(ParameterSlider('q_w', 'noise kernel w', 'amplitude', [0, 10], '%0.1f', 1, ...
  'noise level for field w'), [2, 3]);

% lateral interactions
gui.addControl(ParameterSlider('c_uu', 'u -> u', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field u'), [3, 1]);
gui.addControl(ParameterSlider('c_vu', 'u -> v', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of excitation from field u to field v'), [3, 2]);
gui.addControl(ParameterSlider('c_wu', 'u -> w', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of excitation from field u to field w'), [3, 3]);

gui.addControl(ParameterSlider('c_uv_loc', 'v -> u (local)', 'amplitude', [0, 50], '%0.1f', -1, ...
  'strength of local inhibition from field v to field u'), [4, 1]);
gui.addControl(ParameterSlider('c_uv_glob', 'v -> u (global)', 'amplitude', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition from field v to field u'), [5, 1]);
gui.addControl(ParameterSlider('c_wv_loc', 'v -> w (local)', 'amplitude', [0, 50], '%0.1f', -1, ...
  'strength of local inhibition from field v to field w'), [4, 3]);
gui.addControl(ParameterSlider('c_wv_glob', 'v -> w (global)', 'amplitude', [0, 2], '%0.2f', -1, ...
  'strength of global inhibition from field v to field w'), [5, 3]);

gui.addControl(ParameterSlider('c_uw', 'w -> u', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of excitation from field w to field u'), [6, 1]);
gui.addControl(ParameterSlider('c_vw', 'w -> v', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of excitation from field w to field v'), [6, 2]);
gui.addControl(ParameterSlider('c_ww', 'w -> w', 'amplitude', [0, 50], '%0.1f', 1, ...
  'strength of lateral excitation in field w'), [6, 3]);

% stimuli
gui.addControl(ParameterSlider('w_s1', 'stimulus 1', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 1'), [7, 1]);
gui.addControl(ParameterSlider('p_s1', 'stimulus 1', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 1'), [7, 2]);
gui.addControl(ParameterSlider('a_s1', 'stimulus 1', 'amplitude', [0, 30], '%0.1f', 1, ...
  'amplitude of stimulus 1'), [7, 3]);
gui.addControl(ParameterSlider('w_s2', 'stimulus 2', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 2'), [8, 1]);
gui.addControl(ParameterSlider('p_s2', 'stimulus 2', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 2'), [8, 2]);
gui.addControl(ParameterSlider('a_s2', 'stimulus 2', 'amplitude', [0, 30], '%0.1f', 1, ...
  'amplitude of stimulus 2'), [8, 3]);
gui.addControl(ParameterSlider('w_s3', 'stimulus 3', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 3'), [9, 1]);
gui.addControl(ParameterSlider('p_s3', 'stimulus 3', 'position', [0, fieldSize], '%0.1f', 1, ...
  'position of stimulus 3'), [9, 2]);
gui.addControl(ParameterSlider('a_s3', 'stimulus 3', 'amplitude', [0, 30], '%0.1f', 1, ...
  'amplitude of stimulus 3'), [9, 3]);


% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(PresetSelector('Select', gui, '', ...
  {'presetThreeLayerField_noInteractions.json', 'presetThreeLayerField_globalInhibition.json', ...
  'presetThreeLayerField_chDet_adult.json', 'presetThreeLayerField_chDet_child.json', ...
  'presetThreeLayerField_spRecall_adult.json', 'presetThreeLayerField_spRecall_child.json'}, ...
  {'no interactions', 'working memory with global inhibition', 'change detection (adult)', 'change detection (child)', ...
  'spatial recall (adult)', 'spatial recall (child)'}, ...
  'Load pre-defined parameter settings'), [6, 4], [2, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [8, 4]);


%% run the simulator in the GUI

gui.run(inf);


