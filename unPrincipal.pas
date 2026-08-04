unit unPrincipal;

interface

uses
  {$IFDEF ANDROID}
  ServiceUnit,
  {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Threading, System.Math,
  System.JSON, System.Permissions, FMX.Platform, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.DialogService,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Memo,
  FMX.Memo.Types, FMX.ScrollBox, unFuncoes;

type
  TfrmPrincipal = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    Card: TRectangle;
    LbRepNome: TLabel;
    LbRepCodigo: TLabel;
    LbUsuario: TLabel;
    MenuGrid: TLayout;
    BtnConectar: TButton;
    ProgressBarSync: TProgressBar;
    LbProgresso: TLabel;
    MemoLog: TMemo;
    lbottom: TLayout;
    lySaidas: TLayout;
    rSaidas: TRectangle;
    ImSaidas: TImage;
    lbSaidas: TLabel;
    lySair: TLayout;
    rSair: TRectangle;
    imSair: TImage;
    lbSair: TLabel;
    imgOrdEd: TImage;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    lyCenter: TLayout;
    procedure BtnConectarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure imSairClick(Sender: TObject);
    procedure MenuPedidosEnviadosClick(Sender: TObject);
  private
    FContentScroll: TVertScrollBox;
    FLbVersao: TLabel;
    FUsuarioLogin: string;
    FQueueLogText: string;
    FQueueDoneMsg: string;
    FQueueErrMsg: string;
    FQueueSyncTableName: string;
    FQueueSyncInserted: Integer;
    FQueueSyncTotal: Integer;
    FQueueSyncIsNewTable: Boolean;
    {$IFDEF ANDROID}
    FLocationTrackingRequested: Boolean;
    FLocationPermissionRequested: Boolean;
    FLocationStartupAttempted: Boolean;
    FGeoSendBusy: Boolean;
    FSegundoPlanoSolicitado: Boolean;
    FSurfaceRecoverQueued: Boolean;
    FSurfaceRecoverTicks: Integer;
    FLocationStartTimer: TTimer;
    FSurfaceRecoverTimer: TTimer;
    procedure LocationStartTimerTimer(Sender: TObject);
    procedure SurfaceRecoverTimerTimer(Sender: TObject);
    function HandleApplicationEvent(ApplicationEvent: TApplicationEvent; Context: TObject): Boolean;
    procedure QueueRecoverAndroidSurface;
    procedure DoRecoverAndroidSurface;
    function HasLocationTrackingPermission: Boolean;
    function RepresentantePermiteGps: Boolean;
    procedure RequestLocationTrackingPermission;
    procedure LocationPermissionsResult(Sender: TObject; const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray);
    procedure LocationPermissionRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
    procedure StartLocationServiceIntent;
    procedure StartForegroundKeepAliveIntent;
    procedure StopForegroundKeepAliveIntent;
    procedure StopLocationServiceIfBlocked;
    procedure EnviarGeoPendentesAsync;
    procedure SolicitarLiberacaoSegundoPlano;
    {$ENDIF}
    procedure AtualizarCabecalho;
    procedure EnsureVersionLabel;
    procedure EnsureContentScroll;
    procedure SincronizarTudo;
    procedure EnsureSyncForm;
    procedure EnsurePedidoForm;
    procedure EnsurePedidoItemForm;
    procedure ApplyOrientationLayout;
    procedure DoQueueLog;
    procedure DoQueueDone;
    procedure DoQueueError;
    procedure DoQueueSyncProgress;
    procedure SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
  published
    procedure MenuClientesClick(Sender: TObject);
    procedure MenuPedidosClick(Sender: TObject);
    procedure MenuPedidosDigitadosClick(Sender: TObject);
    procedure MenuProdutosClick(Sender: TObject);
    procedure MenuVendasClick(Sender: TObject);
    procedure MenuTitulosClick(Sender: TObject);
    procedure MenuComissoesClick(Sender: TObject);
    procedure MenuConfigClick(Sender: TObject);
    procedure MenuSuporteClick(Sender: TObject);
    procedure MenuDashboardClick(Sender: TObject);
    procedure MenuLogoffClick(Sender: TObject);
  public
    id_representante: Integer;
    FRepNome: string;
    procedure AtualizarContextoUsuario(AUser: TJSONObject);
    {$IFDEF ANDROID}
    procedure PauseLocationServiceForSync;
    procedure FinishLocationSyncPause;
    procedure ResumeLocationServiceAfterSync;
    {$ENDIF}
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

uses
  unDMApp,
  unClientes,
  unSync,
  unPedido,
  unPedidoItem,
  unPedidosDigitados,
  unPedidosEnviados,
  unDashBoard,
  unLogin
  {$IFDEF ANDROID}
  , System.DateUtils, Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Os,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.App, Androidapi.JNI.Provider,
  Androidapi.JNI.Net, Androidapi.Log, FireDAC.Comp.Client
  {$ENDIF};

const
  CTabelasSyncFiltradas: array[0..7] of string = (
    'representante',
    'cliente',
    'vendas1',
    'vendas2',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );

  CTabelasSyncGlobais: array[0..6] of string = (
    'produto',
    'subcategoria',
    'fop',
    'prazo',
    'cidades',
    'grade_comissao',
    'escala_comissao'
  );

{$IFDEF ANDROID}
const
  CForegroundKeepAliveEnabled = False;
  CGpsServiceEnabled = False;

procedure LogGPSApp(const AText: string);
var
  LText: UTF8String;
begin
  LText := UTF8String(AText);
  __android_log_write(android_LogPriority.ANDROID_LOG_INFO, 'WorbyRepresGPS', MarshaledAString(LText));
end;
{$ENDIF}

procedure TfrmPrincipal.EnsureVersionLabel;
begin
  if not Assigned(FLbVersao) then
  begin
    FLbVersao := TLabel.Create(Self);
    FLbVersao.Parent := lbottom;
    FLbVersao.Align := TAlignLayout.None;
    FLbVersao.StyledSettings := [];
    FLbVersao.TextSettings.Font.Size := 11;
    FLbVersao.TextSettings.FontColor := $FF6B7280;
    FLbVersao.TextSettings.HorzAlign := TTextAlign.Leading;
    FLbVersao.TextSettings.VertAlign := TTextAlign.Center;
    FLbVersao.HitTest := False;
  end;
  FLbVersao.Text := 'Versao ' + AppVersionName;
  FLbVersao.Visible := True;
  FLbVersao.BringToFront;
end;
procedure TfrmPrincipal.AtualizarCabecalho;
begin
  LbUsuario.Text := 'Usuario: ' + FUsuarioLogin;
  LbRepNome.Text := 'Representante: ' + FRepNome;
  LbRepCodigo.Text := 'Codigo: ' + id_representante.ToString;
end;

procedure TfrmPrincipal.AtualizarContextoUsuario(AUser: TJSONObject);
var
  LUserValue: TJSONValue;
  LUserObj: TJSONObject;
  LRepresentanteValue: TJSONValue;
  LNomeValue: TJSONValue;
  LLoginValue: TJSONValue;
begin
  id_representante := 0;
  FRepNome := '';
  FUsuarioLogin := '';

  if Assigned(AUser) then
  begin
    LUserObj := nil;
    LUserValue := AUser.GetValue('user');
    if LUserValue is TJSONObject then
      LUserObj := TJSONObject(LUserValue)
    else
      LUserObj := AUser;

    if Assigned(LUserObj) then
    begin
      LRepresentanteValue := LUserObj.GetValue('cod_representante');
      if not Assigned(LRepresentanteValue) then
        LRepresentanteValue := LUserObj.GetValue('id_representante');
      if Assigned(LRepresentanteValue) then
        id_representante := StrToIntDef(LRepresentanteValue.Value, 0);

      LNomeValue := LUserObj.GetValue('nome');
      if not Assigned(LNomeValue) then
        LNomeValue := LUserObj.GetValue('nomusu');
      if not Assigned(LNomeValue) then
        LNomeValue := LUserObj.GetValue('nom_representante');
      if Assigned(LNomeValue) then
        FRepNome := LNomeValue.Value;

      LLoginValue := LUserObj.GetValue('logusu');
      if not Assigned(LLoginValue) then
        LLoginValue := LUserObj.GetValue('login');
      if not Assigned(LLoginValue) then
        LLoginValue := LUserObj.GetValue('usuario');
      if Assigned(LLoginValue) then
        FUsuarioLogin := LLoginValue.Value;
    end;
  end;

  {$IFDEF ANDROID}
  StopLocationServiceIfBlocked;
  if id_representante > 0 then
  begin
    dmApp.SetAppConfigValue('cod_representante', id_representante.ToString);
    dmApp.SetAppConfigValue('login_saida_manual', '0');
  end;
  FLocationStartupAttempted := False;
  FLocationTrackingRequested := False;
  if Assigned(FLocationStartTimer) then
    FLocationStartTimer.Enabled := False;

  if not CGpsServiceEnabled then
  begin
    AtualizarCabecalho;
    Exit;
  end;

  if RepresentantePermiteGps and Assigned(FLocationStartTimer) then
  begin
    FLocationStartTimer.Interval := 1500;
    FLocationStartTimer.Enabled := True;
  end;
  {$ENDIF}

  AtualizarCabecalho;

end;

procedure TfrmPrincipal.BtnConectarClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
  {$IFDEF ANDROID}
var
  LApplicationEventService: IFMXApplicationEventService;
{$ENDIF}
begin
  EnsureContentScroll;
  {$IFDEF ANDROID}
  FLocationTrackingRequested := False;
  FLocationPermissionRequested := False;
  FLocationStartupAttempted := False;
  FGeoSendBusy := False;
  FSegundoPlanoSolicitado := False;
  FSurfaceRecoverQueued := False;
  FSurfaceRecoverTicks := 0;
  FLocationStartTimer := TTimer.Create(Self);
  FLocationStartTimer.Enabled := False;
  FLocationStartTimer.Interval := 10000;
  FLocationStartTimer.OnTimer := LocationStartTimerTimer;
  FSurfaceRecoverTimer := TTimer.Create(Self);
  FSurfaceRecoverTimer.Enabled := False;
  FSurfaceRecoverTimer.Interval := 350;
  FSurfaceRecoverTimer.OnTimer := SurfaceRecoverTimerTimer;
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(LApplicationEventService)) then
    LApplicationEventService.SetApplicationEventHandler(HandleApplicationEvent);
  {$ENDIF}
  ApplyOrientationLayout;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  {$IFDEF ANDROID}
  FreeAndNil(FSurfaceRecoverTimer);
  FreeAndNil(FLocationStartTimer);
  {$ENDIF}
