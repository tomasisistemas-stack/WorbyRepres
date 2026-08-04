unit unDashBoard;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListBox,
  FMX.Edit, FMX.TabControl, FMX.ScrollBox, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base;

type
  TfrmDashBoard = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    CbMesAno: TComboBox;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    LayoutTabsBottom: TLayout;
    BtnTabDashboard: TLayout;
    IconDashboard: TLayout;
    IconDashBar1: TRectangle;
    IconDashBar2: TRectangle;
    IconDashBar3: TRectangle;
    LbTabDashboard: TLabel;
    BtnTabDashboardHit: TRectangle;
    BtnTabPedidos: TLayout;
    IconPedidos: TLayout;
    IconPedidoFolha: TRectangle;
    IconPedidoLinha1: TRectangle;
    IconPedidoLinha2: TRectangle;
    IconPedidoLinha3: TRectangle;
    LbTabPedidos: TLabel;
    BtnTabPedidosHit: TRectangle;
    Tabs: TTabControl;
    TabDashboard: TTabItem;
    TabListaPedidos: TTabItem;
    ScrollDashboard: TVertScrollBox;
    CardRealizado: TRectangle;
    LbRealizadoTitulo: TLabel;
    LbRealizadoValor: TLabel;
    LbMeta: TLabel;
    LbPercentualMeta: TLabel;
    CardClientes: TRectangle;
    LbClientesTitulo: TLabel;
    LbClientesValor: TLabel;
    LbClientesSub: TLabel;
    CardPositivacao: TRectangle;
    LbPositivacaoTitulo: TLabel;
    LbPositivacaoValor: TLabel;
    CardDesconto: TRectangle;
    LbDescontoTitulo: TLabel;
    LbDescontoValor: TLabel;
    CardTicket: TRectangle;
    LbTicketTitulo: TLabel;
    LbTicketValor: TLabel;
    CardComissao: TRectangle;
    LbComissaoTitulo: TLabel;
    LbComissaoValor: TLabel;
    CardMeta: TRectangle;
    LbMetaTitulo: TLabel;
    LbMetaSub: TLabel;
    BarraMetaFundo: TRectangle;
    BarraMetaRealizado: TRectangle;
    CardResumo: TRectangle;
    LbResumoTitulo: TLabel;
    LbResumoAtendidos: TLabel;
    LbResumoSemCompra: TLabel;
    ScrollPedidos: TVertScrollBox;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    CbStatusPedidos: TComboBox;
    EdDiaInicial: TEdit;
    EdDiaFinal: TEdit;
    CardTotalFaturado: TRectangle;
    LbTotalFaturadoTitulo: TLabel;
    LbTotalFaturadoValor: TLabel;
    CardDescMedio: TRectangle;
    LbDescMedioTitulo: TLabel;
    LbDescMedioValor: TLabel;
    CardComissaoTotal: TRectangle;
    LbComissaoTotalTitulo: TLabel;
    LbComissaoTotalValor: TLabel;
    CardLista: TRectangle;
    LbListaTitulo: TLabel;
    LbListaQtd: TLabel;
    LvPedidosFaturados: TListView;
    LbPedido1: TLabel;
    LbPedido1Sub: TLabel;
    LbPedido1Valores: TLabel;
    LbPedido2: TLabel;
    LbPedido2Sub: TLabel;
    LbPedido2Valores: TLabel;
    LbPedido3: TLabel;
    LbPedido3Sub: TLabel;
    LbPedido3Valores: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CbMesAnoChange(Sender: TObject);
    procedure FiltrosPedidosChange(Sender: TObject);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnTabDashboardClick(Sender: TObject);
    procedure BtnTabPedidosClick(Sender: TObject);
    procedure BtnTabDashboardTap(Sender: TObject; const Point: TPointF);
    procedure BtnTabPedidosTap(Sender: TObject; const Point: TPointF);
  private
    FPercentualMeta: Double;
    FAtualizandoFiltros: Boolean;
    FDashboardLoadSeq: Integer;
    FPedidosLoadSeq: Integer;
    FFormActive: Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormHide(Sender: TObject);
    procedure CarregarMesesAsync;
    procedure ApplyResponsiveLayout;
    procedure AtualizarAbasBottom;
    procedure AtualizarDados;
    procedure AtualizarPedidosFaturados;
    procedure AtualizarDiasFiltro;
  protected
    procedure Resize; override;
  public
  end;

var
  frmDashBoard: TfrmDashBoard;

implementation

