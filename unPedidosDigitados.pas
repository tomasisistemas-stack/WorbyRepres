unit unPedidosDigitados;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.DateUtils, System.IOUtils, System.Math, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListBox,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.DialogService, FMX.DialogService.Async,
  Data.DB, FireDAC.Comp.Client
  {$IF Defined(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

type
  TfrmPedidosDigitados = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    LvPedidos: TListView;
    LayoutRodape: TLayout;
    BtnEditar: TRectangle;
    LbBtnEditar: TLabel;
    BtnExcluir: TRectangle;
    LbBtnExcluir: TLabel;
    BtnImprimir: TRectangle;
    LbBtnImprimir: TLabel;
    BtnCompartilhar: TRectangle;
    LbBtnCompartilhar: TLabel;
    Image1: TImage;
    BtnVoltar: TImage;
    procedure FormShow(Sender: TObject);
    procedure BtnBuscarClick(Sender: TObject);
    procedure LvPedidosItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnEditarClick(Sender: TObject);
    procedure BtnExcluirClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnCompartilharClick(Sender: TObject);
  private
    FContentScroll: TVertScrollBox;
    FFilterTimer: TTimer;
    FApplyingLayout: Boolean;
    CbStatusPedidos: TComboBox;
    EdDiaInicial: TEdit;
    EdDiaFinal: TEdit;
    CardTotalPedidos: TRectangle;
    CardDescMedio: TRectangle;
    LbTotalPedidosTitulo: TLabel;
    LbTotalPedidosValor: TLabel;
    LbDescMedioTitulo: TLabel;
    LbDescMedioValor: TLabel;
    FAjustandoDiaFiltro: Boolean;
    FAtualizandoFiltros: Boolean;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FilterTimerTimer(Sender: TObject);
    function JsonFieldAsString(const AJsonText, AField: string): string;
    function JsonFieldAsFloat(const AJsonText, AField: string): Double;
    function BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
    function TotalLiquidoPedido(const APedidoId: Integer): Double;
    function PedidoSelecionadoId: Integer;
    function FornecedorFromApiBaseUrl(const AUrl: string): string;
    function ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
    function BuscarNomeRepresentante(const AId: Integer): string;
    function BuscarNomeFop(const AId: Integer): string;
    function BuscarNomePrazo(const AId: Integer): string;
    function DataFiltroPedido(const AValue: string): TDateTime;
    function DescontoPedido(const AJsonText: string): Double;
    function DiaFiltroInicial: Integer;
    function DiaFiltroFinal: Integer;
    function MesFiltro: string;
    procedure EnsureContentScroll;
    procedure EnsureFiltroCabecalho;
    procedure CarregarMesesAsync;
    procedure AtualizarDiasFiltro;
    procedure FiltrosChange(Sender: TObject);
    procedure NormalizarEditDia(AEdit: TEdit; const ADefault: string);
    procedure AtualizarResumoPedidos(ATotal: Double; ADescSoma: Double; AQtd: Integer);
    procedure EditarPedido(const APedidoId: Integer);
    procedure ImprimirPedido(const APedidoId: Integer);
    procedure CompartilharPedido(const APedidoId: Integer);
    procedure ApplyResponsiveLayout;
    procedure CarregarPedidos;
    procedure ExcluirPedidoDigitado(const APedidoId: Integer);
  protected
    procedure Resize; override;
  public
  end;

var
  frmPedidosDigitados: TfrmPedidosDigitados;

implementation

{$R *.fmx}

uses
  unDMApp, unPedido, unFuncoes, unPrincipal, unAndroidComboFix
{$IFDEF ANDROID}
  , Androidapi.Helpers
  , Androidapi.JNI.JavaTypes
  , Androidapi.JNI.GraphicsContentViewText
  , Androidapi.JNI.Net
  , Androidapi.JNI.Os
  , Androidapi.JNI.Support
  , Androidapi.IOUtils
  , FMX.Helpers.Android
{$ENDIF}
  ;

{$IFDEF ANDROID}
function BuildContentUriForPdf(const AFileName: string): Jnet_Uri;
var
  LFile: JFile;
  LAuthority: JString;
begin
  LFile := TJFile.JavaClass.init(StringToJString(AFileName));

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.fileprovider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
  end;

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.provider'));
  Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
end;
{$ENDIF}

function GetPdfOutputDir: string;
begin
{$IFDEF ANDROID}
  Result := System.IOUtils.TPath.GetDocumentsPath;
{$ELSE}
  Result := ExtractFilePath(ParamStr(0));
{$ENDIF}
end;

function TfrmPedidosDigitados.FornecedorFromApiBaseUrl(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('PLASFAN');
{  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('FILHO DO CRIADOR');}
  Result := LUrl;
end;

function TfrmPedidosDigitados.ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  if ACodCliente <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select consumidor_final from cliente where cod_cliente = :p0';
    Q.ParamByName('p0').AsInteger := ACodCliente;
    Q.Open;
    if not Q.IsEmpty then
      Result := SameText(Trim(Q.Fields[0].AsString), 'S');
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.DataFiltroPedido(const AValue: string): TDateTime;
var
  LText: string;
  LAno: Integer;
  LMes: Integer;
  LDia: Integer;
begin
  LText := Trim(AValue);
  Result := 0;
  if LText = '' then
    Exit;
  if (Length(LText) >= 10) and (LText[5] = '-') and (LText[8] = '-') then
  begin
    LAno := StrToIntDef(Copy(LText, 1, 4), 0);
    LMes := StrToIntDef(Copy(LText, 6, 2), 0);
    LDia := StrToIntDef(Copy(LText, 9, 2), 0);
    if TryEncodeDate(LAno, LMes, LDia, Result) then
      Exit;
  end;
  if TryISO8601ToDate(LText, Result, True) then
    Exit;
  if TryStrToDateTime(LText, Result) then
    Exit;
  if TryStrToDate(Copy(LText, 1, 10), Result) then
    Exit;
  Result := 0;
end;

function TfrmPedidosDigitados.DescontoPedido(const AJsonText: string): Double;
begin
  Result := JsonFieldAsFloat(AJsonText, 'desconto');
  if SameValue(Result, 0) then
    Result := JsonFieldAsFloat(AJsonText, 'desconto_geral');
end;

function TfrmPedidosDigitados.DiaFiltroInicial: Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(EdDiaInicial.Text), 1), 1, 31);
end;

function TfrmPedidosDigitados.DiaFiltroFinal: Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(EdDiaFinal.Text), DayOf(Date)), 1, 31);
end;