end;

procedure TfrmPrincipal.MenuClientesClick(Sender: TObject);
begin
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosClick(Sender: TObject);
begin
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  frmPedido.PrepararNovoPedido;
  EnsurePedidoForm;
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosDigitadosClick(Sender: TObject);
begin
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  if not Assigned(frmPedidosDigitados) then
    Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
  frmPedidosDigitados.Show;
end;

procedure TfrmPrincipal.MenuPedidosEnviadosClick(Sender: TObject);
begin
  if not Assigned(frmPedidosEnviados) then
    Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  frmPedidosEnviados.Show;
end;


procedure TfrmPrincipal.MenuProdutosClick(Sender: TObject);
begin
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuVendasClick(Sender: TObject);
begin
  EnsurePedidoForm;
  frmPedido.Show;
end;

procedure TfrmPrincipal.MenuTitulosClick(Sender: TObject);
begin
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuComissoesClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuConfigClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuSuporteClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuDashboardClick(Sender: TObject);
begin
  if not Assigned(frmDashBoard) then
    Application.CreateForm(TfrmDashBoard, frmDashBoard);
  frmDashBoard.Show;
end;

procedure TfrmPrincipal.MenuLogoffClick(Sender: TObject);
begin
  try
    dmApp.SetAppConfigValue('login_saida_manual', '1');
    dmApp.ClearAppState('');
  except
  end;

  if not Assigned(frmLogin) then
    Application.CreateForm(TfrmLogin, frmLogin);

  frmLogin.Show;
  Hide;
