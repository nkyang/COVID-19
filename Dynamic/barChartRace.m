function handle_barplot = barChartRace(v,inputs,options)

arguments
    v VideoWriter
    inputs {mustBeNumericTableTimetable(inputs)}
    options.Time (:,1) {mustBeTimeInput(options.Time,inputs)} = setDefaultTime(inputs)
    options.LabelNames {mustBeVariableLabels(options.LabelNames,inputs)} = setDefaultLabels(inputs)
    options.NumDisplay (1,1) double {mustBeInteger,mustBeNonzero} = length(setDefaultLabels(inputs));
    options.NumInterp (1,1) double {mustBeInteger,mustBeNonzero} = 2;
    options.Method char {mustBeMember(options.Method,{'linear','spline'})} = 'linear'
    options.GenerateGIF (1,1) {mustBeNumericOrLogical} = false
    options.GenerateMovie (1,1) {mustBeNumericOrLogical} = false
    options.Outputfilename char {mustBeNonempty} = 'output.gif'
    options.XlabelName char = ""
    options.IsInteger (1,1) {mustBeNumericOrLogical} = true
    options.FontSize (1,1) double {mustBeInteger,mustBeNonzero,mustBeNonNan} = 15
    options.FontName char = "微软雅黑"
    options.DisplayFontSize (1,1) {mustBeInteger,mustBeNonzero} = 24
    options.YTickLabelRotation (1,1) {mustBeNumericOrLogical} = 0
    options.Position (1,4) {mustBeNumeric,mustBeNonzero} = get(0, 'DefaultFigurePosition')
    options.GIFDelayTime (1,1) {mustBeNumeric,mustBeNonzero} = 0.05
    options.Footnote char = "Visualized by MATLAB"
end

if isa(inputs,'timetable') || isa(inputs,'table')
    data = inputs.Variables;
elseif isa(inputs,'double')
    data = inputs;
end

time = options.Time;
LabelNames = string(options.LabelNames);
Outputfilename = options.Outputfilename;
NumInterp = options.NumInterp;
Method = options.Method;
XlabelName = options.XlabelName;
IsInteger = options.IsInteger;
NumDisplay = options.NumDisplay;

nVariables = length(LabelNames); % Number of items

%% Ranking of each variable (names) at each time step
rankings = zeros(size(data,1),NumDisplay);
data = reshape(data,size(data,1),3 ,[]);
data = permute(data,[1 3 2]);
data = cat(3,data(:,:,1),data(:,:,3),data(:,:,2));
data_all = squeeze(sum(data,3));

for ii=1:size(data,1)
    [~,tmp] = sort(data_all(ii,:),'descend');
    rankings(ii,tmp) = 1:nVariables;
end

%% Interpolation: Generate nInterp data point in between
time2plot = linspace(time(1),time(end),length(time)*NumInterp);
ranking2plot = interp1(time,rankings,time2plot,Method);
data2plot = interp1(time,data,time2plot,Method);

%% Let's create Bar Chart
handle_barplot = figure;
handle_barplot.Position = options.Position;
handle_axes = gca;
hold(handle_axes,'on');
handle_axes.XGrid = 'on';
handle_axes.XMinorGrid = 'on';

% Some visual settings
handle_axes.FontSize = options.FontSize;
handle_axes.FontName = options.FontName;
handle_axes.YTickLabelRotation = options.YTickLabelRotation;
handle_axes.YAxis.Direction = 'reverse'; % rank 1 needs to be on the top
handle_axes.YLim = [0, NumDisplay+0.5];

defaultWidth = 0.8; % Default BarWidth

%% Plot the initial data (time = 1)
ranking = ranking2plot(1,:);
value2plot = squeeze(data2plot(1,:,:));

% Create bar plot
handle_bar = barh(ranking, value2plot,'stacked');

% Fix the BarWidth
scaleWidth = min(diff(sort(ranking)));
handle_bar(1).BarWidth = defaultWidth/scaleWidth;
handle_bar(2).BarWidth = defaultWidth/scaleWidth;
handle_bar(3).BarWidth = defaultWidth/scaleWidth;

% Set YTick position by ranking
% Set YTickLabel with variable names
[ytickpos,idx] = sort(ranking,'ascend');
handle_axes.YTick = ytickpos;
handle_axes.YTickLabel = LabelNames(idx);

