unit receiveserverservices;
{

  This unit receives a list of active servers from GPU II superserver
   and stores it in the TDbServerTable object.

  (c) 2010 by HB9TVM and the GPU Team
  This code is licensed under the GPL

}
interface

uses coreservices, servermanagers,
     servertables, loggers, downloadutils, coreconfigurations,
     XMLRead, DOM, Classes, SysUtils;

type TReceiveServerServiceThread = class(TReceiveServiceThread)
 public
  constructor Create(var servMan : TServerManager; proxy, port : String;
                     servertable : TDbServerTable; var logger : TLogger;
                     var conf : TCoreConfiguration);
 protected
    procedure Execute; override;

 private
   servertable_ : TDbServerTable;
   conf_        : TCoreConfiguration;

   procedure parseXml(var xmldoc : TXMLDocument);
end;

implementation

constructor TReceiveServerServiceThread.Create(var servMan : TServerManager; proxy, port : String;
                                               servertable : TDbServerTable; var logger : TLogger;
                                               var conf : TCoreConfiguration);
begin
 inherited Create(servMan, proxy, port, logger);
 servertable_ := servertable;
 conf_ := conf;
end;


procedure TReceiveServerServiceThread.parseXml(var xmldoc : TXMLDocument);
var
    dbrow  : TDbServerRow;
    node   : TDOMNode;
    port   : String;
begin
  logger_.log(LVL_DEBUG, 'Parsing of XML started...');
  node := xmldoc.DocumentElement.FirstChild;

  while Assigned(node) do
    begin
        try
             begin
               dbrow.externalid  :=StrToInt(node.FindNode('externalid').TextContent);
               dbrow.servername  :=node.FindNode('servername').TextContent;
               dbrow.serverurl   :=node.FindNode('serverurl').TextContent;
               dbrow.chatchannel :=node.FindNode('chatchannel').TextContent;
               dbrow.version     :=node.FindNode('version').TextContent;
               dbrow.online        := true;
               dbrow.updated       := true;
               dbrow.defaultsrv    := false;
               dbrow.superserver :=node.FindNode('superserver').TextContent='true';
               dbrow.uptime      :=StrToFloatDef(node.FindNode('uptime').TextContent, 0);
               dbrow.totaluptime :=StrToFloatDef(node.FindNode('totaluptime').TextContent, 0);
               dbrow.longitude   :=StrToFloatDef(node.FindNode('longitude').TextContent, 0);
               dbrow.latitude    :=StrToFloatDef(node.FindNode('latitude').TextContent, 0);
               dbrow.distance    := 0; // TODO: compute correct distance
                                       // TODO: assign minimal distance to default server
               dbrow.activenodes :=StrToInt(node.FindNode('activenodes').TextContent);
               dbrow.jobsinqueue :=StrToInt(node.FindNode('jobsinqueue').TextContent);

               servertable_.insertOrUpdate(dbrow);
               logger_.log(LVL_DEBUG, 'Updated or added <'+dbrow.servername+'> to tbserver table.');
             end;
          except
           on E : Exception do
              begin
                erroneous_ := true;
                logger_.log(LVL_SEVERE, '[TReceiveServerServiceThread]> Exception catched in parseXML: '+E.Message);
              end;
          end; // except

       node := node.NextSibling;
     end;  // while Assigned(node)

   logger_.log(LVL_DEBUG, 'Parsing of XML over.');
end;



procedure TReceiveServerServiceThread.Execute;
var xmldoc    : TXMLDocument;
    stream    : TMemoryStream;
    proxyseed : String;
begin
 stream  := TMemoryStream.Create;

 proxyseed  := getProxySeed;
 erroneous_ := not downloadToStream(servMan_.getSuperServerUrl()+'/supercluster/get_servers.php?randomseed='+proxyseed,
               proxy_, port_, '[TReceiveServerServiceThread]> ', logger_, stream);

 if not erroneous_ then
 begin
  try
    stream.Position := 0; // to avoid Document root is missing exception
    xmldoc := TXMLDocument.Create();
    ReadXMLFile(xmldoc, stream);
  except
     on E : Exception do
        begin
           erroneous_ := true;
           logger_.log(LVL_SEVERE, '[TReceiveServerServiceThread]> Exception catched in Execute: '+E.Message);
        end;
  end; // except

  if not erroneous_ then
    begin
     servertable_.execSQL('UPDATE tbserver set updated=0;');
     parseXml(xmldoc);
     if not erroneous_ then
       begin
        servertable_.execSQL('UPDATE tbserver set online=updated;');
        servMan_.reloadServers();
       end;
    end;
  xmldoc.Free;
 end;


 if stream <>nil then stream.Free  else logger_.log(LVL_SEVERE, '[TReceiveServerServiceThread]> Internal error in receiveserverservices.pas, stream is nil');

 done_ := true;
end;



end.