function TfrmPedidosDigitados.MesFiltro: string;
begin
  Result := '';
  if Assigned(CbStatusPedidos) and (CbStatusPedidos.ItemIndex >= 0) then
    Result := Trim(CbStatusPedidos.Items[CbStatusPedidos.ItemIndex]);
end;

procedure TfrmPedidosDigitados.NormalizarEditDia(AEdit: TEdit; const ADefault: string);
var
  LText: string;
  LChar: Char;
begin
  if not Assigned(AEdit) then
    Exit;

  LText := '';
  for LChar in AEdit.Text do
    if CharInSet(LChar, ['0'..'9']) then
      LText := LText + LChar;

  if Length(LText) > 2 then
    LText := Copy(LText, 1, 2);

  if LText = '' then
    LText := ADefault;

  if AEdit.Text <> LText then
  begin
    FAjustandoDiaFiltro := True;
    try
      AEdit.Text := LText;
      AEdit.GoToTextEnd;
    finally
      FAjustandoDiaFiltro := False;
    end;
  end;
end;

procedure TfrmPedidosDigitados.FiltrosChange(Sender: TObject);
begin
  if FAjustandoDiaFiltro or FAtualizandoFiltros then
    Exit;

  if Sender = CbStatusPedidos then
    AtualizarDiasFiltro;

  if Sender = EdDiaInicial then
    NormalizarEditDia(EdDiaInicial, '01')
  else if Sender = EdDiaFinal then
    NormalizarEditDia(EdDiaFinal, '31');

  if not Assigned(FFilterTimer) then
  begin
    FFilterTimer := TTimer.Create(Self);
    FFilterTimer.Enabled := False;
    FFilterTimer.Interval := 450;
    FFilterTimer.OnTimer := FilterTimerTimer;
  end;
  FFilterTimer.Enabled := False;
  FFilterTimer.Enabled := True;
end;

procedure TfrmPedidosDigitados.FilterTimerTimer(Sender: TObject);
begin
  if Assigned(FFilterTimer) then
    FFilterTimer.Enabled := False;
  CarregarPedidos;
end;

procedure TfrmPedidosDigitados.EnsureContentScroll;
begin
  if Assigned(FContentScroll) then
    Exit;

  FContentScroll := TVertScrollBox.Create(Self);
  FContentScroll.Parent := LayoutRoot;
  FContentScroll.Align := TAlignLayout.None;
  FContentScroll.TabOrder := 0;

  CardBusca.Parent := FContentScroll;
  LvPedidos.Parent := FContentScroll;
  LayoutRodape.Parent := FContentScroll;
  TopBar.BringToFront;
end;
procedure TfrmPedidosDigitados.EnsureFiltroCabecalho;
var
  LMesAtual: string;
  LMesIndex: Integer;

  procedure SetupCard(ACard: TRectangle);
  begin
    if Assigned(FContentScroll) then
      ACard.Parent := FContentScroll
    else
      ACard.Parent := LayoutRoot;
    ACard.Fill.Color := TAlphaColorRec.White;
    ACard.Stroke.Kind := TBrushKind.None;
    ACard.XRadius := 12;
    ACard.YRadius := 12;
  end;

  procedure SetupLabel(ALabel: TLabel; AParent: TFmxObject; const AText: string; AFontSize: Single;
    AColor: TAlphaColor; ABold: Boolean);
  begin
    ALabel.Parent := AParent;
    ALabel.StyledSettings := [];
    ALabel.Text := AText;
    ALabel.TextSettings.Font.Size := AFontSize;
    ALabel.TextSettings.FontColor := AColor;
    if ABold then
      ALabel.TextSettings.Font.Style := [TFontStyle.fsBold]
    else
      ALabel.TextSettings.Font.Style := [];
  end;

