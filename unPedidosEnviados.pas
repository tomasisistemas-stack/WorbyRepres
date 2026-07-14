unit unPedidosEnviados;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON, System.DateUtils, System.IOUtils, System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListBox,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet
  {$IF Defined(MSWINDOWS)}
  , Winapi.Windows, Winapi.ShellAPI
  {$ENDIF}
  ;

type
  TfrmPedidosEnviados = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    LayoutRodape: TLayout;
    LbTitulo: TLabel;
    BtnVoltar: TImage;
    BtnCompartilhar: TRectangle;
    LbBtnCompartilhar: TLabel;
    BtnImprimir: TRectangle;
    LbBtnImprimir: TLabel;
    BtnBuscar: TImage;
    LyListView: TLayout;
    LvPedidos: TListView;
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
    procedure BtnImprimirClick(Sender: TObject);
    procedure BtnCompartilharClick(Sender: TObject);
  private
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
    FFilterTimer: TTimer;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FilterTimerTimer(Sender: TObject);
    function FornecedorFromApiBaseUrl(const AUrl: string): string;
    function ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
    function JsonFieldAsString(const AJsonText, AField: string): string;
    function JsonFieldAsFloat(const AJsonText, AField: string): Double;
    function FormatarDataHora(const AValue: string): string;
    function BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
    function BuscarNomeRepresentante(const AId: Integer): string;
    function BuscarNomeFop(const AId: Integer): string;
    function BuscarNomePrazo(const AId: Integer): string;
    function TotalLiquidoPedido(const APedidoId: Integer): Double;
    function PedidoSelecionadoId: Integer;
    function DataFiltroPedido(const AValue: string): TDateTime;
    function DescontoPedido(const AJsonText: string): Double;
    function DiaFiltroInicial: Integer;
    function DiaFiltroFinal: Integer;
    function MesFiltro: string;
    procedure EnsureFiltroCabecalho;
    procedure CarregarMesesAsync;
    procedure AtualizarDiasFiltro;
    procedure FiltrosChange(Sender: TObject);
    procedure NormalizarEditDia(AEdit: TEdit; const ADefault: string);
    procedure AtualizarResumoPedidos(ATotal: Double; ADescSoma: Double; AQtd: Integer);
    procedure ImprimirPedido(const APedidoId: Integer);
    procedure ApplyResponsiveLayout;
    procedure CarregarPedidos;
  public
  protected
    procedure Resize; override;
  end;

var
  frmPedidosEnviados: TfrmPedidosEnviados;

implementation

{$R *.fmx}

uses
  unDMApp, unPrincipal, unFuncoes
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

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.provider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
  end;

  LAuthority := TAndroidHelper.Context.getPackageName.concat(StringToJString('.fileprovider'));
  try
    Result := TJcontent_FileProvider.JavaClass.getUriForFile(TAndroidHelper.Context, LAuthority, LFile);
    Exit;
  except
    Result := TJnet_Uri.JavaClass.parse(StringToJString('file://' + AFileName));
  end;
end;
{$ENDIF}

function TfrmPedidosEnviados.FornecedorFromApiBaseUrl(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('PLASFAN');
{  if SameText(LUrl, 'http://plasfan.ddns.com.br:9004') then
    Exit('FILHO DO CRIADO');}
  Result := LUrl;
end;

function TfrmPedidosEnviados.DataFiltroPedido(const AValue: string): TDateTime;
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

function TfrmPedidosEnviados.DescontoPedido(const AJsonText: string): Double;
begin
  Result := JsonFieldAsFloat(AJsonText, 'desconto');
  if SameValue(Result, 0) then
    Result := JsonFieldAsFloat(AJsonText, 'desconto_geral');
end;

function TfrmPedidosEnviados.DiaFiltroInicial: Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(EdDiaInicial.Text), 1), 1, 31);
end;

function TfrmPedidosEnviados.DiaFiltroFinal: Integer;
begin
  Result := EnsureRange(StrToIntDef(Trim(EdDiaFinal.Text), DayOf(Date)), 1, 31);
end;

