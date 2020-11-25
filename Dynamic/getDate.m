function date = getDate(f)
date = linspace(datetime,datetime+1,numel(f));
for i = 1:numel(f)
    date(i) = datetime(datestr(f(i).name(1:10),'yyyy/mm/dd'));
end
end