function SerialPlot_20b_Timer(COMport, DataType, NumSamples, BaudRate, Ncx)
global COMdevice
t = timer;
t.StartFcn = @StartFcn;
t.TimerFcn = @TimerFcn;
t.StopFcn = @StopFcn;
% t.Period = 0;
% t.busymode='error';
t.StartDelay=.1;  % provide enough delay to not block the callback.
% t.TasksToExecute = 2;
t.ExecutionMode = 'singleShot';
t.UserData.COMport=COMport;
t.UserData.DataType=DataType;
t.UserData.NumSamples=NumSamples;
t.UserData.BaudRate=BaudRate;
t.UserData.Ncx=Ncx;
start(t)

end

% function StartFcn(mTimer,~)
% disp('StartFcn')
% end
function StopFcn(mTimer,~)
%%disp(['Stopfcn',' executed '...
%%    datestr(now,'dd-mmm-yyyy HH:MM:SS.FFF')]);
disp('Plotting Stopped')
stop(timerfindall)
delete(timerfindall)
timerfindall;
end

function StartFcn(mTimer,~)
disp(['StartFcn',' executed '...
    datestr(now,'dd-mmm-yyyy HH:MM:SS.FFF')]);
end


function TimerFcn(mTimer,~)
global COMdevice AUTOSCALECHECK AUTOSCALEKEYPRESS

disp('TimerFcn')

% NumSamples=500;
% DataType='single';
% COMport='COM89';
% BaudRate=115200;
% Ncx=2;

COMport=mTimer.UserData.COMport;
DataType=mTimer.UserData.DataType;
NumSamples=mTimer.UserData.NumSamples;
BaudRate=mTimer.UserData.BaudRate;
Ncx=mTimer.UserData.Ncx;

close all

disp(['Model: ' gcs])
disp(['COMport: ' COMport ' DataType: ' DataType ' Number Samples:' num2str(NumSamples)]);
disp(' ');
disp(['-------------------- Opening ' COMport '  please wait up to 30 seconds ------------------'])
disp(' ');


%% Read from Serial:

% Create the COMdevice in the base workspace if id is not already open:
COMopen = evalin('base','(exist(''COMdevice''))');
if(COMopen)
    disp('COM port is already open')
    % flush the data that alreay exists:
    evalin('base','flush(COMdevice,"input")')
else
    assignin('base','COMdevice',serialport(COMport,BaudRate));
    syncstring='***Data Start***';
    disp(['syncstring: ' syncstring])
    
    %% find start of data by waiting for ***starting the model***
    istring=[];  % initial string to find/sync start of data
    for i=1:60
        d1=evalin('base','char(read(COMdevice, 1, ''uint8''));');
        istring=[istring d1];
        % if you find the complete starting string
        % ready 2 bytes then move on
        % only data is following
        % istring_found=strfind(istring,'***starting the model***');   % Default string before 2017
        istring_found=strfind(istring,syncstring);     %   added to SerialPlot on 9/18/2018 to replicate '***starting the model***' in pre 2017 versions
    end
    disp(['istring: ' istring])
end

% initialize figure - it is faster to update
% figure data then replotting it each time
[fh, dh]=InitFig(Ncx);
AUTOSCALECHECK=1;

% data storage variable:
fdat=[];
datNumSamples=[];
nrows=0;

ReadString=['read(COMdevice,' num2str(Ncx) ',' '''' DataType '''' ');'];

