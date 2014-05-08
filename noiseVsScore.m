function noiseVsScore(filenames,noiseRates,scoreIdx,scoreName)

algoNames = {'MM','VCMM','SCMM'};
m3nIdx = 3;
vctsmIdx = 1;
sctsmIdx = 2;

errs = zeros(3,length(noiseRates));
stds = zeros(3,length(noiseRates));
% kappas = zeros(1,length(noiseRates));
for f = 1:length(filenames)
	load(filenames{f},'avgResults','stdResults','nFold','bestParam','params');
	errs(:,f) = avgResults(:,scoreIdx);
	stds(:,f) = stdResults(:,scoreIdx);
% 	for fold = 1:nFold
% 		kappas(f) = kappas(f) + params{2,fold,bestParam(2,fold)}.kappa;
% 	end
% 	kappas(f) = kappas(f) / nFold;
end

figure();
errorbar(noiseRates,errs(m3nIdx,:),stds(1,:),'r--','MarkerSize',16,'LineWidth',1.2);
hold on;
errorbar(noiseRates,errs(vctsmIdx,:),stds(2,:),'b--','MarkerSize',10,'LineWidth',1.2);
errorbar(noiseRates,errs(sctsmIdx,:),stds(3,:),'g--','MarkerSize',14,'LineWidth',1.2);
legend('MM','VCMM','SCMM','Location','SouthEast');
xlabel('noise rate','FontSize',18);
ylabel(sprintf('%s (avg %d folds)',scoreName,nFold),'FontSize',18);
axis tight;
hold off;