end;

procedure TfrmPrincipal.EnsureSyncForm;
begin
  if not Assigned(frmSync) then
    Application.CreateForm(TfrmSync, frmSync);
end;

procedure TfrmPrincipal.EnsurePedidoForm;
begin
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
end;

procedure TfrmPrincipal.EnsurePedidoItemForm;
begin
  if not Assigned(frmPedidoItem) then
    Application.CreateForm(TfrmPedidoItem, frmPedidoItem);
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  AtualizarCabecalho;
  lySaidas.Visible := False;
  ProgressBarSync.Value := 0;
  LbProgresso.Text := 'Aguardando sincronizacao';
  ApplyOrientationLayout;
  {$IFDEF ANDROID}
  QueueRecoverAndroidSurface;
  if not CGpsServiceEnabled then
    Exit;
  if not RepresentantePermiteGps then exit;
  EnviarGeoPendentesAsync;
  if (not FLocationStartupAttempted) and Assigned(FLocationStartTimer)  then
  begin
    FLocationStartTimer.Enabled := False;
    FLocationStartTimer.Interval := 2000;
    FLocationStartTimer.Enabled := True;
  end;
  {$ENDIF}
end;

{$IFDEF ANDROID}
procedure TfrmPrincipal.LocationStartTimerTimer(Sender: TObject);
begin
  if not CGpsServiceEnabled then
  begin
    FLocationTrackingRequested := False;
    if Assigned(FLocationStartTimer) then
      FLocationStartTimer.Enabled := False;
    StopLocationServiceIfBlocked;
    Exit;
  end;

  if not RepresentantePermiteGps then
  begin
    FLocationTrackingRequested := False;
    StopLocationServiceIfBlocked;
    Exit;
  end;

  if Assigned(FLocationStartTimer) then
    FLocationStartTimer.Enabled := False;
  FLocationStartupAttempted := True;

  if not HasLocationTrackingPermission then
  begin
    RequestLocationTrackingPermission;
    Exit;
  end;

  FLocationTrackingRequested := True;
  StartLocationServiceIntent;
