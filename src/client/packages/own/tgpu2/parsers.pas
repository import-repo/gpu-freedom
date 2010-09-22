unit parser;
{
 The parser reads a GPU string and converts into a stack by executing the sequence of 
 commands on the string.

  (c) by 2002-2010 the GPU Development Team
  (c) by 2010 HB9TVM
  This unit is released under GNU Public License (GPL)
}

interface

uses argretrievers, stacks, pluginmanager, methodcontrollers, specialcommands;

type TGPUParser = class(TObject);
 public 
   constructor Create(var core :TGPU2Core; var job : TJob; threadId : Longint);
   destructor Destroy();
   
   function parse() : Boolean; overload;  
   function parse(jobStr : String; var stk : TStack; var error : TGPUError) : Boolean; overload;
   
 private
   core_           : TGPU2Core;
   plugman_        : TPluginManager;
   methController_ : TMethodController;
   speccommands_   : TSpecialCommand;  
   thrdId_         : Longint;
   job_            : TJob;
end;


implementation

constructor TGPUParser.Create(var core : TGPU2Core; var job : TJob; threadId : Longint);
begin
  inherited Create();
  core_    := core;
  plugMan_ := core_getPluginManager();
  methController_ := core.getMethController();
  speccommands_ := core.getSpecCommands();
  job_ := job;
  thrdId_ := threadId;
end;

destructor TGPUParser.Destroy();
begin
  inherited;
end;


procedure TGPUParser.parse() : Boolean;; overload;
begin
   Result := parse(job_.job, job_.Stack, job_.error);
   job_.hasError := (job._error.ErrorId>0);
   
   if (Result<>job_.hasError) then raise Exception.Create('Internal error in TGPUParser.Parse()!');
end;

procedure TGPUParser.parse(jobStr : String; var stk : TStack; var error : TGPUError); overload;
var arg    : TGPUArg;
    argRetriever : TArgRetriever;
    isOK         : Boolean;
	pluginName   : String;
begin
  Result := False;
  argRetriever := TArgRetriever.Create(jobStr);
  hasErrors := false;
  
  while (argRetriever_.hasArguments() and (isOK)) do
     begin
       arg := getArgument(error);
       case arg.argType of
       
            GPU_ARG_ERROR :  isOK := false; // the error structure contains the error
            GPU_ARG_FLOAT : // a float was detected
                     isOK := pushFloat(arg.argvalue, stk, error); 
                   
            GPU_ARG_STRING : // a string was detected
                     isOK := pushStr(arg.argstring, stk, error);
            GPU_ARG_BOOLEAN :
                     isOK := pushBool(arg.argvalue, stk, error);
            GPU_ARG_EXPRESSION :
                     // we found an expression, we need to recursively call this method
                     isOK := parse(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_NODE :
                     isOK := speccommands_.execNodeCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_USER :
                     isOK := speccommands_.execUserCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_THREAD :
                     isOK := speccommands_.execThreadCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_PLUGIN :
                     isOK := speccommands_.execPluginCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_FRONTEND :
                     isOK := speccommands_.execFrontendCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_RESULT :
                     isOK := speccommands_.execResultCommand(arg.argstring, stk, error);
            GPU_ARG_SPECIAL_CALL_CORE :
                     isOK := speccommands_.execCoreCommand(arg.argstring, stk, error);
                     
            GPU_ARG_CALL :
                   begin
                     isOK := plugman_.method_exists(arg.argstring, pluginName, error);
					 if isOK then
					      begin
						    methController_.registerMethodCall(arg.argstring, pluginName, thrdID_);
							try
							  isOK := plugman_.method_execute(arg.argstring, pluginName, error);
							except (Exception e)
							  error.errorID := PLUGIN_THREW_EXCEPTION_ID;
							  error.errorMsg := PLUGIN_THREW_EXCEPTION;
							  error.errorArg := e.Message;
							  isOK := false;
							end;
							methController_.unregisterMethodCall(thrdID_);
						  end;

                   end;				   
       
       end; // case
     
     end; // while
   
   argRetriever.Free;
   Result := isOK;
end;

end.