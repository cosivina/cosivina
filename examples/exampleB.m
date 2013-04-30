% Example B: Building an Architecture with Two-Dimensional Fields
% (see the documentation for detailed explanation of the script)

sim = Simulator();

% add elements
% two-dimensional field u
sim.addElement(NeuralField('field u', [100, 150], 10, -5, 4));

% Gaussian stimuli for 2D field
sim.addElement(GaussStimulus2D('stim u1', [100, 150], 5, 5, 8, 30, 50), ...
  [], [], 'field u');
sim.addElement(GaussStimulus2D('stim u2', [100, 150], 5, 5, 8, 70, 100), ...
  [], [], 'field u');

% local lateral interactions in 2D field u
sim.addElement(GaussKernel2D('u -> u (exc)', [100, 150], 5, 5, 20), ...
  'field u', 'output', 'field u', 'output');
sim.addElement(GaussKernel2D('u -> u (inh)', [100, 150], 10, 10, -20), ...
  'field u', 'output', 'field u', 'output');

% output sum for global interactions and projections to 1D field
sim.addElement(SumDimension('sum u (vert)', 1, [1, 150], 1.0), ...
  'field u', 'output');
sim.addElement(SumDimension('u -> u (global)', 2, [1, 1], -0.05), ...
  'sum u (vert)', 'output', 'field u', 'output');

% one-dimensional field w
sim.addElement(NeuralField('field w', [1, 150], 10, -5, 4));

% lateral interactions for one-dimensional field
sim.addElement(LateralInteractions1D('w -> w', [1, 150], 5, 15, 12.5, 15, 0, true), ...
  'field w', 'output', 'field w', 'output');

% Gaussian stimulus for field w
sim.addElement(GaussStimulus1D('stim w1', [1, 150], 5, 3, 50, true), ...
  [], [], 'field w', 'output');

% projection from u to w, using element 'sum u (vert)'
sim.addElement(GaussKernel1D('u -> w', [1, 150], 5, 0.5), ...
  'sum u (vert)', 'output', 'field w', 'output');

% projection from w to u (first convolution, then expansion)
sim.addElement(GaussKernel1D('w -> u', [1, 150], 5, 5), ...
  'field w', 'output');
sim.addElement(ExpandDimension2D('expand w -> u', 1, [100, 150]), ...
  'w -> u', 'output', 'field u', 'output');


sim.run(50);

figure('Name', 'After 50 steps')
axes('Position', [0.1, 0.4, 0.8, 0.5]);
imagesc(sim.getComponent('field u', 'activation'), [-7.5, 7.5])
axes('Position', [0.1, 0.1, 0.8, 0.2], 'YGrid', 'on', 'XLim', [0, 150], 'YLim', [-10, 10], 'nextPlot', 'add');
plot(sim.getComponent('field w', 'activation'));


sim.run(100);

figure('Name', 'After 100 steps')
axes('Position', [0.1, 0.4, 0.8, 0.5]);
imagesc(sim.getComponent('field u', 'activation'), [-7.5, 7.5])
axes('Position', [0.1, 0.1, 0.8, 0.2], 'YGrid', 'on', 'XLim', [0, 150], 'YLim', [-10, 10], 'nextPlot', 'add');
plot(sim.getComponent('field w', 'activation'));