end;

procedure TfrmPrincipal.SurfaceRecoverTimerTimer(Sender: TObject);
begin
  LogGPSApp('SurfaceRecoverTimer tick ' + FSurfaceRecoverTicks.ToString);
  DoRecoverAndroidSurface;
end;

function TfrmPrincipal.HasLocationTrackingPermission: Boolean;
begin
  Result := True;
  if TJBuild_VERSION.JavaClass.SDK_INT >= 23 then
    Result :=
      (TAndroidHelper.Context.checkSelfPermission(
        TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION) = 0) or
      (TAndroidHelper.Context.checkSelfPermission(
        TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION) = 0);
end;

function TfrmPrincipal.RepresentantePermiteGps: Boolean;
var
  LQuery: TFDQuery;
  LFuncionario: string;

  function LerFuncionarioLocal(out AFuncionario: string): Boolean;
  begin
    Result := False;
    AFuncionario := '';

    LQuery.Close;
    LQuery.SQL.Text :=
      'select coalesce(funcionario, '''') as funcionario ' +
      'from representante where id = :p0';
    LQuery.ParamByName('p0').AsInteger := id_representante;
    LQuery.Open;

    if not LQuery.IsEmpty then
    begin
      AFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
      Result := AFuncionario <> '';
    end;
  end;
begin
  if not CGpsServiceEnabled then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  if id_representante <= 0 then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    try
      if not LerFuncionarioLocal(LFuncionario) then
      begin
        // API desativada no principal: nao sincroniza representante aqui.
        LFuncionario := '';
      end;

      if LFuncionario <> '' then
        Result := not SameText(LFuncionario, '0')
      else
        Result := False;
    except
      Result := False;
    end;
  finally
    LQuery.Free;
  end;

  if not Result then
  begin
    FLocationTrackingRequested := False;
    if Assigned(FLocationStartTimer) then
      FLocationStartTimer.Enabled := False;
  end;
end;

procedure TfrmPrincipal.StopLocationServiceIfBlocked;
begin
  FLocationTrackingRequested := False;
  LogGPSApp('StopLocationServiceIfBlocked ignorado: servico GPS desativado');
end;

procedure TfrmPrincipal.PauseLocationServiceForSync;
begin
  LogGPSApp('PauseLocationServiceForSync');
  try
    TAndroidHelper.Context
      .getSharedPreferences(StringToJString('worbyrepres_runtime'), TJContext.JavaClass.MODE_PRIVATE)
      .edit
      .putBoolean(StringToJString('sync_running'), True)
      .apply;
  except
  end;
end;

procedure TfrmPrincipal.FinishLocationSyncPause;
begin
  LogGPSApp('FinishLocationSyncPause');
  try
    TAndroidHelper.Context
      .getSharedPreferences(StringToJString('worbyrepres_runtime'), TJContext.JavaClass.MODE_PRIVATE)
      .edit
      .putBoolean(StringToJString('sync_running'), False)
      .apply;
  except
  end;
end;

procedure TfrmPrincipal.ResumeLocationServiceAfterSync;
begin
  LogGPSApp('ResumeLocationServiceAfterSync');
  FinishLocationSyncPause;
  if not CGpsServiceEnabled then
  begin
    FLocationTrackingRequested := False;
    Exit;
  end;

  if not RepresentantePermiteGps then
  begin
    FLocationTrackingRequested := False;
    StopLocationServiceIfBlocked;
    Exit;
  end;

  if HasLocationTrackingPermission then
  begin
    FLocationTrackingRequested := True;
    StartLocationServiceIntent;
  end
  else
  begin
    FLocationTrackingRequested := False;
    if Assigned(FLocationStartTimer) then
    begin
      FLocationStartTimer.Enabled := False;
      FLocationStartTimer.Interval := 2000;
      FLocationStartTimer.Enabled := True;
    end;
  end;
end;

function TfrmPrincipal.HandleApplicationEvent(ApplicationEvent: TApplicationEvent; Context: TObject): Boolean;
begin
  case ApplicationEvent of
    TApplicationEvent.BecameActive:
    begin
      LogGPSApp('ApplicationEvent BecameActive');
      QueueRecoverAndroidSurface;
      Result := True;
    end;
    TApplicationEvent.WillBecomeForeground:
    begin
      LogGPSApp('ApplicationEvent WillBecomeForeground');
      QueueRecoverAndroidSurface;
      StopForegroundKeepAliveIntent;
      // API desativada no principal: envio de pendentes fica fora desta tela.
      Result := True;
    end;
    TApplicationEvent.EnteredBackground:
    begin
      LogGPSApp('ApplicationEvent EnteredBackground');
      FSurfaceRecoverQueued := False;
      if CForegroundKeepAliveEnabled then
        StartForegroundKeepAliveIntent
      else if CGpsServiceEnabled and FLocationTrackingRequested then
        StartLocationServiceIntent;
      Result := True;
    end;
  else
    Result := False;
  end;
end;

procedure TfrmPrincipal.QueueRecoverAndroidSurface;
begin
  LogGPSApp('QueueRecoverAndroidSurface');
  FSurfaceRecoverTicks := 0;
  if Assigned(FSurfaceRecoverTimer) then
  begin
    FSurfaceRecoverTimer.Enabled := False;
    FSurfaceRecoverTimer.Interval := 350;
    FSurfaceRecoverTimer.Enabled := True;
  end;

  if FSurfaceRecoverQueued then
    Exit;

  FSurfaceRecoverQueued := True;
  TThread.Queue(nil, DoRecoverAndroidSurface);
end;

procedure TfrmPrincipal.DoRecoverAndroidSurface;
begin
  FSurfaceRecoverQueued := False;

  try
    LogGPSApp('DoRecoverAndroidSurface begin');
    if not Visible then
      LogGPSApp('DoRecoverAndroidSurface: form invisivel, tentando recuperar mesmo assim');

    try
      Focused := nil;
    except
      on E: Exception do
        LogGPSApp('DoRecoverAndroidSurface foco: ' + E.ClassName + ' - ' + E.Message);
    end;

    ApplyOrientationLayout;
    TopBar.BringToFront;
    lbottom.BringToFront;

    BackgroundRect.Repaint;
    TopBar.Repaint;
    if Assigned(FContentScroll) then
      FContentScroll.Repaint;
    lyCenter.Repaint;
    lbottom.Repaint;
    Application.ProcessMessages;
    LogGPSApp('DoRecoverAndroidSurface end');
  except
    on E: Exception do
      LogGPSApp('DoRecoverAndroidSurface erro: ' + E.ClassName + ' - ' + E.Message);
  end;

  Inc(FSurfaceRecoverTicks);
  if (FSurfaceRecoverTicks >= 12) and Assigned(FSurfaceRecoverTimer) then
    FSurfaceRecoverTimer.Enabled := False;
end;


procedure TfrmPrincipal.EnviarGeoPendentesAsync;
begin
  // API desativada no principal: nao envia geolocalizacao/visitas em background aqui.
  FGeoSendBusy := False;
end;

procedure TfrmPrincipal.SolicitarLiberacaoSegundoPlano;
var
  LPowerManager: JPowerManager;
  LIntent: JIntent;
  LPackageName: string;
  LManufacturer: string;
  LPrompted: string;
  LQuery: TFDQuery;
begin
  if FSegundoPlanoSolicitado then
    Exit;

  LPrompted := '';
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    if not dmApp.FDConnection.Connected then
      dmApp.FDConnection.Connected := True;
    LQuery.SQL.Text := 'select coalesce(value, '''') as value from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'gps_segundo_plano_solicitado';
    LQuery.Open;
    if not LQuery.IsEmpty then
      LPrompted := Trim(LQuery.FieldByName('value').AsString);
  except
    on E: Exception do
      LogGPSApp('Erro ao consultar flag segundo plano: ' + E.ClassName + ' - ' + E.Message);
  end;
  LQuery.Free;

  if SameText(LPrompted, '1') then
  begin
    FSegundoPlanoSolicitado := True;
    Exit;
  end;

  FSegundoPlanoSolicitado := True;
  dmApp.SetAppConfigValue('gps_segundo_plano_solicitado', '1');
  LPackageName := JStringToString(TAndroidHelper.Context.getPackageName);

  try
    LManufacturer := LowerCase(JStringToString(TJBuild.JavaClass.MANUFACTURER));
    if (Pos('xiaomi', LManufacturer) > 0) or
       (Pos('redmi', LManufacturer) > 0) or
       (Pos('poco', LManufacturer) > 0) then
    begin
      LIntent := TJIntent.JavaClass.init;
      LIntent.setComponent(TJComponentName.JavaClass.init(
        StringToJString('com.miui.securitycenter'),
        StringToJString('com.miui.permcenter.autostart.AutoStartManagementActivity')));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
      try
        TAndroidHelper.Context.startActivity(LIntent);
      except
        LIntent := TJIntent.JavaClass.init(StringToJString('miui.intent.action.OP_AUTO_START'));
        LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
        TAndroidHelper.Context.startActivity(LIntent);
      end;
      LogGPSApp('Aberta tela MIUI AutoStart');
      Exit;
    end;
  except
    on E: Exception do
      LogGPSApp('Erro ao abrir MIUI AutoStart: ' + E.ClassName + ' - ' + E.Message);
  end;

  try
    LPowerManager := TJPowerManager.Wrap(
      TAndroidHelper.Context.getSystemService(TJContext.JavaClass.POWER_SERVICE));
    if Assigned(LPowerManager) and
       (not LPowerManager.isIgnoringBatteryOptimizations(TAndroidHelper.Context.getPackageName)) then
    begin
      LIntent := TJIntent.JavaClass.init(
        TJSettings.JavaClass.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
        TJnet_Uri.JavaClass.parse(StringToJString('package:' + LPackageName)));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
      TAndroidHelper.Context.startActivity(LIntent);
      LogGPSApp('Solicitada liberacao de otimizacao de bateria');
      Exit;
    end;
  except
    on E: Exception do
      LogGPSApp('Erro ao solicitar otimizacao bateria: ' + E.ClassName + ' - ' + E.Message);
  end;
