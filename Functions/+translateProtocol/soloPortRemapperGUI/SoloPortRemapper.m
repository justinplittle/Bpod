function varargout = SoloPortRemapper(varargin)
% SOLOPORTREMAPPER MATLAB code for SoloPortRemapper.fig
%      SOLOPORTREMAPPER, by itself, creates a new SOLOPORTREMAPPER or raises the existing
%      singleton*.
%
%      H = SOLOPORTREMAPPER returns the handle to a new SOLOPORTREMAPPER or the handle to
%      the existing singleton*.
%
%      SOLOPORTREMAPPER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SOLOPORTREMAPPER.M with the given input arguments.
%
%      SOLOPORTREMAPPER('Property','Value',...) creates a new SOLOPORTREMAPPER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SoloPortRemapper_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SoloPortRemapper_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SoloPortRemapper

% Last Modified by GUIDE v2.5 17-Mar-2017 14:56:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SoloPortRemapper_OpeningFcn, ...
                   'gui_OutputFcn',  @SoloPortRemapper_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end


% --- Executes just before SoloPortRemapper is made visible.
function SoloPortRemapper_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SoloPortRemapper (see VARARGIN)

global BpodSystem

inSMA=varargin{1};
outSMA=varargin{2};

%%%%create solo input sma data for table
inTable=[inSMA.input_map(1:end-1,:) inSMA.input_line_map(:,2)...
    cell(size(inSMA.input_line_map(:,2),1),1)];
%populate input table
handles.inputRemapTable.Data=inTable;

%%%%create solo output sma for table
dioNames=fields(inSMA.settings.DIOLINES);
for b=1:1:numel(dioNames)
    dioChans{b}=inSMA.settings.DIOLINES.(dioNames{b});
    dioIDs{b}=b; %is this right?
end

outTable=[dioNames dioIDs' dioChans' cell(size(dioNames,1),1)];

%populate output table
handles.outputRemapTable.Data=outTable;

%data structure for tracking the output remap


