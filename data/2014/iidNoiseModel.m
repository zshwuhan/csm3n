function examples = iidNoiseModel(nEx,nFeat,noiseRate,noiseType,rescale,makeEdgeDist,makeCounts,makePlots)
%
% Loads and processes an example image
%
% nEx : number of examples
% nFeat : number of features
% noiseRate : noise rate
% noiseType : 1) Gaussian (def); 2) Bernoulli (ignores nFeat)
%				If noiseType=Bernoulli, then noiseRate must be in [0,1]
% rescale : rescale rate (def: 1)
% makeEdgeDist : whether to make the edge distribution (def: 1)
% makeCounts : whether to make the convexified Bethe counting numbers (def: 1)
% makePlots : whether to plot the source and noisy images (def: 0)

if ~exist('noiseType','var')
	noiseType = 1;
end
if ~exist('rescale','var')
	rescale = 1;
end
if ~exist('makeEdgeDist','var')
	makeEdgeDist = 1;
end
if ~exist('makeCounts','var')
	makeCounts = 1;
end
if ~exist('makePlots','var')
	makePlots = 0;
end

% Load image and convert grayscale to BW
srcimg = imread('2014.bmp','bmp');
srcimg = rgb2gray(srcimg);
if rescale ~= 1
	srcimg = imresize(srcimg,rescale);
end
[nRows,nCols,~] = size(srcimg);
srcimg = srcimg > 250;

% Ground truth
Ynode = srcimg(:) + 1;
nNode = length(Ynode);

if noiseType == 1
	% i.i.d. Gaussian noise
	Xnode = zeros(nEx,nFeat,nNode);
	for i = 1:nEx
		noisyimg = srcimg*2-1 + noiseRate*randn(size(srcimg));
		if nFeat == 1
			Xnode(i,1,:) = reshape(noisyimg,1,1,nNode);
		else
			noisyimg = min(max((noisyimg+noiseRate)/(2*noiseRate),0),1);
			[~,bins] = histc(noisyimg,linspace(0,1,nFeat));
			for n = 1:nNode
				Xnode(i,bins(n),n) = 1;
			end
		end
	end
else
	% i.i.d. Bernouli noise
	Xnode = zeros(nEx,2,nNode);
	for i = 1:nEx
		noisyimg = abs(srcimg - (rand(size(srcimg)) < noiseRate));
	% 	noisyimg = (srcimg*2-1 + noiseRate*randn(size(srcimg))) > 0;
		Xnode(i,:,:) = [noisyimg(:)==0 noisyimg(:)==1]';
	end
end

% Plots
if makePlots
	fig = figure(makePlots);
	subplot(1,2,1);
	imagesc(srcimg);
	subplot(1,2,2);
	imagesc(noisyimg); % plot last noisy observation
	colormap(gray);
	figPos = get(fig,'Position');
	figPos(3) = 2*figPos(3);
	set(fig,'Position',figPos);
end

% Structural data
G = latticeAdjMatrix4(nRows,nCols);
edgeStruct = UGM_makeEdgeStruct(G,2,1);
edgeStruct.nRows = nRows; edgeStruct.nCols = nCols;
if makeEdgeDist
	edgeStruct.edgeDist = UGM_makeEdgeDistribution(edgeStruct,3,[nRows nCols]);
end
if makeCounts == 1
	[edgeStruct.nodeCount,edgeStruct.edgeCount] = UGM_ConvexBetheCounts(edgeStruct,1,.1,1);
	edgeStruct.momentum = 1;
elseif makeCounts == 2
	[edgeStruct.nodeCount,edgeStruct.edgeCount] = UGM_ConvexBetheCounts2(edgeStruct,1);
	edgeStruct.momentum = 1;
end

% Make examples
examples = cell(nEx,1);
for i = 1:nEx
	Xedge = UGM_makeEdgeFeatures(Xnode(i,:,:),edgeStruct.edgeEnds);
	examples{i} = makeExample(Xnode(i,:,:),Xedge,Ynode,2,edgeStruct,[],[]);
end