% Better to fix XLim
% Here I set maxValue time 1.5. (can be anything)
maxValue = max(sum(value2plot,2));
handle_axes.XLim = [0, maxValue*1.12];
handle_axes.XAxisLocation = 'top';

% Add value string next to the bar
if IsInteger
    displayText = string(round(sum(value2plot(idx,:),2)));
else
    displayText = string(sum(value2plot(idx,:),2));
end
xTextPosition = sum(value2plot(idx,:),2) + maxValue*0.02;
yTextPosition = ytickpos;

% NumDisplay values are used
xTextPosition = xTextPosition(1:NumDisplay);
yTextPosition = yTextPosition(1:NumDisplay);
displayText = displayText(1:NumDisplay);
handle_text = text(xTextPosition,yTextPosition,displayText,...
    'FontName',options.FontName,...
    'FontSize',options.FontSize);

% Display time
handle_timeText = text(0.9,0.1,string(time2plot(1)),'HorizontalAlignment','right',...
    'Units','normalized','FontSize', options.DisplayFontSize,'FontName',options.FontName);
handle_axes.XLabel.String = XlabelName;

% Display created by MATLAB message
nlines = length(string(options.Footnote));
text(0.99,0.02*nlines,string(options.Footnote),'HorizontalAlignment','right',...
    'Units','normalized','FontSize', 12,'Color',0.5*[1,1,1]);

% legend
legend('死亡','现存确诊','治愈','FontName','宋体','FontSize',18,'Location','east');

handle_bar(1).FaceColor = [0.850 0.325 0.098];
handle_bar(2).FaceColor = [0.929 0.694 0.125];
handle_bar(3).FaceColor = [0     0.447 0.741];
%% From the 2nd step and later
for ii=2:length(ranking2plot)
    
    ranking = ranking2plot(ii,:);
    value2plot = squeeze(data2plot(ii,:,:));
    
    % barh gives an error if ranking has duplicate values
    % Thus skip it.
    if length(unique(ranking)) < nVariables
        continue;
    end
    
    % Fix the BarWidth
    scaleWidth = min(diff(sort(ranking)));
    handle_bar(1).BarWidth = defaultWidth/scaleWidth;
    handle_bar(2).BarWidth = defaultWidth/scaleWidth;
    handle_bar(3).BarWidth = defaultWidth/scaleWidth;
    
    % Set to new data
    handle_bar(1).XData = ranking;
    handle_bar(2).XData = ranking;
    handle_bar(3).XData = ranking;
    handle_bar(1).YData = value2plot(:,1);
    handle_bar(2).YData = value2plot(:,2);
    handle_bar(3).YData = value2plot(:,3);
    
    % Set YTick position by ranking
    % Set YTickLabel with variable names
    [ytickpos,idx] = sort(ranking,'ascend');
    handle_axes.YTick = ytickpos;
    handle_axes.YTickLabel = LabelNames(idx);
    
    % Better to fix XLim
    maxValue = max(sum(value2plot,2));
    handle_axes.XLim = [0, maxValue*1.12];
    
    % Add value string next to the bar
    xTextPosition = sum(value2plot(idx,:),2) + maxValue*0.02;
    tmp = sum(value2plot(idx,:),2); % data to display
    for jj = 1:NumDisplay
        handle_text(jj).Position = [xTextPosition(jj), ytickpos(jj)];
        if IsInteger
            handle_text(jj).String = string(round(tmp(jj))); % Modified
        else
            handle_text(jj).String = string(tmp(jj));
        end
    end
    
    % Display the original time stamp (or index)
    handle_timeText.String = string(time(ceil(ii/NumInterp)));
    
    if options.GenerateGIF
        frame = getframe(gcf); 
        tmp = frame2im(frame); 
        [A,map] = rgb2ind(tmp,256); 
        if ii == 2 
            imwrite(A,map,Outputfilename,'gif','LoopCount',Inf,'DelayTime',options.GIFDelayTime);
        else 
            imwrite(A,map,Outputfilename,'gif','WriteMode','append','DelayTime',options.GIFDelayTime);
        end
    end
    
    if options.GenerateMovie
        frame = getframe(gcf);
        tmp = frame2im(frame); 
        writeVideo(v,tmp);
    end
    
end

hold(handle_axes,'off');

end