%% constructing the simulator
sim = Simulator();

fieldSize = 181;

sigma_exc = 5;
sigma_inh = 10;

kcf = 3;
tau = 80;
tau_inhib = 10;
tau_build = 5000;
tau_decay = 50000;

trialduration = 2000;

% color fields
sim.addElement(NeuralField('field_u', fieldSize, tau));
sim.addElement(NeuralField('field_v', fieldSize, tau_inhib));
sim.addElement(NeuralField('field_w', fieldSize, tau));
sim.addElement(MemoryTrace('mem_u', fieldSize, tau_build, tau_decay, 0), 'field_u', 'output');
sim.addElement(MemoryTrace('mem_w', fieldSize, tau_build, tau_decay, 0), 'field_w', 'output');

% node systems with dynamic resting levels
sim.addElement(NeuralField('rest_L', 1, tau));
sim.addElement(NeuralField('rest_C', 1, tau));
sim.addElement(NeuralField('rest_R', 1, tau));
sim.addElement(NeuralField('rest_A', 1, tau));
sim.addElement(NeuralField('node_L', 1, tau), 'rest_L', 'activation');
sim.addElement(NeuralField('node_C', 1, tau), 'rest_C', 'activation');
sim.addElement(NeuralField('node_R', 1, tau), 'rest_R', 'activation');
sim.addElement(NeuralField('node_A', 1, tau), 'rest_A', 'activation');
sim.addElement(ScaleInput('node_L -> rest_L', 1, 0), 'node_L', [], 'rest_L');
sim.addElement(ScaleInput('node_C -> rest_C', 1, 0), 'node_C', [], 'rest_C');
sim.addElement(ScaleInput('node_R -> rest_R', 1, 0), 'node_R', [], 'rest_R');
sim.addElement(ScaleInput('node_A -> rest_A', 1, 0), 'node_A', [], 'rest_A');

sim.addElement(BoostStimulus('boost node_L', 0), [], [], 'node_L');
sim.addElement(BoostStimulus('boost node_C', 0), [], [], 'node_C');
sim.addElement(BoostStimulus('boost node_R', 0), [], [], 'node_R');
sim.addElement(BoostStimulus('boost node_A', 0), [], [], 'node_A');

% lateral connections
sim.addElement(ScaleInput('rest_L -> rest_L', 1, 0), 'rest_L', [], 'rest_L');
sim.addElement(ScaleInput('rest_C -> rest_C', 1, 0), 'rest_C', [], 'rest_C');
sim.addElement(ScaleInput('rest_R -> rest_R', 1, 0), 'rest_R', [], 'rest_R');
sim.addElement(ScaleInput('rest_A -> rest_A', 1, 0), 'rest_A', [], 'rest_A');
sim.addElement(ScaleInput('node_L -> node_L', 1, 0), 'node_L', [], 'node_L');
sim.addElement(ScaleInput('node_C -> node_C', 1, 0), 'node_C', [], 'node_C');
sim.addElement(ScaleInput('node_R -> node_R', 1, 0), 'node_R', [], 'node_R');
sim.addElement(ScaleInput('node_A -> node_A', 1, 0), 'node_A', [], 'node_A');

