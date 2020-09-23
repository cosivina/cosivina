% same architecture as V8, but implemented using LateralInteractions2D
% element


%% setting up the architecture (fields, interactions, and inputs)

% create simulator object
sim = Simulator();

% parameters shared by multiple fields
fieldSize_spt = 100;
fieldSize_ftr = 100;

sigma_exc = 4;
sigma_inh = 8;

nFeatures = 2;

kcf = 3; % kernel cutoff factor
tau = 5;

% add spatial fields
sim.addElement(NeuralField('atn_sr', fieldSize_spt, tau));
sim.addElement(NeuralField('ior_s', fieldSize_spt, tau));
sim.addElement(NeuralField('cos', 1, tau));
sim.addElement(NeuralField('atn_sa', fieldSize_spt, tau));
sim.addElement(NeuralField('con_s', fieldSize_spt, tau));
sim.addElement(NeuralField('wm_s', fieldSize_spt, tau));

% add space-feature and feature fields
for i = 1 : nFeatures
  n = num2str(i);
  sim.addElement(NeuralField(['vis_f' n], [fieldSize_ftr, fieldSize_spt], tau));
  sim.addElement(NeuralField(['atn_f' n], fieldSize_ftr, tau));
  sim.addElement(NeuralField(['con_f' n], fieldSize_ftr, tau));
  sim.addElement(NeuralField(['wm_f' n], fieldSize_ftr, tau));
  sim.addElement(NeuralField(['atn_c' n], [fieldSize_ftr, fieldSize_spt], tau));
  sim.addElement(NeuralField(['wm_c' n], [fieldSize_ftr, fieldSize_spt], tau));
  sim.addElement(NeuralField(['pd_c' n], 1, tau));
end

% add lateral connections for purely spatial fields
sim.addElement(LateralInteractions1D('atn_sr -> atn_sr', fieldSize_spt, sigma_exc, 0, sigma_inh, 0, 0, true, true, kcf), ...
  'atn_sr', [], 'atn_sr');
sim.addElement(LateralInteractions1D('ior_s -> ior_s', fieldSize_spt, sigma_exc, 0, sigma_inh, 0, 0, true, true, kcf), ...
  'ior_s', [], 'ior_s');
sim.addElement(ScaleInput('cos -> cos', 1, 0), 'cos', [], 'cos');
sim.addElement(LateralInteractions1D('atn_sa -> atn_sa', fieldSize_spt, sigma_exc, 0, sigma_inh, 0, 0, true, true, kcf), ...
  'atn_sa', [], 'atn_sa');
sim.addElement(LateralInteractions1D('con_s -> con_s', fieldSize_spt, sigma_exc, 0, sigma_inh, 0, 0, true, true, kcf), ...
  'con_s', [], 'con_s');
sim.addElement(LateralInteractions1D('wm_s -> wm_s', fieldSize_spt, sigma_exc, 0, sigma_inh, 0, 0, true, true, kcf), ...
  'wm_s', [], 'wm_s');

% lateral connections for feature fields
for i = 1 : nFeatures
  n = num2str(i);
  
  % lateral connections and output sums for visual field
  sim.addElement(LateralInteractions2D(['vis_f' n ' -> vis_f' n], [fieldSize_ftr, fieldSize_spt], ...
    sigma_exc, sigma_exc, 7.5, sigma_inh, sigma_inh, 7.5, -0.002, true, true, true, kcf), ...
    ['vis_f' n], [], ['vis_f' n]);
%   sim.addElement(GaussKernel2D(['vis_f' n ' -> vis_f' n ' (exc.)'], [fieldSize_ftr, fieldSize_spt], ...
%     sigma_exc, sigma_exc, 0, true, true, true, kcf), ['vis_f' n], [], ['vis_f' n]);
%   sim.addElement(GaussKernel2D(['vis_f' n ' -> vis_f' n ' (inh.)'], [fieldSize_ftr, fieldSize_spt], ...
%     sigma_inh, sigma_inh, 0, true, true, true, kcf), ['vis_f' n], [], ['vis_f' n]);
%   sim.addElement(SumAllDimensions(['sum vis_f' n], [fieldSize_ftr, fieldSize_spt]), ['vis_f', n]);
%   sim.addElement(ScaleInput(['vis_f' n ' -> vis_f' n ' (global)'], 1, 0), ['sum vis_f' n], 'fullSum', ['vis_f' n]);
  
  % lateral connections and output sums for 2d selection field
  sim.addElement(LateralInteractions2D(['atn_c' n ' -> atn_c' n], [fieldSize_ftr, fieldSize_spt], ...
    sigma_exc, sigma_exc, 2.5, 0, 0, 0, -0.0175, true, true, true, kcf), ...
    ['atn_c' n], [], ['atn_c' n]);