begin
  if Assigned(CbStatusPedidos) then
    Exit;

  CbStatusPedidos := TComboBox.Create(Self);
  CbStatusPedidos.Parent := CardBusca;
  UseAndroidSafeComboPicker([CbStatusPedidos]);
  LMesAtual := FormatDateTime('mm/yyyy', Date);
  if CbStatusPedidos.Items.IndexOf(LMesAtual) < 0 then
    CbStatusPedidos.Items.Add(LMesAtual);

  if CbStatusPedidos.Items.Count = 0 then
    CbStatusPedidos.Items.Add(LMesAtual);
  LMesIndex := CbStatusPedidos.Items.IndexOf(LMesAtual);
  if LMesIndex < 0 then
  begin
    CbStatusPedidos.Items.Insert(0, LMesAtual);
    LMesIndex := 0;
  end;
  CbStatusPedidos.ItemIndex := LMesIndex;
  CbStatusPedidos.OnChange := FiltrosChange;

  EdDiaInicial := TEdit.Create(Self);
  EdDiaInicial.Parent := CardBusca;
  EdDiaInicial.FilterChar := '0123456789';
  EdDiaInicial.MaxLength := 2;
  EdDiaInicial.KeyboardType := TVirtualKeyboardType.PhonePad;
  EdDiaInicial.ReturnKeyType := TReturnKeyType.Done;
  EdDiaInicial.Text := '01';
  EdDiaInicial.OnChange := FiltrosChange;

  EdDiaFinal := TEdit.Create(Self);
  EdDiaFinal.Parent := CardBusca;
  EdDiaFinal.FilterChar := '0123456789';
  EdDiaFinal.MaxLength := 2;
  EdDiaFinal.KeyboardType := TVirtualKeyboardType.PhonePad;
  EdDiaFinal.ReturnKeyType := TReturnKeyType.Done;
  EdDiaFinal.Text := Format('%.2d', [DaysInAMonth(YearOf(Date), MonthOf(Date))]);
  EdDiaFinal.OnChange := FiltrosChange;

  EdBuscar.TextPrompt := 'Nome do cliente ou pedido';
  EdBuscar.OnChange := FiltrosChange;

  CardTotalPedidos := TRectangle.Create(Self);
  SetupCard(CardTotalPedidos);
  CardDescMedio := TRectangle.Create(Self);
  SetupCard(CardDescMedio);

  LbTotalPedidosTitulo := TLabel.Create(Self);
  SetupLabel(LbTotalPedidosTitulo, CardTotalPedidos, 'Total digitado', 12, $FF5D6B85, False);
  LbTotalPedidosValor := TLabel.Create(Self);
  SetupLabel(LbTotalPedidosValor, CardTotalPedidos, 'R$0,00', 14, TAlphaColorRec.Black, True);

  LbDescMedioTitulo := TLabel.Create(Self);
  SetupLabel(LbDescMedioTitulo, CardDescMedio, 'Desc. medio', 12, $FF5D6B85, False);
  LbDescMedioValor := TLabel.Create(Self);
  SetupLabel(LbDescMedioValor, CardDescMedio, '0,00%', 18, TAlphaColorRec.Black, True);
end;

procedure TfrmPedidosDigitados.AtualizarDiasFiltro;
var
  LMes: string;
  LAno: Integer;
  LMesNum: Integer;
  LDias: Integer;
begin
  if not Assigned(EdDiaInicial) or not Assigned(EdDiaFinal) then
    Exit;

  LMes := MesFiltro;
  LAno := StrToIntDef(Copy(LMes, 4, 4), YearOf(Date));
  LMesNum := StrToIntDef(Copy(LMes, 1, 2), MonthOf(Date));
  if not InRange(LMesNum, 1, 12) then
    LMesNum := MonthOf(Date);
  if LAno <= 0 then
    LAno := YearOf(Date);

  LDias := DaysInAMonth(LAno, LMesNum);
  FAtualizandoFiltros := True;
  try
    if Trim(EdDiaInicial.Text) = '' then
      EdDiaInicial.Text := '01';
    if (Trim(EdDiaFinal.Text) = '') or (StrToIntDef(Trim(EdDiaFinal.Text), 0) > LDias) then
      EdDiaFinal.Text := Format('%.2d', [LDias]);
  finally
    FAtualizandoFiltros := False;
  end;
end;

procedure TfrmPedidosDigitados.CarregarMesesAsync;
var
  Q: TFDQuery;
  LMeses: TStringList;
  LMes: string;
  LMesSelecionado: string;
  LIndex: Integer;
  LDt: TDateTime;
  I: Integer;
begin
  EnsureFiltroCabecalho;
  if not Assigned(CbStatusPedidos) then
    Exit;

  LMesSelecionado := Trim(CbStatusPedidos.Text);
  if LMesSelecionado = '' then
    LMesSelecionado := FormatDateTime('mm/yyyy', Date);

  LMeses := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    for I := -6 to 6 do
      LMeses.Add(FormatDateTime('mm/yyyy', IncMonth(Date, I)));

    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select created_at as dt_ref ' +
      'from outbound_pedido ' +
      'where status in (''PENDENTE'', ''ERRO'') ' +
      '  and coalesce(created_at, '''') <> '''' ' +
      'order by created_at desc';
    Q.Open;
    while not Q.Eof do
    begin
      LDt := DataFiltroPedido(Q.FieldByName('dt_ref').AsString);
      if LDt > 0 then
      begin
        LMes := FormatDateTime('mm/yyyy', LDt);
        if LMeses.IndexOf(LMes) < 0 then
          LMeses.Add(LMes);
      end;
      Q.Next;
    end;

    FAtualizandoFiltros := True;
    try
      CbStatusPedidos.Items.Clear;
      for LMes in LMeses do
        CbStatusPedidos.Items.Add(LMes);

      LIndex := CbStatusPedidos.Items.IndexOf(LMesSelecionado);
      if LIndex < 0 then
        LIndex := 0;
      CbStatusPedidos.ItemIndex := LIndex;
      AtualizarDiasFiltro;
    finally
      FAtualizandoFiltros := False;
    end;
  finally
    Q.Free;
    LMeses.Free;
  end;
end;
procedure TfrmPedidosDigitados.AtualizarResumoPedidos(ATotal: Double; ADescSoma: Double; AQtd: Integer);
var
  LFS: TFormatSettings;
begin
  LFS := TFormatSettings.Create('pt-BR');
  LbTotalPedidosValor.Text := 'R$' + FormatFloat('#,##0.00', ATotal, LFS);
  if AQtd > 0 then
    LbDescMedioValor.Text := FormatFloat('0.00', ADescSoma / AQtd, LFS) + '%'
  else
    LbDescMedioValor.Text := '0,00%';
