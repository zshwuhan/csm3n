function [w, fAvg] = trainCSM3N(examples_l, examples_u, decodeFunc, C_w, C_s, maxIter, w)
%
% M3N training with stability regularization.
%
% examples_l : cell array of labeled examples
% examples_u : cell array of unlabeled examples
% decodeFunc : decoder function
% C_w : weight regularization constant or nParam x 1 vector (optional: def=nNode of first example)
% C_s : stability regularization constant (optional: def=0.1)
% maxIter : max. number of iterations of SGD (optional: def=10*length(examples))
% w : init weights (optional: def=zeros)

% parse input
assert(nargin >= 3, 'USAGE: trainM3N(examples_l,examples_u,decodeFunc)')
if nargin < 4
	C_w = examples_l{1}.nNode;
end
if nargin < 5
	C_s = 0.1;
end
if nargin < 6
	maxIter = 10 * length(examples_l);
end
if nargin < 7
	nParam = max(examples_l{1}.edgeMap(:));
	w = zeros(nParam,1);
end

% SGD
options.maxIter = maxIter;
options.stepSize = 1e-4;
options.verbose = 1;
objFun = @(x,ex) csm3nSGDObj(x,ex,examples_u,decodeFunc,C_w,C_s);
[w,fAvg] = sgd(examples_l,objFun,w,options);


% Subroutine for L2-regularized M3N objective
function [f, g] = csm3nSGDObj(w, ex_l, examples_u, decodeFunc, C_w, C_s)
	
	% pick random unlabeled point
	i = ceil(rand() * length(examples_u));
	ex_u = examples_u{i};
	
	% compute CSM3N objective
	[f,g] = csm3nObj(w,{ex_l},{ex_u},decodeFunc,C_w,C_s);

