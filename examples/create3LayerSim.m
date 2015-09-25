%% setting up the simulator

% shared parameters
fieldSize = 397;
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
sim.addElement(NeuralField('field u', fieldSize, 20, -5, 5), 'stimulus sum');
sim.addElement(NeuralField('field v', fieldSize, 5, -5, 5));
sim.addElement(NeuralField('field w', fieldSize, 20, -5, 5), 'stimulus scale w');

% shifted input sum (for plot)
sim.addElement(SumInputs('shifted stimulus sum', fieldSize), {'stimulus sum', 'field u'}, {'output', 'h'});
sim.addElement(SumInputs('shifted stimulus sum w', fieldSize), {'stimulus scale w', 'field w'}, {'output', 'h'});

% create interactions
sim.addElement(GaussKernel1D('u -> u', fieldSize, sigma_exc, 0, true, false), 'field u', 'output', 'field u');
sim.addElement(GaussKernel1D('u -> v', fieldSize, sigma_exc, 0, true, false), 'field u', 'output', 'field v');
sim.addElement(GaussKernel1D('u -> w', fieldSize, sigma_exc, 0, true, false), 'field u', 'output', 'field w');

sim.addElement(GaussKernel1D('v -> u (local)', fieldSize, sigma_inh, 0, true, false), 'field v', 'output', 'field u');
sim.addElement(GaussKernel1D('v -> w (local)', fieldSize, sigma_inh, 0, true, false), 'field v', 'output', 'field w');
sim.addElement(SumDimension('sum v', 2, 1, 1), 'field v', 'output');
sim.addElement(ScaleInput('v -> u (global)', 1, 0), 'sum v', 'output', 'field u');
sim.addElement(ScaleInput('v -> w (global)', 1, 0), 'sum v', 'output', 'field w');

sim.addElement(GaussKernel1D('w -> u', fieldSize, sigma_exc, 0, true, false), 'field w', 'output', 'field u');
sim.addElement(GaussKernel1D('w -> v', fieldSize, sigma_exc, 0, true, false), 'field w', 'output', 'field v');
sim.addElement(GaussKernel1D('w -> w', fieldSize, sigma_exc, 0, true, false), 'field w', 'output', 'field w');

% create noise stimulus and noise kernel
sim.addElement(NormalNoise('noise u', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel u', fieldSize, 0, 0, true, true), 'noise u', 'output', 'field u');
sim.addElement(NormalNoise('noise v', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel v', fieldSize, 0, 0, true, true), 'noise v', 'output', 'field v');
sim.addElement(NormalNoise('noise w', fieldSize, 1));
sim.addElement(GaussKernel1D('noise kernel w', fieldSize, 0, 0, true, true), 'noise w', 'output', 'field w');