end;

procedure TfrmPedidosDigitados.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LBottom: Single;
  LRightSafe: Single;
  LFooterH: Single;
  LScrollTop: Single;
  LScrollW: Single;
  LScrollH: Single;
  LContentW: Single;
  LX: Single;
  LSummaryGap: Single;
  LBtnW: Single;
  LBtnH: Single;
  LBtnGap: Single;
  LListTop: Single;
  LListH: Single;
  LFooterTop: Single;
begin
  if FApplyingLayout then
    Exit;
  if not Assigned(LayoutRodape) then
    Exit;

  FApplyingLayout := True;
  try
    EnsureContentScroll;
    EnsureFiltroCabecalho;

    if CardBusca.Parent <> FContentScroll then
      CardBusca.Parent := FContentScroll;
    if Assigned(CardTotalPedidos) and (CardTotalPedidos.Parent <> FContentScroll) then
      CardTotalPedidos.Parent := FContentScroll;
    if Assigned(CardDescMedio) and (CardDescMedio.Parent <> FContentScroll) then
      CardDescMedio.Parent := FContentScroll;
    if LvPedidos.Parent <> FContentScroll then
      LvPedidos.Parent := FContentScroll;
    if LayoutRodape.Parent <> FContentScroll then
      LayoutRodape.Parent := FContentScroll;

    LIsLandscape := ClientWidth > ClientHeight;
    if LIsLandscape then
    begin
      TopBar.Height := 72;
      LFooterH := 58;
      LBottom := 8;
      LRightSafe := Max(0, AndroidNavigationInset(True) + 8);
    end
    else
    begin
      TopBar.Height := 96;
      LFooterH := 72;
      LBottom := 50;
      LRightSafe := 0;
    end;

    TopBar.Align := TAlignLayout.None;
    TopBar.SetBounds(0, 0, ClientWidth, TopBar.Height);
    LbTitulo.Position.X := 18;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) / 2;
    LbTitulo.Width := ClientWidth - 36;

    LScrollTop := TopBar.Height;
    LScrollW := Max(1, ClientWidth - LRightSafe);
    LScrollH := Max(160, ClientHeight - LScrollTop - LBottom);
    FContentScroll.Align := TAlignLayout.None;
    FContentScroll.SetBounds(0, LScrollTop, LScrollW, LScrollH);

    if LIsLandscape then
      LContentW := Min(LScrollW - 24, 1040)
    else if Min(ClientWidth, ClientHeight) >= 600 then
      LContentW := Min(LScrollW - 28, 760)
    else
      LContentW := Min(LScrollW - 20, 620);
    if LContentW < 300 then
      LContentW := Max(260, LScrollW - 20);
    LX := Max(10, (LScrollW - LContentW) / 2);

    CardBusca.Align := TAlignLayout.None;
    Image1.Visible := False;

    if LIsLandscape and (LContentW >= 700) then
    begin
      LSummaryGap := 12;
      CardBusca.SetBounds(LX, 10, LContentW - 250 - LSummaryGap, 118);
      LbBuscar.SetBounds(18, 8, CardBusca.Width - 36, 20);
      EdBuscar.SetBounds(18, 32, CardBusca.Width - 36, 34);
      CbStatusPedidos.SetBounds(18, 74, 128, 32);
      EdDiaInicial.SetBounds(CbStatusPedidos.Position.X + CbStatusPedidos.Width + 12, 74, 58, 32);
      EdDiaFinal.SetBounds(EdDiaInicial.Position.X + EdDiaInicial.Width + 12, 74, 58, 32);

      CardTotalPedidos.SetBounds(CardBusca.Position.X + CardBusca.Width + LSummaryGap, 10, 250, 54);
      CardDescMedio.SetBounds(CardTotalPedidos.Position.X, CardTotalPedidos.Position.Y + CardTotalPedidos.Height + 10, 250, 54);
      LbTotalPedidosTitulo.SetBounds(10, 7, CardTotalPedidos.Width - 20, 18);
      LbTotalPedidosValor.SetBounds(10, 27, CardTotalPedidos.Width - 20, 22);
      LbDescMedioTitulo.SetBounds(10, 7, CardDescMedio.Width - 20, 18);
      LbDescMedioValor.SetBounds(10, 25, CardDescMedio.Width - 20, 24);

      LListTop := CardBusca.Position.Y + CardBusca.Height + 10;
    end
    else
    begin
      CardBusca.SetBounds(LX, 10, LContentW, 130);
      LbBuscar.SetBounds(18, 8, CardBusca.Width - 36, 20);
      EdBuscar.SetBounds(18, 34, CardBusca.Width - 36, 36);
      CbStatusPedidos.SetBounds(18, 78, 128, 34);
      EdDiaInicial.SetBounds(CbStatusPedidos.Position.X + CbStatusPedidos.Width + 12, 78, 58, 34);
      EdDiaFinal.SetBounds(EdDiaInicial.Position.X + EdDiaInicial.Width + 12, 78, 58, 34);

      LSummaryGap := 12;
      CardTotalPedidos.SetBounds(LX, CardBusca.Position.Y + CardBusca.Height + 10, (LContentW - LSummaryGap) / 2, 78);
      CardDescMedio.SetBounds(CardTotalPedidos.Position.X + CardTotalPedidos.Width + LSummaryGap, CardTotalPedidos.Position.Y, CardTotalPedidos.Width, 78);
      LbTotalPedidosTitulo.SetBounds(10, 10, CardTotalPedidos.Width - 20, 20);
      LbTotalPedidosValor.SetBounds(10, 38, CardTotalPedidos.Width - 20, 26);
      LbDescMedioTitulo.SetBounds(10, 10, CardDescMedio.Width - 20, 20);
      LbDescMedioValor.SetBounds(10, 36, CardDescMedio.Width - 20, 30);

      LListTop := CardTotalPedidos.Position.Y + CardTotalPedidos.Height + 10;
    end;

    LvPedidos.Align := TAlignLayout.None;
    if LIsLandscape then
      LListH := Max(170, FContentScroll.Height - LListTop - LFooterH - 24)
    else
      LListH := Max(220, FContentScroll.Height - LListTop - LFooterH - 24);
    LvPedidos.SetBounds(LX, LListTop, LContentW, LListH);
    if LIsLandscape then
      LvPedidos.ItemAppearance.ItemHeight := 68
    else if Min(ClientWidth, ClientHeight) >= 600 then
      LvPedidos.ItemAppearance.ItemHeight := 64
    else
      LvPedidos.ItemAppearance.ItemHeight := 56;
    LvPedidos.ItemAppearanceObjects.ItemObjects.Text.Width := LContentW - 36;
    LvPedidos.ItemAppearanceObjects.ItemObjects.Detail.Width := LContentW - 36;

    LFooterTop := LvPedidos.Position.Y + LvPedidos.Height + 8;
    LayoutRodape.Align := TAlignLayout.None;
    LayoutRodape.Margins.Bottom := 0;
    LayoutRodape.SetBounds(LX, LFooterTop, LContentW, LFooterH);

    BtnEditar.Align := TAlignLayout.None;
    BtnExcluir.Align := TAlignLayout.None;
    BtnImprimir.Align := TAlignLayout.None;
    BtnCompartilhar.Align := TAlignLayout.None;
    BtnEditar.Visible := True;
    BtnExcluir.Visible := True;
    BtnImprimir.Visible := True;
    BtnCompartilhar.Visible := True;
    LBtnGap := 8;
    LBtnH := Min(42, LayoutRodape.Height - 10);
    if LIsLandscape then
      LBtnW := Max(82, Min(108, (LayoutRodape.Width - 72 - (LBtnGap * 4)) / 4))
    else if Min(ClientWidth, ClientHeight) >= 600 then
      LBtnW := 86
    else
      LBtnW := 64;
    BtnEditar.SetBounds(LayoutRodape.Width - LBtnW - 6, (LayoutRodape.Height - LBtnH) / 2, LBtnW, LBtnH);
    BtnExcluir.SetBounds(BtnEditar.Position.X - LBtnW - LBtnGap, BtnEditar.Position.Y, LBtnW, LBtnH);
    BtnImprimir.SetBounds(BtnExcluir.Position.X - LBtnW - LBtnGap, BtnEditar.Position.Y, LBtnW, LBtnH);
    BtnCompartilhar.SetBounds(BtnImprimir.Position.X - LBtnW - LBtnGap, BtnEditar.Position.Y, LBtnW, LBtnH);
    BtnVoltar.Align := TAlignLayout.None;
    BtnVoltar.SetBounds(0, (LayoutRodape.Height - 50) / 2, 50, 50);

    CardTotalPedidos.Visible := True;
    CardDescMedio.Visible := True;
    CardBusca.BringToFront;
    CardTotalPedidos.BringToFront;
    CardDescMedio.BringToFront;
    LvPedidos.BringToFront;
    LayoutRodape.BringToFront;
    TopBar.BringToFront;
  finally
    FApplyingLayout := False;
  end;
