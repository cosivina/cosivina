% Launcher for a reference frame transformation simulator. The architecture
% can be used to perform a shift of the peak pattern in the retinal field
% by the position of a single peak in the gaze direction field, by forming
% a combined representation in the 2D transformation field and then
% performing a read-out along the diagonal of that field. The architecture
% can also be used for other related tasks, such as inverse transformation
% (from body-centered position to retinal) or alignment of body-centered
% and retinal position for gaze estimation.


%% setting up the simulator

% shared parameters
fieldRange = 60;
sigma_exc = 5;
sigma_inh = 10;

fieldSize = 2 * fieldRange + 1;

% create simulator object
sim = Simulator();

% create inputs
sim.addElement(GaussStimulus1D('stimulus r1', fieldSize, sigma_exc, 0, fieldRange + 1 - fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stimulus r2', fieldSize, sigma_exc, 0, fieldRange + 1 + fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stimulus g', fieldSize, sigma_exc, 0, fieldRange + 1, 0, 0));
sim.addElement(GaussStimulus1D('stimulus b1', 2*fieldSize-1, sigma_exc, 0, fieldSize - fieldRange/2, 0, 0));
sim.addElement(GaussStimulus1D('stimulus b2', 2*fieldSize-1, sigma_exc, 0, fieldSize + fieldRange/2, 0, 0));

sim.addElement(BoostStimulus('boost r', 0));
sim.addElement(BoostStimulus('boost g', 0));
sim.addElement(BoostStimulus('boost b', 0));
sim.addElement(BoostStimulus('boost t', 0));

% create neural field
sim.addElement(NeuralField('field r', fieldSize, 20, -5, 4), {'stimulus r1', 'stimulus r2', 'boost r'});
sim.addElement(NeuralField('field g', fieldSize, 20, -5, 4), {'stimulus g', 'boost g'});
sim.addElement(NeuralField('field b', 2*fieldSize-1, 20, -5, 4), {'stimulus b1', 'stimulus b2', 'boost b'});
sim.addElement(NeuralField('field t', [fieldSize, fieldSize], 20, -5, 4), {'boost t'});

% create interactions

% lateral interactions for field t
sim.addElement(LateralInteractions2D('t -> t', [fieldSize, fieldSize], sigma_exc, sigma_exc, 0, sigma_inh, sigma_inh, 0, ...
  0, false, false, true), 'field t', 'output', 'field t');
sim.addElement(SumAllDimensions('sum t', [fieldSize, fieldSize]), 'field t', 'output');
sim.addElement(DiagonalSum('diag t', [fieldSize, fieldSize], 1), 'field t', 'output');

