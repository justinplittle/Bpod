function [err] = sendstarttime(obj)
% function [err] = sendstarttime(obj)
%
% This function sends the current time as starttime to the sessions table.
% It should be called by runrats at the time the 'Run' button is pressed

try
	rigID=getRigID;
    if isnan(rigID)
		% if not running on a real rig, don't send to sql
	    err=42;
		return
	end;
	
if isnumeric(rigID)
    rigID=sprintf('Rig%02d',rigID);
end
    
    
	sessid = getSessID(obj);
	starttime = datestr(now, 13);
	sessiondate = datestr(now, 29);
	ratname = get_sphandle('fullname', 'SavingSection_ratname');
	if isempty(ratname), ratname = '';
	else			     ratname = value(ratname{1});
	end;
	
	colstr = 'sessid, sessiondate, starttime, was_ended, ratname, hostname';
	valstr = '"{Si}", "{S}", "{S}", "{Si}", "{S}", "{S}"';
	sqlstr = ['insert into bdata.sess_started (' colstr ') values (' valstr ')'];
	bdata(sqlstr, sessid, sessiondate, starttime, 0, ratname, rigID);
	
	err = 0;
catch
	fprintf(2, 'Failed to send starttime to sql\n');
	showerror
	err = 1;
end;