end;
procedure TfrmPedidosDigitados.Resize;
begin
  inherited;
  if not FApplyingLayout then
    ApplyResponsiveLayout;
end;

function TfrmPedidosDigitados.JsonFieldAsString(const AJsonText, AField: string): string;
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  Result := '';
  if Trim(AJsonText) = '' then
    Exit;

  LJson := TJSONObject.ParseJSONValue(AJsonText);
  try
    if LJson is TJSONObject then
    begin
      LObj := TJSONObject(LJson);
      LVal := LObj.GetValue(AField);
      if Assigned(LVal) then
        Result := LVal.Value;
    end;
  finally
    LJson.Free;
  end;
end;

function TfrmPedidosDigitados.JsonFieldAsFloat(const AJsonText, AField: string): Double;
var
  S: string;
begin
  S := JsonFieldAsString(AJsonText, AField);
  S := StringReplace(S, '.', ',', [rfReplaceAll]);
  Result := StrToFloatDef(S, 0);
end;

function TfrmPedidosDigitados.BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if ACodCliente <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_cliente from cliente where cod_cliente = :p0';
    Q.ParamByName('p0').AsInteger := ACodCliente;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.TotalLiquidoPedido(const APedidoId: Integer): Double;
var
  Q: TFDQuery;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.Open;
    while not Q.Eof do
    begin
      LJson := TJSONObject.ParseJSONValue(Q.FieldByName('vendas2_json').AsString);
      try
        if LJson is TJSONObject then
        begin
          LObj := TJSONObject(LJson);
          LVal := LObj.GetValue('total_item');
          if Assigned(LVal) then
            Result := Result + StrToFloatDef(StringReplace(LVal.Value, '.', ',', [rfReplaceAll]), 0);
        end;
      finally
        LJson.Free;
      end;
      Q.Next;
    end;
  finally
    Q.Free;
  end;

  if LvPedidos.Items.Count > 0 then
    LvPedidos.ItemIndex := 0
  else
    LvPedidos.ItemIndex := -1;
end;

