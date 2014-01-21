function [w, fAvg] = trainCACC(examples, decodeFunc, C, optSGD, optPGD, w)
%
% Trains an MRF using CACC.
%
% examples : cell array of examples
% decodeFunc : decoder function
% C : regularization constant or nParam x 1 vector (optional: def=nNode of first example)
% optSGD : optional struct of optimization options for SGD:
% 			maxIter : iterations of SGD (def: 10*length(examples_l))
% 			stepSize : SGD step size (def: 1e-4)
% 			verbose : verbose mode (def: 0)
% optPGD : optional struct of optimization options for stabilityObj
% w : init weights (optional: def=zeros)

% parse input
assert(nargin >= 2, 'USAGE: trainM3N(examples,decodeFunc)')
if nargin < 3
	C = examples{1}.nNode;
end
if nargin < 4 || ~isstruct(optSGD)
	optSGD = struct();
end
if ~isfield(optSGD,'maxIter')
	optSGD.maxIter = 10 * length(examples);
end
if ~isfield(optSGD,'stepSize')
	optSGD.stepSize = 1e-4;
end
if ~isfield(optSGD,'verbose')
	optSGD.verbose = 0;
end
if nargin < 5
	optPGD = struct();
end
if nargin < 6
	nParam = max(examples{1}.edgeMap(:));
	w = zeros(nParam,1);
end

% SGD
objFun = @(x,ex) caccObj(x,{ex},decodeFunc,C,optPGD);
[w,fAvg] = sgd(examples,objFun,w,optSGD);
		