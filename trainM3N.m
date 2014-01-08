function [w, fAvg] = trainM3N(examples, decodeFunc, C, maxIter, w)
%
% Trains an MRF using max-margin formulation.
%
% examples : cell array of examples
% decodeFunc : decoder function
% C : regularization constant or nParam x 1 vector (optional: def=nNode of first example)
% maxIter : max. number of iterations of SGD (optional: def=10*length(examples))
% w : init weights (optional: def=zeros)

% parse input
assert(nargin >= 2, 'USAGE: trainM3N(examples,decodeFunc)')
if nargin < 3
	C = examples{1}.nNode;
end
if nargin < 4
	maxIter = 10 * length(examples);
end
if nargin < 5
	nParam = max(examples{1}.edgeMap(:));
	w = zeros(nParam,1);
end

% SGD
options.maxIter = maxIter;
options.stepSize = 1e-4;
% options.verbose = 1;
objFun = @(x,ex) l2M3N(x,ex,decodeFunc,C); % TODO: get avg loss from l2M3N
[w,fAvg] = sgd(examples,objFun,w,options);


% Subroutine for L2-regularized M3N objective
function [f, g] = l2M3N(w, ex, decodeFunc, C)
	
	% compute M3N objective
	[loss,g] = UGM_M3N_Obj(w,ex.Xnode,ex.Xedge,ex.Y',ex.nodeMap,ex.edgeMap,ex.edgeStruct,decodeFunc);
	
	% average loss
% 	lossAvg = (1/t) * loss + ((t-1)/t) * lossAvg;
	
	% L2 regularization
	f = loss + 0.5 * (C.*w)' * w;
	g = g + C.*w;
		