procedure TfrmPedidosDigitados.CarregarPedidos;
var
  Q: TFDQuery;
  QItens: TFDQuery;
  LTotais: TDictionary<Integer, Double>;
  LItem: TListViewItem;
  LBusca: string;
  LNomeCliente: string;
  LData: string;
  LTotal: Double;
  LDesc: Double;
  LDescSoma: Double;
  LTotalGeral: Double;
  LDt: TDateTime;
  LFS: TFormatSettings;
  LDiaIni: Integer;
  LDiaFim: Integer;
  LMes: string;
  LQtd: Integer;
  LPedidoId: Integer;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LVal: TJSONValue;
begin
  EnsureFiltroCabecalho;
  LFS := TFormatSettings.Create('pt-BR');
  LBusca := LowerCase(Trim(EdBuscar.Text));
  LDiaIni := DiaFiltroInicial;
  LDiaFim := DiaFiltroFinal;
  LMes := MesFiltro;
  LTotalGeral := 0;
  LDescSoma := 0;
  LQtd := 0;
  LvPedidos.Items.Clear;

  LTotais := TDictionary<Integer, Double>.Create;
  try
    QItens := TFDQuery.Create(nil);
    try
      QItens.Connection := dmApp.FDConnection;
      QItens.SQL.Text :=
        'select i.pedido_id, i.vendas2_json ' +
        'from outbound_pedido_item i ' +
        'join outbound_pedido p on p.id = i.pedido_id ' +
        'where p.status in (''PENDENTE'', ''ERRO'')';
      QItens.Open;
      while not QItens.Eof do
      begin
        LPedidoId := QItens.FieldByName('pedido_id').AsInteger;
        if not LTotais.TryGetValue(LPedidoId, LTotal) then
          LTotal := 0;

        LJson := TJSONObject.ParseJSONValue(QItens.FieldByName('vendas2_json').AsString);
        try
          if LJson is TJSONObject then
          begin
            LObj := TJSONObject(LJson);
            LVal := LObj.GetValue('total_item');
            if Assigned(LVal) then
              LTotal := LTotal + StrToFloatDef(StringReplace(LVal.Value, '.', ',', [rfReplaceAll]), 0);
          end;
        finally
          LJson.Free;
        end;

        LTotais.AddOrSetValue(LPedidoId, LTotal);
        QItens.Next;
      end;
    finally
      QItens.Free;
    end;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmApp.FDConnection;
      Q.SQL.Text :=
        'select id, vendas1_json, created_at, status ' +
        'from outbound_pedido ' +
        'where status in (''PENDENTE'', ''ERRO'') ' +
        'order by id desc';
      Q.Open;
      while not Q.Eof do
      begin
        LPedidoId := Q.FieldByName('id').AsInteger;
        LNomeCliente := JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'nom_cliente');
        LData := Q.FieldByName('created_at').AsString;
        LDt := DataFiltroPedido(LData);

        if (LDt > 0) and
           ((LMes = '') or SameText(FormatDateTime('mm/yyyy', LDt), LMes)) and
           ((DayOf(LDt) >= LDiaIni) and (DayOf(LDt) <= LDiaFim)) and
           ((LBusca = '') or (Pos(LBusca, LowerCase(LNomeCliente)) > 0) or (Pos(LBusca, Q.FieldByName('id').AsString) > 0)) then
        begin
          if LDt > 0 then
            LData := FormatDateTime('dd/mm/yyyy', LDt);

          if not LTotais.TryGetValue(LPedidoId, LTotal) then
            LTotal := 0;
          LDesc := DescontoPedido(Q.FieldByName('vendas1_json').AsString);
          LTotalGeral := LTotalGeral + LTotal;
          LDescSoma := LDescSoma + LDesc;
          Inc(LQtd);

          LItem := LvPedidos.Items.Add;
          LItem.Tag := LPedidoId;
          LItem.Text := Format('Pedido %d - %s', [LPedidoId, LNomeCliente]);
          LItem.Detail := Format('%s  R$ %s  Desc %.2f%%',
            [LData, FormatFloat('#,###,##0.00', LTotal, LFS), LDesc]);
        end;
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    LTotais.Free;
  end;
  AtualizarResumoPedidos(LTotalGeral, LDescSoma, LQtd);
end;

procedure TfrmPedidosDigitados.ExcluirPedidoDigitado(const APedidoId: Integer);
var
  Q: TFDQuery;
begin
  if APedidoId <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'delete from outbound_pedido_item where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.ExecSQL;

    Q.SQL.Text := 'delete from outbound_pedido where id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.PedidoSelecionadoId: Integer;
begin
  Result := 0;
  if (LvPedidos.ItemIndex >= 0) and (LvPedidos.ItemIndex < LvPedidos.Items.Count) then
    Result := LvPedidos.Items[LvPedidos.ItemIndex].Tag;
end;

function TfrmPedidosDigitados.BuscarNomeRepresentante(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_representante from representante where id = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.BuscarNomeFop(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select nom_fop from fop where cod_fop = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

function TfrmPedidosDigitados.BuscarNomePrazo(const AId: Integer): string;
var
  Q: TFDQuery;
begin
  Result := '';
  if AId <= 0 then Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select prazo from prazo where id = :p0';
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.Fields[0].AsString);
  finally
    Q.Free;
  end;
end;

procedure TfrmPedidosDigitados.EditarPedido(const APedidoId: Integer);
begin
  if APedidoId <= 0 then
    Exit;

  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);

  frmPedido.CarregarPedidoDigitado(APedidoId);
  frmPedido.Show;
  Close;
end;

