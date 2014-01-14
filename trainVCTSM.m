function [w, kappa, fAvg] = trainVCTSM(examples, C, maxIter, w, kappa)

% Optimizes the VCTSM objective, learning the optimal (w,kappa).
%
% examples : nEx x 1 cell array of examples, each containing:
%	oc : full overcomplete vector representation of Y
%		 (including high-order terms)
%	ocLocalScope : number of local terms in oc
%	Aeq : nCon x length(oc) constraint A matrix
%	beq : nCon x 1 constraint b vector
%	Fx : nParam x length(oc) feature map
%	suffStat : nParam x 1 vector of sufficient statistics (i.e., Fx * oc)
% C : regularization constant or vector
% maxIter : max. number of iterations of SGD (optional: def=10*length(examples))
% w : init weights (optional: def=zeros)
% kappa : init kappa (optional: def=1)

% parse input
assert(nargin >= 1, 'USAGE: trainVCTSM(examples)')

nEx = length(examples);
nParam = max(examples{1}.edgeMap(:));
nCon = 0;
for i = 1:nEx
	nCon = nCon + length(examples{i}.beq);
end

if nargin < 2
	C = examples{1}.nNode;
end
if nargin < 3
	maxIter = 10 * length(examples);
end
if nargin < 4
	w = zeros(nParam,1);
end
if nargin < 5
	kappa = 1;
end

% initial position
x0 = [w ; kappa ; zeros(nCon,1)];

% SGD
options.maxIter = maxIter;
options.stepSize = 1e-6;
% options.verbose = 1;
objFun = @(x,ex) vctsmObj(x,{ex},C);
[x,fAvg] = sgd(examples,objFun,x0,options);

% parse optimization output
w = x(1:nParam);
kappa = exp(x(nParam+1));
% lambda = x(nParam+2:end);


