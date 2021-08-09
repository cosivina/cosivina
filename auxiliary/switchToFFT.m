% switchToFFT (COSIVINA toolbox)
%   Convert classical convolutions in simulator with FFT method.
%
% simSwitch = switchToFFT(sim) determines all non-FFT interaction kernels in the
%   input simulator (GaussKernel, MexicanHatKernel, and LateralInteractions
%   elements of any dimensionality) and replaces them with a KernelFFT elements
%   with matched parameters, such that the behavior of the simulator remains
%   unchanged. If a LateralInteractions element is replaced and other elements
%   use the sum components of that element, then a new SumDimension or
%   SumAllDimensions element is also added to replace that functionality.
% 
% [simSwitch, T, TAll] = switchToFFT(sim) additionally measures the computation
%   time of the original and switched simulator and returns a table T of changed
%   elements with their original and new computation times (in s), and a table
%   TAll with times for all elements. NOTE: For the measurement, the simulator
%   is initialized and then runs for a set number of time steps (see below); to
%   ensure informative measurements, it is advisable that the simulator is
%   configured such that it actually performs some operation upon initialization
%   (e.g., make sure that inputs are activated).
%
% switchToFFT(sim, makeCircular, combineFFT, tMax, nReps, elementsToSwitch)
%   allows adjusting the behavior of the replacement and measurement processes:
% makeCircular - sets boundary conditions in all replaced elements to circular,
%   which is significantly faster than linear when using the FFT method (default
%   is true).
% combineFFT - detects when multiple convolutions are performed on the same
%   input, and introduces separate FastFourierTransform elements in combination
%   with KernelInverseFFT elements to avoid the cost of repeated transformations
%   into Fourier space (default is true). The overhead of the extra elements may
%   not always be canceled out by the more efficient computation, so it is
%   advisable to perform the switch both with and without the combineFFT option
%   to find the best solution.
% tMax - simulation time for which the simulator is run for the measurement
%   of computation times (default is 100)
% nReps - number of repetitions of the simulation used for the measurement if
%   computation times (default is 10)
% elementsToSwitch - cell array of element labels that are to be switched to
%   FFT; all other elements remain unchanged

function [simSwitch, T, TAll] = switchToFFT(sim, makeCircular, combineFFT, tMax, nReps, elementsToSwitch)

if nargin < 2
    makeCircular = true;
end
if nargin < 3
    combineFFT = true;
end
if nargin < 4
    tMax = 100;
end
if nargin < 5
    nReps = 10;
end
if nargin < 6
    elementsToSwitch = {};
end

% working on a copy so as not to change state of the input sim
sim = sim.copy();
nElements = sim.nElements;
elementLabels = sim.elementLabels';


%% define classes that can be replaced

classNamePatterns = {'GaussKernel%dD', 'MexicanHatKernel%dD', 'LateralInteractions%dD'};
kernelDims = 1:3;
nClasses = numel(classNamePatterns);
sumComponents = {'horizontalSum', 'verticalSum', 'fullSum'};

classNames = cell(nClasses, numel(kernelDims));
for ic = 1 : nClasses
    for d = kernelDims
        classNames{ic, d} = sprintf(classNamePatterns{ic}, d);
    end
end


%% determine which elements need to be replaced, and where summing or fft elements need to be added

elementClasses = cell(nElements, 1);

switchElement = false(nElements, 1); % indicates whether element can be switched to FFT kernel

% count repetitions of kernel inputs to decide whether to introduce separate FFT element
kernelInputs = struct('index', {}, 'label', {}, 'component', {}, 'size', {}, 'occurrences', {}, 'targets', {});

kernelType = zeros(nElements, 1);
kernelDimension = zeros(nElements, 1);
sumRequired = false(nElements, 1);
associatedSum = cell(nElements, 1);

% determine which elements should be switched
for ie = 1 : nElements
    el = sim.elements{ie};
    c = class(el);
    elementClasses{ie} = c;
    
    [ic, d] = find(strcmp(c, classNames), 1);
    
    if ~isempty(ic) && (isempty(elementsToSwitch) || any(strcmp(el.label, elementsToSwitch)))
        switchElement(ie) = true;
        
        kernelType(ie) = ic;
        kernelDimension(ie) = d;
        
        % determine whether kernel treats all dimensions as circular (requirement for using separate FFT element)
        isCircular = true;
        if ~makeCircular
            paramNames = fieldnames(el.parameters);
            circVars = paramNames(strncmp('circular', paramNames, numel('circular')));
            for ip = 1 : numel(circVars)
                if ~el.(circVars{ip})
                    isCircular = false;
                    break
                end
            end
        end
        
        % update count of kernel input components 
        if isCircular
            inputLabel = el.inputElements{1}.label;
            inputComponent = el.inputComponents{1};
            
            k = find(strcmp({kernelInputs.label}, inputLabel) ...
                & strcmp({kernelInputs.component}, inputComponent), 1);
            if isempty(k)
                ii = find(strcmp(elementLabels, inputLabel));
                kernelInputs(end + 1) = struct('index', ii, 'label', inputLabel, 'component', inputComponent, ...
                    'size', el.size, 'occurrences', 1, 'targets', ie); %#ok<AGROW>
            else
                kernelInputs(k).occurrences = kernelInputs(k).occurrences + 1;
                kernelInputs(k).targets(end+1) = ie;
            end
        end
        
    elseif any(strcmp(el.label, elementsToSwitch))
        warning('Element ''%s'' cannot be switched to KernelFFT because it is not of an appropriate class.', el.label);
    end
