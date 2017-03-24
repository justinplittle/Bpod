%main script to run for protocol translation

% %create a translateProtocol object
% answer = inputdlg('Please enter the name of a Solo/Bcontrol protocol folder or function','Protocol Selection');
% 
% %check
% pathCell=strsplit(path,':');
% 
% %search for a mathcing name in the path
% idxs=find(cell2mat(cellfun(@(x) ~isempty(strfind(x,[filesep answer{1}])),pathCell,'UniformOutput',false)));
% 
% if idxs==1
%     protPath=pathCell{idxs};
% elseif idxs > 1
%     display('runProtocolTranslation::found multiple matching files')
%     str = pathCell(idxs);
%     [s,v] = listdlg('PromptString','Select a main protocol file/folder/class:',...
%                 'SelectionMode','single',...
%                 'ListString',str);
%     protPath=pathCell{v};
% else
%     display('runProtocolTranslation::could not find a protocol with this name on Matlab path')
%     [file, dir]=uigetfile('~','Protocol not found. Please select a protocol main function');
%     protPath=[dir filesep file];
% end
% 
% 
% % create a protocol translation object
% [dir,file,ext]=fileparts(protPath);
% protocol=file;

%JPL - TEMPORARY

file='JustinNoDiscrimn';

obj=translateProtocol.translateProtocol(soloDir,protocol);