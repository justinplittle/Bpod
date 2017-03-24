function [arglist] = GetSoloFunctionArgsStruct(varargin)
%
% JPL - just like GetSoloFunctionArgsStruct but modified to work with
% 'private_solofunction_list' when its SoloParamHandles have been turned
% into structs

% If the first thing passed in is an object, then use that as the owner
% otherwise try to 'determine_owner'

if nargin>0 && isobject(varargin{1}),
    default_owner = ['@' class(varargin{1})]; varargin = varargin(2:end);
else
    default_owner = determine_owner;
end;

% if the first things passed in is the string 'arglist' then pass back
% the list of variables for that function.

if ~isempty(varargin) && ischar(varargin{1})
    if strcmp(varargin{1}, 'arglist'),
        % Just want the list of arguments, no variable assignment
        if length(varargin)~=3,
            error('when called with ''arglist'', there must be 3 args total');
        end;
        get_arglist = 1;
        func_owner = varargin{2};
        func_name  = varargin{3};
    else
        get_arglist = 0;
        pairs = { ...
            varargin{1}   varargin{2} ; ... %func_name
            varargin{3}   varargin{4} ; ... %func_owner
            'all_read_only'   'off'   ; ...
            'name'            ''      ; ...
            };
        parseargs(varargin, pairs);
    end
    
else
    % Normal operation, will do variable assignments.
    get_arglist = 0;
    pairs = { ...
        'func_name'       determine_fullfuncname   ; ...
        'func_owner'      default_owner            ; ...
        'all_read_only'   'off'                    ; ...
        'name'            ''				          	   ; ...
        };
    parseargs(varargin, pairs);
end;

global private_solofunction_list
% private_solofunction_list is a cell array with three columns. The
% first column contains owner ids. Each row is unique. For each row
% with an owner id, the second column contains a cell array that
% corresponds to the set of function names that are registered for that
% owner. The third row contains the globals declared for that owner.

% First find the list of functions registered to func_owner:
if isempty(private_solofunction_list),
    return;
else
    mod = find(cellfun(@(x) strcmp(func_owner,x.param_owner), private_solofunction_list(:,1)));
end

if isempty(mod)
    return;
end;

% Get the global arguments for this func_owner
global_rw_args = private_solofunction_list{mod,3}{1};
global_ro_args = private_solofunction_list{mod,3}{2};

% Now find the func_name within the list of functions:
funclist = private_solofunction_list{mod, 2};
if isempty(funclist), return;
else fun = find(strcmp(func_name, funclist(:,1)));
end;

% Each funclist is a cell array with three columns. The first column
% contains function names; each row is unique. For each row, the
% second column contains a cell column vector of read/write args;
% the third column contains a cell column vector of read-only args.
if ~isempty(fun),
    rw_args = funclist{fun,2};
    ro_args = funclist{fun,3};
else
    rw_args = cell(0,2);
    ro_args = cell(0,2);
end;



% ---- IF WANT ONLY ARGLIST, GET IT NOW AND EXIT
if get_arglist,
    arglist = {};
    if ~isempty(global_rw_args), arglist=           global_rw_args(:,1); end;
    if ~isempty(global_ro_args), arglist=[arglist ; global_ro_args(:,1)];end;
    if ~isempty(rw_args),        arglist=[arglist ; rw_args(:,1)]; end;
    if ~isempty(ro_args),        arglist=[arglist ; ro_args(:,1)]; end;
    arglist = unique(arglist);
    return;
end;
% -------------------------------


% Now find the specific variables that we want within the list of variables:
if ~isempty(rw_args) && ~isempty(name)
    rw_arg_cidx=strfind(rw_args(:,1),name);
    rw_arg_idx=zeros(size(rw_arg_cidx));
    
    for dx=1:numel(rw_arg_idx)
        rw_arg_idx(dx)=~isempty(rw_arg_cidx{dx});
    end
    
    rw_args=rw_args(rw_arg_idx==1,:);
    
    %if isempty(funclist), return;
end;

if ~isempty(ro_args) && ~isempty(name)
    ro_arg_cidx=strfind(ro_args(:,1),name);
    ro_arg_idx=zeros(size(ro_arg_cidx));
    
    for dx=1:numel(ro_arg_idx)
        ro_arg_idx(dx)=~isempty(ro_arg_cidx{dx});
    end
    ro_args=ro_args(ro_arg_idx==1,:);
    %if isempty(funclist), return;
end;

% DO EVERY ASSIGN TWICE: FIRST FOR GLOBALS, THEN REGULARS:

% ---- globals first : -------
% If we're getting everything in read-only mode, then pile 'em all
% into the read-only list:
if strcmp('all_read_only', 'on'),
    global_ro_args = [global_rw_args ; global_ro_args];
    global_rw_args = {};
end;

for i=1:size(global_rw_args,1),
    if is_validhandle(global_rw_args{i,2}),
        assignin('caller', global_rw_args{i,1}, global_rw_args{i,2});
    end;
end;

for i=1:size(global_ro_args,1),
    if ~isa(global_ro_args{i,2}, 'SoloParamHandle')
        assignin('caller', global_ro_args{i,1}, global_ro_args{i,2});
    else
        if is_validhandle(global_ro_args{i,2}),
            assignin('caller', global_ro_args{i,1}, ...
                value(global_ro_args{i,2}));
            assignin('caller',[global_ro_args{i,1} '_history'], ...
                get_history(global_ro_args{i,2}));
        end;
    end;
end;


% ---- now regular vars : -------
% If we're getting everything in read-only mode, then pile 'em all
% into the read-only list:
if strcmp('all_read_only', 'on'),
    ro_args = [rw_args ; ro_args];
    rw_args = {};
end;

for i=1:size(rw_args,1),
    if is_validhandle(rw_args{i,2}),
        assignin('caller', rw_args{i,1}, rw_args{i,2});
    end;
end;

for i=1:size(ro_args,1),
    if ~isa(ro_args{i,2}, 'SoloParamHandle')
        assignin('caller', ro_args{i,1}, ro_args{i,2});
    else
        if is_validhandle(ro_args{i,2}),
            assignin('caller', ro_args{i,1}, value(ro_args{i,2}));
            assignin('caller',[ro_args{i,1} '_history'], ...
                get_history(ro_args{i,2}));
        end;
    end;
end;