procedure TfrmPedidosDigitados.ImprimirPedido(const APedidoId: Integer);
var
  QPedido, QItens: TFDQuery;
  LVenda1, LVenda2: string;
  LRep, LCli, LData, LHora, LFop, LPrazo, LDtRef: string;
  LTot: Double;
  LFS: TFormatSettings;
  LPdfFile: string;
  LDt: TDateTime;
  LConteudo: TStringList;
  LRepId, LFopId, LPrazoId, LCodCliente: Integer;
  LFornecedor: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
  function PadRight(const S: string; const AWidth: Integer): string;
  begin
    Result := Copy(S + StringOfChar(' ', AWidth), 1, AWidth);
  end;
  function PadLeft(const S: string; const AWidth: Integer): string;
  begin
    if Length(S) >= AWidth then
      Result := Copy(S, 1, AWidth)
    else
      Result := StringOfChar(' ', AWidth - Length(S)) + S;
  end;
  function EscPDF(const S: string): string;
  begin
    Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
    Result := StringReplace(Result, '(', '\(', [rfReplaceAll]);
    Result := StringReplace(Result, ')', '\)', [rfReplaceAll]);
  end;
  procedure SaveTextAsPdf(const AFileName: string; ALines: TStrings);
  var
    I, Y: Integer;
    LStream: TStringList;
    LContent: string;
    LContentLen: Integer;
    LOffsets: array[1..5] of Integer;
    procedure AddRaw(const S: string);
    begin
      LStream.Add(S);
    end;
    function StreamPos: Integer;
    var
      J: Integer;
    begin
      Result := 0;
      for J := 0 to LStream.Count - 1 do
        Inc(Result, Length(AnsiString(LStream[J])) + 2);
    end;
  begin
    LStream := TStringList.Create;
    try
      LContent := 'BT /F1 10 Tf' + sLineBreak;
      Y := 810;
      for I := 0 to ALines.Count - 1 do
      begin
        LContent := LContent + Format('1 0 0 1 20 %d Tm (%s) Tj', [Y, EscPDF(ALines[I])]) + sLineBreak;
        Dec(Y, 12);
        if Y < 20 then Break;
      end;
      LContent := LContent + 'ET' + sLineBreak;
      LContentLen := Length(AnsiString(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll])));

      AddRaw('%PDF-1.4');
      LOffsets[1] := StreamPos; AddRaw('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj');
      LOffsets[2] := StreamPos; AddRaw('2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj');
      LOffsets[3] := StreamPos; AddRaw('3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>endobj');
      LOffsets[4] := StreamPos;
      AddRaw(Format('4 0 obj<< /Length %d >>stream', [LContentLen]));
      AddRaw(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll]));
      AddRaw('endstream endobj');
      LOffsets[5] := StreamPos; AddRaw('5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>endobj');
      AddRaw('xref');
      AddRaw('0 6');
      AddRaw('0000000000 65535 f ');
      for I := 1 to 5 do
        AddRaw(Format('%.10d 00000 n ', [LOffsets[I]]));
      AddRaw('trailer<< /Size 6 /Root 1 0 R >>');
      AddRaw(Format('startxref%s%d', [sLineBreak, StreamPos]));
      AddRaw('%%EOF');
      LStream.SaveToFile(AFileName, TEncoding.ASCII);
    finally
      LStream.Free;
    end;
  end;
