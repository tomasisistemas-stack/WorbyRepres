unit unPrincipal;

interface

uses
  {$IFDEF ANDROID}
  ServiceUnit,
  {$ENDIF}
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Threading, System.Math,
  System.DateUtils,
  System.JSON, System.Permissions, FMX.Platform, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.DialogService,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Memo,
  FMX.Memo.Types, FMX.ScrollBox, FireDAC.Comp.Client, unFuncoes;

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
    FRepresentanteFuncionario: string;
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
    function RepresentantePermiteVisitas: Boolean;
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
    procedure MenuVisitasClick(Sender: TObject);
    procedure MenuLogoffClick(Sender: TObject);
  public
    id_representante: Integer;
    FRepNome: string;
    procedure AtualizarContextoUsuario(AUser: TJSONObject);
    {$IFDEF ANDROID}
    procedure PauseLocationServiceForSync;
    procedure FinishLocationSyncPause;
    procedure ResumeLocationServiceAfterSync;
    procedure AtivarGpsTelaVisitas;
    {$ENDIF}
    procedure RegistrarTelaAtual(const AScreen: string);
    procedure RestaurarFormulario(const AScreen: string; ARegistroId: Integer = 0);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

uses
  unDMApp,
  unClientes,
  unClienteDetalhe,
  unSync,
  unPedido,
  unPedidoItem,
  unPedidosDigitados,
  unPedidosEnviados,
  unDashBoard,
  unVisitas,
  unLogin
  {$IFDEF ANDROID}
  , Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Os,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.App, Androidapi.JNI.Provider,
  Androidapi.JNI.Net, Androidapi.Log
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
  CGpsServiceEnabled = True;

procedure LogGPSApp(const AText: string);
var
  LText: UTF8String;
begin
  LText := UTF8String(AText);
  __android_log_write(android_LogPriority.ANDROID_LOG_INFO, 'WorbyRepresGPS', MarshaledAString(LText));
end;

function CanRunLocationServiceBrasiliaNow: Boolean;
var
  LBrasiliaNow: TDateTime;
  LTime: TTime;
begin
  try
    LBrasiliaNow := IncHour(TTimeZone.Local.ToUniversalTime(Now), -3);
  except
    LBrasiliaNow := Now;
  end;

  LTime := TimeOf(LBrasiliaNow);
  Result := (LTime >= EncodeTime(7, 30, 0, 0)) and (LTime < EncodeTime(18, 0, 0, 0));
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
  LFuncionarioValue: TJSONValue;
  LRepresentanteObjValue: TJSONValue;
  LQuery: TFDQuery;
  LLocalFuncionario: string;
