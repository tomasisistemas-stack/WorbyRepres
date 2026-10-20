unit unSync;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.IOUtils, System.JSON, System.Math,
  Data.DB, FireDAC.Comp.Client,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts;

type
  TfrmSync = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    CardStatus: TRectangle;
    LbStatusTitulo: TLabel;
    LbUltimaSync: TLabel;
    ProgressBarSync: TProgressBar;
    LbProgresso: TLabel;
    ProgressBarTable: TProgressBar;
    LbProgressoTabela: TLabel;
    BtnSync: TRectangle;
    LbBtnSync: TLabel;
    LayoutRod: TLayout;
    lbottom: TLayout;
    ImgVoltar: TImage;
    LyVoltar: TLayout;
    LbTitulo: TLabel;
    procedure LayoutRodTap(Sender: TObject; const Point: TPointF);
    procedure LayoutRodClick(Sender: TObject);
    procedure BtnSyncClick(Sender: TObject);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnSyncTap(Sender: TObject; const Point: TPointF);
    procedure LyVoltarClick(Sender: TObject);
    procedure LyVoltarTap(Sender: TObject; const Point: TPointF);
    procedure ImgVoltarTap(Sender: TObject; const Point: TPointF);
  private
    FSyncRunning: Boolean;
    FQueueStatusIndex: Integer;
    FQueueStatusText: string;
    FQueueStatusColor: TAlphaColor;
    FQueueProgressText: string;
    FQueueProgressValue: Single;
    FQueueMessageText: string;
    FQueueTableName: string;
    FQueueInserted: Integer;
    FQueueTotal: Integer;
    FQueueIsNewTable: Boolean;
    FLastSyncProgressTick: Cardinal;
    FDownloadStartTick: Cardinal;
    FDownloadLastTick: Cardinal;
    FDownloadStartKb: Integer;
    FDownloadSpeedKb: Double;
    FDownloadPeakKb: Double;
    FDownloadLastKb: Integer;
    FDownloadLastTotalKb: Integer;
    FDownloadLastLogKb: Integer;
    FApiWaitStartTick: Cardinal;
    FApiWaitTimer: TTimer;
    FGeoPollBusy: Boolean;
    FGeoProgressVisible: Boolean;
    FSpeedIcon: TLayout;
    FSpeedBar1: TRectangle;
    FSpeedBar2: TRectangle;
    FSpeedBar3: TRectangle;
    FSpeedBar4: TRectangle;
    FFormActive: Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure DoQueueProgress;
    procedure DoQueueMessage;
    procedure DoSyncProgress;
    procedure ApiWaitTimerTimer(Sender: TObject);
    procedure StartApiWaitProgress;
    procedure StopApiWaitProgress;
    procedure UpdateApiWaitProgress;
    procedure PollGeocodeProgress;
    procedure ApplyGeocodeProgress(AProcessed, ATotal, AUpdated, APercent: Integer; AActive: Boolean);
    procedure DoFinishSync;
    procedure DoFailSync;
    procedure QueueProgress(const ATexto: string; AValor: Single);
    procedure QueueMessage(const AText: string);
    procedure SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
    procedure EnsureSpeedIcon;
    procedure AtualizarIconeVelocidade(const ASpeedKb: Double; AVisible: Boolean);
    procedure SetSyncUiEnabled(AEnabled: Boolean);
  private
    procedure AtualizarProgresso(const ATexto: string; AValor: Single);
    procedure ApplyOrientationLayout;
    procedure AtualizarUltimaSyncLabel;
    procedure AtualizarResumoEnvios;
    procedure LogSyncError(const AContext, AMessage: string);
    procedure LogSyncStep(const ATableName: string);
    procedure LogSyncDiag(const AMessage: string);
    function DeviceSyncInfo: string;
    function ActiveNetworkInfo: string;
    function FormatDownloadSpeed(const ASpeedKb: Double): string;
    procedure SetKeepScreenOn(const AEnabled: Boolean);
    procedure Sincronar;
  published
    procedure LbBtnSyncClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  public
  end;

var
  frmSync: TfrmSync;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.LgXhdpiTb.fmx ANDROID}

uses
  unDMApp,
  unPrincipal,
  unFuncoes
  {$IFDEF ANDROID}
  , Androidapi.Log, Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.Net,
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.JavaTypes, Androidapi.JNIBridge
  {$ENDIF};

const
  CLogSyncStepEnabled = False;

procedure TfrmSync.LogSyncDiag(const AMessage: string);
{$IFDEF ANDROID}
var
  LText: UTF8String;
{$ENDIF}
begin
  {$IFDEF ANDROID}
  LText := UTF8String(AMessage);
  __android_log_write(android_LogPriority.ANDROID_LOG_INFO, 'WorbyRepresSync', MarshaledAString(LText));
  {$ENDIF}
end;

function TfrmSync.DeviceSyncInfo: string;
begin
  Result := 'Windows';
  {$IFDEF ANDROID}
  try
    Result :=
      JStringToString(TJBuild.JavaClass.MANUFACTURER) + ' ' +
      JStringToString(TJBuild.JavaClass.MODEL) +
      ' | SDK ' + IntToStr(TJBuild_VERSION.JavaClass.SDK_INT);
  except
    Result := 'Android';
  end;
  {$ENDIF}
end;

function TfrmSync.ActiveNetworkInfo: string;
{$IFDEF ANDROID}
var
  LObj: JObject;
  LConnectivity: JConnectivityManager;
  LNetwork: JNetwork;
  LCaps: JNetworkCapabilities;
{$ENDIF}
begin
  Result := 'Rede: Windows';
  {$IFDEF ANDROID}
  Result := 'Rede: desconhecida';
  try
    LObj := TAndroidHelper.Context.getSystemService(TJContext.JavaClass.CONNECTIVITY_SERVICE);
    if not Assigned(LObj) then
      Exit;

    LConnectivity := TJConnectivityManager.Wrap((LObj as ILocalObject).GetObjectID);
    if not Assigned(LConnectivity) then
      Exit;

    LNetwork := LConnectivity.getActiveNetwork;
    if not Assigned(LNetwork) then
      Exit('Rede: sem conexao ativa');

    LCaps := LConnectivity.getNetworkCapabilities(LNetwork);
    if not Assigned(LCaps) then
      Exit;

    if LCaps.hasTransport(TJNetworkCapabilities.JavaClass.TRANSPORT_WIFI) then
      Result := 'Rede: Wi-Fi'
    else if LCaps.hasTransport(TJNetworkCapabilities.JavaClass.TRANSPORT_CELLULAR) then
      Result := 'Rede: Celular'
    else if LCaps.hasTransport(TJNetworkCapabilities.JavaClass.TRANSPORT_ETHERNET) then
      Result := 'Rede: Ethernet'
    else
      Result := 'Rede: outro transporte';

    if LCaps.hasCapability(TJNetworkCapabilities.JavaClass.NET_CAPABILITY_NOT_METERED) then
      Result := Result + ' sem limite'
    else
      Result := Result + ' medida/limitada';
  except
    on E: Exception do
      Result := 'Rede: erro ao consultar - ' + E.Message;
  end;
  {$ENDIF}