%   sim.addElement(GaussKernel2D(['atn_c' n ' -> atn_c' n ' (exc.)'], [fieldSize_ftr, fieldSize_spt], ...
%     sigma_exc, sigma_exc, 0, true, true, true, kcf), ['atn_c' n], [], ['atn_c' n]);
% %   sim.addElement(GaussKernel2D(['atn_c' n ' -> atn_c' n ' (inh.)'], [fieldSize_ftr, fieldSize_spt], ...
% %     sigma_inh, sigma_inh, 0, true, true, true, kcf), ['atn_c' n], [], ['atn_c' n]);
%   sim.addElement(SumAllDimensions(['sum atn_c' n], [fieldSize_ftr, fieldSize_spt]), ['atn_c', n]);
%   sim.addElement(ScaleInput(['atn_c' n ' -> atn_c' n ' (global)'], 1, 0), ['sum atn_c' n], 'fullSum', ['atn_c' n]);
  
  % lateral connections and output sums for association memory fields
  sim.addElement(LateralInteractions2D(['wm_c' n ' -> wm_c' n], [fieldSize_ftr, fieldSize_spt], ...
    sigma_exc, sigma_exc, 25, sigma_inh, sigma_inh, 27.5, 0, true, true, true, kcf), ...
    ['wm_c' n], [], ['wm_c' n]);