begin
  id_representante := 0;
  FRepNome := '';
  FUsuarioLogin := '';
  FRepresentanteFuncionario := '';

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

      LFuncionarioValue := LUserObj.GetValue('funcionario');
      if not Assigned(LFuncionarioValue) then
        LFuncionarioValue := AUser.GetValue('funcionario');
      if (not Assigned(LFuncionarioValue)) then
      begin
        LRepresentanteObjValue := AUser.GetValue('representante');
        if LRepresentanteObjValue is TJSONObject then
          LFuncionarioValue := TJSONObject(LRepresentanteObjValue).GetValue('funcionario');
      end;
      if Assigned(LFuncionarioValue) then
      begin
        FRepresentanteFuncionario := Trim(LFuncionarioValue.Value);
        dmApp.SetAppConfigValue('representante_funcionario', Trim(LFuncionarioValue.Value))
      end
      else
      begin
        LLocalFuncionario := '';
        if id_representante > 0 then
        begin
          LQuery := TFDQuery.Create(nil);
          try
            try
              LQuery.Connection := dmApp.FDConnection;
              LQuery.SQL.Text :=
                'select coalesce(funcionario, '''') as funcionario ' +
                'from representante where id = :p0 or cod_tablet = :p0 limit 1';
              LQuery.ParamByName('p0').AsInteger := id_representante;
              LQuery.Open;
              if not LQuery.IsEmpty then
                LLocalFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
            except
              LLocalFuncionario := '';
            end;
          finally
            LQuery.Free;
          end;
        end;

        FRepresentanteFuncionario := LLocalFuncionario;
        dmApp.SetAppConfigValue('representante_funcionario', LLocalFuncionario);
      end;
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
    ApplyOrientationLayout;
    Exit;
  end;
  {$ENDIF}

  AtualizarCabecalho;
  ApplyOrientationLayout;
  Application.ProcessMessages;

  {$IFDEF ANDROID}
  if CGpsServiceEnabled then
  begin
    if RepresentantePermiteGps then
    begin
      EnviarGeoPendentesAsync;
      AtivarGpsTelaVisitas;
    end
    else
      StopLocationServiceIfBlocked;
  end;
  {$ENDIF}
end;

procedure TfrmPrincipal.BtnConectarClick(Sender: TObject);
begin
  RegistrarTelaAtual('sync');
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
  RegistrarTelaAtual('clientes');
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosClick(Sender: TObject);
begin
  RegistrarTelaAtual('clientes');
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  frmPedido.PrepararNovoPedido;
  EnsurePedidoForm;
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosDigitadosClick(Sender: TObject);
begin
  RegistrarTelaAtual('pedidos_digitados');
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  if not Assigned(frmPedidosDigitados) then
    Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
  frmPedidosDigitados.Show;
end;

procedure TfrmPrincipal.MenuPedidosEnviadosClick(Sender: TObject);
begin
  RegistrarTelaAtual('pedidos_enviados');
  if not Assigned(frmPedidosEnviados) then
    Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  frmPedidosEnviados.Show;
end;


procedure TfrmPrincipal.MenuProdutosClick(Sender: TObject);
begin
  RegistrarTelaAtual('pedido_item');
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuVendasClick(Sender: TObject);
begin
  RegistrarTelaAtual('pedido');
  EnsurePedidoForm;
  frmPedido.Show;
end;

procedure TfrmPrincipal.MenuTitulosClick(Sender: TObject);
begin
  RegistrarTelaAtual('pedido_item');
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuComissoesClick(Sender: TObject);
begin
  RegistrarTelaAtual('sync');
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuConfigClick(Sender: TObject);
begin
  RegistrarTelaAtual('sync');
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuSuporteClick(Sender: TObject);
begin
  RegistrarTelaAtual('sync');
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuDashboardClick(Sender: TObject);
begin
  RegistrarTelaAtual('dashboard');
  if not Assigned(frmDashBoard) then
    Application.CreateForm(TfrmDashBoard, frmDashBoard);
  frmDashBoard.Show;
end;

procedure TfrmPrincipal.MenuVisitasClick(Sender: TObject);
begin
  {$IFDEF ANDROID}
  if not RepresentantePermiteVisitas then
    Exit;
  AtivarGpsTelaVisitas;
  {$ENDIF}

  RegistrarTelaAtual('visitas');
  if not Assigned(frmVisitas) then
    Application.CreateForm(TfrmVisitas, frmVisitas);
  frmVisitas.Show;
end;

procedure TfrmPrincipal.MenuLogoffClick(Sender: TObject);
begin
  try
    dmApp.SetAppConfigValue('login_saida_manual', '1');
    dmApp.SetAppConfigValue('representante_funcionario', '0');
    dmApp.SetAppConfigValue('cod_representante', '0');
    dmApp.ClearAppState('');
  except
  end;

  FRepresentanteFuncionario := '';
  id_representante := 0;
  {$IFDEF ANDROID}
  FLocationTrackingRequested := False;
  if Assigned(FLocationStartTimer) then
    FLocationStartTimer.Enabled := False;
  {$ENDIF}

  if not Assigned(frmLogin) then
    Application.CreateForm(TfrmLogin, frmLogin);

  frmLogin.Show;
  Hide;

  {$IFDEF ANDROID}
  Application.ProcessMessages;
  StopLocationServiceIfBlocked;
  {$ENDIF}
end;

procedure TfrmPrincipal.RegistrarTelaAtual(const AScreen: string);
begin
  try
    if Assigned(dmApp) then
      dmApp.SetAppState(AScreen, 0, '');
  except
    // A restauração não pode interromper a navegação normal.
  end;
end;

procedure TfrmPrincipal.RestaurarFormulario(const AScreen: string; ARegistroId: Integer);
begin
  if SameText(AScreen, 'clientes') then
    MenuClientesClick(Self)
  else if SameText(AScreen, 'pedidos_digitados') then
    MenuPedidosDigitadosClick(Self)
  else if SameText(AScreen, 'pedidos_enviados') then
    MenuPedidosEnviadosClick(Self)
  else if SameText(AScreen, 'dashboard') then
    MenuDashboardClick(Self)
  else if SameText(AScreen, 'visitas') then
    MenuVisitasClick(Self)
  else if SameText(AScreen, 'sync') then
    BtnConectarClick(Self)
  else if SameText(AScreen, 'pedido') then
    MenuVendasClick(Self)
  else if SameText(AScreen, 'pedido_item') then
    MenuProdutosClick(Self)
  else if SameText(AScreen, 'cliente_detalhe') then
  begin
    if not Assigned(frmClienteDetalhe) then
      Application.CreateForm(TfrmClienteDetalhe, frmClienteDetalhe);
    frmClienteDetalhe.SetCliente('', IntToStr(ARegistroId), '');
    frmClienteDetalhe.Show;
  end;
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
  AtivarGpsTelaVisitas;
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

function TfrmPrincipal.RepresentantePermiteVisitas: Boolean;
var
  LQuery: TFDQuery;
  LFuncionario: string;

  function FuncionarioPermite(const AValue: string): Boolean;
  var
    LValue: string;
    LNumber: Double;
    LFormat: TFormatSettings;
  begin
    LValue := Trim(AValue);
    Result := SameText(LValue, '1') or SameText(LValue, '4');
    if Result or (LValue = '') then
      Exit;

    LFormat := TFormatSettings.Invariant;
    if TryStrToFloat(StringReplace(LValue, ',', '.', [rfReplaceAll]), LNumber, LFormat) then
      Result := (Trunc(LNumber) = 1) or (Trunc(LNumber) = 4);
  end;

  function LerFuncionarioLocal(out AFuncionario: string): Boolean;
  begin
    Result := False;
    AFuncionario := '';

    LQuery.Close;
    LQuery.SQL.Text :=
      'select coalesce(funcionario, '''') as funcionario ' +
      'from representante where id = :p0 or cod_tablet = :p0 limit 1';
    LQuery.ParamByName('p0').AsInteger := id_representante;
    LQuery.Open;

    if not LQuery.IsEmpty then
    begin
      AFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
      Result := AFuncionario <> '';
    end;
  end;