{$R *.fmx}

uses
  System.JSON,
  System.DateUtils,
  System.Math,
  unDMApp,
  unPrincipal,
  unAndroidComboFix;

function JsonFloat(AObj: TJSONObject; const AName: string): Double;
var
  LValue: TJSONValue;
  LText: string;
  LFormat: TFormatSettings;
begin
  Result := 0;
  if not Assigned(AObj) then
    Exit;

  LValue := AObj.GetValue(AName);
  if not Assigned(LValue) or (LValue is TJSONNull) then
    Exit;

  if LValue is TJSONNumber then
    Exit(TJSONNumber(LValue).AsDouble);

  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := '.';
  LFormat.ThousandSeparator := ',';
  LText := StringReplace(Trim(LValue.Value), ',', '.', [rfReplaceAll]);
  Result := StrToFloatDef(LText, 0, LFormat);
end;

function JsonInt(AObj: TJSONObject; const AName: string): Integer;
begin
  Result := Round(JsonFloat(AObj, AName));
end;

function JsonString(AObj: TJSONObject; const AName: string): string;
var
  LValue: TJSONValue;
begin
  Result := '';
  if not Assigned(AObj) then
    Exit;

  LValue := AObj.GetValue(AName);
  if Assigned(LValue) and not (LValue is TJSONNull) then
    Result := LValue.Value;
end;

function JsonFound(AObj: TJSONObject): Boolean;
var
  LValue: TJSONValue;
begin
  Result := Assigned(AObj);
  if not Result then
    Exit;

  LValue := AObj.GetValue('found');
  if Assigned(LValue) then
    Result := SameText(LValue.Value, 'true');
end;

function MoneyBR(AValue: Double): string;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := ',';
  LFormat.ThousandSeparator := '.';
  Result := 'R$ ' + FormatFloat('#,##0.00', AValue, LFormat);
end;

function PercentBR(AValue: Double): string;
var
  LFormat: TFormatSettings;
begin
  LFormat := TFormatSettings.Create;
  LFormat.DecimalSeparator := ',';
  LFormat.ThousandSeparator := '.';
  Result := FormatFloat('0.00', AValue, LFormat) + '%';
end;

function DataBR(const AValue: string): string;
begin
  Result := Trim(AValue);
  if (Length(Result) >= 10) and (Result[5] = '-') and (Result[8] = '-') then
    Result := Copy(Result, 9, 2) + '/' + Copy(Result, 6, 2) + '/' + Copy(Result, 1, 4);
end;

procedure TfrmDashBoard.FormCreate(Sender: TObject);
var
  LMesAtual: string;
begin
  FAtualizandoFiltros := True;
  UseAndroidSafeComboPicker([CbMesAno, CbStatusPedidos]);
  FPercentualMeta := 0;
  FDashboardLoadSeq := 0;
  FPedidosLoadSeq := 0;
  FFormActive := False;
  CbMesAno.Items.Clear;
  LMesAtual := FormatDateTime('mm/yyyy', Date);
  CbMesAno.Items.Add(LMesAtual);
  CbMesAno.ItemIndex := 0;

  if FileExists('C:\Tomasi Sistemas\WorbyRepres\telas\voltar.png') then
    ImgVoltar.Bitmap.LoadFromFile('C:\Tomasi Sistemas\WorbyRepres\telas\voltar.png')
  else
  begin
    ImgVoltar.Bitmap.SetSize(96, 96);
    if ImgVoltar.Bitmap.Canvas.BeginScene then
    begin
      try
        ImgVoltar.Bitmap.Clear(TAlphaColors.Null);
        ImgVoltar.Bitmap.Canvas.Stroke.Color := TAlphaColors.Dodgerblue;
        ImgVoltar.Bitmap.Canvas.Stroke.Thickness := 8;
        ImgVoltar.Bitmap.Canvas.DrawLine(PointF(58, 24), PointF(34, 48), 1);
        ImgVoltar.Bitmap.Canvas.DrawLine(PointF(34, 48), PointF(58, 72), 1);
        ImgVoltar.Bitmap.Canvas.DrawLine(PointF(36, 48), PointF(76, 48), 1);
      finally
        ImgVoltar.Bitmap.Canvas.EndScene;
      end;
    end;
  end;
  CbStatusPedidos.Items.Clear;
  CbStatusPedidos.Items.Add('TODOS');
  CbStatusPedidos.Items.Add('FATURADO');
  CbStatusPedidos.Items.Add('ABERTO');
  CbStatusPedidos.ItemIndex := 1;
  EdBuscar.Text := '';
  AtualizarDiasFiltro;
  FAtualizandoFiltros := False;
  Tabs.TabIndex := 0;
  LvPedidosFaturados.ItemAppearance.ItemHeight := 50;
  LbPedido1.Visible := False;
  LbPedido1Sub.Visible := False;
  LbPedido1Valores.Visible := False;
  LbPedido2.Visible := False;
  LbPedido2Sub.Visible := False;
  LbPedido2Valores.Visible := False;
  LbPedido3.Visible := False;
  LbPedido3Sub.Visible := False;
  LbPedido3Valores.Visible := False;
  AtualizarAbasBottom;