% Make sure the first data is sychronized by checking the first
% couple data points:
% any number greater than 100,000,000 or with percision more
% than
% d=evalin('base',ReadString);%read(app.COMdevice,Ncx,'single'); %d1=evalin('base','char(read(COMdevice, 1, ''uint8''));');
% nd=norm(d);data_out_bounds = or(nd>1e8, and(nd>0,nd<1e-8)); %if(data_out_bounds), keyboard, end
% if(data_out_bounds)
%     for i=1:3*Ncx*4  % try to correct 3 full data reads before exiting
%         if(data_out_bounds),
%             nd,d
%             disp('initial data out of bounds - flushing buffer'),  %if(data_out_bounds), keyboard, end
%             evalin('base','flush(COMdevice,"input")'); %d1=evalin('base',['read(COMdevice,1,''uint8'');']);%char(read(app.COMdevice, 1, 'uint8'));
%             d=evalin('base',ReadString);
%             nd=norm(d);data_out_bounds = or(nd>1e8, and(nd>0,nd<1e-8)); %if(data_out_bounds), keyboard, end
%          else
%             disp('data sychronized')
%             keyboard
%             break
%         end
%     end
% end


%% Read data, update graph, store data
tic
for k=1:1e5
 
    %% Read and store data

    % read all the bytes available:
    Bytes_Available=evalin('base',['COMdevice.NumBytesAvailable']);
    Data_Rows_Available=floor(Bytes_Available/(4*Ncx));

    for i=1:Data_Rows_Available
        d=evalin('base',ReadString);  % read a row of data
        
        % Check data integrity & flush the buffer if data is out of bounds:
        nd=norm(d);data_out_bounds = or(nd>1e6, and(nd>0,nd<1e-8)); %if(data_out_bounds), keyboard, end
        if(data_out_bounds)
            for i=1:3 % try 3 times
                if(data_out_bounds),
                                     
                    disp('main data out of bounds - flushing buffer'),  %if(data_out_bounds), keyboard, end
                    disp(['attempt: ', num2str(i), ' data norm: ', num2str(nd), ' data: ', num2str(d)]);
                    evalin('base','flush(COMdevice,"input")'); %d1=evalin('base',['read(COMdevice,1,''uint8'');']);%char(read(app.COMdevice, 1, 'uint8'));
                    d=evalin('base',ReadString);
                    nd=norm(d);data_out_bounds = or(nd>1e8, and(nd>0,nd<1e-8)); %if(data_out_bounds), keyboard, end
                else
                    disp('main data sychronized')
                    break;
                end
            end
        end
        
        fdat=[fdat;d];
    end
    
    %% Plotting Tasks:

    %% Adjust the plotting data buffer:
    if(length(fdat)>NumSamples)
        datNumSamples=(fdat(end-NumSamples:end,:));  % truncate data to the length of the plotting window
    else
        datNumSamples=fdat;
    end
    
    %% handle figure activities:
    for numxc=1:Ncx
        % Update each channelof data on the graph
        set(dh(numxc),'Xdata', 1:size(datNumSamples,1), 'Ydata',datNumSamples(:,numxc));
    end
    
    % Autoscale up to the NumSammples window size, then only autoscale with button
    % press:  (autoscale until the figure is filled with data)
    if(length(fdat)<NumSamples)
        AutoScale(datNumSamples,NumSamples);
    else
        if(AUTOSCALECHECK)
            AutoScale(datNumSamples,NumSamples);
            %disp('autoscaling')
        end
    end
    
    if(AUTOSCALEKEYPRESS)
        AutoScale(datNumSamples,NumSamples);
        AUTOSCALEKEYPRESS=0;
    end
    
    drawnow
    
    if(stopkeypress),
        disp(' ');disp('Plotting Stopped')
        disp('current data exported to variables: (use plot(fdat) )')
        disp('  fdat and wdat')
        disp('in the workspace and saved to file: (use load fdat )')
        disp('  fdat.mat')
        close all
        break;
    end
    
    nrows=nrows+Data_Rows_Available;
    if(~mod(k,10))
        disp(['data rows read: ' num2str(nrows) ])
        nrows=0;
    end
    pause(.1)

  
end

save 'fdat' fdat
assignin('base','fdat',fdat)
assignin('base', 'wdat',datNumSamples)

try,
    %    fclose(COMdevice), delete(COMdevice), clear s
    %    evalin('base','if(exist(''COMdevice'')), disp('' COM port''),clear(''COMdevice''),end')
    
catch, end

end

