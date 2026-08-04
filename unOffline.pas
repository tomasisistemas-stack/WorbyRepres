unit unOffline;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Maps,
  System.Net.HttpClient, System.Net.URLClient, System.JSON, System.Generics.Collections,
  System.Sensors, System.Sensors.Components, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, System.Net.HttpClientComponent,
  FMX.WebBrowser, System.IOUtils
  {$IFDEF ANDROID}
  ,Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.App, FMX.Helpers.Android,
  Androidapi.Helpers, Androidapi.JNI.Net, Androidapi.JNI.JavaTypes
  {$ENDIF}
  ;


type
  TfrmOffline = class(TForm)
    lbottom: TLayout;
    rfundo: TRectangle;
    rReconectar: TRectangle;
    imgReconectar: TImage;
    lbReconectar: TLabel;
    imgDisconnect: TImage;
    ltop: TLayout;
    Rectangle1: TRectangle;
    lbTop: TLabel;
    tmConexao: TTimer;
    Rectangle2: TRectangle;
    imgSair: TImage;
    Label1: TLabel;
    procedure imgReconectarClick(Sender: TObject);
    procedure tmConexaoTimer(Sender: TObject);
    procedure imgSairClick(Sender: TObject);
  private
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    { Private declarations }
  protected
    procedure DoShow; override;
  public
    { Public declarations }
  end;

var
  frmOffline: TfrmOffline;

implementation

{$R *.fmx}


uses
  unFuncoes,
  unDMApp;

procedure TfrmOffline.imgReconectarClick(Sender: TObject);
begin
  lbTop.Text := 'Reconectando...';
  imgDisconnect.Visible := false;
  if ChecarConexao then
    Close;
end;

procedure TfrmOffline.imgSairClick(Sender: TObject);
begin
  SairdoSistema;
end;

procedure TfrmOffline.tmConexaoTimer(Sender: TObject);
begin
  lbTop.Text := 'Sistema Offline';
  imgDisconnect.Visible := true;

  if ChecarConexao then
    Close;
end;

procedure TfrmOffline.DoShow;
begin
  inherited;
  if Assigned(dmApp) then
    dmApp.SetAppState('offline', 0, '');
  OnClose := FormClose;
end;

procedure TfrmOffline.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(dmApp) then
    dmApp.ClearAppState('offline');
  Action := TCloseAction.caFree;
  frmOffline := nil;
end;

end.