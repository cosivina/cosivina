% Some example usages of the adaptive hebbian weight connection. See step
% implementation for detailed description. You can modify the different
% parameters, timescales, dimensionalities to your liking.


% example configurations 1: 1d->1d, 2: 2d->1d, 3: 2d->2d, 4: 1d->3d
examples = 2;

switch examples
    case 1
        sim = Simulator();
        fieldSize1 = 100;
        fieldSize2 = 100;
        
        tMax = 200;
        tStimOn = 0;
        tBoost = 20;
        tau = 10;
        tauD = 20;
        
        % add elements
        sim.addElement(NeuralField('field u1', fieldSize1, tau, -5, 4));
        sim.addElement(NeuralField('field u2', fieldSize2, tau, -5, 4));
        
        sim.addElement(NormalNoise('noise1', fieldSize1, 0.5), [], [], 'field u1');
        sim.addElement(NormalNoise('noise2', fieldSize2, 0.5), [], [], 'field u2');
        
        sim.addElement(HebbianConnection('hebbian connection', 1, [30, 75], tau, tauD, 'TRUE'), {'field u1', 'field u2'}, {'output','output'}, {'field u2', 'field u1'}, {'output', 'reverse_output'});
        %sim.addElement(GaussKernel1D('u2 -> hebb',fieldSize2, 1, 0.5), ...
        %  'field u2', 'output', 'hebbian connection');
        
        sim.addElement(TimedGaussStimulus1D('stim A', fieldSize1, 0, 5.5, 50, [tStimOn, 100]), ...
          [], [], 'field u1');
        sim.addElement(TimedGaussStimulus1D('stim B', fieldSize2, 0, 5.5, 20, [tStimOn, inf]), ...
          [], [], 'field u2');
        sim.addElement(TimedGaussStimulus1D('stim C', fieldSize2, 0, 5.5, 80, [tStimOn, inf]), ...
          [], [], 'field u2');
        
        sim.addElement(TimedCustomStimulus('learn Signal', 1, [tBoost, 30]), [], [], 'hebbian connection');
        sim.addElement(SumDimension('weights', [1,3], [fieldSize1,fieldSize2], 1), 'hebbian connection', 'weights');
        
        gui = StandardGUI(sim, [50, 50, 700, 400], 0.05, ...
          [0.0, 0.1, 1.0, 0.8], [1, 2], 0.05, ...
          [0.0, 0.0, 1.0, 0.1], [1, 2]);
        gui.addVisualization(MultiPlot({'field u1', 'field u2'}, ...
          {'activation', 'activation'}, [1, 1], 'horizontal', ...
          {'YLim', [-12.5, 12.5], 'Box', 'on'}, ...
          {{'b', 'LineWidth', 2}, {'r'}, {'g'}, {'g'}}, ...
          'Activation Input/Output', ' ', ' '), ...
          [1, 1]);
        gui.addVisualization(ScaledImage('weights', 'output', [0, 1], {}, {}, 'Weight Matrix'), [1, 2]);
        gui.addVisualization(TimeDisplay(), [1, 2], [1, 1], 'control');

    case 2
        sim = Simulator();

        % shared element parameters
        fieldSize1 = 100;
        fieldSize2 = 100;
        
        % timing parameters
        tMax = 200;
        tStimOn = 0;
        tBoost = 20;
        tau = 10;
        tauD = 10;
        
        % add elements
        sim.addElement(NeuralField('field u1', [fieldSize1, fieldSize1], tau, -5, 4));
        sim.addElement(NeuralField('field u2', fieldSize2, tau, -5, 4));
        
        sim.addElement(NormalNoise('noise1', fieldSize1, 0.5), [], [], 'field u1');
        sim.addElement(NormalNoise('noise2', fieldSize2, 0.5), [], [], 'field u2');
        
        sim.addElement(HebbianConnection('hebbian connection', 1, [-1, -1], tau, tauD, 'TRUE', 0), {'field u2', 'field u1'}, {'output','output'}, {'field u1', 'field u2'}, {'output', 'reverse_output'});
        %sim.addElement(GaussKernel1D('u2 -> hebb',fieldSize2, 1, 0.5), ...
        %  'field u2', 'output', 'hebbian connection');
        
        sim.addElement(TimedGaussStimulus2D('stim A', [fieldSize1, fieldSize1], 0, 0, 7, 50, 50, [tStimOn, 100]), ...
          [], [], 'field u1');
        
        sim.addElement(TimedGaussStimulus1D('stim B', fieldSize2, 0, 5.5, 50, [tStimOn, inf]), ...
          [], [], 'field u2');
        sim.addElement(TimedCustomStimulus('learn Signal', 1, [tBoost, inf]), [], [], 'hebbian connection');
        sim.addElement(SumDimension('projected Weights', 3, [fieldSize2, fieldSize1]), 'hebbian connection', 'weights');
        
        % create the gui object
        gui = StandardGUI(sim, [50, 50, 700, 400], 0.05, ...
          [0.0, 0.1, 1.0, 0.8], [1, 3], 0.01, ...
          [0.0, 0.0, 1.0, 0.1], [1, 3]);
        
        % add a plot of field u (with activation, output, and inputs)
        gui.addVisualization(ScaledImage('field u1', 'activation', [-1, 1], {}, {}, 'Input Activation'), [1, 1]);
        gui.addVisualization(MultiPlot({'field u2', 'hebbian connection'}, ...
          {'activation', 'reverse_output'}, [1, 1], 'horizontal', ...
          {'YLim', [-12.5, 12.5], 'Box', 'on'}, ...
          {{'b', 'LineWidth', 2}, {'r'}, {'g'}, {'g'}}, ...
          'Weight/Activation Output', ' ', ' '), ...
          [1, 2]);
        gui.addVisualization(ScaledImage('projected Weights', 'output', [-1, 1], {}, {}, 'Projected Weight Matrix'), [1, 3]);
        gui.addVisualization(TimeDisplay(), [1, 3], [1, 1], 'control');

    case 3
        sim = Simulator();
        % shared element parameters
        fieldSize1 = 50;
        fieldSize2 = 50;
        % timing parameters
        tMax = 200;
        tStimOn = 0;
        tBoost = 20;
        tau = 10;
        tauD = 20;
        
        % add elements
        sim.addElement(NeuralField('field u1', [fieldSize1, fieldSize1], tau, -5, 4));
        sim.addElement(NeuralField('field u2', [fieldSize2, fieldSize2], tau, -5, 4));
        sim.addElement(NormalNoise('noise1', [fieldSize1, fieldSize1], 0.5), [], [], 'field u1');
        sim.addElement(NormalNoise('noise2', [fieldSize2, fieldSize2], 0.5), [], [], 'field u2');
        sim.addElement(HebbianConnection('hebbian connection', 20, [30, 150], tau, tauD, 'TRUE'), {'field u1', 'field u2'}, {'output','output'}, {'field u2', 'field u1'}, {'output', 'reverse_output'});
        %sim.addElement(GaussKernel2D('u2 -> hebb',[fieldSize2,fieldSize2], 1, 1, 1), ...
        %  'field u2', 'output', 'hebbian connection');
        sim.addElement(TimedGaussStimulus2D('stim A', [fieldSize1, fieldSize1], 2, 2, 5.5, 25, 25, [tStimOn, inf]), ...
          [], [], 'field u1');
        sim.addElement(TimedGaussStimulus2D('stim B', [fieldSize2, fieldSize2], 2, 2, 5.5, 10, 10, [tStimOn, inf]), ...
          [], [], 'field u2');
        sim.addElement(TimedGaussStimulus2D('stim C', [fieldSize2, fieldSize2], 2, 2, 5.5, 40, 40, [tStimOn, 100]), ...
          [], [], 'field u2');
        sim.addElement(TimedCustomStimulus('learn Signal', 1, [tBoost, 30]), [], [], 'hebbian connection');
        
        % create the gui object
        gui = StandardGUI(sim, [50, 50, 1500, 800], 0.05, ...
          [0.0, 0.1, 1., 0.8], [1, 3], 0.01, ...
          [0.0, 0.0, 1.0, 0.1], [1, 3]);
        
        % add a plot of field u (with activation, output, and inputs)
        gui.addVisualization(ScaledImage('field u1', 'activation', [-5, 1], {}, {}, 'Input Activation'), [1, 1]);
        gui.addVisualization(ScaledImage('field u2', 'activation', [-5, 1], {}, {}, 'Output Activation'), [1, 2]);
        gui.addVisualization(ScaledImage('hebbian connection', 'output', [-1, 1], {}, {}, 'Weight Output'), [1, 3]);
        
        % add text-based visualization (placed in the controls grid)
        gui.addVisualization(TimeDisplay(), [1, 3], [1, 1], 'control');

    case 4
        % create object sim by constructor call
        sim = Simulator();
        fieldSize1 = 1;
        fieldSize2 = 50;
        
        % timing parameters
        tMax = 200;
        tStimOn = 0;
        tBoost = 20;
        tau = 10;
        tauD = 20;
        
        % add elements
        sim.addElement(NeuralField('field u1', fieldSize1, tau, -5, 4));
        sim.addElement(NeuralField('field u2', [fieldSize2, fieldSize2, fieldSize2], tau, -5, 4));
        sim.addElement(NormalNoise('noise1', fieldSize1, 0.5), [], [], 'field u1');
        sim.addElement(NormalNoise('noise2', [fieldSize2, fieldSize2, fieldSize2], 0.5), [], [], 'field u2');
        sim.addElement(HebbianConnection('hebbian connection',1, [30, 150], tau, tauD,'TRUE'), {'field u1', 'field u2'}, {'output','output'}, {'field u2', 'field u1'}, {'output', 'reverse_output'});
        %sim.addElement(ScaleInput('u2 -> hebb',[fieldSize2, fieldSize2, fieldSize2],1), ...
        %  'field u2', 'output', 'hebbian connection');
        sim.addElement(TimedCustomStimulus('boost', 6.5, [tStimOn, inf]), [], [], 'field u1');
        sim.addElement(TimedGaussStimulus2D('stim B', [fieldSize2, fieldSize2], 2, 2, 6.5, 10, 10, [tStimOn, inf]), ...
          [], [], 'field u2');
        sim.addElement(TimedGaussStimulus2D('stim C', [fieldSize2, fieldSize2], 2, 2, 6.5, 40, 40, [tStimOn, 100]), ...
          [], [], 'field u2');
        sim.addElement(TimedCustomStimulus('learn Signal', 1, [tBoost, 30]), [], [], 'hebbian connection');
        
        % create the gui object
        gui = StandardGUI(sim, [50, 50, 1500, 800], 0.05, ...
          [0.0, 0.1, 1., 0.8], [1, 3], 0.02, ...
          [0.0, 0.0, 1.0, 0.1], [1, 3]);
        
        gui.addVisualization(TilePlot('field u2', 'activation', [fieldSize2, fieldSize2, fieldSize2], [5, 10], [-5, 5], {}, {}, ...
          'Output Activation', ''), [1, 2]);
        gui.addVisualization(TilePlot('hebbian connection', 'output', [fieldSize2, fieldSize2, fieldSize2], [5, 10], [-1, 1], {}, {}, ...
          'Weight output', ''), [1, 3]);
        
        gui.addVisualization(MultiPlot({'field u1'}, ...
          {'activation'}, ...
          [1], 'horizontal', {'YLim', [-5, 5], 'XLim', [0, 2], 'XGrid', 'on', ...
          'XTick', [1], 'XTickLabel', ['Nodes']}, ...
          {{'bo', 'LineWidth', 1, 'MarkerFaceColor', 'b'}, ...
          {'ro', 'LineWidth', 3}, {'ko', 'LineWidth', 3, 'XDataMode', 'manual', 'XData', 1}, ...
          {'ko', 'LineWidth', 3, 'XDataMode', 'manual', 'XData', 2+1.5} }, ...
          'Input activation', '', 'activation'), [1, 1]);
        
        % add text-based visualization (placed in the controls grid)
        gui.addVisualization(TimeDisplay(), [1, 3], [1, 1], 'control');
end

sim.init();
gui.init();
while sim.t < tMax
  sim.step();
  gui.updateVisualizations();
  pause(0.05);
end