end;

function TfrmSync.FormatDownloadSpeed(const ASpeedKb: Double): string;
begin
  if ASpeedKb <= 0 then
    Exit('');

  if ASpeedKb >= 1024 then
    Result := FormatFloat('0.00', ASpeedKb / 1024) + ' MB/s'
  else
    Result := FormatFloat('0', ASpeedKb) + ' KB/s';
end;

procedure TfrmSync.SetKeepScreenOn(const AEnabled: Boolean);
begin
  {$IFDEF ANDROID}
  try
    if Assigned(TAndroidHelper.Activity) and Assigned(TAndroidHelper.Activity.getWindow) then
    begin
      if AEnabled then
        TAndroidHelper.Activity.getWindow.addFlags(
          TJWindowManager_LayoutParams.JavaClass.FLAG_KEEP_SCREEN_ON)
      else
        TAndroidHelper.Activity.getWindow.clearFlags(
          TJWindowManager_LayoutParams.JavaClass.FLAG_KEEP_SCREEN_ON);
    end;
  except
    on E: Exception do
      LogSyncDiag('KeepScreenOn erro: ' + E.ClassName + ' - ' + E.Message);
  end;
  {$ENDIF}
end;

procedure TfrmSync.LogSyncError(const AContext, AMessage: string);
var
  LPath: string;
  LDbPath: string;
  LDbDir: string;
  LLine: string;
  LQuery: TFDQuery;
begin
  try
    LPath := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'sync_error.log');
    LLine := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' | ' + AContext + ' | ' + AMessage + sLineBreak;
    System.IOUtils.TFile.AppendAllText(LPath, LLine, TEncoding.UTF8);
  except
  end;

  try
    if Assigned(dmApp) and dmApp.FDConnection.Connected then
      LDbPath := dmApp.FDConnection.Params.Values['Database'];
    if LDbPath <> '' then
    begin
      LDbDir := System.IOUtils.TPath.GetDirectoryName(LDbPath);
      if LDbDir <> '' then
      begin
        LPath := System.IOUtils.TPath.Combine(LDbDir, 'sync_error.log');
        LLine := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' | ' + AContext + ' | ' + AMessage + sLineBreak;
        System.IOUtils.TFile.AppendAllText(LPath, LLine, TEncoding.UTF8);
      end;
    end;
  except
  end;

  if not Assigned(dmApp) then
    Exit;
  if Assigned(dmApp) then
    dmApp.AddRequestLog('sync', AContext, AMessage, '', 0);
end;

procedure TfrmSync.LogSyncStep(const ATableName: string);
begin
  if not CLogSyncStepEnabled then
    Exit;
  if not Assigned(dmApp) then
    Exit;
  dmApp.AddRequestLog('SYNC_STEP', ATableName, '', '', 0);
end;
procedure TfrmSync.LyVoltarClick(Sender: TObject);
begin
  close;
end;

procedure TfrmSync.LyVoltarTap(Sender: TObject; const Point: TPointF);
begin
  close;
end;

procedure TfrmSync.BtnSyncClick(Sender: TObject);
begin
  Sincronar;
end;

procedure TfrmSync.BtnSyncTap(Sender: TObject; const Point: TPointF);
begin
  Sincronar;
end;

procedure TfrmSync.FormShow(Sender: TObject);
begin
  FFormActive := True;
  if Assigned(dmApp) then
    dmApp.SetAppState('sync', 0, '');
  OnClose := FormClose;
  OnHide := FormHide;
  AtualizarUltimaSyncLabel;
  AtualizarResumoEnvios;
  LbProgresso.Text := 'Aguardando sincronizacao';
  ProgressBarSync.Value := 0;
  ApplyOrientationLayout;
  TThread.ForceQueue(nil,
    procedure
    begin
      if (not (csDestroying in ComponentState)) and FFormActive and Visible then
        AtualizarUltimaSyncLabel;
    end);
end;

procedure TfrmSync.AtualizarUltimaSyncLabel;
var
  LQuery: TFDQuery;
  LUltima: string;

  function FormatarDataHora(const AValue: string): string;
  var
    S: string;
  begin
    S := Trim(AValue);
    Result := S;
    if Length(S) >= 16 then
    begin
      if (S[5] = '-') and (S[8] = '-') then
        Result := Copy(S, 9, 2) + '/' + Copy(S, 6, 2) + '/' + Copy(S, 1, 4) + ' ' + Copy(S, 12, 5)
      else if (S[3] = '/') and (S[6] = '/') then
        Result := Copy(S, 1, 16);
    end;
  end;

