function [w, f] = trainSCTSM_lbgfs(examples, inferFunc, kappa, C, options, w)

% Optimizes the VCTSM objective, learning the optimal (w,kappa).
%
% examples : nEx x 1 cell array of examples, each containing:
%	Fx : nParam x length(oc) feature map
%	suffStat : nParam x 1 vector of sufficient statistics (i.e., Fx * oc)
%	Ynode : nState x nNode overcomplete matrix representation of labels
% inferFunc : inference function used for convexified inference
% kappa : modulus of convexity
% C : optional regularization constant or vector (def: 1)
% options : optional struct of optimization options for LBFGS:
%			Important options (for complete list, see minFunc)
%				Display : display mode
%				MaxIter : maximum iterations
%				MaxFunEvals : maximum function evals
% w : init weights (optional: def=zeros)

% parse input
assert(nargin >= 3, 'USAGE: trainSCTSM(examples,inferFunc,kappa)')

nEx = length(examples);
nParam = max(examples{1}.edgeMap(:));

if ~exist('C','var') || isempty(C)
	C = 1;
end

if ~exist('options','var') || ~isstruct(options)
	options = struct();
end
options.Method = 'lbfgs';
if ~isfield(options,'Display')
	options.Display = 'off';
end

if ~exist('w','var') || isempty(w)
	w = zeros(nParam,1);
end

if ~exist('kappa','var') || isempty(kappa)
	kappa = 1;
end

% run optimization
objFun = @(x, varargin) sctsmObj(x, examples, C, inferFunc, kappa, varargin{:});
[w,f] = minFunc(objFun, w, options);