function [fh, dh]=InitFig(Ncx)
%% initizlize a figure for plotting data:
fh=figure;

axes('Parent',fh,'FontSize',14);
set(fh,'toolbar','figure'); %stopkeypress=0;
assignin('caller','stopkeypress',0);
% assignin('caller','byteadjustkeypress',0);
% assignin('caller','AutoScalekeypress',1);

uicontrol('Style', 'pushbutton', 'String', 'Stop',...
    'Units','normalized','Position', [0 0 .1 .05],...
    'Callback', @stopbutton);
% uicontrol('Style', 'pushbutton', 'String', 'Byte Adjust',...
%     'Units','normalized','Position', [.1 0 .2 .05],...
%     'Callback', @byteadjust);
%%
uicontrol('Style', 'pushbutton', 'String', 'Manual AutoScale',...
    'Units','normalized','Position', [.1 0 .2 .05],...
    'Callback', @AutoScaleButton);
hchkbox=uicontrol('Style', 'checkbox', 'String', 'AutoScale',...
    'Units','normalized','Position', [.3 0 .3 .05],...
    'Callback', @AutoScaleCheckbox,'Value',1);

%% collect data only check box (not really used or practical)
% hchkbox=uicontrol('Style', 'checkbox', 'String', 'Collect Data Only',...
%     'Units','normalized','Position', [.7 0 .3 .05],...
%     'Callback', @CollectDataonlyCheckbox,'Value',0);
% assignin('caller','DataOnlyCheck',0);

%%

if(Ncx>1)
    dh=plot(zeros(2,Ncx),'LineWidth',3);
    %  for i=1:Ncx
    %     dh(i)=plot(0,0,'LineWidth',4);
    %  end
    switch Ncx
        case 1
            legend('data 1');
        case 2
            legend('data 1','data 2');
        case 3
            legend('data 1','data 2','data 3');
        case 4
            legend('data 1','data 2','data 3','data 4');
        case 5
            legend('data 1','data 2','data 3','data 4','data 5');
        case 6
            legend('data 1','data 2','data 3','data 4','data 5',' data 6');
        case 7
            legend('data 1','data 2','data 3','data 4','data 5', 'data 6','data 7');
        case 8
            legend('data 1','data 2','data 3','data 4','data 5', 'data 6','data 7','data 8');
        case 9
            legend('data 1','data 2','data 3','data 4','data 5', 'data 6','data 7','data 8','data 9');
    end
    
else
    dh=plot(0,0,'r','LineWidth',4);
end


ylim([-1 1]) % for x in mm
drawnow
end

function stopbutton(~, event)
% if the stop button is pressed
% assign stopkeypress high to stop taking data
assignin('caller','stopkeypress',1)
%% CloseInstObjects
end

function AutoScaleButton(~, event)
global AUTOSCALEKEYPRESS
%assignin('caller','AutoScalekeypress',1)
AUTOSCALEKEYPRESS=1;
end

function AutoScaleCheckbox(~, event)
global AUTOSCALECHECK
%assignin('caller','AutoScaleCheck',event.Source.Value)
AUTOSCALECHECK=event.Source.Value;
end

function CollectDataonlyCheckbox(~, event)
assignin('caller','DataOnlyCheck',event.Source.Value)
end

function CloseInstObjects
disp('Closing COM port ');
% disp('-- Closing all instrument objects --')
% disp(' ');
%
% newobjs=instrfindall
% % Close them!
% try,
%     fclose(newobjs);
%     delete(newobjs);
% catch, end

end

function AutoScale(datNumSamples, NumSamples)
%[min(datNumSamples)  max(datNumSamples)]
%if(max(datNumSamples) > 0  && min(datNumSamples) <= max(datNumSamples) )
% disp('adj y axis')
minD=min(min(datNumSamples));
maxD=max(max(datNumSamples));
diffD=maxD-minD;
if(diffD>0)
    ylim([minD, maxD]);
else
    ylim([minD-1, maxD+1]);
end
xlim([0 length(datNumSamples)]);
%end

end