function TfrmPedidosEnviados.MesFiltro: string;
begin
  Result := '';
  if Assigned(CbStatusPedidos) and (CbStatusPedidos.ItemIndex >= 0) then
    Result := Trim(CbStatusPedidos.Items[CbStatusPedidos.ItemIndex]);
end;

procedure TfrmPedidosEnviados.NormalizarEditDia(AEdit: TEdit; const ADefault: string);
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

procedure TfrmPedidosEnviados.FiltrosChange(Sender: TObject);
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

procedure TfrmPedidosEnviados.FilterTimerTimer(Sender: TObject);
begin
  if Assigned(FFilterTimer) then
    FFilterTimer.Enabled := False;
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.EnsureFiltroCabecalho;
var
  LMesAtual: string;
  LMesIndex: Integer;

  procedure SetupCard(ACard: TRectangle);
  begin
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
  LMesAtual := FormatDateTime('mm/yyyy', Date);
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
  SetupLabel(LbTotalPedidosTitulo, CardTotalPedidos, 'Total enviado', 12, $FF5D6B85, False);
  LbTotalPedidosValor := TLabel.Create(Self);
  SetupLabel(LbTotalPedidosValor, CardTotalPedidos, 'R$0,00', 14, TAlphaColorRec.Black, True);

  LbDescMedioTitulo := TLabel.Create(Self);
  SetupLabel(LbDescMedioTitulo, CardDescMedio, 'Desc. medio', 12, $FF5D6B85, False);
  LbDescMedioValor := TLabel.Create(Self);
  SetupLabel(LbDescMedioValor, CardDescMedio, '0,00%', 18, TAlphaColorRec.Black, True);
end;

procedure TfrmPedidosEnviados.AtualizarDiasFiltro;
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

procedure TfrmPedidosEnviados.CarregarMesesAsync;
var
  LCodRepresentante: Integer;
begin
  EnsureFiltroCabecalho;

  LCodRepresentante := 0;
  if Assigned(frmPrincipal) then
    LCodRepresentante := frmPrincipal.id_representante;
  if LCodRepresentante <= 0 then
    Exit;

  TThread.CreateAnonymousThread(
    procedure
    var
      LMeses: TJSONArray;
      LJsonText: string;
    begin
      LJsonText := '';
      try
        TMonitor.Enter(dmApp);
        try
          LMeses := dmApp.GetMesesDashboard(LCodRepresentante);
          try
            LJsonText := LMeses.ToJSON;
          finally
            LMeses.Free;
          end;
        finally
          TMonitor.Exit(dmApp);
        end;
      except
        LJsonText := '';
      end;

      TThread.Queue(nil,
        procedure
        var
          LJsonValue: TJSONValue;
          LArray: TJSONArray;
          LValue: TJSONValue;
          LObj: TJSONObject;
          LMes: string;
          LMesSelecionado: string;
          LIndex: Integer;
        begin
          if (csDestroying in ComponentState) or not Assigned(CbStatusPedidos) then
            Exit;

          LJsonValue := TJSONObject.ParseJSONValue(LJsonText);
          try
            if not (LJsonValue is TJSONArray) then
              Exit;

            LArray := TJSONArray(LJsonValue);
            LMesSelecionado := Trim(CbStatusPedidos.Text);
            FAtualizandoFiltros := True;
            try
              for LValue in LArray do
              begin
                LMes := '';
                if LValue is TJSONObject then
                begin
                  LObj := TJSONObject(LValue);
                  if Assigned(LObj.GetValue('mes')) then
                    LMes := Trim(LObj.GetValue('mes').Value);
                end
                else if Assigned(LValue) then
                  LMes := Trim(LValue.Value);

                if (LMes <> '') and (CbStatusPedidos.Items.IndexOf(LMes) < 0) then
                  CbStatusPedidos.Items.Add(LMes);
              end;

              LIndex := CbStatusPedidos.Items.IndexOf(LMesSelecionado);
              if LIndex < 0 then
                LIndex := 0;
              CbStatusPedidos.ItemIndex := LIndex;
              AtualizarDiasFiltro;
            finally
              FAtualizandoFiltros := False;
            end;
          finally
            LJsonValue.Free;
          end;
        end);
    end).Start;
