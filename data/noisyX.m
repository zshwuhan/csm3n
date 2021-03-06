function examples = noisyX(nEx, obsNoise, addBias, binarizeX, dispPlot)
%
% Creates a "noisy X" image segmentation dataset, per Mark Schmidt.
%
% nEx : number of examples to generate
% obsNoise : noise rate for observed variables
% addBias : add bias term to features
% binarizeX : binarize the X values (threshold at 0)
% dispPlot : whether to plot first 2 examples

if nargin < 2
	obsNoise = 0.5;
end
if nargin < 3
	addBias = 0;
end
if nargin < 4
	binarizeX = 0;
end
if nargin < 5
	dispPlot = 0;
end

load data/Ximage.mat
[nRows,nCols] = size(Ximage);
nNode = nRows * nCols;
nStateY = 2;

% Make noisy X instances
Y = reshape(Ximage,[nNode 1]);
Y = repmat(Y,[1 nEx]);
Y = int32(Y > 0.5);
Y = Y + 1;

% noisy observations
obs = (double(Y)-1)*2-1 + obsNoise*randn(size(Y));
% obs = abs((double(Y)-1) - (rand(size(Y))<obsNoise));
X = zeros(nEx,addBias+1+binarizeX,nNode);
for i = 1:nEx
	if ~binarizeX
		xi = obs(:,i);
	else
		xi = [(obs(:,i) <= 0) (obs(:,i) > 0)];
	end
	if addBias
		xi = [ones(nNode,1) xi];
	end
	X(i,:,:) = xi';
end

% plot first example
if dispPlot
	fig = figure();
	figpos = get(fig,'Position');
	figpos(4) = 2*figpos(4);
	set(fig,'Position',figpos);
	subplot(2,1,1);
	imagesc(reshape(Y(:,1),nRows,nCols));
	subplot(2,1,2);
	if ~binarizeX
		imagesc(reshape(obs(:,1),nRows,nCols));
	else
		imagesc(reshape(obs(:,1)>0,nRows,nCols));
	end
	colormap(gray);
	suptitle(sprintf('Example of Noisy X (noiseRate = %f)',obsNoise));
end

% adjacency graph
G = latticeAdjMatrix4(nRows,nCols);

% convert to cell array of examples
examples = cell(nEx,1);
edgeStruct = UGM_makeEdgeStruct(G,nStateY,1);
edgeStruct.edgeDist = UGM_makeEdgeDistribution(edgeStruct,3,[nRows nCols]);
% [Aeq,beq] = pairwiseConstraints(edgeStruct);
for i = 1:nEx
	Xnode = X(i,:,:);
	Xedge = makeEdgeFeatures(Xnode,edgeStruct.edgeEnds);
	examples{i} = makeExample(Xnode,Xedge,Y(:,i),nStateY,edgeStruct,[],[]);
end