begin
  Result := False;
  if id_representante <= 0 then
    Exit;

  LFuncionario := Trim(FRepresentanteFuncionario);

  if LFuncionario <> '' then
  begin
    Result := FuncionarioPermite(LFuncionario);
    LogGPSApp('RepresentantePermiteVisitas memoria rep=' + id_representante.ToString +
      ' funcionario=' + LFuncionario + ' permite=' + BoolToStr(Result, True));
    Exit;
  end;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    try
      if not LerFuncionarioLocal(LFuncionario) then
      begin
        // Fallback para quando a tabela representante ainda nao foi sincronizada.
        try
          LFuncionario := Trim(dmApp.FDConnection.ExecSQLScalar(
            'select coalesce(value, '''') from app_config where key = ''representante_funcionario'''));
        except
          LFuncionario := '';
        end;
      end;

      if LFuncionario <> '' then
        Result := FuncionarioPermite(LFuncionario)
      else
        Result := False;
      LogGPSApp('RepresentantePermiteVisitas local rep=' + id_representante.ToString +
        ' funcionario=' + LFuncionario + ' permite=' + BoolToStr(Result, True));
    except
      Result := False;
      LogGPSApp('RepresentantePermiteVisitas erro local rep=' + id_representante.ToString);
    end;
  finally
    LQuery.Free;
  end;
end;

function TfrmPrincipal.RepresentantePermiteGps: Boolean;
begin
  Result := CGpsServiceEnabled and CanRunLocationServiceBrasiliaNow and RepresentantePermiteVisitas;

  if not Result then
  begin
    FLocationTrackingRequested := False;
    if Assigned(FLocationStartTimer) then
      FLocationStartTimer.Enabled := False;
  end;
end;

procedure TfrmPrincipal.StopLocationServiceIfBlocked;
var
  LIntent: JIntent;
begin
  FLocationTrackingRequested := False;
  if Assigned(frmVisitas) then
    frmVisitas.DesativarGpsLocal;
  try
    LIntent := TJIntent.JavaClass.init;
    LIntent.setClassName(
      TAndroidHelper.Context.getPackageName,
      StringToJString('com.embarcadero.services.ForegroundLocationService'));
    LIntent.setAction(StringToJString('com.embarcadero.intent.action.DISABLE_LOCATION_TRACKING'));
    TAndroidHelper.Context.startService(LIntent);
    LogGPSApp('StopLocationServiceIfBlocked disable action enviada');
  except
    on E: Exception do
      LogGPSApp('StopLocationServiceIfBlocked erro: ' + E.ClassName + ' - ' + E.Message);
  end;
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
  StopLocationServiceIfBlocked;
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
    RequestLocationTrackingPermission;
  end;
end;

procedure TfrmPrincipal.AtivarGpsTelaVisitas;
begin
  LogGPSApp('AtivarGpsTelaVisitas');
  if not RepresentantePermiteGps then
  begin
    StopLocationServiceIfBlocked;
    Exit;
  end;
  ResumeLocationServiceAfterSync;
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
var
  LIntent: JIntent;