end;
procedure TfrmPedidosEnviados.AtualizarResumoPedidos(ATotal: Double; ADescSoma: Double; AQtd: Integer);
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

procedure TfrmPedidosEnviados.ApplyResponsiveLayout;
var
  LIsTabletPortrait: Boolean;
  LBottom: Single;
  LContentW: Single;
  LX: Single;
  LFooterH: Single;
begin
  if not Assigned(LayoutRodape) then
    Exit;
  EnsureFiltroCabecalho;

  LIsTabletPortrait := (ClientHeight > ClientWidth) and (ClientWidth >= 430);
  LBottom := 8;
  if ClientHeight > ClientWidth then
    LBottom := 50;

  if LIsTabletPortrait then
  begin
    TopBar.Height := 82;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) * 0.75;

    if ClientWidth >= 600 then
      LContentW := Min(ClientWidth - 28, 760)
    else
      LContentW := Min(ClientWidth - 20, 620);
    LX := (ClientWidth - LContentW) / 2;

    CardBusca.Align := TAlignLayout.None;
    CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 130);
    LbBuscar.Position.X := 18;
    LbBuscar.Position.Y := 8;
    EdBuscar.Position.X := 18;
    EdBuscar.Position.Y := 34;
    EdBuscar.Width := CardBusca.Width - 36;
    CbStatusPedidos.SetBounds(18, 78, 128, 34);
    EdDiaInicial.SetBounds(CbStatusPedidos.Position.X + CbStatusPedidos.Width + 12, 78, 58, 34);
    EdDiaFinal.SetBounds(EdDiaInicial.Position.X + EdDiaInicial.Width + 12, 78, 58, 34);
    BtnBuscar.Visible := False;

    CardTotalPedidos.SetBounds(LX, CardBusca.Position.Y + CardBusca.Height + 10, (LContentW - 12) / 2, 78);
    CardDescMedio.SetBounds(CardTotalPedidos.Position.X + CardTotalPedidos.Width + 12, CardTotalPedidos.Position.Y, CardTotalPedidos.Width, 78);
    LbTotalPedidosTitulo.SetBounds(10, 10, CardTotalPedidos.Width - 20, 20);
    LbTotalPedidosValor.SetBounds(10, 38, CardTotalPedidos.Width - 20, 26);
    LbDescMedioTitulo.SetBounds(10, 10, CardDescMedio.Width - 20, 20);
    LbDescMedioValor.SetBounds(10, 36, CardDescMedio.Width - 20, 30);

    LFooterH := 58;
    LayoutRodape.Align := TAlignLayout.None;
    LayoutRodape.SetBounds(LX, ClientHeight - LFooterH - LBottom, LContentW, LFooterH);
    LayoutRodape.Margins.Bottom := 0;
    BtnImprimir.Align := TAlignLayout.None;
    BtnCompartilhar.Align := TAlignLayout.None;
    BtnCompartilhar.SetBounds(LayoutRodape.Width - BtnCompartilhar.Width, 1, BtnCompartilhar.Width, 56);
    BtnImprimir.SetBounds(BtnCompartilhar.Position.X - BtnImprimir.Width - 12, 1, BtnImprimir.Width, 56);

    LyListView.Align := TAlignLayout.None;
    LyListView.SetBounds(LX, CardTotalPedidos.Position.Y + CardTotalPedidos.Height + 10,
      LContentW, LayoutRodape.Position.Y - (CardTotalPedidos.Position.Y + CardTotalPedidos.Height) - 18);
    if ClientWidth >= 600 then
      LvPedidos.ItemAppearance.ItemHeight := 68
    else
      LvPedidos.ItemAppearance.ItemHeight := 70;
    LvPedidos.ItemAppearanceObjects.ItemObjects.Text.Width := LContentW - 36;
    LvPedidos.ItemAppearanceObjects.ItemObjects.Detail.Width := LContentW - 36;
  end
  else
  begin
    CardBusca.Height := 130;
    EdBuscar.Width := CardBusca.Width - 36;
    CbStatusPedidos.SetBounds(18, 78, 128, 34);
    EdDiaInicial.SetBounds(158, 78, 58, 34);
    EdDiaFinal.SetBounds(228, 78, 58, 34);
    BtnBuscar.Visible := False;
    CardTotalPedidos.SetBounds(10, CardBusca.Position.Y + CardBusca.Height + 8, (ClientWidth - 32) / 2, 78);
    CardDescMedio.SetBounds(CardTotalPedidos.Position.X + CardTotalPedidos.Width + 12, CardTotalPedidos.Position.Y, CardTotalPedidos.Width, 78);
    LbTotalPedidosTitulo.SetBounds(10, 10, CardTotalPedidos.Width - 20, 20);
    LbTotalPedidosValor.SetBounds(10, 38, CardTotalPedidos.Width - 20, 26);
    LbDescMedioTitulo.SetBounds(10, 10, CardDescMedio.Width - 20, 20);
    LbDescMedioValor.SetBounds(10, 36, CardDescMedio.Width - 20, 30);
    LyListView.Align := TAlignLayout.None;
    LyListView.SetBounds(10, CardTotalPedidos.Position.Y + CardTotalPedidos.Height + 8,
      ClientWidth - 20, ClientHeight - LayoutRodape.Height - LayoutRodape.Margins.Bottom - (CardTotalPedidos.Position.Y + CardTotalPedidos.Height) - 20);
    LayoutRodape.Margins.Bottom := LBottom;
    LvPedidos.ItemAppearance.ItemHeight := 50;
  end;

  CardTotalPedidos.Visible := True;
  CardDescMedio.Visible := True;
  CardTotalPedidos.BringToFront;
  CardDescMedio.BringToFront;
  LayoutRodape.BringToFront;