end

% determine for which elements an additional summing element is required
for ie = 1 : nElements
    el = sim.elements{ie};
    
    for ii = 1 : el.nInputs
        k = find(strcmp(el.inputElements{ii}.label, elementLabels));
        if switchElement(k) && any(strcmp(el.inputComponents{ii}, sumComponents))
            sumRequired(k) = true;
        end
    end
end

% determine for which element components an additional fft element is required
fftElementRequired = false(nElements, 1);
receivingInputFFT = false(nElements, 1);
if combineFFT
    fftElementSpecs = kernelInputs([kernelInputs.occurrences] > 1);
    fftElementRequired([fftElementSpecs.index]) = true;
    receivingInputFFT(cell2mat({fftElementSpecs.targets})) = true;
end


%% create new Simulator with classical kernels replaced by FFT kernels

simSwitch = Simulator('deltaT', sim.deltaT, 'tZero', sim.tZero);
for ie = 1 : nElements
    el = sim.elements{ie};
    
    if switchElement(ie)
        ic = kernelType(ie);
        d = kernelDimension(ie);
        
        if receivingInputFFT(ie)
            newKernel = KernelInverseFFT(el.label, el.size, ones(d, 1), 0, ones(d, 1), 0, 0, el.normalized);
        else
            newKernel = KernelFFT(el.label, el.size, ones(d, 1), 0, ones(d, 1), 0, 0, true(d, 1), el.normalized);
        end
        
        if d == 1
            dimStr = {''};
        else
            dimStr = {'Y', 'X', 'Z'};
        end
        
        if ic == 1 % GaussKernel
            newKernel.amplitudeExc = el.amplitude;
        else % MexicanHatKernel and LateralInteractions
            newKernel.amplitudeExc = el.amplitudeExc;
            newKernel.amplitudeInh = el.amplitudeInh;
        end
        if ic == 3 % LateralInteractions
            newKernel.amplitudeGlobal = el.amplitudeGlobal;
        end
        
        for id = 1 : d
            if ~receivingInputFFT(ie)
                newKernel.circular(id) = el.(['circular' dimStr{id}]) | makeCircular;
            end
            
            if ic == 1 % GaussKernel
                newKernel.sigmaExc(id) = el.(['sigma' dimStr{id}]);
            else % MexicanHatKernel and LateralInteractions
                newKernel.sigmaExc(id) = el.(['sigmaExc' dimStr{id}]);
                newKernel.sigmaInh(id) = el.(['sigmaInh' dimStr{id}]);
            end
        end
        
        simSwitch.addElement(newKernel);
        
        if sumRequired(ie)
            newLabel = ['sum ', el.inputElements{1}.label];
            while any(strcmp(newLabel, elementLabels))
                newLabel = [newLabel, '+']; %#ok<AGROW>
            end
            associatedSum{ie} = newLabel;
            
            if d == 1
                [~, dSum] = max(el.size);
                newSum = SumDimension(newLabel, dSum, [1, 1]);
            elseif d == 2
                newSum = SumAllDimensions(newLabel, el.size);
            else % d == 3, only fullSum available
                newSum = SumDimension(newLabel, [1, 2, 3], [1, 1]);
            end
            
            % add new element for summing, with the same input as the kernel
            simSwitch.addElement(newSum, el.inputElements{1}.label, el.inputComponents{1});
        end
    else
        % copy elements that are not changed
        newElement = el.copy();
        newElement.nInputs = 0;
        newElement.inputElements = {};
        newElement.inputComponents = {};
        simSwitch.addElement(newElement);
        
        if any(strcmp(el.label, elementsToSwitch))
            warning('Element ''%s'' cannot be switched to KernelFFT because it is not of an appropriate class.', ...
                el.label);
        end
    end
    
    % add new FFT element if required
    if fftElementRequired(ie)
        Ic = reshape(find(strcmp(el.label, {fftElementSpecs.label})), 1, []);
        nc = numel(Ic);
        for ic = Ic
            spec = fftElementSpecs(ic);
            inputLabel = spec.label;
            inputComponent = spec.component;
            
            if sumRequired(ie) && any(strcmp(inputComponent, sumComponents))
                inputLabel = associatedSum{ie};
                if isa(simSwitch.getElement(associatedSum{k}), 'SumDimension')
                    inputComponent = 'output';
                end
            end
            
            if nc == 1
                newLabel = ['fft ', inputLabel];
            else
                newLabel = ['fft ', inputLabel, ' ', inputComponent];
            end
            while any(strcmp(newLabel, elementLabels))
                newLabel = [newLabel, '+']; %#ok<AGROW>
            end
            fftElementSpecs(ic).newLabel = newLabel;
            simSwitch.addElement(FastFourierTransform(newLabel, fftElementSpecs(ic).size), inputLabel, inputComponent);
        end

    end