%   sim.addElement(GaussKernel2D(['wm_c' n ' -> wm_c' n ' (exc.)'], [fieldSize_ftr, fieldSize_spt], ...
%     sigma_exc, sigma_exc, 0, true, true, true, kcf), ['wm_c' n], [], ['wm_c' n]);
%   sim.addElement(GaussKernel2D(['wm_c' n ' -> wm_c' n ' (inh.)'], [fieldSize_ftr, fieldSize_spt], ...
%     sigma_inh, sigma_inh, 0, true, true, true, kcf), ['wm_c' n], [], ['wm_c' n]);
%   sim.addElement(SumAllDimensions(['sum wm_c' n], [fieldSize_ftr, fieldSize_spt]), ['wm_c', n]);
%   sim.addElement(ScaleInput(['wm_c' n ' -> wm_c' n ' (global)'], 1, 0), ['sum wm_c' n], 'fullSum', ['wm_c' n]);
  sim.addElement(ScaleInput(['wm_c' n ' -> wm_c' n ' (global/feature)'], [1, fieldSize_spt], 0), ...
    ['wm_c' n ' -> wm_c' n], 'verticalSum');
  sim.addElement(ExpandDimension2D(['expand wm_c' n ' -> wm_c' n ' (global/feature)'], ...
    1, [fieldSize_ftr, fieldSize_spt]), ['wm_c' n ' -> wm_c' n ' (global/feature)'], [], ['wm_c' n]);
  
  % lateral connections for 1D fields
  sim.addElement(LateralInteractions1D(['atn_f' n ' -> atn_f' n], fieldSize_ftr, sigma_exc, 0, sigma_inh, 0, 0, ...
    true, true, kcf), ['atn_f' n], [], ['atn_f' n]);
  sim.addElement(LateralInteractions1D(['con_f' n ' -> con_f' n], fieldSize_ftr, sigma_exc, 0, sigma_inh, 0, 0, ...
    true, true, kcf), ['con_f' n], [], ['con_f' n]);
  sim.addElement(LateralInteractions1D(['wm_f' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, sigma_inh, 0, 0, ...
    true, true, kcf), ['wm_f' n], [], ['wm_f' n]);
  
  % self-excitation for peak detector nodes
  sim.addElement(ScaleInput(['pd_c' n ' -> pd_c' n], 1, 0), ['pd_c' n], [], ['pd_c' n]);
end


% add connections between purely spatial fields
% from spatial attention (retinal) field
sim.addElement(GaussKernel1D('atn_sr -> atn_sa', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sr');
sim.addElement(ScaleInput('scale atn_sr -> atn_sa', fieldSize_spt, 1), 'atn_sr -> atn_sa', [], 'atn_sa');
sim.addElement(GaussKernel1D('atn_sr -> vis_f', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sr');
sim.addElement(ExpandDimension2D('expand atn_sr -> vis_f', 1, [fieldSize_ftr, fieldSize_spt]), ...
  'atn_sr -> vis_f', [], cellstr([repmat('vis_f', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(GaussKernel1D('atn_sr -> ior_s', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sr', [], 'ior_s');

% from inhibition of return field
sim.addElement(GaussKernel1D('ior_s -> atn_sr', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'ior_s', [], 'atn_sr');
sim.addElement(GaussKernel1D('ior_s -> atn_sa', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'ior_s');
sim.addElement(ScaleInput('scale ior_s -> atn_sa', fieldSize_spt, 1), 'ior_s -> atn_sa', [], 'atn_sa');


% from condition of satisfaction node
sim.addElement(ScaleInput('cos -> ior_s', 1, 0), 'cos', [], 'ior_s');
sim.addElement(ScaleInput('cos -> atn_c', 1, 0), 'cos', [], ...
  cellstr([repmat('atn_c', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(ScaleInput('cos -> atn_sr', 1, 0), 'cos', [], 'atn_sr');
sim.addElement(ScaleInput('cos -> atn_sa', 1, 0), 'cos', [], 'atn_sa');
sim.addElement(ScaleInput('cos -> atn_f', 1, 0), 'cos', [], ...
  cellstr([repmat('atn_f', [nFeatures, 1]), num2str((1:nFeatures)')]));

% from spatial attention (allocentric) field
sim.addElement(GaussKernel1D('atn_sa -> atn_sr', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sa');
sim.addElement(ScaleInput('scale atn_sa -> atn_sr', fieldSize_spt, 1), 'atn_sa -> atn_sr', [], 'atn_sr');
sim.addElement(GaussKernel1D('atn_sa -> con_s', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sa', [], 'con_s');
sim.addElement(GaussKernel1D('atn_sa -> wm_s', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sa', [], 'wm_s');

sim.addElement(GaussKernel1D('atn_sa -> wm_c', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sa');
sim.addElement(ExpandDimension2D('expand atn_sa -> wm_c', 1, [fieldSize_ftr, fieldSize_spt]), ...
  'atn_sa -> wm_c', [], cellstr([repmat('wm_c', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(GaussKernel1D('atn_sa -> atn_c', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'atn_sa');
sim.addElement(ExpandDimension2D('expand atn_sa -> atn_c', 1, [fieldSize_ftr, fieldSize_spt]), ...
  'atn_sa -> atn_c', [], cellstr([repmat('atn_c', [nFeatures, 1]), num2str((1:nFeatures)')]));

% from contrast (spatial) field
sim.addElement(GaussKernel1D('con_s -> atn_sa', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'con_s', [], 'atn_sa');
sim.addElement(GaussKernel1D('con_s -> wm_s', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'con_s', [], 'wm_s');
sim.addElement(GaussKernel1D('con_s -> atn_c', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'con_s');
sim.addElement(ExpandDimension2D('expand con_s -> atn_c', 1, [fieldSize_ftr, fieldSize_spt]), ...
  'con_s -> atn_c', [], cellstr([repmat('atn_c', [nFeatures, 1]), num2str((1:nFeatures)')]));

% from working memory (spatial)
sim.addElement(GaussKernel1D('wm_s -> con_s', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'wm_s', [], 'con_s');
sim.addElement(GaussKernel1D('wm_s -> atn_sa', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'wm_s', [], 'atn_sa');
sim.addElement(GaussKernel1D('wm_s -> wm_c', fieldSize_spt, sigma_exc, 0, true, true, kcf), 'wm_s');
sim.addElement(ExpandDimension2D('expand wm_s -> wm_c', 1, [fieldSize_ftr, fieldSize_spt]), ...
  'wm_s -> wm_c', [], cellstr([repmat('wm_c', [nFeatures, 1]), num2str((1:nFeatures)')]));


for i = 1 : nFeatures
  n = num2str(i);
  
  % from visual field
  sim.addElement(GaussKernel1D(['vis_f' n ' -> atn_sr'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'verticalSum', 'atn_sr');
  sim.addElement(GaussKernel1D(['vis_f' n ' -> ior_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'verticalSum', 'ior_s');
  sim.addElement(GaussKernel1D(['vis_f' n ' -> con_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'verticalSum', 'con_s');
  sim.addElement(GaussKernel1D(['vis_f' n ' -> wm_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'verticalSum', 'wm_s');
  sim.addElement(GaussKernel1D(['vis_f' n ' -> atn_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'horizontalSum', ['atn_f' n]);
  sim.addElement(GaussKernel1D(['vis_f' n ' -> con_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'horizontalSum', ['con_f' n]);
  sim.addElement(GaussKernel1D(['vis_f' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['vis_f' n ' -> vis_f' n], 'horizontalSum', ['wm_f' n]);
  
  % from feature attention field
  sim.addElement(GaussKernel1D(['atn_f' n ' -> vis_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ['atn_f' n]);
  sim.addElement(ExpandDimension2D(['expand atn_f' n ' -> vis_f' n], 2, [fieldSize_ftr, fieldSize_spt]), ...
    ['atn_f' n ' -> vis_f' n], [], ['vis_f' n]);
  
  sim.addElement(GaussKernel1D(['atn_f' n ' -> con_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['atn_f' n], [], ['con_f' n]);
  sim.addElement(GaussKernel1D(['atn_f' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['atn_f' n], [], ['wm_f' n]);
  
  sim.addElement(GaussKernel1D(['atn_f' n ' -> atn_c' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ['atn_f' n]);
  sim.addElement(ExpandDimension2D(['expand atn_f' n ' -> atn_c' n], 2, [fieldSize_ftr, fieldSize_spt]), ...
    ['atn_f' n ' -> atn_c' n], [], ['atn_c' n]);
  
  sim.addElement(GaussKernel1D(['atn_f' n ' -> wm_c' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ['atn_f' n]);
  sim.addElement(ExpandDimension2D(['expand atn_f' n ' -> wm_c' n], 2, [fieldSize_ftr, fieldSize_spt]), ...
    ['atn_f' n ' -> wm_c' n], [], ['wm_c' n]);
  
  % from perceptual intention (feature) field
  sim.addElement(GaussKernel1D(['con_f' n ' -> atn_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['con_f' n], [], ['atn_f' n]);
  sim.addElement(GaussKernel1D(['con_f' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['con_f' n], [], ['wm_f' n]);
  
  sim.addElement(GaussKernel1D(['con_f' n ' -> atn_c' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ['con_f' n]);
  sim.addElement(ExpandDimension2D(['expand con_f' n ' -> atn_c' n], 2, [fieldSize_ftr, fieldSize_spt]), ...
    ['con_f' n ' -> atn_c' n], [], ['atn_c' n]);
  
  % from working memory memory (feature) field
  sim.addElement(GaussKernel1D(['wm_f' n ' -> con_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['wm_f' n], [], ['con_f' n]);
  sim.addElement(GaussKernel1D(['wm_f' n ' -> atn_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['wm_f' n], [], ['atn_f' n]);
  
  sim.addElement(GaussKernel1D(['wm_f' n ' -> wm_c' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ['wm_f' n]);
  sim.addElement(ExpandDimension2D(['expand wm_f' n ' -> wm_c' n], 2, [fieldSize_ftr, fieldSize_spt]), ...
    ['wm_f' n ' -> wm_c' n], [], ['wm_c' n]);

  % from feature selection field
  sim.addElement(GaussKernel1D(['atn_c' n ' -> atn_sa'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['atn_c' n ' -> atn_c' n], 'verticalSum', 'atn_sa');
  sim.addElement(GaussKernel1D(['atn_c' n ' -> con_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['atn_c' n ' -> atn_c' n], 'verticalSum', 'con_s');
  sim.addElement(GaussKernel1D(['atn_c' n ' -> wm_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['atn_c' n ' -> atn_c' n], 'verticalSum', 'wm_s');
    
  sim.addElement(GaussKernel1D(['atn_c' n ' -> con_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['atn_c' n ' -> atn_c' n], 'horizontalSum', ['con_f' n]);
  sim.addElement(GaussKernel1D(['atn_c' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['atn_c' n ' -> atn_c' n], 'horizontalSum', ['wm_f' n]);
  
  sim.addElement(GaussKernel2D(['atn_c' n ' -> wm_c' n], [fieldSize_ftr, fieldSize_spt], sigma_exc, sigma_exc, 0, ...
    true, true, true, kcf), ['atn_c' n], [], ['wm_c' n]);
  
  sim.addElement(ScaleInput(['atn_c' n ' -> pd_c' n], 1, 0), ['atn_c' n ' -> atn_c' n], 'fullSum', ['pd_c' n]);
  
  % from peak detector node
  sim.addElement(ScaleInput(['pd_c' n ' -> cos'], 1, 0), ['pd_c' n], [], 'cos');
    
  % from integrated working memory field
  sim.addElement(GaussKernel1D(['wm_c' n ' -> wm_s'], fieldSize_spt, sigma_exc, 0, true, true, kcf), ...
    ['wm_c' n ' -> wm_c' n], 'verticalSum', 'wm_s');
  sim.addElement(GaussKernel1D(['wm_c' n ' -> wm_f' n], fieldSize_ftr, sigma_exc, 0, true, true, kcf), ...
    ['wm_c' n ' -> wm_c' n], 'horizontalSum', ['wm_f' n]);
  sim.addElement(GaussKernel2D(['wm_c' n ' -> atn_c' n], [fieldSize_ftr, fieldSize_spt], sigma_exc, sigma_exc, 0, ...
    true, true, true, kcf), ['wm_c' n], [], ['atn_c' n]);
end


% create stimuli

% visual stimulus locations and feature values
stimulusPositions_s = [20, 50, 80, 20, 50, 80];
stimulusPositions_f = [20, 50, 80, 80, 50, 20; 80, 50, 20, 20, 50, 80];
nStimuli_v = min(size(stimulusPositions_s, 2), size(stimulusPositions_f, 2));

for i = 1 : nFeatures
  n = num2str(i);
  for j = 1 : nStimuli_v
    m = num2str(j);
    sim.addElement(GaussStimulus2D(['i' m ' for vis_f', n], [fieldSize_ftr, fieldSize_spt], ...
      sigma_exc, sigma_exc, 0, stimulusPositions_s(j), stimulusPositions_f(i, j), true, true, false), ...
      [], [], ['vis_f' n]);
  end
end

nStimuli_s = nStimuli_v/2;
for j = 1 : nStimuli_s
  m = num2str(j);
  sim.addElement(GaussStimulus1D(['i' m ' for atn_sr'], fieldSize_spt, sigma_exc, 0, stimulusPositions_s(j), true), ...
    [], [], 'atn_sr');
end



% boost stimuli for all fields
sim.addElement(BoostStimulus('boost ior_s', 0), [], [], 'ior_s');
sim.addElement(BoostStimulus('boost atn_sr', 0), [], [], 'atn_sr');
sim.addElement(BoostStimulus('boost atn_sa', 0), [], [], 'atn_sa');
sim.addElement(BoostStimulus('boost con_s', 0), [], [], 'con_s');
sim.addElement(BoostStimulus('boost wm_s', 0), [], [], 'wm_s');

sim.addElement(BoostStimulus('boost vis_f', 0), [], [], cellstr([repmat('vis_f', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(BoostStimulus('boost atn_f', 0), [], [], cellstr([repmat('atn_f', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(BoostStimulus('boost con_f', 0), [], [], cellstr([repmat('con_f', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(BoostStimulus('boost wm_f', 0), [], [], cellstr([repmat('wm_f', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(BoostStimulus('boost atn_c', 0), [], [], cellstr([repmat('atn_c', [nFeatures, 1]), num2str((1:nFeatures)')]));
sim.addElement(BoostStimulus('boost wm_c', 0), [], [], cellstr([repmat('wm_c', [nFeatures, 1]), num2str((1:nFeatures)')]));

% add correlated noise
sim.addElement(NormalNoise('noise atn_sr', fieldSize_spt, 1));
sim.addElement(GaussKernel1D('noise kernel atn_sr', fieldSize_spt, 0, 0, true, true, kcf), ...
  'noise atn_sr', [], 'atn_sr');
% sim.addElement(NormalNoise('noise ior_s', fieldSize_spt, 1));
% sim.addElement(GaussKernel1D('noise kernel ior_s', fieldSize_spt, 0, 0, true, true, kcf), ...
%   'noise ior_s', [], 'ior_s');
sim.addElement(NormalNoise('noise atn_sa', fieldSize_spt, 1));
sim.addElement(GaussKernel1D('noise kernel atn_sa', fieldSize_spt, 0, 0, true, true, kcf), ...
  'noise atn_sa', [], 'atn_sa');
% sim.addElement(NormalNoise('noise con_s', fieldSize_spt, 1));
% sim.addElement(GaussKernel1D('noise kernel con_s', fieldSize_spt, 0, 0, true, true, kcf), ...
%   'noise con_s', [], 'con_s');
% sim.addElement(NormalNoise('noise wm_s', fieldSize_spt, 1));
% sim.addElement(GaussKernel1D('noise kernel wm_s', fieldSize_spt, 0, 0, true, true, kcf), ...
%   'noise wm_s', [], 'wm_s');

for i = 1 : nFeatures
  n = num2str(i);
%   sim.addElement(NormalNoise(['noise vis_f' n], [fieldSize_ftr, fieldSize_spt], 1));
%   sim.addElement(GaussKernel2D(['noise kernel vis_f' n], [fieldSize_ftr, fieldSize_spt], 0, 0, 0, ...
%     true, true, true, kcf), ['noise vis_f' n], [], ['vis_f' n]);
%   
%   sim.addElement(NormalNoise(['noise atn_f' n], fieldSize_ftr, 1));
%   sim.addElement(GaussKernel1D(['noise kernel atn_f' n], fieldSize_ftr, 0, 0, true, true, kcf), ...
%     ['noise atn_f' n], [], ['atn_f' n]);
%   sim.addElement(NormalNoise(['noise con_f' n], fieldSize_ftr, 1));
%   sim.addElement(GaussKernel1D(['noise kernel con_f' n], fieldSize_ftr, 0, 0, true, true, kcf), ...
%     ['noise con_f' n], [], ['con_f' n]);
%   sim.addElement(NormalNoise(['noise wm_f' n], fieldSize_ftr, 1));
%   sim.addElement(GaussKernel1D(['noise kernel wm_f' n], fieldSize_ftr, 0, 0, true, true, kcf), ...
%     ['noise wm_f' n], [], ['wm_f' n]);
%   
%   sim.addElement(NormalNoise(['noise atn_c' n], [fieldSize_ftr, fieldSize_spt], 1));
%   sim.addElement(GaussKernel2D(['noise kernel atn_c' n], [fieldSize_ftr, fieldSize_spt], 0, 0, 0, ...
%     true, true, true, kcf), ['noise atn_c' n], [], ['atn_c' n]);
%   sim.addElement(NormalNoise(['noise wm_c' n], [fieldSize_ftr, fieldSize_spt], 1));
%   sim.addElement(GaussKernel2D(['noise kernel wm_c' n], [fieldSize_ftr, fieldSize_spt], 0, 0, 0, ...
%     true, true, true, kcf), ['noise wm_c' n], [], ['wm_c' n]);
end


%% settings for element list in advanced parameter panel

elementGroups = sim.elementLabels;
elementsInGroup = sim.elementLabels;

% exclude elements that should not appear in the param panel
excludeLabels = {'sum', 'expand', 'boost', 'scale'};
excludeIndices = zeros(size(elementGroups));
for i = 1 : length(excludeLabels)
  excludeIndices = excludeIndices | strncmp(excludeLabels{i}, elementGroups, length(excludeLabels{i}));
end
elementGroups(excludeIndices) = [];
elementsInGroup(excludeIndices) = [];

% group together elements that only differ in index (and remove the index
for i = 1 : length(elementGroups)
  if elementGroups{i}(1) ~= 'i' % include the inputs
    nonumber = true(1, length(elementGroups{i}));
    nonumber([strfind(elementGroups{i}, '1'), strfind(elementGroups{i}, '2')]) = false;
    elementGroups{i} = elementGroups{i}(nonumber);
  end
end

i = 1;
while i <= length(elementGroups)
  %if ~isempty(elementGroups{i})
  same = strcmp(elementGroups{i}, elementGroups);
  elementsInGroup{i} = elementsInGroup(same);
  same(find(same, 1)) = 0;
  elementsInGroup(same) = [];
  elementGroups(same) = [];
  i = i + 1;
end


%% create gui and visualizations

% create GUI object
gui = StandardGUI(sim, [25, 25, 1150, 900], 0.0, [0, 0.175, 1.0, 0.8], [8, 12], 0.015, [0, 0, 1.0, 0.15], [6, 4], ...
  elementGroups, elementsInGroup);

% syntax: addVisualization(sim, visualizationType, position, elementLabels, components, axesProperties, plotProperties)
gui.addVisualization(MultiPlot({'wm_s', 'wm_s'}, {'activation', 'output'}, [1, 10], 'horizontal', ...
  {'XLim', [1, fieldSize_spt], 'YLim', [-15, 15], 'Box', 'on'}, {{'Color', 'b'}, {'Color', 'r'}}, 'wm s'), ...
  [2, 1], [1, 3]);
gui.addVisualization(MultiPlot({'atn_sa', 'atn_sa'}, {'activation', 'output'}, [1, 10], 'horizontal', ...
  {'XLim', [1, fieldSize_spt], 'YLim', [-15, 15], 'Box', 'on'}, {{'Color', 'b'}, {'Color', 'r'}}, 'atn sa'), ...
  [1, 4], [1, 3]);
gui.addVisualization(MultiPlot({'con_s', 'con_s'}, {'activation', 'output'}, [1, 10], 'horizontal', ...
  {'XLim', [1, fieldSize_spt], 'YLim', [-15, 15], 'Box', 'on'}, {{'Color', 'b'}, {'Color', 'r'}}, 'con s'), ...
  [2, 4], [1, 3]);
gui.addVisualization(MultiPlot({'atn_sr', 'atn_sr'}, {'activation', 'output'}, [1, 10], 'horizontal', ...
  {'XLim', [1, fieldSize_spt], 'YLim', [-15, 15], 'Box', 'on'}, {{'Color', 'b'}, {'Color', 'r'}},  'atn sr'), ...
  [2, 10], [1, 3]);
gui.addVisualization(MultiPlot({'ior_s', 'ior_s', 'pd_c1', 'pd_c1', 'pd_c2', 'pd_c2', 'cos', 'cos'}, ...
  {'activation', 'output', 'activation', 'output', 'activation', 'output', 'activation', 'output'}, ...
  [1, 10, 1, 10, 1, 10, 1, 10], 'horizontal', ...
  {'XLim', [1, fieldSize_spt], 'YLim', [-15, 15], 'Box', 'on'}, ...
  {{'Color', 'b'}, {'Color', 'r'}, ...
  {'bs', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 1}, ...
  {'rs', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 1}, ...
  {'bs', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 5}, ...
  {'rs', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 5}, ...
  {'bo', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 10}, ...
  {'ro', 'MarkerSize', 4, 'XDataMode', 'manual', 'XData', 10}}, ...
  'ior s'), [1, 10], [1, 3]);


for i = 1 : nFeatures
  n = num2str(i);
  if i == nFeatures % x-axis labels only for the bottommost axes
    xla = 'space (all)';
    xlr = 'space (ret)';
  else
    xla = [];
    xlr = [];
  end
  ov = 3*i; % vertical offset for placing visualizations of the current feature
  
  gui.addVisualization(ScaledImage(['wm_c' n], 'activation', [-7.5, 7.5], ...
    {'CLim', [-7.5, 7.5], 'YAxisLocation', 'right', 'YDir', 'normal'}, {}, ['scene wm' n], xla), [ov, 1], [3, 3]);
  gui.addVisualization(ScaledImage(['atn_c' n], 'activation', [-7.5, 7.5], ...
    {'CLim', [-7.5, 7.5], 'YAxisLocation', 'right', 'YDir', 'normal'}, {}, ['scene atn' n], xla), [ov, 4], [3, 3]);
  gui.addVisualization(MultiPlot({['wm_f' n], ['wm_f' n]}, {'activation', 'output'}, [1, 10], 'vertical', ...
    {'YLim', [1, fieldSize_ftr], 'XLim', [-15, 15], 'XDir', 'reverse', 'YAxisLocation', 'right', 'Box', 'on'}, ...
    {{'Color', 'b'}, {'Color', 'r'}}, ['wm f' n]), [ov, 7], [3, 1]);
  gui.addVisualization(MultiPlot({['con_f' n], ['con_f' n]}, {'activation', 'output'}, [1, 10], 'vertical', ...
    {'YLim', [1, fieldSize_ftr], 'XLim', [-15, 15], 'XDir', 'reverse', 'YAxisLocation', 'right', 'Box', 'on'}, ...
    {{'Color', 'b'}, {'Color', 'r'}}, ['con f' n]), [ov, 8], [3, 1]);
  gui.addVisualization(MultiPlot({['atn_f' n], ['atn_f' n]}, {'activation', 'output'}, [1, 10], 'vertical', ...
    {'YLim', [1, fieldSize_ftr], 'XLim', [-15, 15], 'XDir', 'reverse', 'YAxisLocation', 'right', 'Box', 'on'}, ...
    {{'Color', 'b'}, {'Color', 'r'}}, ['atn f' n]), [ov, 9], [3, 1]);
  
  gui.addVisualization(ScaledImage(['vis_f' n], 'activation', [-7.5, 7.5], ...
    {'CLim', [-7.5, 7.5], 'YAxisLocation', 'right', 'YDir', 'normal'}, {}, ['ret f' n], xlr, ['feature ' n]), ...
    [ov, 10], [3, 3]);
end


%% create controls

% sliders for boosts
gui.addControl(ParameterSlider('atn_sa', 'boost atn_sa', 'amplitude', [-5, 5], '%0.1f', 1, 'boost allocentric spatial attention field'), [1, 1]);
gui.addControl(ParameterSlider('con_s', 'boost con_s', 'amplitude', [-5, 5], '%0.1f', 1, 'boost spatial contrast field'), [2, 1]);
gui.addControl(ParameterSlider('wm_s', 'boost wm_s', 'amplitude', [-5, 5], '%0.1f', 1, 'boost spatial WM field'), [3, 1]);
gui.addControl(ParameterSlider('atn_c', 'boost atn_c', 'amplitude', [-5, 5], '%0.1f', 1, 'boost scene attention fields'), [4, 1]);
gui.addControl(ParameterSlider('wm_c', 'boost wm_c', 'amplitude', [-5, 5], '%0.1f', 1, 'boost scene WM fields'), [5, 1]);

gui.addControl(ParameterSlider('ior_s', 'boost ior_s', 'amplitude', [-5, 5], '%0.1f', 1, 'boost IOR field'), [1, 2]);
gui.addControl(ParameterSlider('atn_sr', 'boost atn_sr', 'amplitude', [-5, 5], '%0.1f', 1, 'boost retinal spatial attention field'), [2, 2]);
gui.addControl(ParameterSlider('atn_f', 'boost atn_f', 'amplitude', [-5, 5], '%0.1f', 1, 'boost feature attention fields'), [3, 2]);
gui.addControl(ParameterSlider('con_f', 'boost con_f', 'amplitude', [-5, 5], '%0.1f', 1, 'boost feature contrast fields'), [4, 2]);
gui.addControl(ParameterSlider('wm_f', 'boost wm_f', 'amplitude', [-5, 5], '%0.1f', 1, 'boost feature WM fields'), [5, 2]);
gui.addControl(ParameterSwitchButton('spatial coupling ret<->allo', ...
  {'scale atn_sr -> atn_sa', 'scale atn_sa -> atn_sr', 'scale ior_s -> atn_sa', 'atn_sa', 'atn_c1', 'atn_c2'}, ...
  {'amplitude', 'amplitude', 'amplitude', 'h', 'h', 'h'}, [0.0, 0.0, 0.0, -3, -4.75, -4.75], [1.0, 1.0, 1.0, -5, -5, -5], ...
  'coupling between retinal and allocentric spatial attention', true), [6, 2]);
% gui.addControl(ParameterSwitchButton('r <-> a', ...
%   {'scale atn_sr -> atn_sa', 'scale atn_sa -> atn_sr', 'scale ior_s -> atn_sa'}, ...
%   {'amplitude', 'amplitude', 'amplitude'}, [0.1, 0.1, 0.1], [1.0, 1.0, 1.0], ...
%   'coupling between retinal and allocentric spatial attention', true), [6, 2]);

% input buttons and sliders
gui.addControl(ParameterSwitchButton('stimulus pattern A', ...
  {'i1 for vis_f1', 'i1 for vis_f2', 'i2 for vis_f1', 'i2 for vis_f2', 'i3 for vis_f1', 'i3 for vis_f2'}, ...
  {'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude'}, zeros(1, 6), 6 * ones(1, 6), ...
  [], false), [1, 3]);
gui.addControl(ParameterSwitchButton('stimulus pattern B', ...
  {'i4 for vis_f1', 'i4 for vis_f2', 'i5 for vis_f1', 'i5 for vis_f2', 'i6 for vis_f1', 'i6 for vis_f2'}, ...
  {'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude'}, zeros(1, 6), 6 * ones(1, 6), ...
  [], false), [2, 3]);
gui.addControl(ParameterSwitchButton('stimulus pattern C', ...
  {'i5 for vis_f2', 'i3 for vis_f1', 'i6 for vis_f2', 'i1 for vis_f1', 'i4 for vis_f2', 'i2 for vis_f1'}, ...
  {'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude', 'amplitude'}, zeros(1, 6), 6 * ones(1, 6), ...
  [], false), [3, 3]);
gui.addControl(ParameterSlider('a_s1', 'i1 for atn_sr', 'amplitude', [-5, 5], '%0.1f', 1, 'spatial attention input for left location'), [4, 3]);
gui.addControl(ParameterSlider('a_s2', 'i2 for atn_sr', 'amplitude', [-5, 5], '%0.1f', 1, 'spatial attention input for middle location'), [5, 3]);
gui.addControl(ParameterSlider('a_s3', 'i3 for atn_sr', 'amplitude', [-5, 5], '%0.1f', 1, 'spatial attention input for right location'), [6, 3]);

% general control buttons
gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);

sim.loadSettings('presetSceneRepresentation.json');


%% run the simulation

gui.run(inf);