% lateral interactions in fields r, g, and b
sim.addElement(LateralInteractions1D('r -> r', fieldSize, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'field r', 'output', 'field r');
sim.addElement(LateralInteractions1D('g -> g', fieldSize, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'field g', 'output', 'field g');
sim.addElement(LateralInteractions1D('b -> b', 2*fieldSize-1, sigma_exc, 0, sigma_inh, 0, 0, false, true), 'field b', 'output', 'field b');

% interactions between fields
sim.addElement(GaussKernel1D('r -> t', fieldSize, sigma_exc, 0, false, true), 'field r', 'output');
sim.addElement(ExpandDimension2D('expand r -> t', 1, [fieldSize, fieldSize]), 'r -> t', 'output', 'field t');
sim.addElement(GaussKernel1D('g -> t', fieldSize, sigma_exc, 0, false, true), 'field g', 'output');
sim.addElement(ExpandDimension2D('expand g -> t', 2, [fieldSize, fieldSize]), 'g -> t', 'output', 'field t');
sim.addElement(GaussKernel1D('b -> t', 2*fieldSize-1, sigma_exc, 0, false, true), 'field b', 'output');
sim.addElement(DiagonalExpansion('expand b -> t', 2*fieldSize-1, 0), 'b -> t', 'output', 'field t');

sim.addElement(GaussKernel1D('t -> r', fieldSize, sigma_exc, 0, false, true), 'sum t', 'verticalSum', 'field r');
sim.addElement(GaussKernel1D('t -> g', fieldSize, sigma_exc, 0, false, true), 'sum t', 'horizontalSum', 'field g');
sim.addElement(GaussKernel1D('t -> b', 2*fieldSize-1, sigma_exc, 0, false, true), 'diag t', 'output', 'field b');

sim.addElement(NormalNoise('noise r', [1, fieldSize], 1.0), [], [], 'field r');
sim.addElement(NormalNoise('noise g', [1, fieldSize], 1.0), [], [], 'field g');
sim.addElement(NormalNoise('noise b', [1, 2*fieldSize-1], 1.0), [], [], 'field b');
sim.addElement(NormalNoise('noise t', [fieldSize, fieldSize], 1.0), [], [], 'field t');

%% setting up the GUI

elementGroupLabels = {'field r', 'field g', 'field b', 'field t', ...
  'lateral kernel r -> r', 'lateral kernel g -> g', 'lateral kernel b -> b', 'lateral kernel t -> t', ...
  'kernel r -> t', 'kernel g -> t', 'kernel b -> t', 'kernel t -> r', 'kernel t -> g', 'kernel t -> b', ...
  'stimulus r1', 'stimulus r2', 'stimulus g', 'stimulus b1', 'stimulus b2', 'boost r', 'boost g', 'boost b', 'boost t', ...
  'noise r', 'noise g', 'noise b', 'noise t'};
elementGroups = {'field r', 'field g', 'field b', 'field t', ...
  'r -> r', 'g -> g', 'b -> b', 't -> t', ...
  'r -> t', 'g -> t', 'b -> t', 't -> r', 't -> g', 't -> b', ...
  'stimulus r1', 'stimulus r2', 'stimulus g', 'stimulus b1', 'stimulus b2', 'boost r', 'boost g', 'boost b', 'boost t', ...
  'noise r', 'noise g', 'noise b', 'noise t'};

figureWidth = 900;
figureHeight = 3/4 * figureWidth;
S = diag([figureHeight/figureWidth, 1, figureHeight/figureWidth, 1]);

% create GUI object
gui = StandardGUI(sim, [50, 50, figureWidth, figureHeight], 0.01, [0.0, 0.0, 0.75, 1.0], [1, 1], 0.05, ...
  [0.75, 0.0, 0.25, 1.0], [28, 1], elementGroupLabels, elementGroups);

w = 0.4; h = 0.125; m = 0.05;
gui.addVisualization(ScaledImage('field t', 'activation', [-7.5, 7.5], ...
  {'YAxisLocation', 'right', 'YDir', 'normal', 'XTick', -40:20:40, 'YTick', -40:20:40}, ...
  {'XData', -fieldRange:fieldRange, 'YData', -fieldRange:fieldRange}, ...
  '', 'retinal position', 'gaze direction', [h+2*m, 1-w-h-2*m, w, w] * S));
gui.addVisualization(MultiPlot({'field r', 'field r', 'stimulus r1', 'stimulus r2'}, {'activation', 'output', 'output', 'output'}, ...
  [1, 10, 1, 1], 'horizontal', ...
  {'YLim', [-10, 10], 'XLim', [-fieldRange, fieldRange], 'Box', 'on', 'YGrid', 'on', 'XTick', -40:20:40}, ...
  {{'Color', 'b', 'LineWidth', 2, 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', 'r', 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldRange:fieldRange}}, ...
  'retinal field', '', 'activation', [h+2*m, 1-h-m, w, h] * S));
gui.addVisualization(MultiPlot({'field g', 'field g', 'stimulus g'}, {'activation', 'output', 'output'}, ...
  [1, 10, 1], 'vertical', ...
  {'XLim', [-10, 10], 'XDir', 'reverse', 'YLim', [-fieldRange, fieldRange], 'YAxisLocation', 'right', 'Box', 'on', ...
  'XGrid', 'on', 'YTick', -40:20:40}, ...
  {{'Color', 'b', 'LineWidth', 2, 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}, ...
  {'Color', 'r', 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'YData', -fieldRange:fieldRange}}, ...
  'gaze direction field', 'activation', '', [m, 1-w-h-2*m, h, w] * S));

% plot diagonal axes
ylim_b = [-10, 10];
d = h/sqrt(2) + w; % size of diagonal axes
up = [(2*fieldSize-1)/(w*sqrt(2))-2, diff(ylim_b)/h, 0]; % "up vector" for diagonal axes
up = up/norm(up, 2);
pbar = [sqrt(2)*w, h, 1]; % "plot box aspect ratio" for diagonal axes
gui.addVisualization(MultiPlot({'field b', 'field b', 'stimulus b1', 'stimulus b2'}, {'activation', 'output', 'output', 'output'}, ...
  [1, 10, 1, 1], 'horizontal', ...
  {'XLim', [-fieldSize+1, fieldSize-1], 'YLim', ylim_b, 'PlotBoxAspectRatio', pbar, 'CameraUpVector', up, 'Box', 'on', ...
  'XTick', -120:20:120, 'YGrid', 'on'}, ...
  {{'b', 'LineWidth', 2, 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'r', 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}, ...
  {'Color', [0, 0.75, 0], 'XDataMode', 'manual', 'XData', -fieldSize+1:fieldSize-1}}, ...
  '', 'body-centered position', '', [w+h+3.5*m-d/2, 1-w-h-3.5*m-d/2, d, d] * S));


% add sliders
gui.addVisualization(StaticText('stimuli for field r'), [1, 1], [1, 1], 'control');
gui.addControl(ParameterSlider('p_s1', 'stimulus r1', 'position', [1, fieldSize], '%0.1f', 1, 'position of retinal stimulus 1'), [2, 1]);
gui.addControl(ParameterSlider('a_s1', 'stimulus r1', 'amplitude', [0, 10], '%0.1f', 1, 'amplitude of retinal stimulus 1'), [3, 1]);
gui.addControl(ParameterSlider('p_s2', 'stimulus r2', 'position', [1, fieldSize], '%0.1f', 1, 'position of retinal stimulus 2'), [4, 1]);
gui.addControl(ParameterSlider('a_s2', 'stimulus r2', 'amplitude', [0, 10], '%0.1f', 1, 'amplitude of retinal stimulus 2'), [5, 1]);
gui.addControl(ParameterSlider('boost', 'boost r', 'amplitude', [0, 10], '%0.1f', 1, 'boost of retinal field'), [6, 1]);

gui.addVisualization(StaticText('stimuli for field g'), [8, 1], [1, 1], 'control');
gui.addControl(ParameterSlider('p_s1', 'stimulus g', 'position', [1, fieldSize], '%0.1f', 1, 'position of gaze field stimulus'), [9, 1]);
gui.addControl(ParameterSlider('a_s1', 'stimulus g', 'amplitude', [0, 10], '%0.1f', 1, 'strength of gaze field stimulus'), [10, 1]);
gui.addControl(ParameterSlider('boost', 'boost g', 'amplitude', [0, 10], '%0.1f', 1, 'boost of gaze field'), [11, 1]);

gui.addVisualization(StaticText('stimuli for field b'), [13, 1], [1, 1], 'control');
gui.addControl(ParameterSlider('p_s1', 'stimulus b1', 'position', [1, 2*fieldSize-1], '%0.1f', 1, 'position of body-centered stimulus 1'), [14, 1]);
gui.addControl(ParameterSlider('a_s1', 'stimulus b1', 'amplitude', [0, 10], '%0.1f', 1, 'amplitude of body-centered stimulus 1'), [15, 1]);
gui.addControl(ParameterSlider('p_s2', 'stimulus b2', 'position', [1, 2*fieldSize-1], '%0.1f', 1, 'position of body-centered stimulus 2'), [16, 1]);
gui.addControl(ParameterSlider('a_s2', 'stimulus b2', 'amplitude', [0, 10], '%0.1f', 1, 'amplitude of body-centered stimulus 2'), [17, 1]);
gui.addControl(ParameterSlider('boost', 'boost b', 'amplitude', [0, 10], '%0.1f', 1, 'boost of body-centered field'), [18, 1]);

gui.addVisualization(StaticText('stimuli for field t'), [20, 1], [1, 1], 'control');
gui.addControl(ParameterSlider('boost', 'boost t', 'amplitude', [0, 10], '%0.1f', 1, 'boost of transformation field'), [21, 1]);


% add buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [23, 1]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [24, 1]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [25, 1]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [26, 1]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [27, 1]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [28, 1]);

%% run the simulator in the GUI

gui.run(inf);


