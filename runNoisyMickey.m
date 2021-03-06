%% Noisy Mickey experiment
%
% Variables:
%   nFold (def: 10)
%   noiseRate (def: .2)
%   runAlgos (def: [4 5 7])
%   inferFunc (def: UGM_Infer_CountBP)
%   decodeFunc (def: UGM_Decode_LBP)
%   convexity (def: 1)
%   Cvec (def: [.0001 .00025 .0005 .001 .0025 .005 .01 .025 .05 .1])
%   kappaVec (def: [.01 .02 .05 .075 .1 .2 .5 .75 1])
%   save2file (def: will not save)
%   makePlots (def: 0)

if ~exist('nFold','var')
	nFold = 10;
end
if ~exist('noiseRate','var')
	noiseRate = .2;
end
if ~exist('runAlgos','var')
	runAlgos = [4 5 7];
end
if ~exist('inferFunc','var')
	inferFunc = @UGM_Infer_CountBP;
end
if ~exist('decodeFunc','var')
	decodeFunc = @UGM_Decode_LBP;
end
if ~exist('convexity','var')
	convexity = 1;
end
if ~exist('Cvec','var')
	Cvec = [.0001 .00025 .0005 .001 .0025 .005 .01 .025 .05 .1];
end
if ~exist('kappaVec','var')
	kappaVec = [.01 .02 .05 .075 .1 .2 .5 .75 1];
end
if ~exist('makePlots','var')
	makePlots = 0;
end


if makePlots
	dataFig = 101;
	objFig = 102;
	predFig = 103;
else
	dataFig = 0;
	objFig = 0;
	predFig = 0;
end

% seed the RNG
rng(0);

% create the folds
nTrain = 1;
nCV = 1;
nTest = 10;
for f = 1:nFold
	sidx = (f-1)*(nTrain+nCV+nTest);
	foldIdx(f).tridx = sidx+1:sidx+nTrain;
	foldIdx(f).ulidx = [];
	foldIdx(f).cvidx = sidx+nTrain+1:sidx+nTrain+nCV;
	foldIdx(f).teidx = sidx+nTrain+nCV+1:sidx+nTrain+nCV+nTest;
end

% create the data
cd data/mickey;
nFeat = 2;
noiseType = 2;
scale = .5;
[examples] = iidNoiseModel(nFold*(nTrain+nCV+nTest),nFeat,...
						   noiseRate,noiseType,scale,1,2,convexity,dataFig);
cd ../..;

% add RCN to training examples
if exist('rcnRate','var')
	for f = 1:nFold
		for i = foldIdx(f).tridx
			y = double(examples{i}.Y) - 1;
			y = abs(y - (rand(size(y)) < rcnRate));
			examples{i}.Y = int32(y) + 1;
			examples{i}.Ynode = overcompleteRep(examples{i}.Y,2,0);
		end
	end
end

expSetup = struct('foldIdx',foldIdx ...
				 ,'runAlgos',runAlgos ...
				 ,'decodeFunc',decodeFunc,'inferFunc',inferFunc ...
				 ,'Cvec',Cvec ...
				 ,'kappaVec',kappaVec ...
				 ,'computeBaseline',1 ...
				 );
maxIter = 1000;
expSetup.optSGD = struct('maxIter',maxIter ...
						,'plotObj',objFig,'plotRefresh',10 ...
						,'verbose',0,'returnBest',1);
expSetup.optLBFGS = struct('Display','off','verbose',0 ...
						  ,'MaxIter',maxIter,'MaxFunEvals',maxIter);
expSetup.plotPred = predFig;

if exist('save2file','var')
	expSetup.save2file = save2file;
end

experiment;
