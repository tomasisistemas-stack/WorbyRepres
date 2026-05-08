unit unSync;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.IOUtils, System.JSON,
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
    procedure DoQueueProgress;
    procedure DoQueueMessage;
    procedure DoSyncProgress;
    procedure DoFinishSync;
    procedure DoFailSync;
    procedure QueueProgress(const ATexto: string; AValor: Single);
    procedure QueueMessage(const AText: string);
    procedure SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
    procedure SetSyncUiEnabled(AEnabled: Boolean);
  private
    procedure AtualizarProgresso(const ATexto: string; AValor: Single);
    procedure ApplyOrientationLayout;
    procedure AtualizarUltimaSyncLabel;
    procedure AtualizarResumoEnvios;
    procedure LogSyncError(const AContext, AMessage: string);
    procedure LogSyncStep(const ATableName: string);
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
  unFuncoes;

const
  CLogSyncStepEnabled = False;

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
  AtualizarUltimaSyncLabel;
  AtualizarResumoEnvios;
  LbProgresso.Text := 'Aguardando sincronizacao';
  ProgressBarSync.Value := 0;
  ApplyOrientationLayout;
end;

procedure TfrmSync.AtualizarUltimaSyncLabel;
var
  LQuery: TFDQuery;
  LUltima: string;
begin
  LbUltimaSync.Text := 'Ultima sincronizacao: --';

  if not Assigned(dmApp) then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select strftime(''%d/%m/%Y %H:%M'', max(last_sync_at), ''localtime'') as ultima ' +
      'from sync_table_state ' +
      'where last_sync_at is not null and coalesce(last_error, '''') = ''''';
    LQuery.Open;
    LUltima := Trim(LQuery.FieldByName('ultima').AsString);
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
  LSafeBottom: Single;
  LContentTop: Single;
  LStatusWidth: Single;
  LButtonWidth: Single;
begin
  LIsLandscape := Width > Height;
  LSafeBottom := 0;
  if (not LIsLandscape) and IsXiaomiDevice then
    LSafeBottom := 50;

  if LIsLandscape then
  begin
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    LContentTop := TopBar.Height + 12;
    LStatusWidth := Width - 220;
    if LStatusWidth < 360 then
      LStatusWidth := Width - 40;
    if LStatusWidth > 760 then
      LStatusWidth := 760;
    if LStatusWidth < 300 then
      LStatusWidth := 300;

    CardStatus.Align := TAlignLayout.None;
    CardStatus.Width := LStatusWidth;
    CardStatus.Position.X := (Width - CardStatus.Width) / 2;
    CardStatus.Position.Y := LContentTop;

    LayoutRod.Align := TAlignLayout.None;
    LButtonWidth := Width - 120;
    if LButtonWidth > 420 then
      LButtonWidth := 420;
    if LButtonWidth < 180 then
      LButtonWidth := 180;
    LayoutRod.Width := LButtonWidth;
    LayoutRod.Position.X := (Width - LayoutRod.Width) / 2;
    LayoutRod.Position.Y := CardStatus.Position.Y + CardStatus.Height + 10;

    lbottom.Align := TAlignLayout.None;
    lbottom.Margins.Bottom := 0;
    lbottom.Height := 60;
    lbottom.Width := Width;
    lbottom.Position.X := 0;
    lbottom.Position.Y := Height - lbottom.Height;
  end
  else
  begin
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    LContentTop := TopBar.Height + 18;
    LStatusWidth := Width - 20;
    if LStatusWidth > 460 then
      LStatusWidth := 460;
    if LStatusWidth < 280 then
      LStatusWidth := 280;
    CardStatus.Align := TAlignLayout.None;
    CardStatus.Width := LStatusWidth;
    CardStatus.Position.X := (Width - CardStatus.Width) / 2;
    CardStatus.Position.Y := LContentTop;

    LayoutRod.Align := TAlignLayout.None;
    LayoutRod.Width := Width - 75;
    if LayoutRod.Width > 480 then
      LayoutRod.Width := 480;
    LayoutRod.Position.X := (Width - LayoutRod.Width) / 2;
    LayoutRod.Position.Y := Height - (72 + LSafeBottom) - LayoutRod.Height - 12;

    lbottom.Align := TAlignLayout.None;
    lbottom.Margins.Bottom := 0;
    lbottom.Height := 72;
    lbottom.Width := Width;
    lbottom.Position.X := 0;
    lbottom.Position.Y := Height - lbottom.Height - LSafeBottom;
  end;
