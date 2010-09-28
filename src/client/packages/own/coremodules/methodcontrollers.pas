unit methodcontrollers;
{
 The object defined in this unit makes sure
 that only one function with a given name is called
 by one thread at a time. Two threads cannot be
 in the same DLL function. This should increase stability
 of the plugin mechanism
 
   (c) by 2002-2010 the GPU Development Team
  (c) by 2010 HB9TVM
  This unit is released under GNU Public License (GPL)
}
interface

uses SysUtils, Classes, SyncObjs,
     stacks, stkconstants;


type TMethodController = class(TObject)
 public 
   constructor Create();
   destructor Destroy();
      
   procedure registerMethodCall(funcName, plugName : String; threadId : Longint);
   procedure unregisterMethodCall(threadId : Longint);
   
   function isAlreadyCalled(funcName : String) : Boolean;
   
   function getMethodCall(threadId : Longint) : String;
   function getPluginName(threadId : Longint) : String;
   
   // this function is used to remember functions, which are
   // allowed to run concurrently despite the mechanism implemented
   // in this unit.
   // terragen function is such an example
   procedure allowRunningFunctionConcurrently(funcName : String);
   // clears contents, for example needed if user wants to reset
   // the virtual machine
   procedure clear();

 private
   method_call_ : Array[1..MAX_THREADS] of String;
   plugin_name_ : Array[1..MAX_THREADS] of String;
   CS_ : TCriticalSection;
   concurrently_allowed_ : TStringList;
end;

implementation

constructor TMethodController.Create();
begin
  inherited Create;
  CS_ := TCriticalSection.Create;
  concurrently_allowed_ := TStringList.Create;
  clear();
end;

destructor TMethodController.Destroy();
begin
 CS_.Free;
 concurrently_allowed_.Free;
 inherited;
end;
   

procedure TMethodController.registerMethodCall(funcName, plugName : String; threadId : Longint);
begin
  CS_.Enter;
  // exception to the rule: if the function is allowed to run
 // concurrently, we simply do not register the function, such that the
 // FunctionCallController is out of order for that particular functions
  if not (concurrently_allowed_.IndexOf(funcName)>-1) then
    begin  
     method_call_[threadId]  := funcName;
     plugin_name_[threadId] := plugName;
    end; 
  CS_.Leave;
end;

procedure TMethodController.unregisterMethodCall(threadId : Longint);
begin
  CS_.Enter;
  method_call_[threadId] := '';
  plugin_name_[threadId] := '';
  CS_.Leave;  
end;

function TMethodController.isAlreadyCalled(funcName : String) : Boolean;
var i : Longint;
begin
  CS_.Enter;
  Result := true;
  for i:=1 to MAX_THREADS do
     if (method_call_[i] = funcName) then
         begin
           CS_.Leave;
           Exit;
         end;
  Result := false;       
  CS_.Leave;
end;   

function TMethodController.getMethodCall(threadId : Longint) : String;
begin
  // these are merely informative. Therefore no critical section thing
  Result := method_call_[threadId];
end;

function TMethodController.getPluginName(threadId : Longint) : String;
begin
  // these are merely informative. Therefore no critical section thing
 Result := plugin_name_[threadId];
end;

procedure TMethodController.allowRunningFunctionConcurrently(funcName : String);
begin
 CS_.Enter;
 concurrently_allowed_.Add(funcName);
 CS_.Leave;
end;

procedure TMethodController.clear();
var i : Longint;
begin
 for i:=1 to MAX_THREADS do method_call_[i] := '';
 for i:=1 to MAX_THREADS do plugin_name_[i] := '';
end;

end.
