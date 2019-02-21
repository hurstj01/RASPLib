function  SerialPlot(COMport, DataType, NumSamples, BaudRate, Ncx)
%SerialPlot(get_param(gcb,'COMport'), get_param(gcb,'DataType'), get_param(gcb,'NumSamples'), get_param(gcb,'BaudRate'))
% NumSamples=500;
% DataType='single';
% COMport='COM28'
% BaudRate=115200;
% Ncx=3;  % number of muxed data types for multiple channel data
% clc

%% get the sample time of the model
try,
    model_sample_time=str2num(get_param(gcs,'FixedStep'))
    % if the sample time is not a number, but a parameter
    % look for it in the base workspace
    if(isempty(model_sample_time))
        model_sample_time=evalin('base',get_param(gcs,'FixedStep') );
    end
catch,
    % if it is still empty
    if(isempty(model_sample_time))
        model_sample_time=.005; % guess a sample time if not model is available
        est_sample_time=1;
    end
end

% refesh plot 50 times a second, or as fast as possible
refresh_num=ceil(.02/model_sample_time)

close all
% search for all instrument objects:
% Ensure the com port is closed by closing all instrument objects:
CloseInstObjects
disp(['Model: ' gcs ' Sample Time:' model_sample_time])
disp(['COMport: ' COMport ' DataType: ' DataType ' Number Samples:' num2str(NumSamples)]);
disp(' ');
disp(['-------------------- Opening ' COMport '  please wait up to 30 seconds ------------------'])
disp(' ');


%% Read from Serial:
s = serial(COMport);
set(s, 'ByteOrder', 'bigEndian','BaudRate', BaudRate);
fopen(s);

is_post_2015=~verLessThan('matlab','8.6');
if(is_post_2015)
    % then '***Data Start***' should be sent to replace the ***starting the
    % model*** string that was removed.
    syncstring='***Data Start***';
else
    % If 2015a (maybe 2015b?) the '***Data Start***' string is somehow
    % supressed and the default ***starting the
    % model*** is still sent - so look for that to sync data
    syncstring='***starting the model***';
end

disp(['syncstring: ' syncstring])

