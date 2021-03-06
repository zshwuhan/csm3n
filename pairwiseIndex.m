function inds = pairwiseIndex(e, s1, s2, nNode, nState)

% Returns the indices of the pairwise terms for the i'th edge, where:
% e : edge index
% s1 : state(s) of variable i
% s2 : state(s) of variable j
% nNode : number of local variables
% nState : number of states per variable

inds = nNode*nState + (e-1)*nState^2 + bsxfun(@plus, (s1'-1).*nState, s2);
inds = inds(:);