end;

procedure TfrmPedidosEnviados.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

function TfrmPedidosEnviados.JsonFieldAsString(const AJsonText, AField: string): string;
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

function TfrmPedidosEnviados.JsonFieldAsFloat(const AJsonText, AField: string): Double;
var
  S: string;
begin
  S := JsonFieldAsString(AJsonText, AField);
  S := StringReplace(S, '.', ',', [rfReplaceAll]);
  Result := StrToFloatDef(S, 0);
end;

function TfrmPedidosEnviados.TotalLiquidoPedido(const APedidoId: Integer): Double;
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
end;

function TfrmPedidosEnviados.PedidoSelecionadoId: Integer;
begin
  Result := 0;
  if Assigned(LvPedidos.Selected) then
    Result := LvPedidos.Selected.Tag;
end;

procedure TfrmPedidosEnviados.ImprimirPedido(const APedidoId: Integer);
var
  QPedido, QItens: TFDQuery;
  LVenda1, LVenda2: string;
  LRep, LCli, LData, LHora, LFop, LPrazo, LDtRef: string;
  LTot: Double;
  LFS: TFormatSettings;
  LPdfFile: string;
  LDt: TDateTime;
  LConteudo: TStringList;
  LRepId, LFopId, LPrazoId: Integer;
  LFornecedor: string;
  LCodCliente: Integer;
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

      LOffsets[1] := StreamPos;
      AddRaw('1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj');

      LOffsets[2] := StreamPos;
      AddRaw('2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj');

      LOffsets[3] := StreamPos;
      AddRaw('3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>endobj');

      LOffsets[4] := StreamPos;
      AddRaw(Format('4 0 obj<< /Length %d >>stream', [LContentLen]));
      AddRaw(StringReplace(LContent, sLineBreak, #10, [rfReplaceAll]));
      AddRaw('endstream endobj');

      LOffsets[5] := StreamPos;
      AddRaw('5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>endobj');

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

    {LRepId := QPedido.FieldByName('representative_code').AsInteger;
    LRep := BuscarNomeRepresentante(LRepId);}
    LRep := frmPrincipal.FRepNome;

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    LFop   := BuscarNomeFop(LFopId);

    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    LPrazo   := BuscarNomePrazo(LPrazoId);

    LDtRef := Trim(QPedido.FieldByName('dt_ref').AsString);
    if TryISO8601ToDate(StringReplace(LDtRef, ' ', 'T', []), LDt, True) or
       TryISO8601ToDate(LDtRef, LDt, True) then
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
    LConteudo.Add('CLIENTE.......: ' + JsonFieldAsString(LVenda1, 'cod_cliente') + ' - ' + LCli);
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

    LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'codfop'), 0);
    if LFopId <= 0 then LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_fop'), 0);
    if LFopId <= 0 then LFopId := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_fop'), 0);
    LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'codprazo'), 0);
    if LPrazoId <= 0 then LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'id_prazo'), 0);
    if LPrazoId <= 0 then LPrazoId := StrToIntDef(JsonFieldAsString(LVenda1, 'cod_prazo'), 0);

    LFop := BuscarNomeFop(LFopId);
    if LFop = '' then
      LFop := IntToStr(LFopId);
    LPrazo := BuscarNomePrazo(LPrazoId);
    if LPrazo = '' then
      LPrazo := IntToStr(LPrazoId);

    LConteudo.Add(StringOfChar('-', 95));
    LConteudo.Add(PadRight('CONDICAO DE PAGTO.: ' + LFop + ' - ' + LPrazo, 68) + PadLeft('TOTAL: ' + FormatFloat('#,###,##0.00', LTot, LFS), 25));


    LPdfFile := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetDocumentsPath) +
      Format('pedido_enviado_%d.pdf', [APedidoId]);
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
{$IFNDEF MSWINDOWS}
{$IFNDEF ANDROID}
    ShowMessage('PDF gerado em: ' + LPdfFile);
{$ENDIF}
{$ENDIF}
  finally
    LConteudo.Free;
    QItens.Free;
    QPedido.Free;
  end;