end;

procedure TfrmDashBoard.CarregarMesesAsync;
var
  LMeses: TStringList;
  LMes: string;
  LMesSelecionado: string;
  LIndex: Integer;
  I: Integer;
  LOldAtualizando: Boolean;
begin
  if not FFormActive then
    Exit;

  LMesSelecionado := Trim(CbMesAno.Text);
  if LMesSelecionado = '' then
    LMesSelecionado := FormatDateTime('mm/yyyy', Date);

  LMeses := TStringList.Create;
  try
    for I := -6 to 6 do
      LMeses.Add(FormatDateTime('mm/yyyy', IncMonth(Date, I)));

    LOldAtualizando := FAtualizandoFiltros;
    FAtualizandoFiltros := True;
    try
      CbMesAno.Items.Clear;
      for LMes in LMeses do
        CbMesAno.Items.Add(LMes);

      LIndex := CbMesAno.Items.IndexOf(LMesSelecionado);
      if LIndex < 0 then
        LIndex := CbMesAno.Items.IndexOf(FormatDateTime('mm/yyyy', Date));
      if LIndex < 0 then
        LIndex := 0;
      CbMesAno.ItemIndex := LIndex;
      AtualizarDiasFiltro;
    finally
      FAtualizandoFiltros := LOldAtualizando;
    end;

    AtualizarDados;
          AtualizarPedidosFaturados;
  finally
    LMeses.Free;
  end;
end;

procedure TfrmDashBoard.FormShow(Sender: TObject);
begin
  FFormActive := True;
  if Assigned(dmApp) then
    dmApp.SetAppState('dashboard', 0, '');
  OnClose := FormClose;
  OnHide := FormHide;
  CarregarMesesAsync;
  ApplyResponsiveLayout;
  AtualizarAbasBottom;
end;

procedure TfrmDashBoard.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

procedure TfrmDashBoard.CbMesAnoChange(Sender: TObject);
begin
  if FAtualizandoFiltros then
    Exit;
  AtualizarDiasFiltro;
  AtualizarDados;
end;

procedure TfrmDashBoard.FiltrosPedidosChange(Sender: TObject);
begin
  if FAtualizandoFiltros then
    Exit;
  AtualizarPedidosFaturados;
end;

procedure TfrmDashBoard.ImgVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmDashBoard.AtualizarAbasBottom;
const
  CActiveColor: TAlphaColor = $FF009688;
  CInactiveColor: TAlphaColor = $FF5D6B85;
begin
  if Tabs.TabIndex = 0 then
  begin
    LbTabDashboard.TextSettings.FontColor := CActiveColor;
    IconDashBar1.Fill.Color := CActiveColor;
    IconDashBar2.Fill.Color := CActiveColor;
    IconDashBar3.Fill.Color := CActiveColor;

    LbTabPedidos.TextSettings.FontColor := CInactiveColor;
    IconPedidoFolha.Stroke.Color := CInactiveColor;
    IconPedidoLinha1.Fill.Color := CInactiveColor;
    IconPedidoLinha2.Fill.Color := CInactiveColor;
    IconPedidoLinha3.Fill.Color := CInactiveColor;
  end
  else
  begin
    LbTabDashboard.TextSettings.FontColor := CInactiveColor;
    IconDashBar1.Fill.Color := CInactiveColor;
    IconDashBar2.Fill.Color := CInactiveColor;
    IconDashBar3.Fill.Color := CInactiveColor;

    LbTabPedidos.TextSettings.FontColor := CActiveColor;
    IconPedidoFolha.Stroke.Color := CActiveColor;
    IconPedidoLinha1.Fill.Color := CActiveColor;
    IconPedidoLinha2.Fill.Color := CActiveColor;
    IconPedidoLinha3.Fill.Color := CActiveColor;
  end;