end;

procedure TfrmPrincipal.StartForegroundKeepAliveIntent;
begin
  LogGPSApp('StartForegroundKeepAliveIntent ignorado: servico GPS desativado');
end;

procedure TfrmPrincipal.StopForegroundKeepAliveIntent;
begin
  LogGPSApp('StopForegroundKeepAliveIntent ignorado: servico GPS desativado');
end;
procedure TfrmPrincipal.StartLocationServiceIntent;
begin
  FLocationTrackingRequested := False;
  LogGPSApp('StartLocationServiceIntent ignorado: servico GPS desativado');
end;

procedure TfrmPrincipal.RequestLocationTrackingPermission;
begin
  if not CGpsServiceEnabled then
    Exit;

  if FLocationPermissionRequested then
    Exit;

  FLocationPermissionRequested := True;

  if TJBuild_VERSION.JavaClass.SDK_INT >= 33 then
    TPermissionsService.DefaultService.RequestPermissions(
      [JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION),
       JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION),
       'android.permission.POST_NOTIFICATIONS'],
      LocationPermissionsResult,
      LocationPermissionRationale)
  else if TJBuild_VERSION.JavaClass.SDK_INT >= 29 then
    TPermissionsService.DefaultService.RequestPermissions(
      [JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION),
       JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
      LocationPermissionsResult,
      LocationPermissionRationale)
  else
    TPermissionsService.DefaultService.RequestPermissions(
      [JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION),
       JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)],
      LocationPermissionsResult,
      LocationPermissionRationale);