%%%create list of Bpod modules for input and output selection
%non-connected module will be gray
for b=1:1:numel(BpodSystem.Modules.Name)
    if isempty(BpodSystem.Modules.Name{b})
        nameString='none';
    else
        nameString=BpodSystem.Modules.Name{b};
    end
    
    if ~any(BpodSystem.Modules.Connected)
        %black color
        moduleStrings{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
    elseif BpodSystem.Modules.Connected(b)==0 
        %gray color
       moduleStrings{b}=['<HTML><FONT color="' rgb2Hex([100 100 100]) '">' nameString '</FONT></HTML>'];
    else %black color
       moduleStrings{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
    end
end

%output
handles.bpodOutputModuleList.String=moduleStrings;
%input
handles.bpodInputModuleList.String=moduleStrings;

%set the default selected module to be the first in the list
handles.bpodOutputModuleList.Value=1;
handles.bpodInputModuleList.Value=1;

%%%list of names for bpod input channels for the selected module
curModule=BpodSystem.Modules.Name{handles.bpodOutputModuleList.Value};
wireCounter=1;
portCounter=1;
if isempty(curModule) %no module names, just list from Bpod System object
     
    %NOTE 'Serial','USB', and 'BNC' input types present in enabled struct, so going 
    %to assume they are ALWAYS enabled. At startup
    
    %color by ports enabled (black), disabled (grey). Red will mean already
    %remapped, but this will be while the GUI is in use
     for b=1:1:numel(BpodSystem.StateMachineInfo.InputChannelNames)
         nameString=BpodSystem.StateMachineInfo.InputChannelNames{b};
         if ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Serial'))...
                 || ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'USB'))...
                 || ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'BNC'))
             
            inputNameString{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
         
         elseif strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Wire')
             if BpodSystem.InputsEnabled.WiresEnabled(wireCounter)==0 %gray color
                 inputNameString{b}=['<HTML><FONT color="' rgb2Hex([100 100 100]) '">' nameString '</FONT></HTML>'];
             else %black color
                 inputNameString{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
             end
             wireCounter=wireCounter+1;
         elseif strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Port')
             if BpodSystem.InputsEnabled.PortsEnabled(portCounter)==0 %gray color
                 inputNameString{b}=['<HTML><FONT color="' rgb2Hex([100 100 100]) '">' nameString '</FONT></HTML>'];
             else %black color
                 inputNameString{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
             end
             portCounter=portCounter+1;
         end
         
     end
else %dont know what to do here yet
    
    
end

handles.bpodInputNameList.String=inputNameString;


%%%list of names for BPod output channels
%do these have an enabled/disabled feature as well?
curModule=BpodSystem.Modules.Name{handles.bpodOutputModuleList.Value};
if isempty(curModule) %no module names, just list from Bpod System object
    
    %color by ports enabled (black), disabled (grey). Red will mean already
    %remapped, but this will be while the GUI is in use
    for b=1:1:numel(BpodSystem.StateMachineInfo.OutputChannelNames)
        nameString=BpodSystem.StateMachineInfo.OutputChannelNames{b};
        outputNameString{b}=['<HTML><FONT color="' rgb2Hex([0 0 0]) '">' nameString '</FONT></HTML>'];
    end
else %dont know what to do here yet
    
    
end

handles.bpodOutputNameList.String=outputNameString;

%%%list of IDs for Bpod input ports

%for this, need to know how many physical lines exists for each port type
%not sure how Josh codes things, taking a guess temporarily here

for b=1:1:numel(inputNameString)
    if ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Serial'))
        handles.bpodOutputPortNum.String = {1};
    elseif ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'USB'))
        handles.bpodOutputPortNum.String = {1};
    elseif ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'BNC'))
        handles.bpodOutputPortNum.String = {1};
    elseif ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Wire'))
        handles.bpodOutputPortNum.String = {1};
    elseif ~isempty(strfind(BpodSystem.StateMachineInfo.InputChannelNames{b},'Port'))
        handles.bpodOutputPortNum.String = {1 2 3 4 5 6 7};
    else
        error('SoloPortRemapper:: unfamiliar with this input channel type')
    end
    
end

%%%% data structure for tracking the input remap, fill with some defaults on start
for b=1:1:size(inTable,1)
    handles.inputRemapTable.UserData.inputRemapStruct{b}=struct('SoloName' ,inTable{b,1},'SoloProps',inTable(b,2:end),...
                               'Module',BpodSystem.Modules.Name(1),...
                               'ChanName',BpodSystem.StateMachineInfo.InputChannelNames(1),...
                               'PortNum',1);
end

%%%% data structure for tracking the output remap, fill with some defaults on start
for b=1:1:size(outTable,1)
    handles.outputRemapTable.UserData.outputRemapStruct{b}=struct('SoloName' ,outTable{b,1},'SoloProps',outTable(b,2:end),...
                               'Module',BpodSystem.Modules.Name(1),...
                               'ChanName',BpodSystem.StateMachineInfo.OutputChannelNames(1),...
                               'PortNum',1);
end


% Choose default command line output for SoloPortRemapper
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SoloPortRemapper wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = SoloPortRemapper_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%   STUFF FOR THE TABLES   %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%CREATE FUNCTION CALLBACKS

% --- Executes during object creation, after setting all properties.
function inputRemapTable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputRemapTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


end

% --- Executes during object creation, after setting all properties.
function outputRemapTable_CreateFcn(hObject, eventdata, handles)
% hObject    handle to outputRemapTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
end

%%%%%%%%%%%%%CELL SELECTION CALLBACKS

% --- Executes when selected cell(s) is changed in inputRemapTable.
function inputRemapTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to inputRemapTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

keyboard
%set the user data to the current selected id
handles.inputRemapTable.UserData.currSelection=eventdata.Indices(1);

end


% --- Executes when selected cell(s) is changed in outputRemapTable.
function outputRemapTable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to outputRemapTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)