end;

procedure TfrmDashBoard.BtnTabDashboardClick(Sender: TObject);
begin
  Tabs.ActiveTab := TabDashboard;
  Tabs.TabIndex := 0;
  AtualizarAbasBottom;
end;

procedure TfrmDashBoard.BtnTabPedidosClick(Sender: TObject);
begin
  Tabs.ActiveTab := TabListaPedidos;
  Tabs.TabIndex := 1;
  AtualizarAbasBottom;
  AtualizarPedidosFaturados;
end;

procedure TfrmDashBoard.BtnTabDashboardTap(Sender: TObject; const Point: TPointF);
begin
  BtnTabDashboardClick(Sender);
end;

procedure TfrmDashBoard.BtnTabPedidosTap(Sender: TObject; const Point: TPointF);
begin
  BtnTabPedidosClick(Sender);
end;

procedure TfrmDashBoard.AtualizarDiasFiltro;
var
  LMes: string;
  LMesNum: Integer;
  LAnoNum: Integer;
  LDias: Integer;
  LOldAtualizando: Boolean;
begin
  if not FFormActive then
    Exit;

  LMes := Trim(CbMesAno.Text);
  if (Length(LMes) <> 7) or (LMes[3] <> '/') then
    Exit;

  LMesNum := StrToIntDef(Copy(LMes, 1, 2), 0);
  LAnoNum := StrToIntDef(Copy(LMes, 4, 4), 0);
  if (LMesNum < 1) or (LMesNum > 12) or (LAnoNum <= 0) then
    Exit;

  LDias := DayOf(EndOfTheMonth(EncodeDate(LAnoNum, LMesNum, 1)));
  LOldAtualizando := FAtualizandoFiltros;
  FAtualizandoFiltros := True;
  try
    if Trim(EdDiaInicial.Text) = '' then
      EdDiaInicial.Text := '01';
    if (Trim(EdDiaFinal.Text) = '') or (StrToIntDef(EdDiaFinal.Text, 0) > LDias) then
      EdDiaFinal.Text := Format('%.2d', [LDias]);
  finally
    FAtualizandoFiltros := LOldAtualizando;
  end;
end;

procedure TfrmDashBoard.AtualizarDados;
var
  LCodRepresentante: Integer;
  LMes: string;
  LSeq: Integer;