end;

procedure TfrmPrincipal.LocationPermissionsResult(Sender: TObject; const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
var
  I: Integer;
  LLocationGranted: Boolean;
begin
  FLocationPermissionRequested := False;
  LLocationGranted := False;
  for I := 0 to High(AGrantResults) do
    if (AGrantResults[I] = TPermissionStatus.Granted) and
       ((I <= High(APermissions)) and
        (SameText(APermissions[I], JStringToString(TJManifest_permission.JavaClass.ACCESS_COARSE_LOCATION)) or
         SameText(APermissions[I], JStringToString(TJManifest_permission.JavaClass.ACCESS_FINE_LOCATION)))) then
    begin
      LLocationGranted := True;
      Break;
    end;

  if LLocationGranted then
  begin
    if RepresentantePermiteGps then
    begin
      FLocationTrackingRequested := True;
      StartLocationServiceIntent;
    end
    else
    begin
      FLocationTrackingRequested := False;
      StopLocationServiceIfBlocked;
    end;
  end;
end;

procedure TfrmPrincipal.LocationPermissionRationale(Sender: TObject; const APermissions: TClassicStringDynArray;
  const APostRationaleProc: TProc);
begin
  APostRationaleProc;
end;

{$ENDIF}

procedure TfrmPrincipal.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmPrincipal.EnsureContentScroll;
begin
  if Assigned(FContentScroll) then
    Exit;

  FContentScroll := TVertScrollBox.Create(Self);
  FContentScroll.Parent := BackgroundRect;
  FContentScroll.Align := TAlignLayout.None;
  FContentScroll.ShowScrollBars := True;
  FContentScroll.TabOrder := 0;

  lyCenter.Parent := FContentScroll;
  lyCenter.Align := TAlignLayout.None;
  TopBar.BringToFront;
  lbottom.BringToFront;
end;

procedure TfrmPrincipal.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LGap: Single;
  LBottomMargin: Single;
  LRightSafe: Single;
  LScrollTop: Single;
  LScrollBottom: Single;
  LScrollW: Single;
  LScrollH: Single;
  LBaseContentW: Single;
  LBaseContentH: Single;
  LPadX: Single;
  LCanSideBySide: Boolean;
  LIsTablet: Boolean;
  LMenuW: Single;
  LMenuH: Single;
  LMenuObj: TControl;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  EnsureContentScroll;

  LIsLandscape := Width > Height;
  LIsTablet := Min(Width, Height) >= 600;
  LGap := 18;
  LPadX := 12;

  if LIsLandscape then
  begin
    TopBar.Height := 72;
    lbottom.Height := 58;
    LBottomMargin := 44;
    LRightSafe := Max(0, AndroidNavigationInset(True) + 8);
  end
  else
  begin
    TopBar.Height := 96;
    lbottom.Height := 72;
    LBottomMargin := 44;
    LRightSafe := 0;
  end;

  TopBar.Align := TAlignLayout.None;
  TopBar.Position.X := 0;
  TopBar.Position.Y := 0;
  TopBar.Width := Width;
  LbTitulo.Position.X := 24;
  LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) / 2;
  LbTitulo.Width := Width - 48;

  lbottom.Align := TAlignLayout.None;
  lbottom.Margins.Bottom := 0;
  lbottom.Width := Max(120, Width - LRightSafe);
  if LIsLandscape then
    lbottom.Position.X := 0
  else
    lbottom.Position.X := 0;
  lbottom.Position.Y := Height - lbottom.Height - LBottomMargin;
  if lbottom.Position.Y < TopBar.Height + 120 then
    lbottom.Position.Y := Height - lbottom.Height - 12;

  lySair.Align := TAlignLayout.MostRight;
  lySair.Width := 64;
  lySair.Height := lbottom.Height;
  rSair.Height := lySair.Height;
  EnsureVersionLabel;
  FLbVersao.SetBounds(12, (lbottom.Height - 18) / 2, Max(80, lbottom.Width - 156), 18);
  lySaidas.Align := TAlignLayout.MostRight;
  lySaidas.Width := 64;
  lySaidas.Height := lbottom.Height;

  LScrollTop := TopBar.Height;
  LScrollBottom := lbottom.Position.Y - 8;
  LScrollW := Max(1, Width - LRightSafe);
  LScrollH := LScrollBottom - LScrollTop;
  if LScrollH < 120 then
    LScrollH := Max(120, Height - TopBar.Height - lbottom.Height - LBottomMargin - 8);

  FContentScroll.Align := TAlignLayout.None;
  FContentScroll.Position.X := 0;
  FContentScroll.Position.Y := LScrollTop;
  FContentScroll.Width := LScrollW;
  FContentScroll.Height := LScrollH;
  FContentScroll.BringToFront;
  TopBar.BringToFront;
  lbottom.BringToFront;

  LCanSideBySide := LIsLandscape and ((LScrollW - (LPadX * 2)) >= (420 + LGap + 420));
  if LCanSideBySide then
  begin
    LBaseContentW := 420 + LGap + 420;
    LBaseContentH := 310;
  end
  else
  begin
    if LIsTablet then
      LBaseContentW := Min(520, LScrollW - (LPadX * 2))
    else
      LBaseContentW := Min(350, LScrollW - (LPadX * 2));
    if LBaseContentW < 300 then
      LBaseContentW := Max(260, LScrollW - (LPadX * 2));
    if LIsTablet then
      LBaseContentH := 156 + LGap + 330 + 16
    else
      LBaseContentH := 128 + LGap + 272 + 16;
  end;

  lyCenter.Align := TAlignLayout.None;
  lyCenter.Width := LBaseContentW;
  lyCenter.Height := LBaseContentH;
  lyCenter.Scale.X := 1;
  lyCenter.Scale.Y := 1;
  lyCenter.Position.X := Max(LPadX, (LScrollW - LBaseContentW) / 2);
  lyCenter.Position.Y := 12;

  Card.Align := TAlignLayout.None;
  MenuGrid.Align := TAlignLayout.None;
  if LIsTablet then
  begin
    Card.Width := Min(420, LBaseContentW);
    Card.Height := 148;
    MenuGrid.Width := Min(420, LBaseContentW);
    MenuGrid.Height := 330;
  end
  else
  begin
    Card.Width := Min(350, LBaseContentW);
    Card.Height := 128;
    MenuGrid.Width := Min(325, LBaseContentW);
    MenuGrid.Height := 272;
  end;
  Card.Scale.X := 1;
  Card.Scale.Y := 1;
  MenuGrid.Scale.X := 1;
  MenuGrid.Scale.Y := 1;

  if LCanSideBySide then
  begin
    Card.Position.X := 0;
    Card.Position.Y := (LBaseContentH - Card.Height) / 2;
    MenuGrid.Position.X := Card.Width + LGap;
    MenuGrid.Position.Y := (LBaseContentH - MenuGrid.Height) / 2;
  end
  else
  begin
    Card.Position.X := (LBaseContentW - Card.Width) / 2;
    Card.Position.Y := 0;
    MenuGrid.Position.X := (LBaseContentW - MenuGrid.Width) / 2;
    MenuGrid.Position.Y := Card.Height + LGap;
  end;

  if LIsTablet then
  begin
    LMenuW := (MenuGrid.Width - 18) / 2;
    LMenuH := 92;
    LMenuObj := FindComponent('Menu1') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(0, 0, LMenuW, LMenuH);
    LMenuObj := FindComponent('Menu2') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(LMenuW + 18, 0, LMenuW, LMenuH);
    LMenuObj := FindComponent('Menu3') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(0, LMenuH + 16, LMenuW, LMenuH);
    LMenuObj := FindComponent('Menu4') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(LMenuW + 18, LMenuH + 16, LMenuW, LMenuH);
    LMenuObj := FindComponent('Menu5') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(0, (LMenuH + 16) * 2, LMenuW, LMenuH);
    LMenuObj := FindComponent('Menu6') as TControl;
    if Assigned(LMenuObj) then LMenuObj.SetBounds(LMenuW + 18, (LMenuH + 16) * 2, LMenuW, LMenuH);
  end;
