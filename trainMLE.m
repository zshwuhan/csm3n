function [w, nll] = trainMLE(examples, inferFunc, C, maxIter, w)
%
% Trains an MRF using MLE.
%
% examples : cell array of examples
% inferFunc : inference function (0: use pseudolikelihood)
% C : regularization constant or nParam x 1 vector (optional: def=nNode of first example)
% maxIter : max. number of iterations of SGD (optional: def=10*length(examples))
% w : init weights (optional: def=zeros)

% parse input
assert(nargin >= 2, 'USAGE: trainM3N(examples,inferFunc)')
usePL = ~isa(inferFunc,'function_handle');
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

% L2-regularized NLL objective
if length(C) == 1
	C = C * ones(size(w));
end
if usePL
	objFun = @(w,ex) penalizedL2(w,@UGM_CRFcell_PseudoNLL,C,{ex});
else
	objFun = @(w,ex) penalizedL2(w,@UGM_CRFcell_NLL,C,{ex},inferFunc);
end

% SGD
options.maxIter = maxIter;
options.stepSize = 1e-4;
% options.verbose = 1;
[w,fAvg] = sgd(examples,objFun,w,options);

% NLL of learned model
if usePL
	nll = UGM_CRFcell_PseudoNLL(w,examples);
else
	nll = UGM_CRFcell_NLL(w,examples,inferFunc);
end

		