%set the user data to the current selected id
handles.outputRemapTable.UserData.currSelection=eventdata.Indices(1);
end
%%%%%%%%%%%%%CELL EDIT CALLBACKS


% --- Executes when entered data in editable cell(s) in inputRemapTable.
function inputRemapTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to inputRemapTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes when entered data in editable cell(s) in outputRemapTable.
function outputRemapTable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to outputRemapTable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% STUFF FOR THE LISTBOXES %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on selection change in bpodOutputModuleList.
function bpodOutputModuleList_Callback(hObject, eventdata, handles)
% hObject    handle to bpodOutputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodOutputModuleList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodOutputModuleList

%set module name for the currently selected solo channel
handles.outputRemapTable.UserData.outputRemapStruct...
    {handles.outputRemapTable.UserData.currSelection}.Module=...
    hObject.String{hObject.Value};

end


% --- Executes during object creation, after setting all properties.
function bpodOutputModuleList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end


% --- Executes on selection change in bpodOutputNameList.
function bpodOutputNameList_Callback(hObject, eventdata, handles)
% hObject    handle to bpodOutputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodOutputNameList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodOutputNameList

%set channel nbame for the currently selected solo channel
handles.outputRemapTable.UserData.outputRemapStruct...
    {handles.outputRemapTable.UserData.currSelection}.ChanName=...
    hObject.String{hObject.Value};

end


% --- Executes during object creation, after setting all properties.
function bpodOutputNameList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in bpodOutputPortNum.
function bpodOutputPortNum_Callback(hObject, eventdata, handles)
% hObject    handle to bpodOutputPortNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodOutputPortNum contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodOutputPortNum

%set port number for the currently selected solo channel
handles.outputRemapTable.UserData.outputRemapStruct...
    {handles.outputRemapTable.UserData.currSelection}.PortNum=...
    hObject.String{hObject.Value};
end

% --- Executes during object creation, after setting all properties.
function bpodOutputPortNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputPortNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in bpodInputModuleList.
function bpodInputModuleList_Callback(hObject, eventdata, handles)
% hObject    handle to bpodInputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodInputModuleList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodInputModuleList

%set module name for the currently selected solo channel
handles.inputRemapTable.UserData.inputRemapStruct...
    {handles.inputRemapTable.UserData.currSelection}.Module=...
    hObject.String{hObject.Value};
end

% --- Executes during object creation, after setting all properties.
function bpodInputModuleList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in bpodInputNameList.
function bpodInputNameList_Callback(hObject, eventdata, handles)
% hObject    handle to bpodInputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodInputNameList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodInputNameList
keyboard

%set channel name for the currently selected solo channel
handles.inputRemapTable.UserData.inputRemapStruct...
    {handles.inputRemapTable.UserData.currSelection}.ChanName=...
    hObject.String{hObject.Value};
end

% --- Executes during object creation, after setting all properties.
function bpodInputNameList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in bpodInputPortNumList.
function bpodInputPortNumList_Callback(hObject, eventdata, handles)
% hObject    handle to bpodInputPortNumList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns bpodInputPortNumList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from bpodInputPortNumList
keyboard
end

% --- Executes during object creation, after setting all properties.
function bpodInputPortNumList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputPortNumList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodInputModuleList.
function bpodInputModuleList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodInputNameList.
function bpodInputNameList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodInputPortNumList.
function bpodInputPortNumList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodInputPortNumList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodOutputModuleList.
function bpodOutputModuleList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputModuleList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodOutputNameList.
function bpodOutputNameList_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputNameList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over bpodOutputPortNum.
function bpodOutputPortNum_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to bpodOutputPortNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

function hex=rgb2Hex(rgb)

%% If no value in RGB exceeds unity, scale from 0 to 255: 
if max(rgb(:))<=1
    rgb = round(rgb*255); 
else
    rgb = round(rgb); 
end

%% Convert 

hex(:,2:7) = reshape(sprintf('%02X',rgb.'),6,[]).'; 
hex(:,1) = '#';

end