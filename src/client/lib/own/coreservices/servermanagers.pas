unit servermanagers;
{
  This unit manages GPU II servers, it can cicly give them back via
   getServerURL, or the default server url can be retrieved as well

  (c) 2010 by HB9TVM and the GPU Team
  This code is licensed under the GPL
}
interface

uses SyncObjs, Sysutils, Classes, servertables;

type TServerManager = class(TObject)
   public
    constructor Create(urls : TStringList; defaultserver, superserver : Longint; servertable : TDbServerTable);
    destructor Destroy;

    function getServerUrl : String;
    function getDefaultServerUrl : String;
    function getSuperServerUrl : String;

    procedure reloadServers();

   private
    defaultserver_ : Longint;
    superserver_   : Longint;
    urls_          : TStringList;
    cs_            : TCriticalSection;
    count_         : Longint;
    servertable_   : TDbServerTable;

    procedure verify();
end;

implementation

constructor TServerManager.Create(urls : TStringList; defaultserver, superserver : Longint; servertable : TDbServerTable);
begin
  inherited Create;
  urls_ := urls;
  defaultserver_ := defaultserver;
  superserver_ := superserver;
  cs_ := TCriticalSection.Create();
  count_ := 0;
  servertable_ := servertable;

  verify();
end;

destructor TServerManager.Destroy;
begin
  cs_.Free;
end;

function TServerManager.getServerUrl : String;
begin
  cs_.Enter;
  Result := urls_.Strings[count_];
  Inc(count_);
  if (count_)>(urls_.Count-1) then count_ := 0;
  cs_.Leave;
end;

function TServerManager.getDefaultServerUrl : String;
begin
  cs_.Enter;
  Result := urls_.Strings[defaultserver_];
  cs_.Leave;
end;

function TServerManager.getSuperServerUrl : String;
begin
  cs_.Enter;
  Result := urls_.Strings[superserver_];
  cs_.Leave;
end;


procedure TServerManager.reloadServers();
begin
 cs_.Enter;
 //TODO: implement it
 cs_.Leave;

 verify();
end;

procedure TServerManager.verify();
begin
  if urls_.Count = 0 then
     raise Exception.Create('TServerManager.Create: url_ is empty');
  if defaultserver_ > (urls_.Count-1) then
      raise Exception.Create('TServerManager.Create: defaultserver is out of range (>'+IntToStr(urls_.Count-1)+')');
end;

end.