end;

procedure TfrmPrincipal.imSairClick(Sender: TObject);
begin
  try
    dmApp.SetAppConfigValue('login_saida_manual', '1');
    dmApp.ClearAppState('');
  except
  end;
  SairdoSistema;
end;

procedure TfrmPrincipal.SincronizarTudo;
begin
  // API desativada no principal: sincronizacao deve ocorrer pela tela unSync.
  ShowMessage('Sincronizacao disponivel apenas pela tela Sincronizar.');
end;

procedure TfrmPrincipal.SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
var
  LTable: string;
  LInserted: Integer;
  LTotal: Integer;
  LIsNewTable: Boolean;
begin
  LTable := ATable;
  LInserted := AInserted;
  LTotal := ATotal;
  LIsNewTable := AIsNewTable;
  FQueueSyncTableName := LTable;
  FQueueSyncInserted := LInserted;
  FQueueSyncTotal := LTotal;
  FQueueSyncIsNewTable := LIsNewTable;

  TThread.Queue(nil, DoQueueSyncProgress);
end;

procedure TfrmPrincipal.DoQueueSyncProgress;
begin
  if SameText(FQueueSyncTableName, 'cliente') and (FQueueSyncTotal = 0) then
  begin
    LbProgresso.Text := 'Buscando clientes na API...';
    Application.ProcessMessages;
    Exit;
  end;

  if SameText(FQueueSyncTableName, 'cliente') then
  begin
    LbProgresso.Text := 'Sincronizando clientes: ' +
      FQueueSyncInserted.ToString + ' / ' + FQueueSyncTotal.ToString;
    if FQueueSyncTotal > 0 then
      ProgressBarSync.Value := FQueueSyncInserted / FQueueSyncTotal;
  end
  else if FQueueSyncTotal > 0 then
    LbProgresso.Text := 'Sincronizando ' + FQueueSyncTableName + ': ' +
      FQueueSyncInserted.ToString + ' / ' + FQueueSyncTotal.ToString;
  Application.ProcessMessages;
end;

procedure TfrmPrincipal.DoQueueLog;
begin
  MemoLog.Lines.Add(FQueueLogText);
end;

procedure TfrmPrincipal.DoQueueDone;
begin
  MemoLog.Lines.Add(FQueueDoneMsg);
  ProgressBarSync.Value := 1;
  LbProgresso.Text := 'Sincronizacao concluida';
end;

procedure TfrmPrincipal.DoQueueError;
begin
  MemoLog.Lines.Add('Erro na sincronizacao: ' + FQueueErrMsg);
  LbProgresso.Text := 'Erro na sincronizacao: ' + FQueueErrMsg;
end;

end.