end;

procedure TfrmSync.ImgVoltarClick(Sender: TObject);
begin
  close;
end;

procedure TfrmSync.ImgVoltarTap(Sender: TObject; const Point: TPointF);
begin
  close;
end;

procedure TfrmSync.AtualizarProgresso(const ATexto: string; AValor: Single);
begin
  LbProgresso.Text := ATexto;
  ProgressBarSync.Value := AValor;
  Application.ProcessMessages;
end;

procedure TfrmSync.SyncProgressHandler(const ATable: string; AInserted, ATotal: Integer; AIsNewTable: Boolean);
begin
  FQueueTableName := ATable;
  FQueueInserted := AInserted;
  FQueueTotal := ATotal;
  FQueueIsNewTable := AIsNewTable;
  TThread.Queue(nil, DoSyncProgress);
end;

procedure TfrmSync.QueueProgress(const ATexto: string; AValor: Single);
begin
  FQueueProgressText := ATexto;
  FQueueProgressValue := AValor;
  TThread.Queue(nil, DoQueueProgress);
end;

procedure TfrmSync.QueueMessage(const AText: string);
begin
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
  AtualizarProgresso(FQueueProgressText, FQueueProgressValue);
end;

procedure TfrmSync.DoQueueMessage;
begin
  LbProgresso.Text := FQueueMessageText;
  ShowMessage(FQueueMessageText);
end;

procedure TfrmSync.DoSyncProgress;
begin
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
    ProgressBarTable.Value := FQueueInserted;
  end;
  LbProgressoTabela.Text := 'Registros (' + FQueueTableName + '): ' +
    FQueueInserted.ToString + ' / ' + FQueueTotal.ToString;
  Application.ProcessMessages;
end;

procedure TfrmSync.DoFinishSync;
begin
  AtualizarProgresso('Sincronizacao concluida', ProgressBarSync.Max);
  AtualizarUltimaSyncLabel;
  AtualizarResumoEnvios;
  SetSyncUiEnabled(True);
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
end;

procedure TfrmSync.DoFailSync;
begin
  SetSyncUiEnabled(True);
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
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
  CTabelasSyncFiltradas: array[0..8] of string = (
    'representante',
    'cidades',
    'cliente',
    'vendas1',
    'vendas2',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );

  CTabelasSyncGlobais: array[0..3] of string = (
    'produto',
    'subcategoria',
    'fop',
    'prazo'
  );
var
  I: Integer;
  LMax: Integer;
  LIdRep: Integer;
begin
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
  SetSyncUiEnabled(False);

  LMax := 1 + Length(CTabelasSyncFiltradas) + Length(CTabelasSyncGlobais);
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
    begin
      try
        dmApp.OnSyncProgress := SyncProgressHandler;
        LogSyncStep('INIT');

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

        for K := 0 to High(CTabelasSyncGlobais) do
        begin
          QueueProgress('Sincronizando ' + CTabelasSyncGlobais[K] + '...', K + 2);
          LogSyncStep(CTabelasSyncGlobais[K]);
          try
            dmApp.SyncTable(CTabelasSyncGlobais[K], '', 0);
          except
            on E: Exception do
            begin
              dmApp.SetSyncTableError(CTabelasSyncGlobais[K], '', E.Message);
              LogSyncError(CTabelasSyncGlobais[K], E.Message);
              raise;
            end;
          end;
        end;

        for K := 0 to High(CTabelasSyncFiltradas) do
        begin
          QueueProgress('Sincronizando ' + CTabelasSyncFiltradas[K] + '...', Length(CTabelasSyncGlobais) + 2 + K);
          LogSyncStep(CTabelasSyncFiltradas[K]);
          try
            dmApp.SyncTable(CTabelasSyncFiltradas[K], LIdRep.ToString, 0);
          except
            on E: Exception do
            begin
              dmApp.SetSyncTableError(CTabelasSyncFiltradas[K], LIdRep.ToString, E.Message);
              LogSyncError(CTabelasSyncFiltradas[K], E.Message);
              raise;
            end;
          end;
        end;


        TThread.Queue(nil, DoFinishSync);
      except
        on E: Exception do
        begin
          LogSyncError('Sync', E.Message);
          QueueMessage('Erro na sincronizacao: ' + E.Message);
          TThread.Queue(nil, DoFailSync);
        end;
      end;
    end).Start;
end;

procedure TfrmSync.LbBtnSyncClick(Sender: TObject);
begin
  Sincronar;
end;

end.

