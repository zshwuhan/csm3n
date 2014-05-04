function synthPlots(expSetup,cvErrs,teErrs,params,plotFolds,plotKappa,plotErrorBars)
%
% Plots results of synethetic experiment
%
	
% Experiment variables
if isfield(expSetup,'foldIdx')
	nFold = length(expSetup.foldIdx);
else
	nFold = expSetup.nFold;
end
Cvec = expSetup.Cvec;
kappaVec = expSetup.kappaVec;

m3nIdx = find(expSetup.runAlgos==2);
vctsmIdx = find(expSetup.runAlgos==4);
sctsmIdx = find(expSetup.runAlgos==5);

% Which trials to use
if ~exist('plotFolds','var') || isempty(plotFolds)
	plotFolds = 1:nFold;
end
if ~exist('plotKappa','var') || isempty(plotKappa)
	plotKappa = 1:length(kappaVec);
end

% Error bars?
if ~exist('plotErrorBars','var') || isempty(plotErrorBars)
	plotErrorBars = 0;
end


%% Compute stats

% Best error and norm of weights (SCTSM only)
bestErr = zeros(3,length(plotFolds),length(plotKappa));
normW = zeros(length(plotFolds),length(plotKappa));
for f = 1:length(plotFolds)
	% M3N
	[~,minIdx] = min(cvErrs(m3nIdx,plotFolds(f),:));
	[c1idx,c2idx] = ind2sub([size(cvErrs,3),size(cvErrs,4)],minIdx);
	bestErr(1,f,1) = teErrs(m3nIdx,plotFolds(f),c1idx,c2idx);
	
	% VCTSM
	[~,minIdx] = min(cvErrs(vctsmIdx,plotFolds(f),:,1));
	bestErr(2,f,1) = teErrs(vctsmIdx,plotFolds(f),minIdx,1);

	% SCTSM
	for k = 1:length(plotKappa)
		[~,minIdx] = min(cvErrs(sctsmIdx,plotFolds(f),:,plotKappa(k)));
		bestErr(3,f,k) = teErrs(sctsmIdx,plotFolds(f),minIdx,plotKappa(k));
		normW(f,k) = norm(params{sctsmIdx,plotFolds(f),minIdx,plotKappa(k)}.w)^2;
	end
end
avgErr = squeeze(mean(bestErr,2));
stdErr = squeeze(std(bestErr,0,2));
avgNormW = mean(normW,1)';


%% Plots

fig = figure();
figPos = get(fig,'Position');
figPos(3) = 2*figPos(3);
set(fig,'Position',figPos);

subplot(1,2,1);
hold on;
if plotErrorBars
	% M3N
	errorbar(kappaVec(plotKappa),repmat(avgErr(1,1),length(plotKappa),1),stdErr(1,:)*ones(length(plotKappa)),'r--');
	% VCTSM
	errorbar(kappaVec(plotKappa),repmat(avgErr(2,1),length(plotKappa),1),stdErr(2,:)*ones(length(plotKappa)),'b-.');
	% SCTSM
	errorbar(kappaVec(plotKappa),avgErr(3,:)',stdErr(3,:),'g');
else
	% M3N
	plot(kappaVec(plotKappa),repmat(avgErr(1,1),length(plotKappa),1),'r--');
	% VCTSM
	plot(kappaVec(plotKappa),repmat(avgErr(2,1),length(plotKappa),1),'b-.');
	% SCTSM
	plot(kappaVec(plotKappa),avgErr(3,:)','g');
end
title('Convexity vs. Test Error');
xlabel('log(kappa)'); ylabel(sprintf('test error (avg %d folds)',nFold));
legend({'SCTSM','M3N','VCTSM'},'Location','East');
set(gca,'xscale','log');
axis tight
hold off;

subplot(1,2,2);
plot(kappaVec(plotKappa),avgNormW,'g');
title('Convexity vs. Norm of Weights (SCTSM)');
xlabel('kappa');
ylabel(sprintf('Local ||w||^2 (avg %d folds)',nFold));