begin
  LMes := Trim(CbMesAno.Text);
  LCodRepresentante := 0;
  if Assigned(frmPrincipal) then
    LCodRepresentante := frmPrincipal.id_representante;

  Inc(FDashboardLoadSeq);
  LSeq := FDashboardLoadSeq;
  LbSubtitulo.Text := 'Carregando painel - ' + LMes;
  LbRealizadoValor.Text := '...';
  LbPercentualMeta.Text := '...';
  LbClientesValor.Text := '...';
  LbPositivacaoValor.Text := '...';
  LbDescontoValor.Text := '...';
  LbTicketValor.Text := '...';

  if (LCodRepresentante <= 0) or (LMes = '') then
    Exit;

  TThread.CreateAnonymousThread(
    procedure
    var
      LMeta: TJSONObject;
      LJsonText: string;
      LErro: string;
    begin
      LJsonText := '';
      LErro := '';
      try
        TMonitor.Enter(dmApp);
        try
          LMeta := dmApp.GetMetaRepresentante(LCodRepresentante, LMes);
          try
            LJsonText := LMeta.ToJSON;
          finally
            LMeta.Free;
          end;
        finally
          TMonitor.Exit(dmApp);
        end;
      except
        on E: Exception do
          LErro := E.Message;
      end;

      TThread.Queue(nil,
        procedure
        var
          LJsonValue: TJSONValue;
          LMetaObj: TJSONObject;
          LVlMeta: Double;
          LVlRealizado: Double;
          LPercRealizado: Double;
          LClientesAtendidos: Integer;
          LClientesBase: Integer;
          LSemCompra: Integer;
          LPercPositivacao: Double;
          LTicketMedio: Double;
          LPercDesconto: Double;
        begin
          if (csDestroying in ComponentState) or (not FFormActive) or
             (not Visible) or (LSeq <> FDashboardLoadSeq) then
            Exit;

          LVlMeta := 0;
          LVlRealizado := 0;
          LPercRealizado := 0;
          LClientesAtendidos := 0;
          LClientesBase := 0;
          LPercPositivacao := 0;
          LTicketMedio := 0;
          LPercDesconto := 0;

          if LErro <> '' then
            LbSubtitulo.Text := 'Dados indisponiveis para ' + LMes
          else
          begin
            LJsonValue := TJSONObject.ParseJSONValue(LJsonText);
            try
              if LJsonValue is TJSONObject then
              begin
                LMetaObj := TJSONObject(LJsonValue);
                if JsonFound(LMetaObj) then
                begin
                  LVlMeta := JsonFloat(LMetaObj, 'vl_meta');
                  LVlRealizado := JsonFloat(LMetaObj, 'vl_realizado');
                  LPercRealizado := JsonFloat(LMetaObj, 'perc_realizado');
                  LClientesAtendidos := JsonInt(LMetaObj, 'qtd_clientes_atendidos');
                  LClientesBase := JsonInt(LMetaObj, 'qtd_clientes_base');
                  LPercPositivacao := JsonFloat(LMetaObj, 'perc_positivacao');
                  LTicketMedio := JsonFloat(LMetaObj, 'ticket_medio');
                  LPercDesconto := JsonFloat(LMetaObj, 'perc_desconto');
                  LbSubtitulo.Text := 'Painel comercial - ' + LMes;
                end
                else
                  LbSubtitulo.Text := 'Sem meta cadastrada para ' + LMes;
              end
              else
                LbSubtitulo.Text := 'Dados indisponiveis para ' + LMes;
            finally
              LJsonValue.Free;
            end;
          end;

          LSemCompra := Max(LClientesBase - LClientesAtendidos, 0);
          FPercentualMeta := EnsureRange(LPercRealizado / 100, 0, 1);

          LbRealizadoValor.Text := MoneyBR(LVlRealizado);
          LbMeta.Text := 'Meta  ' + MoneyBR(LVlMeta);
          LbPercentualMeta.Text := PercentBR(LPercRealizado) + ' da meta';
          LbClientesValor.Text := LClientesAtendidos.ToString;
          LbClientesSub.Text := 'de ' + LClientesBase.ToString + ' clientes';
          LbPositivacaoValor.Text := PercentBR(LPercPositivacao);
          LbDescontoValor.Text := PercentBR(LPercDesconto);
          LbTicketValor.Text := MoneyBR(LTicketMedio);
          LbComissaoValor.Text := 'R$ 0,00';
          LbResumoAtendidos.Text := 'Atendidos     ' + LClientesAtendidos.ToString;
          LbResumoSemCompra.Text := 'Sem compra  ' + LSemCompra.ToString;
          BarraMetaRealizado.Width := BarraMetaFundo.Width * FPercentualMeta;
          AtualizarPedidosFaturados;
        end);
    end).Start;
end;

procedure TfrmDashBoard.AtualizarPedidosFaturados;
var
  LCodRepresentante: Integer;
  LMes: string;
  LStatus: string;
  LBusca: string;
  LDiaInicial: Integer;
  LDiaFinal: Integer;
  LSeq: Integer;
