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
    FLastSyncProgressTick: Cardinal;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
  if Assigned(dmApp) then
    dmApp.SetAppState('sync', 0, '');
  OnClose := FormClose;
  AtualizarUltimaSyncLabel;
  AtualizarResumoEnvios;
  LbProgresso.Text := 'Aguardando sincronizacao';
  ProgressBarSync.Value := 0;
  ApplyOrientationLayout;
  TThread.ForceQueue(nil,
    procedure
    begin
      if not (csDestroying in ComponentState) then
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
  LIsTabletPortrait: Boolean;
  LSafeBottom: Single;
  LContentTop: Single;
  LStatusWidth: Single;
  LButtonWidth: Single;
begin
  LIsLandscape := Width > Height;
  LIsTabletPortrait := (not LIsLandscape) and (Width >= 430);
  LSafeBottom := 0;
  if not LIsLandscape then
    LSafeBottom := 50;

  if LIsLandscape then
  begin
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    LContentTop := TopBar.Height + 12;
    LStatusWidth := Width - 220;
    if LStatusWidth < 360 then
      LStatusWidth := Width - 40;
    if LStatusWidth > 900 then
      LStatusWidth := 900;
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
  else if LIsTabletPortrait then
  begin
    TopBar.Height := 82;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) * 0.75;

    LContentTop := TopBar.Height + 22;
    LStatusWidth := Width - 36;
    if Width >= 600 then
    begin
      if LStatusWidth > 760 then
        LStatusWidth := 760;
    end
    else if LStatusWidth > 560 then
      LStatusWidth := 560;
    CardStatus.Align := TAlignLayout.None;
    CardStatus.Width := LStatusWidth;
    if Width >= 600 then
      CardStatus.Height := 160
    else
      CardStatus.Height := 142;
    CardStatus.Position.X := (Width - CardStatus.Width) / 2;
    CardStatus.Position.Y := LContentTop;

    LayoutRod.Align := TAlignLayout.None;
    LButtonWidth := Width - 120;
    if Width >= 600 then
    begin
      if LButtonWidth > 460 then
        LButtonWidth := 460;
    end
    else if LButtonWidth > 360 then
      LButtonWidth := 360;
    if LButtonWidth < 220 then
      LButtonWidth := 220;
    LayoutRod.Width := LButtonWidth;
    LayoutRod.Position.X := (Width - LayoutRod.Width) / 2;
    LayoutRod.Position.Y := CardStatus.Position.Y + CardStatus.Height + 34;

    lbottom.Align := TAlignLayout.None;
    lbottom.Margins.Bottom := 0;
    lbottom.Height := 64;
    lbottom.Width := Width;
    lbottom.Position.X := 0;
    lbottom.Position.Y := Height - lbottom.Height - LSafeBottom;
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
      if (csDestroying in ComponentState) then
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
var
  LPerc: Integer;
  LNomeTabela: string;
  LDownloadProgress: Boolean;
  LApplyProgress: Boolean;

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
begin
  LDownloadProgress := SameText(FQueueTableName, '__script_download') and
    (((FQueueTotal > 5) and (FQueueInserted >= 0)) or
     ((FQueueTotal = 0) and (FQueueInserted > 0)));
  LApplyProgress := SameText(FQueueTableName, '__script_apply') and (FQueueTotal > 5);

  if LDownloadProgress then
  begin
    ProgressBarSync.Min := 0;
    ProgressBarSync.Max := 100;

    ProgressBarTable.Min := 0;
    if FQueueTotal > 0 then
    begin
      ProgressBarTable.Max := FQueueTotal;
      ProgressBarTable.Value := FQueueInserted;
      LPerc := Round(FQueueInserted / FQueueTotal * 100);
      if LPerc > 100 then
        LPerc := 100;
      ProgressBarSync.Value := 40 + Round(LPerc * 0.20);
      LbProgresso.Text := 'Etapa 3 de 5 - Baixando dados da API';
      LbProgressoTabela.Text := 'Download: ' + FormatKb(FQueueInserted) + ' de ' +
        FormatKb(FQueueTotal) + ' - ' + LPerc.ToString + '%';
    end
    else
    begin
      ProgressBarSync.Value := 40;
      ProgressBarTable.Max := 1;
      ProgressBarTable.Value := 0;
      LbProgresso.Text := 'Etapa 3 de 5 - Baixando dados da API';
      LbProgressoTabela.Text := 'Download: ' + FormatKb(FQueueInserted);
    end;
    Exit;
  end;

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
begin
  if Assigned(dmApp) then
  begin
    dmApp.SetAppConfigValue('ultima_sincronizacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    dmApp.SetAppConfigValue('ultima_sincronizacao_label', FormatDateTime('dd/mm/yyyy hh:nn', Now));
  end;
  AtualizarProgresso('Sincronizacao concluida', ProgressBarSync.Max);
  AtualizarUltimaSyncLabel;
  AtualizarResumoEnvios;
  SetSyncUiEnabled(True);
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
  {$IFDEF ANDROID}
  if Assigned(frmPrincipal) then
    frmPrincipal.ResumeLocationServiceAfterSync;
  {$ENDIF}
end;

procedure TfrmSync.DoFailSync;
begin
  SetSyncUiEnabled(True);
  FSyncRunning := False;
  if Assigned(dmApp) then
    dmApp.OnSyncProgress := nil;
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

  CTabelasSyncGlobais: array[0..5] of string = (
    'produto',
    'subcategoria',
    'fop',
    'prazo',
    'grade_comissao',
    'escala_comissao'
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
  FLastSyncProgressTick := 0;
  SetSyncUiEnabled(False);
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
  if Assigned(dmApp) then
    dmApp.ClearAppState('sync');
  Action := TCloseAction.caFree;
  frmSync := nil;
end;

end.

