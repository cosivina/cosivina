% Launcher for a simulation of two coupled dynamic node. The rates of
% change in dependence of the node activation are plotted, with attractor
% and repellor states marked.
% Hover over sliders and buttons to see a description of their function.


%% setting up the simulator

historyDuration = 100;
samplingRange = [-10, 10];
samplingResolution = 0.05;

sim = Simulator();

sim.addElement(BoostStimulus('stimulus u', 0));
sim.addElement(BoostStimulus('stimulus v', 0));

sim.addElement(SingleNodeDynamics('node u', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulus u');
sim.addElement(SingleNodeDynamics('node v', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulus v');

sim.addElement(ScaleInput('u -> v', [1, 1]), 'node u', 'output', 'node v');
sim.addElement(ScaleInput('v -> u', [1, 1]), 'node v', 'output', 'node u');

sim.addElement(RunningHistory('history u', [1, 1], historyDuration, 1), 'node u', 'activation');
sim.addElement(RunningHistory('history v', [1, 1], historyDuration, 1), 'node v', 'activation');

sim.addElement(SumInputs('shifted stimulus u', [1, 1]), {'stimulus u', 'node u'}, {'output', 'h'});
sim.addElement(SumInputs('shifted stimulus v', [1, 1]), {'stimulus v', 'node v'}, {'output', 'h'});

sim.addElement(RunningHistory('stimulus history u', [1, 1], historyDuration, 1), 'shifted stimulus u');
sim.addElement(RunningHistory('stimulus history v', [1, 1], historyDuration, 1), 'shifted stimulus v');


%% setting up the GUI

gui = StandardGUI(sim, [50, 50, 1000, 500], 0.01, [0.0, 0.0, 0.75, 1.0], [2, 3], [0.045, 0.08], [0.75, 0.0, 0.25, 1.0], [20, 1]);

gui.addVisualization(XYPlot({'node u', 'history u'}, {'activation', 'output'}, ...
  {'node v', 'history v'}, {'activation', 'output'}, ...
  {'XLim', [-10, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
  { {'bo', 'MarkerFaceColor', 'b'}, {'b-', 'LineWidth', 2} }, '', 'activation u', 'activation v'), [1.5, 1]);
gui.addVisualization(MultiPlot({'node u', 'stimulus history u', 'history u'}, {'activation', 'output', 'output'}, ...
  [1, 1, 1], 'horizontal', ...
  {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
  { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
  {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1} }, ...
  'node u', 'relative time', 'activation'), [1, 2]);
gui.addVisualization(MultiPlot({'node v', 'stimulus history v', 'history v'}, {'activation', 'output', 'output'}, ...
  [1, 1, 1], 'horizontal', ...
  {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
  { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
  {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1} }, ...
  'node v', 'relative time', 'activation'), [2, 2]);

gui.addVisualization(XYPlot({[], 'node u', 'node u', 'node u'}, ...
  {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
  {'node u', 'node u', 'node u', 'node u'}, ...
  {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
  {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
  { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
  'activation dynamics u', 'activation', 'rate of change'), [1, 3]);
gui.addVisualization(XYPlot({[], 'node v', 'node v', 'node v'}, ...
  {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
  {'node v', 'node v', 'node v', 'node v'}, ...
  {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
  {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
  { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
  'activation dynamics v', 'activation', 'rate of change'), [2, 3]);


% add parameter sliders
gui.addControl(ParameterSlider('h_u', 'node u', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u'), [1, 1]);
gui.addControl(ParameterSlider('q_u', 'node u', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u'), [2, 1]);
gui.addControl(ParameterSlider('u->u', 'node u', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
  'connection strength from node u to itself'), [3, 1]);
gui.addControl(ParameterSlider('v->u', 'v -> u', 'amplitude', [-10, 10], '%0.1f', 1, ...
  'connection strength from node v to node u'), [4, 1]);
gui.addControl(ParameterSlider('s_u', 'stimulus u', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stimulus strength for node u'), [5, 1]);

gui.addControl(ParameterSlider('h_v', 'node v', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u'), [8, 1]);
gui.addControl(ParameterSlider('q_v', 'node v', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u'), [9, 1]);
gui.addControl(ParameterSlider('v->v', 'node v', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
  'connection strength from node v to itself'), [10, 1]);
gui.addControl(ParameterSlider('u->v', 'u -> v', 'amplitude', [-10, 10], '%0.1f', 1, ...
  'connection strength from node u to node v'), [11, 1]);
gui.addControl(ParameterSlider('s_v', 'stimulus v', 'amplitude', [0, 20], '%0.1f', 1, ...
  'stimulus strength for node v'), [12, 1]);

% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [15, 1]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [16, 1]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [17, 1]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [18, 1]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [19, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [20, 1]);

gui.run(inf);





