function [f, sg, x_p, y_p] = stabilityObj(w, ex, y_u, decodeFunc, options, varargin)
% 
% Computes the stability regularization objective and gradient.
% 
% w : nParam x 1 vector of weights
% ex : an (unlabeled) example
% y_u : predicted (or true) label for ex
% decodeFunc : decoder function
% options : optional struct of options:
%			edgeFeatFunc : function to generate edge features
% 			maxIter : iterations of PGD (def: 10)
% 			stepSize : PGD step size (def: 1e-3)
% 			verbose : verbose mode (def: 0)
% 			plotObj : plot stability objective (def: 0)

if nargin < 5 || ~isstruct(options)
	options = struct();
end
if ~isfield(options,'edgeFeatFunc')
	options.edgeFeatFunc = @makeEdgeFeatures;
end
if ~isfield(options,'maxIter')
	options.maxIter = 10;
end
if ~isfield(options,'stepSize')
	options.stepSize = 1e-3;
end
if ~isfield(options,'verbose')
	options.verbose = 0;
end
if ~isfield(options,'plotObj')
	options.plotObj = 0;
end

nodeMap = ex.nodeMap;
edgeMap = ex.edgeMap;
edgeStruct = ex.edgeStruct;
edgeEnds = edgeStruct.edgeEnds;
[nNode,nState,nNodeFeat] = size(nodeMap);
nEdge = size(edgeEnds,1);

x_u = ex.Xnode(:);
yoc_u = overcompletePairwise(y_u,edgeStruct);
Ynode_u = reshape(yoc_u(1:(nNode*nState)),nState,nNode);

%% FIND WORST PERTURBATION

% init perturbation to current x, with buffer
x0 = x_u;%min(max(x_u,.00001),.99999);

% perturbation objective
objFun = @(x,varargin) perturbObj(x,w,yoc_u,Ynode_u,nodeMap,edgeMap,edgeStruct,options.edgeFeatFunc,decodeFunc,varargin{:});

% projection function
projFun = @(x) perturbProj(x,x_u);

% % check gradient calculations
% fastDerivativeCheck(objFun,x0);
% return;

% find worst perturbation using PGD
[x_p,f,fVec] = pgd(objFun,projFun,x0,options);

% convert min to max
f = -f;


%% GRADIENT w.r.t. WEIGHTS

% reconstruct Xnode,Xedge from x_p
Xnode_p = reshape(x_p, 1, nNodeFeat, nNode);
Xedge_p = options.edgeFeatFunc(Xnode_p,edgeEnds);
nEdgeFeat = size(Xedge_p,2);

% loss-augmented inference for perturbed input
y_p = lossAugInfer(w,Xnode_p,Xedge_p,Ynode_u,nodeMap,edgeMap,edgeStruct,decodeFunc,varargin{:});
yoc_p = overcompletePairwise(y_p,edgeStruct);

% compute (sub)gradient w.r.t. w
sg = zeros(size(w));
widx = reshape(nodeMap(1,:,:),nState,nNodeFeat);
yidx = localIndex(1,1:nState,nState);
for i = 1:nNode
	dy = yoc_p(yidx) - yoc_u(yidx);
	sg(widx) = sg(widx) + dy * Xnode_p(1,:,i);
	yidx = yidx + nState;
end
widx = reshape(edgeMap(:,:,1,:),nState^2,nEdgeFeat);
yidx = pairwiseIndex(1,1:nState,1:nState,nNode,nState);
for e = 1:size(edgeEnds,1)
	dy = yoc_p(yidx) - yoc_u(yidx);
	sg(widx) = sg(widx) + dy * Xedge_p(1,:,e);
	yidx = yidx + nState^2;
end


%% LOG

if options.verbose
	[mxv,mxi] = max(abs(x_u-x_p));
	fprintf('Worst perturbation: (%d, %f)\n', mxi,mxv);
	fprintf('Perturbation objective: %f\n', f);
	fprintf('Stability (L1-distance): %f\n', norm(yoc_u-yoc_p,1));
end

if options.plotObj
	plot(1:length(fVec),fVec);
end


%% PERTURBATION OBJECTIVE

function [f, g] = perturbObj(x, w, yoc_u, Ynode_u, nodeMap, edgeMap, edgeStruct, edgeFeatFunc, decodeFunc, varargin)

	edgeEnds = edgeStruct.edgeEnds;
	[nNode,nState,nNodeFeat] = size(nodeMap);
	nEdge = size(edgeEnds,1);

	% reconstruct Xnode,Xedge from x
	Xnode_p = reshape(x, 1, nNodeFeat, nNode);
	Xedge_p = edgeFeatFunc(Xnode_p,edgeEnds);
	nEdgeFeat = size(Xedge_p,2);
	
	% loss-augmented inference for perturbed input
	y_p = lossAugInfer(w,Xnode_p,Xedge_p,Ynode_u,nodeMap,edgeMap,edgeStruct,decodeFunc,varargin{:});
	yoc_p = overcompletePairwise(y_p,edgeStruct);

	% L1 distance between predictions
	stab = norm(yoc_u - yoc_p, 1);
	
	% objective/gradient w.r.t. x
	f = 0;
	g = zeros(nNodeFeat,nNode);
	Wnode = reshape(w(nodeMap(1,:,:)),nState,nNodeFeat)';
	yidx = localIndex(1,1:nState,nState);
	for i = 1:nNode
		dy = yoc_p(yidx) - yoc_u(yidx);
		f = f + sum(sum( Wnode .* (Xnode_p(1,:,i)' * dy') ));
		g(:,i) = Wnode * dy;
		yidx = yidx + nState;
	end
	Wedge = w(reshape(edgeMap(:,:,1,:),nState^2,nEdgeFeat)');
	yidx = pairwiseIndex(1,1:nState,1:nState,nNode,nState);
	for e = 1:size(edgeEnds,1)
		i = edgeEnds(e,1);
		j = edgeEnds(e,2);
		dy = yoc_p(yidx) - yoc_u(yidx);
		f = f + sum(sum( Wedge .* (Xedge_p(1,:,e)' * dy') ));
		% following lines assume that edge-specific features occur
		% after concatenation of edge features.
		g(:,i) = g(:,i) + Wedge(1:nNodeFeat,:) * dy;
		g(:,j) = g(:,j) + Wedge(nNodeFeat+1:2*nNodeFeat,:) * dy;
		yidx = yidx + nState^2;
	end

	% convert max to min
	f = -(f + stab);
	g = -g(:);

%% PERTURBATION PROJECTION

function x_p = perturbProj(v, x_u)

	x_p = projectOntoL1Ball(v - x_u, 1);
	x_p = x_p + x_u;

	