end;

function TfrmPedidosEnviados.FormatarDataHora(const AValue: string): string;
var
  S: string;
  D: TDateTime;
begin
  S := Trim(AValue);
  if S = '' then
    Exit('');

  // SQLite costuma vir como 'yyyy-mm-dd hh:nn:ss'
  if TryISO8601ToDate(StringReplace(S, ' ', 'T', []), D, True) or
     TryISO8601ToDate(S, D, True) then
    Exit(FormatDateTime('dd/mm/yyyy hh:nn:ss', D));

  // fallback: mantém texto original se não conseguir converter
  Result := S;
end;

function TfrmPedidosEnviados.BuscarNomeClientePorCodigo(const ACodCliente: Integer): string;
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

function TfrmPedidosEnviados.ClienteConsumidorFinal(const ACodCliente: Integer): Boolean;
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

function TfrmPedidosEnviados.BuscarNomeRepresentante(const AId: Integer): string;
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

function TfrmPedidosEnviados.BuscarNomeFop(const AId: Integer): string;
var
  Q: TFDQuery;
  LCols: TStringList;
  LNomeCampo: string;
  LIdCampo: string;
begin
  Result := '';
  if AId <= 0 then Exit;
  LCols := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'PRAGMA table_info("fop")';
    Q.Open;
    while not Q.Eof do
    begin
      LCols.Add(LowerCase(Trim(Q.FieldByName('name').AsString)));
      Q.Next;
    end;
    Q.Close;

    if LCols.IndexOf('id') >= 0 then
      LIdCampo := 'id'
    else if LCols.IndexOf('cod_fop') >= 0 then
      LIdCampo := 'cod_fop'
    else if LCols.IndexOf('codigo') >= 0 then
      LIdCampo := 'codigo'
    else
      LIdCampo := LCols[0];

    if LCols.IndexOf('fop') >= 0 then
      LNomeCampo := 'fop'
    else if LCols.IndexOf('descricao') >= 0 then
      LNomeCampo := 'descricao'
    else if LCols.IndexOf('nome') >= 0 then
      LNomeCampo := 'nome'
    else if LCols.IndexOf('nom_fop') >= 0 then
      LNomeCampo := 'nom_fop'
    else
      LNomeCampo := 'id';

    Q.SQL.Text := Format('select %s as nome from fop where %s = :p0', [LNomeCampo, LIdCampo]);
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.FieldByName('nome').AsString);
  finally
    LCols.Free;
    Q.Free;
  end;