end


%% re-create connections
for ie = 1 : nElements
    el = sim.elements{ie};
    
    inputLabels = cell(1, el.nInputs);
    inputComponents = el.inputComponents;
    
    for ii = 1 : el.nInputs
        l = el.inputElements{ii}.label;
        c = el.inputComponents{ii};
        k = find(strcmp(l, elementLabels));
        
        if switchElement(k) && any(strcmp(c, sumComponents)) && ~receivingInputFFT(ie)
            % need to change input element if summing from lateral interactions was used
            inputLabels{ii} = associatedSum{k};
            if isa(simSwitch.getElement(associatedSum{k}), 'SumDimension')
                inputComponents{ii} = 'output';
            end
        elseif receivingInputFFT(ie)
            % need to change input if separate FFT element has been added
            m = strcmp({fftElementSpecs.label}, l) & strcmp({fftElementSpecs.label}, l);
            if any(m) % this isn't strictly required since kernels can have only one input
                inputLabels{ii} = fftElementSpecs(m).newLabel;
                inputComponents{ii} = 'output';
            end
        else
            inputLabels{ii} = l;
        end
    end
    
    simSwitch.addConnection(inputLabels, inputComponents, elementLabels{ie});
end

%% compare performance of original and FFT version

if nargout == 1
    return
end

elementLabelsNew = simSwitch.elementLabels';
nElementsNew = simSwitch.nElements;
elementClassesNew = cell(nElementsNew, 1);
switchedElement = false(nElementsNew, 1);
addedElement = false(nElementsNew, 1);
for i = find(switchElement)'
    switchedElement(strcmp(elementLabels{i}, elementLabelsNew)) = true;
end
for i = find(sumRequired)'
    addedElement(strcmp(associatedSum{i}, elementLabelsNew)) = true;
end
if combineFFT
    for i = 1 : numel(fftElementSpecs)
        addedElement(strcmp(fftElementSpecs(i).newLabel, elementLabelsNew)) = true;
    end
end

for i = 1 : nElementsNew
    elementClassesNew{i} = class(simSwitch.elements{i});
end
    
nElementsAdded = sum(addedElement);

tOrig = zeros(nElements, 1);
tSwitch = zeros(nElementsNew, 1);
for ir = 1 : nReps
    tOrig = tOrig + 1000 * sim.runWithTimer(tMax, true) / nReps;
    tSwitch = tSwitch + 1000 * simSwitch.runWithTimer(tMax, true) / nReps;
end

tabLabels = [elementLabelsNew(switchedElement); elementLabelsNew(addedElement); {'[other]'; '[total]'}];
tabClassesOrig = [elementClasses(switchElement); repmat({'none'}, [nElementsAdded, 1]); ...
    {sprintf('[%d elements]', nElements - sum(switchElement)); sprintf('[%d elements]', nElements)}];
tabClassesNew = [elementClassesNew(switchedElement); elementClassesNew(addedElement); ...
    {sprintf('[%d elements]', nElementsNew - sum(switchedElement | addedElement)); sprintf('[%d elements]', nElementsNew)}];
tabTOrig = [tOrig(switchElement); NaN(nElementsAdded, 1); sum(tOrig(~switchElement)); sum(tOrig)];
tabTSwitch = [tSwitch(switchedElement); tSwitch(addedElement); ...
    sum(tSwitch(~switchedElement & ~addedElement)); sum(tSwitch)];
tabImproved = tabTOrig > tabTSwitch;

T = table(tabLabels, tabClassesOrig, tabClassesNew, tabTOrig, tabTSwitch, tabImproved, ...
    'VariableNames', {'label', 'class_original', 'class_switched', 'time_original', 'time_switched', 'improved'});

tOrigExt = NaN(nElementsNew, 1);
tOrigExt(~addedElement) = tOrig;
tabClassesOrigExt = repmat({'none'}, [nElementsNew, 1]);
tabClassesOrigExt(~addedElement) = elementClasses;
TAll = table(elementLabelsNew, tabClassesOrigExt, elementClassesNew, tOrigExt, tSwitch, tOrigExt > tSwitch, ...
    'VariableNames', {'label', 'class_original', 'class_switched', 'time_original', 'time_switched', 'improved'});

end





