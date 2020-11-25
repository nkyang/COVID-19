function data = getReport(f,ctyList)
China = categorical({'Mainland China','Hong Kong','Macau','Taiwan'});
function x = isChina(x)
if iscategory(China,x)
    x = 'China';
end
end
report = readtable(f,'ReadVariableNames',true);
% 对无数据的地区补零
report = fillmissing(report,'constant',0,...
    'DataVariables',{'Confirmed','Deaths','Recovered'});
% 一个中国
report(:,'Country') = rowfun(@isChina,report,'InputVariables','Country_Region');
% 累加相同国家的数据
report = varfun(@sum, report, 'GroupingVariables','Country',...
    'InputVariables',{'Confirmed','Deaths','Recovered'});
% 计算当前接受治疗人数
report.Active = report.sum_Confirmed - report.sum_Deaths - report.sum_Recovered;
tmp1 = ismember(report.Country,ctyList);
tmp2 = ismember(ctyList,report.Country);
data = zeros(3,numel(ctyList));
data(:,tmp2) = report{tmp1,4:end}';
[c,d] = ismember('South Korea',report.Country);
if c
    data(:,12) = report{d,4:end}';
end
end