end;

function TfrmPedidosEnviados.BuscarNomePrazo(const AId: Integer): string;
var
  Q: TFDQuery;
  LCols: TStringList;
  LNomeCampo: string;
  LIdCampo: string;
begin
  Result := '';
  if AId <= 0 then Exit;
  LCols := TStringList.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'PRAGMA table_info("prazo")';
    Q.Open;
    while not Q.Eof do
    begin
      LCols.Add(LowerCase(Trim(Q.FieldByName('name').AsString)));
      Q.Next;
    end;
    Q.Close;

    if LCols.IndexOf('id') >= 0 then
      LIdCampo := 'id'
    else if LCols.IndexOf('cod_prazo') >= 0 then
      LIdCampo := 'cod_prazo'
    else if LCols.IndexOf('codigo') >= 0 then
      LIdCampo := 'codigo'
    else
      LIdCampo := LCols[0];

    if LCols.IndexOf('prazo') >= 0 then
      LNomeCampo := 'prazo'
    else if LCols.IndexOf('descricao') >= 0 then
      LNomeCampo := 'descricao'
    else if LCols.IndexOf('nome') >= 0 then
      LNomeCampo := 'nome'
    else
      LNomeCampo := LIdCampo;

    Q.SQL.Text := Format('select %s as nome from prazo where %s = :p0', [LNomeCampo, LIdCampo]);
    Q.ParamByName('p0').AsInteger := AId;
    Q.Open;
    if not Q.IsEmpty then
      Result := Trim(Q.FieldByName('nome').AsString);
  finally
    LCols.Free;
    Q.Free;
  end;
end;