begin
  if (not CGpsServiceEnabled) or (not CanRunLocationServiceBrasiliaNow) then
  begin
    FLocationTrackingRequested := False;
    if CGpsServiceEnabled then
      LogGPSApp('StartLocationServiceIntent bloqueado por horario Brasilia');
    Exit;
  end;

  try
    LIntent := TJIntent.JavaClass.init;
    LIntent.setClassName(
      TAndroidHelper.Context.getPackageName,
      StringToJString('com.embarcadero.services.ForegroundLocationService'));
    TAndroidHelper.Context.startService(LIntent);
    FLocationTrackingRequested := True;
    LogGPSApp('StartLocationServiceIntent executado sdk=' +
      TJBuild_VERSION.JavaClass.SDK_INT.ToString);
  except
    on E: Exception do
    begin
      FLocationTrackingRequested := False;
      LogGPSApp('StartLocationServiceIntent erro: ' + E.ClassName + ' - ' + E.Message);
    end;
  end;
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
  LShowVisitas: Boolean;
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
    LBottomMargin := AndroidBottomSafeMargin(LIsLandscape);
    LRightSafe := Max(0, AndroidNavigationInset(True) + 8);
  end
  else
  begin
    TopBar.Height := 96;
    lbottom.Height := 72;
    LBottomMargin := AndroidBottomSafeMargin(LIsLandscape);
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
  lySair.Width := 84;
  lySair.Height := lbottom.Height;
  rSair.Height := lySair.Height;
  imSair.Align := TAlignLayout.None;
  imSair.SetBounds((lySair.Width - 30) / 2, 3, 30, 30);
  lbSair.Align := TAlignLayout.None;
  lbSair.SetBounds(0, 32, lySair.Width, 18);
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
    LBaseContentH := 438;
  end
  else
  begin
    if LIsTablet then
    begin
      if LIsLandscape then
        LBaseContentW := Min(560, LScrollW - (LPadX * 2))
      else
        LBaseContentW := Min(500, LScrollW - 48);
    end
    else
      LBaseContentW := Min(350, LScrollW - (LPadX * 2));
    if LBaseContentW < 300 then
      LBaseContentW := Max(260, LScrollW - (LPadX * 2));
    if LIsTablet then
      LBaseContentH := 156 + LGap + 438 + 16
    else
      LBaseContentH := 128 + LGap + 380 + 16;
  end;

  lyCenter.Align := TAlignLayout.None;
  lyCenter.Width := LBaseContentW;
  lyCenter.Height := LBaseContentH;
  lyCenter.Scale.X := 1;
  lyCenter.Scale.Y := 1;
  lyCenter.Position.X := Max(LPadX, (LScrollW - LBaseContentW) / 2);
  if LIsTablet then
    lyCenter.Position.Y := Max(12, (LScrollH - LBaseContentH) / 2)
  else
    lyCenter.Position.Y := 12;

  Card.Align := TAlignLayout.None;
  MenuGrid.Align := TAlignLayout.None;
  if LIsTablet then
  begin
    if (not LIsLandscape) and (not LCanSideBySide) then
      Card.Width := Min(460, LBaseContentW)
    else
      Card.Width := Min(420, LBaseContentW);
    Card.Height := 148;
    if (not LIsLandscape) and (not LCanSideBySide) then
      MenuGrid.Width := Min(460, LBaseContentW)
    else
      MenuGrid.Width := Min(420, LBaseContentW);
    MenuGrid.Height := 438;
  end
  else
  begin
    Card.Width := Min(350, LBaseContentW);
    Card.Height := 128;
    MenuGrid.Width := Min(325, LBaseContentW);
    MenuGrid.Height := 380;
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

  LMenuW := (MenuGrid.Width - 18) / 2;
  if LIsTablet then
    LMenuH := 92
  else
    LMenuH := 80;

  {$IFDEF ANDROID}
  LShowVisitas := RepresentantePermiteVisitas;
  {$ELSE}
  LShowVisitas := True;
  {$ENDIF}

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
  if Assigned(LMenuObj) then
  begin
    LMenuObj.Visible := LShowVisitas;
    LMenuObj.SetBounds(LMenuW + 18, (LMenuH + 16) * 2, LMenuW, LMenuH);
  end;

  LMenuObj := FindComponent('Menu7') as TControl;
  if Assigned(LMenuObj) then
  begin
    LMenuObj.Visible := True;
    if LShowVisitas then
      LMenuObj.SetBounds(0, (LMenuH + 16) * 3, LMenuW, LMenuH)
    else
      LMenuObj.SetBounds(LMenuW + 18, (LMenuH + 16) * 2, LMenuW, LMenuH);
  end;
end;

procedure TfrmPrincipal.imSairClick(Sender: TObject);
begin
  // Fechar a tela nao encerra a sessao nem o rastreamento do servico.
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