begin
  LbUltimaSync.Text := 'Ultima sincronizacao: --';

  if not Assigned(dmApp) then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;

    LQuery.SQL.Text := 'select coalesce(value, '''') as ultima from app_config where key = ''ultima_sincronizacao_label''';
    LQuery.Open;
    if not LQuery.IsEmpty then
      LUltima := Trim(LQuery.FieldByName('ultima').AsString);

    if LUltima = '' then
    begin
      LQuery.Close;
      LQuery.SQL.Text := 'select coalesce(value, '''') as ultima from app_config where key = ''ultima_sincronizacao''';
      LQuery.Open;
      if not LQuery.IsEmpty then
        LUltima := FormatarDataHora(LQuery.FieldByName('ultima').AsString);
    end;

    if LUltima = '' then
    begin
      LQuery.Close;
      LQuery.SQL.Text :=
        'select coalesce(max(last_sync_at), '''') as ultima ' +
        'from sync_table_state ' +
        'where last_sync_at is not null and coalesce(last_error, '''') = ''''';
      LQuery.Open;
      if not LQuery.IsEmpty then
        LUltima := FormatarDataHora(LQuery.FieldByName('ultima').AsString);
    end;

    if LUltima <> '' then
      LbUltimaSync.Text := 'Ultima sincronizacao: ' + LUltima;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmSync.AtualizarResumoEnvios;
var
  LQuery: TFDQuery;
  LPedidos: Integer;
  LValorTotal: Double;
  LVenda1: TJSONObject;
  LJson: TJSONValue;
  LNum: TJSONNumber;
  LVal: string;
begin
  LbProgressoTabela.Text := 'Enviados hoje: 0 pedido(s) | Valor: R$ 0,00';

  if not Assigned(dmApp) then
    Exit;

  LPedidos := 0;
  LValorTotal := 0;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select vendas1_json ' +
      'from outbound_pedido ' +
      'where status = :p0 ' +
      '  and sent_at is not null ' +
      '  and date(sent_at, ''localtime'') = date(''now'', ''localtime'')';
    LQuery.ParamByName('p0').AsString := 'ENVIADO';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      Inc(LPedidos);
      LVenda1 := TJSONObject.ParseJSONValue(LQuery.FieldByName('vendas1_json').AsString) as TJSONObject;
      try
        if Assigned(LVenda1) then
        begin
          LJson := LVenda1.GetValue('tot_liquido');
          if LJson is TJSONNumber then
          begin
            LNum := TJSONNumber(LJson);
            LValorTotal := LValorTotal + LNum.AsDouble;
          end
          else if Assigned(LJson) then
          begin
            LVal := StringReplace(LJson.Value, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
            LVal := StringReplace(LVal, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
            LValorTotal := LValorTotal + StrToFloatDef(LVal, 0);
          end;
        end;
      finally
        LVenda1.Free;
      end;
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;

  LbProgressoTabela.Text := 'Enviados hoje: ' + LPedidos.ToString +
    ' pedido(s) | Valor: R$ ' + FormatFloat('#,##0.00', LValorTotal);
end;

procedure TfrmSync.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmSync.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LIsTablet: Boolean;
  LSafeBottom: Single;
  LRightSafe: Single;
  LContentW: Single;
  LBlockH: Single;
  LContentX: Single;
  LContentY: Single;
  LAvailableH: Single;
  LInnerW: Single;
  LButtonWidth: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LIsTablet := Min(Width, Height) >= 600;
  LSafeBottom := AndroidBottomSafeMargin(LIsLandscape);
  if LIsLandscape then
    LRightSafe := Max(0, AndroidNavigationInset(True) + 8)
  else
    LRightSafe := 0;

  if LIsLandscape then
    TopBar.Height := 64
  else if LIsTablet then
    TopBar.Height := 82
  else
    TopBar.Height := 96;

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, TopBar.Height);
  LbTitulo.Position.X := 24;
  LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) / 2;
  LbTitulo.Width := Width - 48;

  if LIsLandscape then
    lbottom.Height := 58
  else if LIsTablet then
    lbottom.Height := 64
  else
    lbottom.Height := 72;
  lbottom.Align := TAlignLayout.None;
  lbottom.Margins.Bottom := 0;
  lbottom.SetBounds(0, Height - lbottom.Height - LSafeBottom, Width - LRightSafe, lbottom.Height);

  if LIsLandscape then
    LContentW := Min(760, Width - LRightSafe - 56)
  else if LIsTablet then
    LContentW := Min(620, Width - 48)
  else
    LContentW := Min(460, Width - 20);
  if LContentW < 300 then
    LContentW := Max(280, Width - LRightSafe - 20);

  if LIsLandscape then
    CardStatus.Height := 142
  else if LIsTablet then
    CardStatus.Height := 158
  else
    CardStatus.Height := 177;

  if LIsLandscape then
    LayoutRod.Height := 40
  else
    LayoutRod.Height := 46;
  if LIsTablet then
    LButtonWidth := Min(480, LContentW - 96)
  else if LIsLandscape then
    LButtonWidth := Min(420, LContentW - 160)
  else
    LButtonWidth := Min(310, LContentW - 28);
  if LIsLandscape then
  begin
    if LButtonWidth < 210 then
      LButtonWidth := 210;
  end
  else if LButtonWidth < 270 then
    LButtonWidth := Min(LContentW - 24, 270);

  LBlockH := CardStatus.Height + 18 + LayoutRod.Height;
  LAvailableH := lbottom.Position.Y - TopBar.Height;
  if LIsTablet then
    LContentY := TopBar.Height + Max(12, (LAvailableH - LBlockH) / 3)
  else
    LContentY := TopBar.Height + 18;
  if LContentY + LBlockH > lbottom.Position.Y - 8 then
    LContentY := Max(TopBar.Height + 8, lbottom.Position.Y - LBlockH - 8);

  LContentX := Max(10, ((Width - LRightSafe) - LContentW) / 2);

  CardStatus.Align := TAlignLayout.None;
  CardStatus.SetBounds(LContentX, LContentY, LContentW, CardStatus.Height);

  LInnerW := CardStatus.Width - 36;
  if LInnerW < 240 then
    LInnerW := CardStatus.Width - 24;

  LbStatusTitulo.SetBounds(18, 14, LInnerW, 22);
  LbUltimaSync.SetBounds(18, 42, LInnerW, 20);
  ProgressBarSync.SetBounds(18, 67, LInnerW, 9);
  LbProgresso.SetBounds(18, 88, LInnerW, 20);
  ProgressBarTable.SetBounds(18, 111, LInnerW, 9);
  if LIsLandscape then
    LbProgressoTabela.SetBounds(18, 124, LInnerW, Max(18, CardStatus.Height - 130))
  else
    LbProgressoTabela.SetBounds(18, 126, LInnerW, Max(18, CardStatus.Height - 132));

  LayoutRod.Align := TAlignLayout.None;
  LayoutRod.SetBounds(LContentX + ((LContentW - LButtonWidth) / 2),
    CardStatus.Position.Y + CardStatus.Height + 18, LButtonWidth, LayoutRod.Height);

  BtnSync.Align := TAlignLayout.None;
  BtnSync.SetBounds(0, 0, LayoutRod.Width, LayoutRod.Height);
  LbBtnSync.Align := TAlignLayout.None;
  LbBtnSync.SetBounds(0, 0, BtnSync.Width, BtnSync.Height);
  LbBtnSync.TextSettings.WordWrap := False;
  if LIsTablet then
    LbBtnSync.TextSettings.Font.Size := 18
  else if LIsLandscape then
    LbBtnSync.TextSettings.Font.Size := 20
  else
    LbBtnSync.TextSettings.Font.Size := 16;

  lbottom.BringToFront;
  LayoutRod.BringToFront;
end;
procedure TfrmSync.ImgVoltarClick(Sender: TObject);
begin
  close;
end;

procedure TfrmSync.ImgVoltarTap(Sender: TObject; const Point: TPointF);
begin
  close;
end;

procedure TfrmSync.EnsureSpeedIcon;

  function CriarBarra(const AX, AY, AHeight: Single): TRectangle;
  begin
    Result := TRectangle.Create(Self);
    Result.Parent := FSpeedIcon;
    Result.Stored := False;
    Result.HitTest := False;
    Result.Width := 4;
    Result.Height := AHeight;
    Result.Position.X := AX;
    Result.Position.Y := AY;
    Result.XRadius := 2;
    Result.YRadius := 2;
    Result.Stroke.Kind := TBrushKind.None;
    Result.Fill.Color := $FFE5E7EB;
  end;

begin
  if Assigned(FSpeedIcon) then
    Exit;

  FSpeedIcon := TLayout.Create(Self);
  FSpeedIcon.Parent := CardStatus;
  FSpeedIcon.Stored := False;
  FSpeedIcon.HitTest := False;
  FSpeedIcon.Width := 30;
  FSpeedIcon.Height := 20;
  FSpeedIcon.Visible := False;

  FSpeedBar1 := CriarBarra(2, 13, 5);
  FSpeedBar2 := CriarBarra(9, 10, 8);
  FSpeedBar3 := CriarBarra(16, 6, 12);
  FSpeedBar4 := CriarBarra(23, 2, 16);
end;

procedure TfrmSync.AtualizarIconeVelocidade(const ASpeedKb: Double; AVisible: Boolean);
var
  LNivel: Integer;
  LCorAtiva: TAlphaColor;
  LTextWidth: Single;

  procedure PintarBarra(ABarra: TRectangle; AAtiva: Boolean);
  begin
    if not Assigned(ABarra) then
      Exit;
    if AAtiva then
      ABarra.Fill.Color := LCorAtiva
    else
      ABarra.Fill.Color := $FFE5E7EB;
  end;

begin
  EnsureSpeedIcon;
  FSpeedIcon.Visible := AVisible;
  if not AVisible then
  begin
    LTextWidth := CardStatus.Width - LbProgressoTabela.Position.X - 18;
    if LTextWidth > 80 then
      LbProgressoTabela.Width := LTextWidth;
    Exit;
  end;

  FSpeedIcon.Position.X := CardStatus.Width - FSpeedIcon.Width - 18;
  FSpeedIcon.Position.Y := LbProgressoTabela.Position.Y - 2;
  LTextWidth := FSpeedIcon.Position.X - LbProgressoTabela.Position.X - 6;
  if LTextWidth > 80 then
    LbProgressoTabela.Width := LTextWidth;

  if ASpeedKb < 128 then
  begin
    LNivel := 1;
    LCorAtiva := $FFE53935;
  end
  else if ASpeedKb < 512 then
  begin
    LNivel := 2;
    LCorAtiva := $FFFF9800;
  end
  else if ASpeedKb < 1024 then
  begin
    LNivel := 3;
    LCorAtiva := $FF2E7D32;
  end
  else
  begin
    LNivel := 4;
    LCorAtiva := $FF00897B;
  end;

  PintarBarra(FSpeedBar1, LNivel >= 1);
  PintarBarra(FSpeedBar2, LNivel >= 2);
  PintarBarra(FSpeedBar3, LNivel >= 3);
  PintarBarra(FSpeedBar4, LNivel >= 4);
end;

procedure TfrmSync.AtualizarProgresso(const ATexto: string; AValor: Single);
begin
  LbProgresso.Text := ATexto;
  ProgressBarSync.Value := AValor;
end;

procedure TfrmSync.SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
var
  LTable: string;
  LInserted: Integer;
  LTotal: Integer;
  LIsNewTable: Boolean;
  LNow: Cardinal;
begin
  LTable := ATable;
  LInserted := AInserted;
  LTotal := ATotal;
  LIsNewTable := AIsNewTable;

  LNow := TThread.GetTickCount;
  if (not LIsNewTable) and (LTotal > 0) and (LInserted < LTotal) and
     ((LNow - FLastSyncProgressTick) < 300) then
    Exit;
  FLastSyncProgressTick := LNow;

  TThread.Queue(nil,
    procedure
    begin
      if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) then
        Exit;
      FQueueTableName := LTable;
      FQueueInserted := LInserted;
      FQueueTotal := LTotal;
      FQueueIsNewTable := LIsNewTable;
      DoSyncProgress;
    end);
end;

procedure TfrmSync.QueueProgress(const ATexto: string; AValor: Single);
begin
  if not FFormActive then
    Exit;
  FQueueProgressText := ATexto;
  FQueueProgressValue := AValor;
  TThread.Queue(nil, DoQueueProgress);
end;

procedure TfrmSync.QueueMessage(const AText: string);
begin
  if not FFormActive then
    Exit;
  FQueueMessageText := AText;
  TThread.Queue(nil, DoQueueMessage);
end;

procedure TfrmSync.SetSyncUiEnabled(AEnabled: Boolean);
begin
  BtnSync.Enabled := AEnabled;
  LbBtnSync.Enabled := AEnabled;
  LayoutRod.Enabled := AEnabled;
end;

procedure TfrmSync.DoQueueProgress;
begin
  if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) then
    Exit;
  AtualizarProgresso(FQueueProgressText, FQueueProgressValue);
end;

procedure TfrmSync.DoQueueMessage;
begin
  if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) then
    Exit;
  LbProgresso.Text := FQueueMessageText;
end;

procedure TfrmSync.ApiWaitTimerTimer(Sender: TObject);
begin
  UpdateApiWaitProgress;
end;

procedure TfrmSync.StartApiWaitProgress;
begin
  if FApiWaitStartTick = 0 then
    FApiWaitStartTick := TThread.GetTickCount;

  if not Assigned(FApiWaitTimer) then
  begin
    FApiWaitTimer := TTimer.Create(Self);
    FApiWaitTimer.Interval := 500;
    FApiWaitTimer.OnTimer := ApiWaitTimerTimer;
  end;

  FApiWaitTimer.Enabled := True;
  UpdateApiWaitProgress;
end;

procedure TfrmSync.StopApiWaitProgress;
begin
  if Assigned(FApiWaitTimer) then
    FApiWaitTimer.Enabled := False;
  FApiWaitStartTick := 0;
  FGeoProgressVisible := False;
end;

procedure TfrmSync.ApplyGeocodeProgress(AProcessed, ATotal, AUpdated, APercent: Integer; AActive: Boolean);
begin
  if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) then
    Exit;
  FGeoProgressVisible := AActive;
  if not AActive then
    Exit;
  ProgressBarSync.Min := 0;
  ProgressBarSync.Max := 100;
  ProgressBarSync.Value := 40;
  ProgressBarTable.Min := 0;
  if ATotal > 0 then
  begin
    ProgressBarTable.Max := ATotal;
    ProgressBarTable.Value := AProcessed;
  end
  else
  begin
    ProgressBarTable.Max := 1;
    ProgressBarTable.Value := 0;
  end;
  LbProgresso.Text := 'API processando clientes e geolocalizacao';
  LbProgressoTabela.Text := 'Geocodificacao: ' + AProcessed.ToString + ' de ' +
    ATotal.ToString + ' - ' + APercent.ToString + '% | atualizados: ' + AUpdated.ToString;
end;

procedure TfrmSync.PollGeocodeProgress;
var
  LRep: string;
begin
  if FGeoPollBusy or (not Assigned(dmApp)) or (not Assigned(frmPrincipal)) then
    Exit;
  LRep := frmPrincipal.id_representante.ToString;
  FGeoPollBusy := True;
  TThread.CreateAnonymousThread(
    procedure
    var
      LJson: TJSONObject;
      LActive: Boolean;
      LTotal, LProcessed, LUpdated, LPercent: Integer;
    begin
      LJson := nil;
      try
        try
          LJson := dmApp.GetGeocodeProgress(LRep);
          LActive := Assigned(LJson) and LJson.GetValue<Boolean>('active', False);
          LTotal := 0;
          LProcessed := 0;
          LUpdated := 0;
          LPercent := 0;
          if Assigned(LJson) then
          begin
            LTotal := LJson.GetValue<Integer>('total', 0);
            LProcessed := LJson.GetValue<Integer>('processados', 0);
            LUpdated := LJson.GetValue<Integer>('atualizados', 0);
            LPercent := LJson.GetValue<Integer>('percentual', 0);
          end;
          TThread.Queue(nil,
            procedure
            begin
              FGeoPollBusy := False;
              ApplyGeocodeProgress(LProcessed, LTotal, LUpdated, LPercent, LActive);
            end);
        except
          FGeoPollBusy := False;
        end;
      finally
        LJson.Free;
      end;
    end).Start;
end;

procedure TfrmSync.UpdateApiWaitProgress;
var
  LElapsedSec: Cardinal;
  LAnim: Integer;
begin
  PollGeocodeProgress;

  if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) or (not FSyncRunning) then
    Exit;

  if FApiWaitStartTick = 0 then
    FApiWaitStartTick := TThread.GetTickCount;

  LElapsedSec := (TThread.GetTickCount - FApiWaitStartTick) div 1000;
  LAnim := 35 + Integer(((TThread.GetTickCount - FApiWaitStartTick) div 250) mod 65);

  ProgressBarSync.Min := 0;
  ProgressBarSync.Max := 100;
  ProgressBarSync.Value := 40;
  if not FGeoProgressVisible then
  begin
    ProgressBarTable.Min := 0;
    ProgressBarTable.Max := 100;
    ProgressBarTable.Value := LAnim;
    LbProgresso.Text := 'Etapa 3 de 5 - Buscando dados na API';
    LbProgressoTabela.Text := 'API processando clientes e geolocalizacao... ' + IntToStr(Integer(LElapsedSec)) + 's';
  end;
  AtualizarIconeVelocidade(0, False);
end;
procedure TfrmSync.DoSyncProgress;
var
  LPerc: Integer;
  LNomeTabela: string;
  LDownloadProgress: Boolean;
  LApplyProgress: Boolean;
  LVelocidade: string;

  function NomeTabelaAmigavel(const ATable: string): string;
  begin
    if SameText(ATable, 'representante') then
      Exit('Representante');
    if SameText(ATable, 'cidades') then
      Exit('Cidades');
    if SameText(ATable, 'cliente') then
      Exit('Clientes');
    if SameText(ATable, 'vendas1') then
      Exit('Pedidos');
    if SameText(ATable, 'vendas2') then
      Exit('Itens dos pedidos');
    if SameText(ATable, 'produto') then
      Exit('Produtos');
    if SameText(ATable, 'subcategoria') then
      Exit('Imagens/Categorias');
    if SameText(ATable, 'fop') then
      Exit('Formas de pagamento');
    if SameText(ATable, 'fop_prazo') then
      Exit('Prazos por forma de pagamento');
    if SameText(ATable, 'prazo') then
      Exit('Prazos');
    if SameText(ATable, 'produto_representante') then
      Exit('Descontos por produto');
    if SameText(ATable, 'grupo_representante') then
      Exit('Descontos por grupo');
    if SameText(ATable, 'produto_representante_inativos') then
      Exit('Produtos inativos');
    if SameText(ATable, 'prazo_representante') then
      Exit('Prazos por representante');
    Result := ATable;
  end;

  function FormatKb(const AValue: Integer): string;
  begin
    if AValue >= 1024 then
      Result := FormatFloat('0.0', AValue / 1024) + ' MB'
    else
      Result := AValue.ToString + ' KB';
  end;

  function FormatVelocidadeDownload: string;
  var
    LNow: Cardinal;
    LElapsedMs: Cardinal;
    LInstantMs: Cardinal;
    LDeltaKb: Integer;
    LInstantDeltaKb: Integer;
    LSpeedKb: Double;
  begin
    Result := '';
    FDownloadSpeedKb := 0;
    if FQueueInserted <= 0 then
      Exit;

    LNow := TThread.GetTickCount;
    if (FDownloadStartTick = 0) or (FQueueInserted < FDownloadStartKb) then
    begin
      FDownloadStartTick := LNow;
      FDownloadLastTick := LNow;
      FDownloadStartKb := FQueueInserted;
      FDownloadLastKb := FQueueInserted;
      FDownloadLastTotalKb := FQueueTotal;
      Exit;
    end;

    LElapsedMs := LNow - FDownloadStartTick;
    LInstantMs := LNow - FDownloadLastTick;
    LDeltaKb := FQueueInserted - FDownloadStartKb;
    LInstantDeltaKb := FQueueInserted - FDownloadLastKb;
    if (LElapsedMs < 500) or (LDeltaKb <= 0) then
      Exit;

    if (LInstantMs >= 500) and (LInstantDeltaKb > 0) then
      LSpeedKb := LInstantDeltaKb / (LInstantMs / 1000)
    else
      LSpeedKb := LDeltaKb / (LElapsedMs / 1000);
    FDownloadSpeedKb := LSpeedKb;
    if LSpeedKb > FDownloadPeakKb then
      FDownloadPeakKb := LSpeedKb;
    FDownloadLastTotalKb := FQueueTotal;

    if LInstantMs >= 500 then
    begin
      FDownloadLastTick := LNow;
      FDownloadLastKb := FQueueInserted;
    end;
    Result := FormatDownloadSpeed(LSpeedKb);
  end;
begin
  if (csDestroying in ComponentState) or (not FFormActive) or (not Visible) then
    Exit;

  LDownloadProgress := SameText(FQueueTableName, '__script_download') and
    (((FQueueTotal > 5) and (FQueueInserted >= 0)) or
     ((FQueueTotal = 5) and (FQueueInserted = 3)) or
     ((FQueueTotal = 0) and (FQueueInserted > 0)) or
     ((FQueueTotal = 0) and (FQueueInserted = 0) and (FQueueIsNewTable = False)));
  LApplyProgress := SameText(FQueueTableName, '__script_apply') and (FQueueTotal > 5);

  if SameText(FQueueTableName, '__geo_upload') then
  begin
    ProgressBarSync.Min := 0;
    ProgressBarSync.Max := 5;
    ProgressBarSync.Value := 1;
    ProgressBarTable.Min := 0;
    if FQueueTotal > 0 then
    begin
      ProgressBarTable.Max := FQueueTotal;
      ProgressBarTable.Value := FQueueInserted;
      LPerc := Round(FQueueInserted / FQueueTotal * 100);
    end
    else
    begin
      ProgressBarTable.Max := 1;
      ProgressBarTable.Value := 0;
      LPerc := 0;
    end;
    LbProgresso.Text := 'Enviando localizacao e visitas';
    LbProgressoTabela.Text := 'Registros enviados: ' + FQueueInserted.ToString +
      ' de ' + FQueueTotal.ToString + ' - ' + LPerc.ToString + '%';
    Exit;
  end;

  if LDownloadProgress then
  begin
    ProgressBarSync.Min := 0;
    ProgressBarSync.Max := 100;

    ProgressBarTable.Min := 0;
    if ((FQueueTotal = 5) and (FQueueInserted = 3)) or
       ((FQueueTotal = 0) and (FQueueInserted = 0)) then
    begin
      StartApiWaitProgress;
      Exit;
    end;

    StopApiWaitProgress;
    if FQueueTotal > 0 then
    begin
      ProgressBarTable.Max := FQueueTotal;
      ProgressBarTable.Value := FQueueInserted;
      LPerc := Round(FQueueInserted / FQueueTotal * 100);
      if LPerc > 100 then
        LPerc := 100;
      ProgressBarSync.Value := 40 + Round(LPerc * 0.20);
      LbProgresso.Text := 'Etapa 3 de 5 - Baixando dados da API';
      LVelocidade := FormatVelocidadeDownload;
      LbProgressoTabela.Text := 'Download: ' + FormatKb(FQueueInserted) + ' de ' +
        FormatKb(FQueueTotal) + ' - ' + LPerc.ToString + '%';
      AtualizarIconeVelocidade(FDownloadSpeedKb, LVelocidade <> '');
      if LVelocidade <> '' then
      begin
        LbProgressoTabela.Text := LbProgressoTabela.Text + ' | Vel: ' + LVelocidade;
        if (FQueueInserted - FDownloadLastLogKb >= 5120) or (FQueueInserted >= FQueueTotal) then
        begin
          FDownloadLastLogKb := FQueueInserted;
          LogSyncDiag('Download progresso | ' + FormatKb(FQueueInserted) + ' de ' +
            FormatKb(FQueueTotal) + ' | ' + LVelocidade);
        end;
      end;
    end
    else
    begin
      ProgressBarSync.Value := 40;
      ProgressBarTable.Max := 1;
      ProgressBarTable.Value := 0;
      LbProgresso.Text := 'Etapa 3 de 5 - Baixando dados da API';
      LVelocidade := FormatVelocidadeDownload;
      LbProgressoTabela.Text := 'Download: ' + FormatKb(FQueueInserted);
      AtualizarIconeVelocidade(FDownloadSpeedKb, LVelocidade <> '');
      if LVelocidade <> '' then
      begin
        LbProgressoTabela.Text := LbProgressoTabela.Text + ' | Vel: ' + LVelocidade;
        if FQueueInserted - FDownloadLastLogKb >= 5120 then
        begin
          FDownloadLastLogKb := FQueueInserted;
          LogSyncDiag('Download progresso | ' + FormatKb(FQueueInserted) + ' | ' + LVelocidade);
        end;
      end;
    end;
    Exit;
  end;
  AtualizarIconeVelocidade(0, False);
  StopApiWaitProgress;

  if LApplyProgress then
  begin
    ProgressBarSync.Min := 0;
    ProgressBarSync.Max := 100;

    ProgressBarTable.Min := 0;
    ProgressBarTable.Max := FQueueTotal;
    ProgressBarTable.Value := FQueueInserted;
    if FQueueTotal > 0 then
      LPerc := Round(FQueueInserted / FQueueTotal * 100)
    else
      LPerc := 0;
    if LPerc > 100 then
      LPerc := 100;

    ProgressBarSync.Value := 60 + Round(LPerc * 0.20);
    LbProgresso.Text := 'Etapa 4 de 5 - Gravando dados no aparelho';
    LbProgressoTabela.Text := 'Comandos aplicados: ' + FQueueInserted.ToString +
      ' de ' + FQueueTotal.ToString + ' - ' + LPerc.ToString + '%';
    Exit;
  end;

  if SameText(FQueueTableName, '__script_prepare') or
     SameText(FQueueTableName, '__script_download') or
     SameText(FQueueTableName, '__script_apply') or
     SameText(FQueueTableName, '__script_finish') then
  begin
    ProgressBarSync.Min := 0;
    ProgressBarSync.Max := 100;
    if FQueueTotal > 0 then
    begin
      ProgressBarSync.Value := Round(FQueueInserted / FQueueTotal * 100);
    end;

    ProgressBarTable.Min := 0;
    ProgressBarTable.Max := 1;
    ProgressBarTable.Value := 0;
    if FQueueTotal > 0 then
      LPerc := Round(FQueueInserted / FQueueTotal * 100)
    else
      LPerc := 0;

    if SameText(FQueueTableName, '__script_prepare') then
      LbProgresso.Text := 'Etapa 2 de 5 - Preparando sincronizacao'
    else if SameText(FQueueTableName, '__script_download') then
      LbProgresso.Text := 'Etapa 3 de 5 - Buscando dados na API'
    else if SameText(FQueueTableName, '__script_apply') then
      LbProgresso.Text := 'Etapa 4 de 5 - Gravando dados no aparelho'
    else
      LbProgresso.Text := 'Etapa 5 de 5 - Finalizando sincronizacao';

    LbProgressoTabela.Text := 'Etapa ' + FQueueInserted.ToString + ' de ' +
      FQueueTotal.ToString + ' - ' + LPerc.ToString + '%';
    Exit;
  end;

  if SameText(FQueueTableName, 'cliente') and (FQueueTotal = 0) then
  begin
    ProgressBarTable.Min := 0;
    ProgressBarTable.Max := 1;
    ProgressBarTable.Value := 0;
    LbProgresso.Text := 'Sincronizando clientes';
    if FQueueInserted > 0 then
      LbProgressoTabela.Text := 'Clientes sincronizados: ' + FQueueInserted.ToString
    else
      LbProgressoTabela.Text := 'Aguardando clientes...';
    Exit;
  end;

  if FQueueIsNewTable then
  begin
    ProgressBarTable.Min := 0;
    if FQueueTotal < 1 then
      ProgressBarTable.Max := 1
    else
      ProgressBarTable.Max := FQueueTotal;
    ProgressBarTable.Value := 0;
  end
  else
  begin
    if FQueueTotal > ProgressBarTable.Max then
      ProgressBarTable.Max := FQueueTotal;
    ProgressBarTable.Value := FQueueInserted;
  end;
  LNomeTabela := NomeTabelaAmigavel(FQueueTableName);
  if SameText(FQueueTableName, 'cliente') then
  begin
    LbProgresso.Text := 'Sincronizando clientes';
    LbProgressoTabela.Text := 'Clientes sincronizados: ' +
      FQueueInserted.ToString + ' / ' + FQueueTotal.ToString;
  end
  else
  begin
    if FQueueTotal > 0 then
      LPerc := Round(FQueueInserted / FQueueTotal * 100)
    else
      LPerc := 0;
    LbProgresso.Text := 'Sincronizando ' + LowerCase(LNomeTabela);
    LbProgressoTabela.Text := LNomeTabela + ': ' +
      FQueueInserted.ToString + ' / ' + FQueueTotal.ToString;
    if FQueueTotal > 0 then
      LbProgressoTabela.Text := LbProgressoTabela.Text + ' - ' + LPerc.ToString + '%';
  end;
end;

procedure TfrmSync.DoFinishSync;
var
  LElapsedMs: Cardinal;
  LResumoDownload: string;
begin
  StopApiWaitProgress;
  LResumoDownload := '';
  if (FDownloadStartTick > 0) and (FDownloadLastKb > FDownloadStartKb) then
  begin
    LElapsedMs := TThread.GetTickCount - FDownloadStartTick;
    if LElapsedMs > 0 then
    begin
      LResumoDownload := 'Download: ' + FormatFloat('0.0', FDownloadLastKb / 1024) + ' MB';
      if FDownloadLastTotalKb > 0 then
        LResumoDownload := LResumoDownload + ' de ' + FormatFloat('0.0', FDownloadLastTotalKb / 1024) + ' MB';
      LResumoDownload := LResumoDownload + ' em ' + FormatFloat('0.0', LElapsedMs / 1000) + 's';
      LogSyncDiag('Fim sincronizacao | ' + LResumoDownload + ' | ' + ActiveNetworkInfo);
    end;
  end;

  if Assigned(dmApp) then
  begin
    dmApp.SetAppConfigValue('ultima_sincronizacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    dmApp.SetAppConfigValue('ultima_sincronizacao_label', FormatDateTime('dd/mm/yyyy hh:nn', Now));
  end;
  if (not (csDestroying in ComponentState)) and FFormActive and Visible then
  begin
    AtualizarProgresso('Sincronizacao concluida', ProgressBarSync.Max);
    AtualizarUltimaSyncLabel;
    AtualizarResumoEnvios;
    if LResumoDownload <> '' then
      LbProgressoTabela.Text := LResumoDownload;
    AtualizarIconeVelocidade(0, False);
    SetSyncUiEnabled(True);
  end;
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
  SetKeepScreenOn(False);
  {$IFDEF ANDROID}
  if Assigned(frmPrincipal) then
    frmPrincipal.ResumeLocationServiceAfterSync;
  {$ENDIF}
end;

procedure TfrmSync.DoFailSync;
begin
  StopApiWaitProgress;
  if (not (csDestroying in ComponentState)) and FFormActive and Visible then
  begin
    AtualizarIconeVelocidade(0, False);
    SetSyncUiEnabled(True);
  end;
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
  SetKeepScreenOn(False);
  {$IFDEF ANDROID}
  if Assigned(frmPrincipal) then
    frmPrincipal.FinishLocationSyncPause;
  {$ENDIF}
end;

procedure TfrmSync.LayoutRodClick(Sender: TObject);
begin
  Sincronar;
end;

procedure TfrmSync.LayoutRodTap(Sender: TObject; const Point: TPointF);
begin
  Sincronar;
end;

procedure TfrmSync.Sincronar;
const
  CTabelasSyncFiltradas: array[0..9] of string = (
    'representante',
    'cidades',
    'cliente',
    'vendas1',
    'vendas2',
    'cr1',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );

  CTabelasSyncGlobais: array[0..6] of string = (
    'produto',
    'subcategoria',
    'fop',
    'fop_prazo',
    'prazo',
    'grade_comissao',
    'escala_comissao'
  );
var
  I: Integer;
  LMax: Integer;
  LIdRep: Integer;
begin
  if not FFormActive then
    Exit;

  if not Assigned(dmApp) then
  begin
    LbProgresso.Text := 'Sem conexao com o banco local.';
    LogSyncError('Init', 'dmApp nao esta criado');
    Exit;
  end;

  if Assigned(frmPrincipal) then
    LIdRep := frmPrincipal.id_representante
  else
    LIdRep := 0;

  if LIdRep <= 0 then
  begin
    LbProgresso.Text := 'Representante invalido para sincronizacao.';
    Exit;
  end;

  if FSyncRunning then
    Exit;
  FSyncRunning := True;
  FGeoPollBusy := False;
  FGeoProgressVisible := False;
  FLastSyncProgressTick := 0;
  FDownloadStartTick := 0;
  FDownloadLastTick := 0;
  FDownloadStartKb := 0;
  FDownloadSpeedKb := 0;
  FDownloadPeakKb := 0;
  FDownloadLastKb := 0;
  FDownloadLastTotalKb := 0;
  FDownloadLastLogKb := 0;
  AtualizarIconeVelocidade(0, False);
  SetSyncUiEnabled(False);
  SetKeepScreenOn(True);
  LogSyncDiag('Inicio sincronizacao | rep=' + LIdRep.ToString + ' | ' +
    DeviceSyncInfo + ' | ' + ActiveNetworkInfo);
  {$IFDEF ANDROID}
  if Assigned(frmPrincipal) then
    frmPrincipal.PauseLocationServiceForSync;
  {$ENDIF}

  LMax := 5;
  ProgressBarSync.Min := 0;
  ProgressBarSync.Max := LMax;
  ProgressBarSync.Value := 0;
  AtualizarProgresso('Sincronizando dados...', 0);
  LbProgressoTabela.Text := 'Registros: 0';
  ProgressBarTable.Min := 0;
  ProgressBarTable.Max := 1;
  ProgressBarTable.Value := 0;

  TThread.CreateAnonymousThread(
    procedure
    var
      K: Integer;
      LEnviados: Integer;
      LFullReason: string;
      LTables: TArray<string>;
      LMsg: string;
    begin
      try
        {$IFDEF ANDROID}
        TThread.Sleep(1200);
        {$ENDIF}
        dmApp.OnSyncProgress := SyncProgressHandler;
        LogSyncStep('INIT');

        QueueProgress('Enviando GPS e visitas...', 1);
        LogSyncStep('SEND_GEO_VISITAS');
        try
          dmApp.EnviarPendentesBackground(SyncProgressHandler);
          LogSyncStep('SEND_GEO_VISITAS_OK');
        except
          on E: Exception do
          begin
            LogSyncError('SEND_GEO_VISITAS', E.Message);
            LogSyncStep('SEND_GEO_VISITAS_ERRO');
          end;
        end;

        QueueProgress('Enviando pedidos digitados...', 1);
        LogSyncStep('SEND_PEDIDOS');
        try
          LEnviados := dmApp.SendPendingPedidos;
          LogSyncStep('SEND_PEDIDOS_OK_' + LEnviados.ToString);
        except
          on E: Exception do
          begin
            LogSyncError('SEND_PEDIDOS', E.Message);
            LogSyncStep('SEND_PEDIDOS_ERRO');
          end;
        end;

        if dmApp.ShouldClearSyncData(LFullReason) then
        begin
          dmApp.ClearSyncData;
          LogSyncStep('CLEAR_OK_' + LFullReason);
        end;

        QueueProgress('Preparando sincronizacao...', 1);
        SetLength(LTables, Length(CTabelasSyncFiltradas) + Length(CTabelasSyncGlobais));
        for K := 0 to High(CTabelasSyncFiltradas) do
          LTables[K] := CTabelasSyncFiltradas[K];
        for K := 0 to High(CTabelasSyncGlobais) do
          LTables[Length(CTabelasSyncFiltradas) + K] := CTabelasSyncGlobais[K];

        LogSyncStep('SYNC_SCRIPT');
        try
          dmApp.SyncAllTablesSelectedByScript(LIdRep.ToString, LTables);
          dmApp.SetAppConfigValue('ultima_sincronizacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
          dmApp.SetAppConfigValue('ultima_sincronizacao_label', FormatDateTime('dd/mm/yyyy hh:nn', Now));
        except
          on E: Exception do
          begin
            dmApp.SetSyncTableError('sync_script', LIdRep.ToString, E.Message);
            LogSyncError('SYNC_SCRIPT', E.Message);
            raise;
          end;
        end;


        TThread.Queue(nil, DoFinishSync);
      except
        on E: Exception do
        begin
          LogSyncError('Sync', E.Message);
          LMsg := E.Message;
          if (Pos('socketexception', LowerCase(LMsg)) > 0) or
             (Pos('connection abort', LowerCase(LMsg)) > 0) or
             (Pos('software caused connection abort', LowerCase(LMsg)) > 0) or
             (Pos('connection reset', LowerCase(LMsg)) > 0) then
            LMsg := 'Conexao interrompida durante o download. Verifique a internet e tente sincronizar novamente.'
          else if (Pos('timeout', LowerCase(LMsg)) > 0) or
             (Pos('timed out', LowerCase(LMsg)) > 0) or
             (Pos('sockettimeoutexception', LowerCase(LMsg)) > 0) then
            LMsg := 'Internet lenta ou instavel. Tente sincronizar novamente em alguns minutos.';
          QueueMessage('Erro na sincronizacao: ' + LMsg);
          TThread.Queue(nil, DoFailSync);
        end;
      end;
    end).Start;
end;

procedure TfrmSync.LbBtnSyncClick(Sender: TObject);
begin
  Sincronar;
end;

procedure TfrmSync.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FSyncRunning then
  begin
    Action := TCloseAction.caNone;
    Exit;
  end;

  SetKeepScreenOn(False);
  FormHide(Sender);
  if Assigned(dmApp) then
    dmApp.ClearAppState('sync');
  Action := TCloseAction.caFree;
  frmSync := nil;
end;

procedure TfrmSync.FormHide(Sender: TObject);
begin
  StopApiWaitProgress;
  if not FSyncRunning then
    SetKeepScreenOn(False);
  FFormActive := False;
end;

end.