begin
  if not FFormActive then
    Exit;

  LMes := Trim(CbMesAno.Text);
  LStatus := Trim(CbStatusPedidos.Text);
  if LStatus = '' then
    LStatus := 'FATURADO';
  LBusca := Trim(EdBuscar.Text);
  LDiaInicial := StrToIntDef(Trim(EdDiaInicial.Text), 0);
  LDiaFinal := StrToIntDef(Trim(EdDiaFinal.Text), 0);
  LCodRepresentante := 0;
  if Assigned(frmPrincipal) then
    LCodRepresentante := frmPrincipal.id_representante;
  Inc(FPedidosLoadSeq);
  LSeq := FPedidosLoadSeq;
  LbTotalFaturadoValor.Text := MoneyBR(0);
  LbDescMedioValor.Text := PercentBR(0);
  LbComissaoTotalValor.Text := MoneyBR(0);
  LbComissaoValor.Text := MoneyBR(0);
  LbListaQtd.Text := 'Carregando...';
  if (LCodRepresentante <= 0) or (LMes = '') then
    Exit;

  TThread.CreateAnonymousThread(
    procedure
    var
      LDados: TJSONObject;
      LJsonText: string;
      LErro: string;
    begin
      LJsonText := '';
      LErro := '';
      try
        TMonitor.Enter(dmApp);
        try
          LDados := dmApp.GetPedidosFaturadosDashboard(LCodRepresentante, LMes, LStatus, LDiaInicial, LDiaFinal, LBusca);
          try
            LJsonText := LDados.ToJSON;
          finally
            LDados.Free;
          end;
        finally
          TMonitor.Exit(dmApp);
        end;
      except
        on E: Exception do
          LErro := E.Message;
      end;

      TThread.Queue(nil,
        procedure
        var
          LJsonValue: TJSONValue;
          LDadosObj: TJSONObject;
          LPedidosValue: TJSONValue;
          LPedidos: TJSONArray;
          LPedido: TJSONObject;
          LItem: TListViewItem;
          LComissaoTexto: string;
          LNumdoc: string;
          LCliente: string;
          LData: string;
          LTotal: Double;
          LDesconto: Double;
          LPercComissao: Double;
          LVlrComissao: Double;
          I: Integer;
        begin
          if (csDestroying in ComponentState) or (not FFormActive) or
             (not Visible) or (LSeq <> FPedidosLoadSeq) then
            Exit;

          if SameText(LStatus, 'ABERTO') then
            LbTotalFaturadoTitulo.Text := 'Total aberto'
          else
            LbTotalFaturadoTitulo.Text := 'Total faturado';

          if LErro <> '' then
          begin
            LbListaQtd.Text := 'Erro ao carregar pedidos';
            LvPedidosFaturados.Items.Clear;
            Exit;
          end;

          LJsonValue := TJSONObject.ParseJSONValue(LJsonText);
          try
            if not (LJsonValue is TJSONObject) then
            begin
              LbListaQtd.Text := '0 pedidos';
              Exit;
            end;

            LDadosObj := TJSONObject(LJsonValue);
            LbTotalFaturadoValor.Text := StringReplace(MoneyBR(JsonFloat(LDadosObj, 'total_faturado')), 'R$ ', 'R$', []);
            LbDescMedioValor.Text := PercentBR(JsonFloat(LDadosObj, 'perc_desconto_medio'));
            LComissaoTexto := StringReplace(MoneyBR(JsonFloat(LDadosObj, 'total_comissao')), 'R$ ', 'R$', []) +
              ' (' + PercentBR(JsonFloat(LDadosObj, 'perc_comissao_media')) + ')';
            LbComissaoTotalValor.Text := LComissaoTexto;
            LbComissaoValor.Text := LComissaoTexto;
            LbListaQtd.Text := JsonInt(LDadosObj, 'qtd_pedidos').ToString + ' pedidos';

            LvPedidosFaturados.BeginUpdate;
            try
              LvPedidosFaturados.Items.Clear;
              LPedidos := nil;
              LPedidosValue := LDadosObj.GetValue('pedidos');
              if LPedidosValue is TJSONArray then
                LPedidos := TJSONArray(LPedidosValue);

              if Assigned(LPedidos) then
                for I := 0 to LPedidos.Count - 1 do
                  if LPedidos.Items[I] is TJSONObject then
                  begin
                    LPedido := TJSONObject(LPedidos.Items[I]);
                    LNumdoc := JsonString(LPedido, 'numdoc_destino');
                    if (LNumdoc = '') or (StrToIntDef(LNumdoc, 0) <= 0) then
                      LNumdoc := JsonString(LPedido, 'numdoc');
                    LCliente := JsonString(LPedido, 'nom_cliente');
                    LData := DataBR(JsonString(LPedido, 'dta_emissao'));
                    LTotal := JsonFloat(LPedido, 'tot_liquido');
                    LDesconto := JsonFloat(LPedido, 'desconto');
                    LPercComissao := JsonFloat(LPedido, 'perc_comissao');
                    LVlrComissao := JsonFloat(LPedido, 'vlr_comissao');

                    LItem := LvPedidosFaturados.Items.Add;
                    LItem.Text := 'Pedido ' + LNumdoc + ' - ' + LCliente;
                    LItem.Detail := LData + '  ' + MoneyBR(LTotal) + '  Desc ' + PercentBR(LDesconto) + sLineBreak +
                      'Comissao ' + PercentBR(LPercComissao) + ' / ' + MoneyBR(LVlrComissao);
                    LItem.TagString := JsonString(LPedido, 'numdoc');
                  end;
            finally
              LvPedidosFaturados.EndUpdate;
            end;
          finally
            LJsonValue.Free;
          end;
        end);
    end).Start;
end;

procedure TfrmDashBoard.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LMargin: Single;
  LCardW: Single;
  LTop: Single;
  LBottomSafe: Single;
  LIsTablet: Boolean;