%% find start of data by waiting for ***starting the model***
istring=[];  % initial string to find/sync start of data
for i=1:60
    d1=char(fread(s, 1, 'uint8'));
    istring=[istring d1];
    % if you find the complete starting string
    % ready 2 bytes then move on
    % only data is following
    % istring_found=strfind(istring,'***starting the model***');   % Default string before 2017
    istring_found=strfind(istring,syncstring);     %   added to SerialPlot on 9/18/2018 to replicate '***starting the model***' in pre 2017 versions
    if(istring_found)
        % then we can assume when the data start:
        if(is_post_2015)
            % skip the rest, go right to getting data
            break;
        else
            % skip two bytes, as it seems it has 2 extra bytes (probably
            % newline and clearling?
            d1=char(fread(s, 2, 'uint8'));%  Default value for string before 2017
            break
        end
    end
end

disp(['istring: ' istring])

% initialize figure - it is faster to update
% figure data then replotting it each time
[fh, dh]=InitFig(Ncx);
AutoScaleCheck=0;

% data storage variable:
fdat=[];
datNumSamples=[];

% refresh rate estimation timer
refresh_est_size=5;
refresh_est_vec=zeros(1:refresh_est_size);

%% --------- Perform initial data checks: ----------------------------
% initialliy read one single data type perform checks on data quality
% a unsighed single has max of 3.4028e+38
% a signed single max of plus minus 2.1475e+09
% so the easiest data check is if any number is above 2.1475e+09
% there must have been a byte skipped

% % find the fist data type:
% if(DataType=='single')
%     d=fread(s, 1, 'uint32')
% end

% read 2 samples and check - usually able to see out of bounds data after
% the first one or two
% for k=1:2
% d=fread(s,[Ncx 1],DataType)  % each channel of data one time
% max_d=max(abs(d));
% out_of_range = ((max_d~=0)&&( (max_d<2e-10) || (max_d>2e10) ))
% fdat=[fdat;d'];
% end

% if(max(abs(d))>2.1475e+09)
%     disp('Data integrity error detected')
% else
%     % the data is ok to store
%     fdat=[fdat;d'];
% end

% %% --------- Perform initial data checks: ----------------------------


%% Read data, update graph, store data
for k=1:1e5
    
    %% Read and store data
    % assume your computer can execute this loop faster than data is
    % sent to the seria port:
    
    tic
    d=fread(s,[Ncx refresh_num],DataType);  % each channel of data refresh_num times
    read_time=toc;
    byte_time=read_time/refresh_num/1;
    fdat=[fdat;d'];
    
    % ------  ToDo ---------------------------------------------------
    %     chn=2;  % select only one channel (one column) of data
    %     %% Adjust the plotting data buffer:
    %     if(length(fdat)>NumSamples)
    %         datNumSamples=(fdat(end-NumSamples:end,chn));
    %     else
    %         datNumSamples=fdat(:,chn);
    %     end
    
    % Plotting Tasks:
    if(~DataOnlyCheck)
        %% Adjust the plotting data buffer:
        if(length(fdat)>NumSamples)
            datNumSamples=(fdat(end-NumSamples:end,:));
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
        if(k*refresh_num<NumSamples)
            AutoScale(datNumSamples,NumSamples);
        else
            if(AutoScaleCheck)
                AutoScale(datNumSamples,NumSamples);
            end
        end
        
        if(AutoScalekeypress)
            AutoScale(datNumSamples,NumSamples);
            AutoScalekeypress=0;
        end
        
    end
    
    
    drawnow
    if(stopkeypress),
        disp('Plotting Stopped')
        disp('current data exported to variables:')
        disp('  fdat')
        disp('and')
        disp('  wdat')
        disp('in the workspace and saved to file')
        disp('  dat.mat')
        close all
        break;
    end
    
    % shift bytes read to try and sync data stream:
    if(byteadjustkeypress)
        disp('skipping a byte in an attempt to correct data');
        fread(s,1, 'uint8');
        byteadjustkeypress=0;
    end
    
    %% estimate the sample time if it cannot be found.
    % the estimated time should match the actual sample time
    % if no then the plotting/refresh rate needs to slow
    % down (increase refresh_num)
    
    est_sample_time=toc/refresh_num;
    refresh_est_vec=[refresh_est_vec(2:(refresh_est_size)) est_sample_time];
    avg_sample_time=sum(refresh_est_vec)/sum(refresh_est_vec>0);
    if(~mod(k,50))
        disp(['refresh time: ' num2str(toc) ' avg_sample_time: ' num2str(avg_sample_time)...
            ' samples per refresh: ' num2str(refresh_num)]);
        %[toc avg_sample_time refresh_num]
        if(est_sample_time)
            refresh_num=ceil(.02/avg_sample_time);
        end
    end
    
    
end

save 'fdat' fdat
assignin('base','fdat',fdat)
assignin('base', 'wdat',datNumSamples)

try,
    fclose(s)
    delete(s)
    clear s
catch, end

end

function [fh, dh]=InitFig(Ncx)
%% initizlize a figure for plotting data:
fh=figure;

axes('Parent',fh,'FontSize',14);
set(fh,'toolbar','figure'); %stopkeypress=0;
assignin('caller','stopkeypress',0);
assignin('caller','byteadjustkeypress',0);
assignin('caller','AutoScalekeypress',0);

uicontrol('Style', 'pushbutton', 'String', 'Stop',...
    'Units','normalized','Position', [0 0 .1 .05],...
    'Callback', @stopbutton);
uicontrol('Style', 'pushbutton', 'String', 'Byte Adjust',...
    'Units','normalized','Position', [.1 0 .2 .05],...
    'Callback', @byteadjust);
%%
uicontrol('Style', 'pushbutton', 'String', 'Manual AutoScale',...
    'Units','normalized','Position', [.3 0 .2 .05],...
    'Callback', @AutoScaleButton);
hchkbox=uicontrol('Style', 'checkbox', 'String', 'AutoScale',...
    'Units','normalized','Position', [.5 0 .3 .05],...
    'Callback', @AutoScaleCheckbox,'Value',0);

hchkbox=uicontrol('Style', 'checkbox', 'String', 'Collect Data Only',...
    'Units','normalized','Position', [.7 0 .3 .05],...
    'Callback', @CollectDataonlyCheckbox,'Value',0);
assignin('caller','DataOnlyCheck',0);
%%

if(Ncx>1)
    dh=plot(zeros(2,Ncx),'LineWidth',4);
    %  for i=1:Ncx
    %     dh(i)=plot(0,0,'LineWidth',4);
    %  end
    
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
CloseInstObjects
end

function byteadjust(~, event)
assignin('caller','byteadjustkeypress',1)
end

function AutoScaleButton(~, event)
assignin('caller','AutoScalekeypress',1)
end

function AutoScaleCheckbox(~, event)
assignin('caller','AutoScaleCheck',event.Source.Value)
end

function CollectDataonlyCheckbox(~, event)
assignin('caller','DataOnlyCheck',event.Source.Value)
end

function CloseInstObjects
disp(' ');
disp('-- Closing all instrument objects --')
disp(' ');

newobjs=instrfindall
% Close them!
try,
    fclose(newobjs);
    delete(newobjs);
catch, end

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