sim.addElement(LateralInteractions1D('u -> u', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_u', [], 'field_u');
sim.addElement(LateralInteractions1D('v -> v', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_v', [], 'field_v');
sim.addElement(LateralInteractions1D('w -> w', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_w', [], 'field_w');

% connections between fields
sim.addElement(LateralInteractions1D('v -> u', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_v', [], 'field_u');
sim.addElement(LateralInteractions1D('w -> u', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_w', [], 'field_u');
sim.addElement(LateralInteractions1D('mem_u -> u', fieldSize, sigma_exc, ... 
    0, sigma_inh, 0, 0, true, true, kcf), 'mem_u', [], 'field_u');
sim.addElement(LateralInteractions1D('u -> v', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_u', [], 'field_v');
sim.addElement(LateralInteractions1D('w -> v', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_w', [], 'field_v');
sim.addElement(LateralInteractions1D('u -> w', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_u', [], 'field_w');
sim.addElement(LateralInteractions1D('v -> w', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'field_v', [], 'field_w');
sim.addElement(LateralInteractions1D('mem_w -> w', fieldSize, sigma_exc, ...
    0, sigma_inh, 0, 0, true, true, kcf), 'mem_w', [], 'field_w');

sim.addElement(ScaleInput('node mutual inhibition', 1, 0), ... 
    {'node_L', 'node_C', 'node_R', 'node_A'}, [], ...
    {'node_L', 'node_C', 'node_R', 'node_A'});

% connections between nodes and fields
sim.addElement(SumDimension('field_u -> nodes_LR', 2, [1, 1], 1), 'field_u');
sim.addElement(PointwiseProduct('gated field_u -> node_R', 1), ...
    {'field_u -> nodes_LR', 'node_R'}, [], 'node_R');
sim.addElement(PointwiseProduct('gated field_u -> node_L', 1), ...
    {'field_u -> nodes_LR', 'node_L'}, [], 'node_L');
sim.addElement(ScaleInput('nodes_LR -> field_u', 1, 0), {'node_L', 'node_R'}, [], 'field_u');
sim.addElement(NeuralField('stimOn', 1)); %to serve as boolean for node boost
sim.addElement(ScaleInput('stim boost node_L', 1, 0), 'stimOn', [], 'node_L');
sim.addElement(ScaleInput('stim boost node_R', 1, 0), 'stimOn', [], 'node_R');
sim.addElement(BoostStimulus('constant input node_A', 0), [], [], 'node_A');


% stimulus patterns
sim.addElement(GaussStimulus1D('stim_L', fieldSize, sigma_exc, 0, 50, true));
sim.addElement(GaussStimulus1D('stim_R', fieldSize, sigma_exc, 0, 50, true));

% gating inputs by node activation
sim.addElement(NeuralField('expand node_L', fieldSize, tau), 'node_L', 'output');
sim.addElement(PointwiseProduct('gated stim_L -> u', fieldSize), ...
    {'expand node_L', 'stim_L'}, {'activation', 'output'}, {'field_u'});
sim.addElement(ScaleInput('gated stim_L -> w', fieldSize, 0), ...
    'gated stim_L -> u', [], 'field_w');

sim.addElement(NeuralField('expand node_R', fieldSize, tau), 'node_R');
sim.addElement(PointwiseProduct('gated stim_R -> u', fieldSize), ...
    {'expand node_R', 'stim_R'}, {'activation', 'output'}, {'field_u'});
sim.addElement(ScaleInput('gated stim_R -> w', fieldSize, 0), ...
    'gated stim_R -> u', [], 'field_w');

% various noise
sim.addElement(NormalNoise('activation noise field_u', fieldSize, 1));
sim.addElement(GaussKernel1D('activation noise kernel field_u', fieldSize, ...
    0, 0, true, true, kcf), 'activation noise field_u', [], 'field_u');
sim.addElement(NormalNoise('activation noise field_v', fieldSize, 1));
sim.addElement(GaussKernel1D('activation noise kernel field_v', fieldSize, ...
    0, 0, true, true, kcf), 'activation noise field_v', [], 'field_v');
sim.addElement(NormalNoise('activation noise field_w', fieldSize, 1));
sim.addElement(GaussKernel1D('activation noise kernel field_w', fieldSize, ...
    0, 0, true, true, kcf), 'activation noise field_w', [], 'field_w');

sim.addElement(NormalNoise('resting noise field_u', 1, 1), [], [], 'field_u');
sim.addElement(NormalNoise('resting noise field_v', 1, 1), [], [], 'field_v');
sim.addElement(NormalNoise('resting noise field_w', 1, 1), [], [], 'field_w');

sim.addElement(NormalNoise('activation noise mem_u', fieldSize, 1));
sim.addElement(GaussKernel1D('activation noise kernel mem_u', fieldSize, ...
    0, 0, true, true, kcf), 'activation noise mem_u', [], 'mem_u');
sim.addElement(NormalNoise('activation noise mem_w', fieldSize, 1));
sim.addElement(GaussKernel1D('activation noise kernel mem_w', fieldSize, ...
    0, 0, true, true, kcf), 'activation noise mem_w', [], 'mem_w');

sim.addElement(NormalNoise('noise node_A', 1, 1), [], [], 'node_A');
sim.addElement(NormalNoise('noise node_L', 1, 1));
sim.addElement(PointwiseProduct('gated noise node_L', 1), ...
    {'noise node_L', 'stimOn'}, [], 'node_L'); % noise only in node L/R when boosted
sim.addElement(NormalNoise('noise node_R', 1, 1));
sim.addElement(PointwiseProduct('gated noise node_R', 1), ...
    {'noise node_R', 'stimOn'}, [], 'node_R');

% elements from running tally of looking behavior
sim.addElement(SumInputs('cumulative sum node_L', 1), 'node_L');
sim.addElement(SumInputs('cumulative sum node_R', 1), 'node_R');
sim.addElement(SumInputs('cumulative sum node_A', 1), 'node_A');
sim.addElement(ScaleInput('repeater sum node_L', 1, 1.0), 'cumulative sum node_L', [], 'cumulative sum node_L');
sim.addElement(ScaleInput('repeater sum node_R', 1, 1.0), 'cumulative sum node_R', [], 'cumulative sum node_R');
sim.addElement(ScaleInput('repeater sum node_A', 1, 1.0), 'cumulative sum node_A', [], 'cumulative sum node_A');


%% GUI
gui = StandardGUI(sim, [50, 50, 1000, 720], 0.03, [0.0, 0.25, 1.0, 0.75], [3, 3], ...
    [0.03, 0.05], [0.0, 0.0, 1.0, 0.225], [6, 4]);

gui.addVisualization(MultiPlot({'field_u', 'field_u'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XLim', [1,fieldSize], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'CON', 'activation / output', 'feature space'), [1, 2]);
gui.addVisualization(MultiPlot({'field_v', 'field_v'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XLim', [1,fieldSize], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}}, ...
  'Inhib', 'activation / output', 'feature space'), [2, 2]);
gui.addVisualization(MultiPlot({'field_w', 'field_w'}, {'activation', 'output'}, ...
  [1, 10], 'horizontal', {'YLim', [-15, 15], 'XLim', [1,fieldSize], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2},}, ...
  'WM', 'activation / output', 'feature space'), [3, 2]);
gui.addVisualization(MultiPlot('mem_u', 'output', ...
  1, 'horizontal', {'YLim', [0, 1], 'XLim', [1,fieldSize], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}}, ...
  'memory trace CON', 'activation', 'feature space'), [1, 1]);
gui.addVisualization(MultiPlot('mem_w', 'output', ...
  1, 'horizontal', {'YLim', [0, 1], 'XLim', [1,fieldSize], 'XGrid', 'on', 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 3}}, ...
  'memory trace WM', 'activation', 'feature space'), [3, 1]);

gui.addVisualization(MultiPlot({'node_L', 'node_L', 'rest_L', ...
  'node_R', 'node_R', 'rest_R', 'node_A', 'node_A', 'rest_A'}, ...
  {'activation', 'output', 'activation', 'activation', 'output', 'activation', ...
  'activation', 'output', 'activation'}, ...
  [1, 10, 1, 1, 10, 1, 1, 10, 1], 'horizontal', ...
  {'XLim', [0.5, 3.5], 'YLim', [-15, 15], 'Box', 'on', 'XTick', 1:3, 'XTickLabel', {'L', 'R', 'A'}}, ...
  {{'bo', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 1}, ...
  {'ro', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 1}, ...
  {'ks', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 1}, ...
  {'bo', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 2}, ...
  {'ro', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 2}, ...
  {'ks', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 2}, ...
  {'bo', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 3}, ...
  {'ro', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 3}, ...
  {'ks', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 3}}, ...
  'Nodes LRA', '', 'resting level / activation / output'), [1, 3], [1.5, 1]);

gui.addVisualization(MultiPlot({'cumulative sum node_L', ...
    'cumulative sum node_R', 'cumulative sum node_A'}, ...
  {'output', 'output', 'output'}, [1, 1, 1], 'horizontal', ...
  {'XLim', [0.5, 3.5], 'YLim', [0, .75*trialduration], 'Box', 'on', 'XTick', 1:3, 'XTickLabel', {'L', 'R', 'A'}}, ...
  {{'bs', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 1}, ...
  {'bs', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 2}, ...
  {'bs', 'MarkerSize', 5, 'XDataMode', 'manual', 'XData', 3}}, ...
  'Activation Totals Nodes LRA', '', ''), [2.5, 3], [1.5, 1]);

gui.addVisualization(TimeDisplay(), [1, 1], [1, 1], 'control');

gui.addControl(ParameterSlider('c_uu', 'u -> u', 'amplitudeExc', [0, 5], '%0.1f', 1, 'self excitation in field u'), [2, 1]);
gui.addControl(ParameterSlider('c_ww', 'w -> w', 'amplitudeExc', [0, 5], '%0.1f', 1, 'self excitation in field u'), [3, 1]);

gui.addControl(ParameterSlider('c_uv', 'v -> u', 'amplitudeInh', [0, 5], '%0.1f', 1, 'inhibition to field u'), [4, 1]);
gui.addControl(ParameterSlider('c_wv', 'v -> w', 'amplitudeInh', [0, 5], '%0.1f', 1, 'inhibition to field w'), [5, 1]);

gui.addControl(ParameterSlider('c_ii_exc', {'node_L -> node_L', ...
    'node_C -> node_C', 'node_R -> node_R', 'node_A -> node_A'}, ...
    {'amplitude', 'amplitude', 'amplitude', 'amplitude'}, [0, 10], '%0.1f', 1, 'node self-excitation'), [2, 2]);
gui.addControl(ParameterSlider('c_ii_inh', 'node mutual inhibition', 'amplitude', [-20, 0], '%0.1f', 1, 'node mutual inhibition'), [3, 2]);
gui.addControl(ParameterSlider('c_ri', {'node_L -> rest_L', ...
    'node_C -> rest_C', 'node_R -> rest_R', 'node_A -> rest_A'}, ...
    {'amplitude', 'amplitude', 'amplitude', 'amplitude'}, [-10, 0], '%0.1f', 1, 'strength of resing level suppression effect'), [4, 2]);


%gui.addControl(ParameterSwitchButton('Stimulus Present', {'stimOn'}, {'h'}, -5, 5, [], false), [3,3]);
gui.addControl(ParameterSlider('p_sL', 'stim_L', 'position', [1, fieldSize], '%0.1f', 1), [2, 3]);
gui.addControl(ParameterSlider('p_sR', 'stim_R', 'position', [1, fieldSize], '%0.1f', 1), [3, 3]);

gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);

gui.run(inf);