begin
  LIsLandscape := Width > Height;
  LIsTablet := Min(Width, Height) >= 600;
  if LIsTablet then
    LMargin := 18
  else
    LMargin := 12;
  LBottomSafe := 0;
  if not LIsLandscape then
    LBottomSafe := 60;

  if LIsLandscape then
    TopBar.Height := 76
  else
    TopBar.Height := 112;

  LbTitulo.Position.X := 20;
  LbTitulo.Position.Y := 18;
  LbTitulo.Width := Width - 210;
  LbSubtitulo.Position.X := 20;
  LbSubtitulo.Position.Y := LbTitulo.Position.Y + LbTitulo.Height + 2;
  LbSubtitulo.Width := Width - 210;
  LbSubtitulo.TextSettings.Font.Size := 14;
  CbMesAno.Width := 150;
  CbMesAno.Height := 36;
  CbMesAno.Position.X := Width - CbMesAno.Width - 18;
  CbMesAno.Position.Y := (TopBar.Height - CbMesAno.Height) / 2;

  Tabs.Position.X := 0;
  Tabs.Position.Y := TopBar.Height;
  Tabs.Width := Width;
  Tabs.TabHeight := 0;
  lbottom.Align := TAlignLayout.None;
  lbottom.Margins.Bottom := 0;
  lbottom.Width := Width;
  lbottom.Height := 58;
  lbottom.Position.X := 0;
  lbottom.Position.Y := Height - lbottom.Height - LBottomSafe;
  LyVoltar.Width := 73;
  LyVoltar.Height := lbottom.Height;
  ImgVoltar.Width := 48;
  ImgVoltar.Height := 48;
  ImgVoltar.Position.X := 12;
  ImgVoltar.Position.Y := 5;
  LayoutTabsBottom.Position.X := LyVoltar.Width;
  LayoutTabsBottom.Width := Width - LyVoltar.Width;
  LayoutTabsBottom.Height := lbottom.Height;
  BtnTabDashboard.Width := Min(140, LayoutTabsBottom.Width / 2 - 8);
  BtnTabPedidos.Width := BtnTabDashboard.Width;
  BtnTabDashboard.Height := 50;
  BtnTabPedidos.Height := 50;
  BtnTabDashboard.Position.X := (LayoutTabsBottom.Width / 2) - BtnTabDashboard.Width - 8;
  BtnTabPedidos.Position.X := (LayoutTabsBottom.Width / 2) + 8;
  BtnTabDashboard.Position.Y := 4;
  BtnTabPedidos.Position.Y := 4;
  IconDashboard.Position.X := (BtnTabDashboard.Width - IconDashboard.Width) / 2;
  IconPedidos.Position.X := (BtnTabPedidos.Width - IconPedidos.Width) / 2;
  LbTabDashboard.Width := BtnTabDashboard.Width;
  LbTabPedidos.Width := BtnTabPedidos.Width;
  lbottom.BringToFront;
  LayoutTabsBottom.BringToFront;
  BtnTabDashboardHit.BringToFront;
  BtnTabPedidosHit.BringToFront;
  Tabs.Height := Height - TopBar.Height - lbottom.Height - LBottomSafe;

  ScrollDashboard.Width := Width;
  ScrollDashboard.Height := Tabs.Height;
  ScrollPedidos.Width := Width;
  ScrollPedidos.Height := Tabs.Height;

  LCardW := Width - (LMargin * 2);
  if LIsLandscape then
  begin
    CardRealizado.SetBounds(LMargin, 12, LCardW, 118);
    CardClientes.SetBounds(LMargin, 144, (LCardW - 24) / 3, 96);
    CardPositivacao.SetBounds(CardClientes.Position.X + CardClientes.Width + 12, 144, CardClientes.Width, 96);
    CardDesconto.SetBounds(CardPositivacao.Position.X + CardPositivacao.Width + 12, 144, CardClientes.Width, 96);
    CardTicket.SetBounds(LMargin, 254, (LCardW - 12) / 2, 96);
    CardComissao.SetBounds(CardTicket.Position.X + CardTicket.Width + 12, 254, CardTicket.Width, 96);
    CardMeta.SetBounds(LMargin, 364, LCardW, 130);
    CardResumo.SetBounds(LMargin, 508, LCardW, 104);
  end
  else
  begin
    CardRealizado.SetBounds(LMargin, 12, LCardW, 136);
    CardClientes.SetBounds(LMargin, 162, (LCardW - 12) / 2, 98);
    CardPositivacao.SetBounds(CardClientes.Position.X + CardClientes.Width + 12, 162, CardClientes.Width, 98);
    CardDesconto.SetBounds(LMargin, 274, CardClientes.Width, 98);
    CardTicket.SetBounds(CardDesconto.Position.X + CardDesconto.Width + 12, 274, CardClientes.Width, 98);
    CardComissao.SetBounds(LMargin, 386, LCardW, 98);
    CardMeta.SetBounds(LMargin, 498, LCardW, 142);
    CardResumo.SetBounds(LMargin, 654, LCardW, 128);
  end;

  BarraMetaFundo.Width := CardMeta.Width - 48;
  BarraMetaRealizado.Width := BarraMetaFundo.Width * FPercentualMeta;

  LTop := 12;
  CardBusca.SetBounds(LMargin, LTop, LCardW, 156);
  LbBuscar.SetBounds(18, 14, LCardW - 36, 22);
  EdBuscar.SetBounds(18, 42, LCardW - 36, 34);
  CbStatusPedidos.SetBounds(18, 88, 128, 34);
  EdDiaInicial.SetBounds(158, 88, 76, 34);
  EdDiaFinal.SetBounds(246, 88, 76, 34);
  LTop := LTop + CardBusca.Height + 14;
  CardTotalFaturado.SetBounds(LMargin, LTop, (LCardW - 24) / 3, 96);
  CardDescMedio.SetBounds(CardTotalFaturado.Position.X + CardTotalFaturado.Width + 12, LTop, CardTotalFaturado.Width, 92);
  CardComissaoTotal.SetBounds(CardDescMedio.Position.X + CardDescMedio.Width + 12, LTop, CardTotalFaturado.Width, 92);
  CardDescMedio.Height := CardTotalFaturado.Height;
  CardComissaoTotal.Height := CardTotalFaturado.Height;
  LTop := LTop + CardTotalFaturado.Height + 14;
  CardLista.SetBounds(LMargin, LTop, LCardW, Max(430, ScrollPedidos.Height - LTop - 12));

  LbTotalFaturadoValor.TextSettings.Font.Size := 12;
  LbTotalFaturadoValor.Height := 42;
  LbTotalFaturadoValor.Width := CardTotalFaturado.Width - 16;
  LbDescMedioValor.TextSettings.Font.Size := 17;
  LbComissaoTotalValor.TextSettings.Font.Size := 11.5;
  LbComissaoTotalValor.Height := 42;
  LbComissaoTotalValor.Width := CardComissaoTotal.Width - 16;

  LbListaTitulo.Text := CbStatusPedidos.Text;
  LbListaTitulo.Position.X := 18;
  LbListaTitulo.Position.Y := 14;
  LbListaTitulo.Width := CardLista.Width - 128;
  LbListaTitulo.Height := 26;
  LbListaTitulo.TextSettings.Font.Size := 18;
  LbListaQtd.Width := 86;
  LbListaQtd.Position.X := CardLista.Width - LbListaQtd.Width - 18;
  LbListaQtd.Position.Y := 17;
  LbListaQtd.TextSettings.HorzAlign := TTextAlign.Trailing;

  LvPedidosFaturados.SetBounds(14, 52, CardLista.Width - 28, CardLista.Height - 62);
  if LIsTablet then
    LvPedidosFaturados.ItemAppearance.ItemHeight := 58
  else
    LvPedidosFaturados.ItemAppearance.ItemHeight := 50;
  if LIsTablet then
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 12.5
  else
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 11;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.Width := LvPedidosFaturados.Width - 25;
  if LIsTablet then
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.Height := 18
  else
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.Height := 15;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 1;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Text.WordWrap := False;
  if LIsTablet then
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 11
  else
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 10;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.Width := LvPedidosFaturados.Width - 25;
  if LIsTablet then
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.Height := 36
  else
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.Height := 30;
  if LIsTablet then
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 18
  else
    LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 15;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := False;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Image.Visible := False;
  LvPedidosFaturados.ItemAppearanceObjects.ItemObjects.Accessory.Visible := False;
end;

procedure TfrmDashBoard.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FormHide(Sender);
  if Assigned(dmApp) then
    dmApp.ClearAppState('dashboard');
  Action := TCloseAction.caFree;
  frmDashBoard := nil;
end;

procedure TfrmDashBoard.FormHide(Sender: TObject);
begin
  FFormActive := False;
  Inc(FDashboardLoadSeq);
  Inc(FPedidosLoadSeq);
end;

end.