begin
  LFS := TFormatSettings.Create('pt-BR');
  QPedido := TFDQuery.Create(nil);
  QItens := TFDQuery.Create(nil);
  LConteudo := TStringList.Create;
  try
    QPedido.Connection := dmApp.FDConnection;
    QPedido.SQL.Text := 'select representative_code, vendas1_json, coalesce(sent_at, created_at) dt_ref, numdoc_remote from outbound_pedido where id = :p0';
    QPedido.ParamByName('p0').AsInteger := APedidoId;
    QPedido.Open;
    if QPedido.IsEmpty then Exit;

    LVenda1 := QPedido.FieldByName('vendas1_json').AsString;
    LCodCliente := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_cliente'), 0);
    LCli := JsonFieldAsString(LVenda1, 'nom_cliente');
    if LCli = '' then
      LCli := BuscarNomeClientePorCodigo(LCodCliente);

    LRepId := StrToIntDef(Trim(QPedido.FieldByName('representative_code').AsString), 0);
    LRep := BuscarNomeRepresentante(LRepId);
    if LRep = '' then
      LRep := frmPrincipal.FRepNome;

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    LFop := BuscarNomeFop(LFopId);
    LPrazo := BuscarNomePrazo(LPrazoId);

    LDtRef := Trim(QPedido.FieldByName('dt_ref').AsString);
    if TryISO8601ToDate(StringReplace(LDtRef, ' ', 'T', []), LDt, True) or TryISO8601ToDate(LDtRef, LDt, True) then
    begin
      LData := FormatDateTime('dd/mm/yyyy', LDt);
      LHora := FormatDateTime('hh:nn', LDt);
    end
    else
    begin
      LData := LDtRef;
      LHora := '';
    end;

    QItens.Connection := dmApp.FDConnection;
    QItens.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0 order by item_ord';
    QItens.ParamByName('p0').AsInteger := APedidoId;
    QItens.Open;

    LTot := 0;
    LFornecedor := FornecedorFromApiBaseUrl(dmApp.ApiBaseUrl);
    if LFornecedor = '' then
      LFornecedor := 'PLASFAN';
    if SameText(LFornecedor, 'PLASFAN') and ClienteConsumidorFinal(LCodCliente) then
      LFornecedor := 'MP';

    LConteudo.Add('FORNECEDOR....: ' + LFornecedor);
    if LRepId > 0 then
      LConteudo.Add('REPRESENTANTE.: ' + LRep + ' (COD.' + IntToStr(LRepId) + ')')
    else
      LConteudo.Add('REPRESENTANTE.: ' + LRep);
    LConteudo.Add('CLIENTE.......: ' + IntToStr(LCodCliente) + ' - ' + LCli);
    LConteudo.Add('DATA..........: ' + LData + ' ' + LHora);
    LConteudo.Add('');
    LConteudo.Add(PadRight('CODIGO', 10) + PadRight('DESCRICAO', 45) + PadRight('UND', 6) + PadLeft('QTDE', 8) + PadLeft('PRECO', 12) + PadLeft('TOTAL', 12));
    LConteudo.Add(StringOfChar('-', 95));
    while not QItens.Eof do
    begin
      LVenda2 := QItens.FieldByName('vendas2_json').AsString;
      LConteudo.Add(
        PadRight(JsonFieldAsString(LVenda2, 'cod_produto'), 10) +
        PadRight(Copy(JsonFieldAsString(LVenda2, 'nom_produto'), 1, 45), 45) +
        PadRight(JsonFieldAsString(LVenda2, 'unidade'), 6) +
        PadLeft(FormatFloat('#,##0.###', JsonFieldAsFloat(LVenda2, 'qtd'), LFS), 8) +
        PadLeft(FormatFloat('#,##0.00', JsonFieldAsFloat(LVenda2, 'preco'), LFS), 12) +
        PadLeft(FormatFloat('#,##0.00', JsonFieldAsFloat(LVenda2, 'total_item'), LFS), 12)
      );
      LTot := LTot + JsonFieldAsFloat(LVenda2, 'total_item');
      QItens.Next;
    end;

    LConteudo.Add(StringOfChar('-', 95));
    LConteudo.Add(PadRight('CONDICAO DE PAGTO.: ' + LFop + ' - ' + LPrazo, 68) + PadLeft('TOTAL: ' + FormatFloat('#,###,##0.00', LTot, LFS), 25));


    LPdfFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + Format('pedido_digitado_%d.pdf', [APedidoId]);
    SaveTextAsPdf(LPdfFile, LConteudo);
{$IFDEF MSWINDOWS}
    ShellExecute(0, 'open', PChar(LPdfFile), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
{$IFDEF ANDROID}
    LUri := BuildContentUriForPdf(LPdfFile);
    LIntent := TJIntent.Create;
    LIntent.setAction(TJIntent.JavaClass.ACTION_VIEW);
    LIntent.setDataAndType(LUri, StringToJString('application/pdf'));
    LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
    LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
    TAndroidHelper.Activity.startActivity(LIntent);
{$ENDIF}
  finally
    LConteudo.Free;
    QItens.Free;
    QPedido.Free;
  end;
end;

procedure TfrmPedidosDigitados.CompartilharPedido(const APedidoId: Integer);
var
  LPdfFile: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
begin
  if APedidoId <= 0 then
    Exit;

  ImprimirPedido(APedidoId);
  LPdfFile := IncludeTrailingPathDelimiter(GetPdfOutputDir) + Format('pedido_digitado_%d.pdf', [APedidoId]);
{$IFDEF ANDROID}
  LUri := BuildContentUriForPdf(LPdfFile);
  LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_SEND);
  LIntent.setType(StringToJString('application/pdf'));
  LIntent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(LUri));
  LIntent.addFlags(TJIntent.JavaClass.FLAG_ACTIVITY_NEW_TASK);
  LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(TJIntent.JavaClass.createChooser(LIntent, StrToJCharSequence('Compartilhar PDF')));
{$ENDIF}
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(LPdfFile), nil, nil, SW_SHOWNORMAL);
{$ENDIF}
end;

procedure TfrmPedidosDigitados.FormShow(Sender: TObject);
begin
  OnClose := FormClose;
  ApplyResponsiveLayout;
  EnsureFiltroCabecalho;
  AtualizarDiasFiltro;
  CarregarMesesAsync;
  CarregarPedidos;
end;

procedure TfrmPedidosDigitados.BtnBuscarClick(Sender: TObject);
begin
  CarregarPedidos;
end;


procedure TfrmPedidosDigitados.LvPedidosItemClick(const Sender: TObject; const AItem: TListViewItem);
begin
  // Apenas seleciona o item; ações ficam nos botões Editar/Excluir.
end;

procedure TfrmPedidosDigitados.BtnEditarClick(Sender: TObject);
begin
  EditarPedido(PedidoSelecionadoId);
end;

procedure TfrmPedidosDigitados.BtnExcluirClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para excluir.');
    Exit;
  end;

  TDialogServiceAsync.MessageDialog(
    'Deseja excluir este pedido digitado?',
    System.UITypes.TMsgDlgType.mtConfirmation,
    [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
    System.UITypes.TMsgDlgBtn.mbNo,
    0,
    procedure(const AResult: System.UITypes.TModalResult)
    begin
      if AResult <> mrYes then
        Exit;

      ExcluirPedidoDigitado(LPedidoId);
      CarregarPedidos;
    end
  );
end;

procedure TfrmPedidosDigitados.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidosDigitados.BtnImprimirClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para imprimir.');
    Exit;
  end;
  ImprimirPedido(LPedidoId);
end;

procedure TfrmPedidosDigitados.BtnCompartilharClick(Sender: TObject);
var
  LPedidoId: Integer;
begin
  LPedidoId := PedidoSelecionadoId;
  if LPedidoId <= 0 then
  begin
    ShowMessage('Selecione um pedido para compartilhar.');
    Exit;
  end;
  CompartilharPedido(LPedidoId);
end;

procedure TfrmPedidosDigitados.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmPedidosDigitados := nil;
end;

end.