procedure TfrmPedidosEnviados.CarregarPedidos;
var
  Q: TFDQuery;
  LItem: TListViewItem;
  LBusca: string;
  LNomeCliente: string;
  LData: string;
  LTotal: Double;
  LDescSoma: Double;
  LTotalGeral: Double;
  LDt: TDateTime;
  LFS: TFormatSettings;
  LCodCliente: Integer;
  LDiaIni: Integer;
  LDiaFim: Integer;
  LMes: string;
  LQtd: Integer;
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
  LvPedidos.Items.BeginUpdate;
  try
    LvPedidos.Items.Clear;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := dmApp.FDConnection;
      Q.SQL.Text :=
        'select id, vendas1_json, coalesce(sent_at, created_at) as dt_ref, numdoc_remote ' +
        'from outbound_pedido ' +
        'where upper(trim(coalesce(status, ''''))) = ''ENVIADO'' ' +
        'order by dt_ref desc';
      Q.Open;
      while not Q.Eof do
      begin
        LNomeCliente := Trim(JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'nom_cliente'));
        if LNomeCliente = '' then
        begin
          LCodCliente := StrToIntDef(JsonFieldAsString(Q.FieldByName('vendas1_json').AsString, 'cod_cliente'), 0);
          LNomeCliente := BuscarNomeClientePorCodigo(LCodCliente);
        end;
        if LNomeCliente = '' then
          LNomeCliente := 'Pedido ' + Q.FieldByName('id').AsString;

        LDt := DataFiltroPedido(Q.FieldByName('dt_ref').AsString);
        if (LDt > 0) and
           ((LMes = '') or SameText(FormatDateTime('mm/yyyy', LDt), LMes)) and
           ((DayOf(LDt) >= LDiaIni) and (DayOf(LDt) <= LDiaFim)) and
           ((LBusca = '') or (Pos(LBusca, LowerCase(LNomeCliente)) > 0) or
            (Pos(LBusca, LowerCase(Q.FieldByName('numdoc_remote').AsString)) > 0) or
            (Pos(LBusca, Q.FieldByName('id').AsString) > 0)) then
        begin
          LData := FormatarDataHora(Q.FieldByName('dt_ref').AsString);

          LTotal := TotalLiquidoPedido(Q.FieldByName('id').AsInteger);
          LTotalGeral := LTotalGeral + LTotal;
          LDescSoma := LDescSoma + DescontoPedido(Q.FieldByName('vendas1_json').AsString);
          Inc(LQtd);

          LItem := LvPedidos.Items.Add;
          LItem.Tag := Q.FieldByName('id').AsInteger;
          LItem.Text := Format('Pedido %s - %s', [Q.FieldByName('numdoc_remote').AsString, LNomeCliente]);
          LItem.Detail := Format(
            '%s  R$ %s  Desc %.2f%%',
            [LData,
             FormatFloat('#,###,##0.00', LTotal, LFS),
             DescontoPedido(Q.FieldByName('vendas1_json').AsString)]
          );
        end;
        Q.Next;
      end;
      if LvPedidos.Items.Count = 0 then
      begin
        LItem := LvPedidos.Items.Add;
        LItem.Text := 'Nenhum pedido enviado';
        LItem.Detail := 'Sem registros para os filtros atuais';
        LItem.Tag := 0;
      end;
    finally
      Q.Free;
    end;
  finally
    LvPedidos.Items.EndUpdate;
  end;
  AtualizarResumoPedidos(LTotalGeral, LDescSoma, LQtd);
end;

procedure TfrmPedidosEnviados.FormShow(Sender: TObject);
begin
    OnClose := FormClose;
LbTitulo.Text := 'Pedidos Enviados';
  //LvPedidos.ItemAppearanceClassName := 'ListItem';
  BtnCompartilhar.OnClick := BtnCompartilharClick;
  LbBtnCompartilhar.OnClick := BtnCompartilharClick;
  ApplyResponsiveLayout;
  EnsureFiltroCabecalho;
  AtualizarDiasFiltro;
  CarregarMesesAsync;
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.FormActivate(Sender: TObject);
begin
end;

procedure TfrmPedidosEnviados.BtnBuscarClick(Sender: TObject);
begin
  CarregarPedidos;
end;

procedure TfrmPedidosEnviados.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidosEnviados.BtnImprimirClick(Sender: TObject);
var
  LId: Integer;
begin
  LId := PedidoSelecionadoId;
  if LId <= 0 then
  begin
    ShowMessage('Selecione um pedido enviado para imprimir.');
    Exit;
  end;
  ImprimirPedido(LId);
end;

procedure TfrmPedidosEnviados.BtnCompartilharClick(Sender: TObject);
var
  LId: Integer;
  LPdfFile: string;
{$IFDEF ANDROID}
  LIntent: JIntent;
  LUri: Jnet_Uri;
{$ENDIF}
begin
  LId := PedidoSelecionadoId;
  if LId <= 0 then
  begin
    ShowMessage('Selecione um pedido enviado para compartilhar.');
    Exit;
  end;

  LPdfFile := IncludeTrailingPathDelimiter(System.IOUtils.TPath.GetDocumentsPath) +
    Format('pedido_enviado_%d.pdf', [LId]);
  if not FileExists(LPdfFile) then
    ImprimirPedido(LId);

  if not FileExists(LPdfFile) then
  begin
    ShowMessage('Falha ao gerar PDF para compartilhamento.');
    Exit;
  end;

{$IFDEF ANDROID}
  LUri := BuildContentUriForPdf(LPdfFile);
  LIntent := TJIntent.Create;
  LIntent.setAction(TJIntent.JavaClass.ACTION_SEND);
  LIntent.setType(StringToJString('application/pdf'));
  LIntent.putExtra(TJIntent.JavaClass.EXTRA_STREAM, JParcelable(LUri));
  LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
  TAndroidHelper.Activity.startActivity(
    TJIntent.JavaClass.createChooser(LIntent, StrToJCharSequence('Compartilhar PDF'))
  );
{$ELSE}
  ShowMessage('Compartilhamento implementado para Android.');
{$ENDIF}
end;

procedure TfrmPedidosEnviados.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmPedidosEnviados := nil;
end;

end.