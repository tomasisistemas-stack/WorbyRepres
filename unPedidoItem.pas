unit unPedidoItem;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.JSON,
  System.Math,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit,
  FMX.DialogService.Async, unFuncoes, FireDAC.Comp.Client;

type
  TfrmPedidoItem = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    CardProduto: TRectangle;
    ThumbProduto: TRectangle;
    LbProdNome: TLabel;
    LbProdCodigo: TLabel;
    LbProdEstoque: TLabel;
    CardPreco: TRectangle;
    LbPrecoTitulo: TLabel;
    EdPreco: TEdit;
    LbDescTitulo: TLabel;
    EdDescPct: TEdit;
    CardTotal: TRectangle;
    LbTotalTitulo: TLabel;
    LbTotalValor: TLabel;
    LbQtdTitulo: TLabel;
    EdQtd: TEdit;
    LbQtdUn: TLabel;
    lbDescontoMax: TLabel;
    lbValorMin: TLabel;
    lyRodape: TLayout;
    Layout2: TLayout;
    BtnAdicionar: TRectangle;
    LayoutPedido: TLayout;
    LbAdicionar: TLabel;
    Layout3: TLayout;
    BtnCancelar: TRectangle;
    LayoutCancelar: TLayout;
    LbCancelar: TLabel;
    procedure EdPrecoEnter(Sender: TObject);
    procedure EdDescPctEnter(Sender: TObject);
    procedure EdQtdEnter(Sender: TObject);
  private
    FPrecoBase: Double;
    FDescMax: Double;
    FValorMin: Double;
    FUpdating: Boolean;
    FProdutoCodigo: string;
    FProdutoNome: string;
    FUnidade: string;
    FEditingPedidoId: Integer;
    FEditingItemOrd: Integer;
    FViewOnly: Boolean;
    function FmtNumero(const AValue: Double; const ADecimals: Integer = 2): string;
    function FmtMoeda(const AValue: Double): string;
    function ParseNumber(const AText: string; out AValue: Double): Boolean;
    procedure AddItemToOutbound;
    procedure BtnAdicionarClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure RecalcularTotal;
    procedure ValidarPreco;
    procedure ValidarDesconto;
    procedure EditsEnter(Sender: TObject);
    procedure EditsKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure FocarProximoCampo(const AAtual: TControl);
    function ObterQtdMultiplaProduto(out AQtdMultipla: Double): Boolean;
    function ValidarQuantidadeMinima(const AShowMessage: Boolean): Boolean;
    function AjustarEValidarQuantidade(const AShowMessage: Boolean): Boolean;
    procedure ApplyResponsiveLayout;
    procedure AvisarCampoInvalido(const AMsg: string; const AEdit: TEdit);
    function ValidarLimitesEntrada(const AShowMessage: Boolean): Boolean;
  protected
    procedure DoShow; override;
    procedure Resize; override;
  public
    procedure SetProdutoDados(const ACodigo, ANome, AUnidade, AEstoque: string;
      APrecoVenda, ADescMax: Double; const AImagem: TBytes);
    procedure SetEdicaoItem(const APedidoId, AItemOrd: Integer; const AQtd, APreco, ADescPct: Double);
    procedure SetModoVisualizacao(const AQtd, APreco, ADescPct: Double);
  published
    procedure EdPrecoExit(Sender: TObject);
    procedure EdDescPctExit(Sender: TObject);
    procedure EdQtdExit(Sender: TObject);
  end;

var
  frmPedidoItem: TfrmPedidoItem;

implementation

{$R *.fmx}

uses
  unDMApp,
  unPedido;

procedure TfrmPedidoItem.ApplyResponsiveLayout;
var
  LW, LH: Single;
  LMargin, LGap, LTopH, LContentW, LX: Single;
  LBtnY, LBtnW: Single;
  LRodapeH: Single;
  LRodapeBottom: Single;
  LLandscape: Boolean;
  LPrecoW, LTotalW: Single;
  LPad: Single;
  LCol1W, LCol2W, LCol3W: Single;
  LX1, LX2, LX3: Single;
  LImgW, LTxtX, LTxtW: Single;
  LProdutoH, LPrecoH, LTotalH: Single;
begin
  if csDestroying in ComponentState then
    Exit;

  LW := ClientWidth;
  LH := ClientHeight;
  if (LW <= 0) or (LH <= 0) then
    Exit;

  LMargin := Max(12, LW * 0.05);
  LGap := 10;
  LTopH := EnsureRange(LH * 0.15, 78, 120);
  LContentW := Min(LW - (LMargin * 2), 560);
  if LContentW < 260 then
    LContentW := LW - (LMargin * 2);
  LX := (LW - LContentW) * 0.5;
  LLandscape := LW > LH;
  LPad := 18;

  TopBar.SetBounds(0, 0, LW, LTopH);
  LbTitulo.Position.X := LMargin;
  LbTitulo.Position.Y := (LTopH - LbTitulo.Height) * 0.8;

  if LLandscape then
  begin
    LProdutoH := 132;
    LPrecoH := 70;
    LTotalH := 70;
    CardProduto.SetBounds(LX, LTopH + LGap, LContentW, LProdutoH);
  end
  else
  begin
    LProdutoH := 146;
    LPrecoH := 96;
    LTotalH := 88;
    CardProduto.SetBounds(LX, LTopH + LGap, LContentW, LProdutoH);
  end;

  // Layout interno do card do produto
  LImgW := EnsureRange(CardProduto.Height - 44, 84, 104);
  ThumbProduto.SetBounds(8, 8, LImgW, LImgW * 0.82);
  LTxtX := ThumbProduto.Position.X + ThumbProduto.Width + 12;
  LTxtW := CardProduto.Width - LTxtX - 12;

  LbProdNome.Position.X := LTxtX;
  LbProdNome.Position.Y := 10;
  LbProdNome.Width := LTxtW;
  LbProdNome.Height := CardProduto.Height - 52;
  LbProdNome.TextSettings.HorzAlign := TTextAlign.Center;
  LbProdNome.TextSettings.VertAlign := TTextAlign.Center;
  LbProdNome.TextSettings.WordWrap := True;

  LbProdCodigo.Position.X := 8;
  LbProdCodigo.Position.Y := CardProduto.Height - 43;
  LbProdCodigo.Width := (CardProduto.Width * 0.5) - 26;

  LbProdEstoque.Position.X := CardProduto.Width * 0.5;
  LbProdEstoque.Position.Y := CardProduto.Height - 43;
  LbProdEstoque.Width := (CardProduto.Width * 0.5) - 12;
  LbProdEstoque.TextSettings.HorzAlign := TTextAlign.Trailing;

  lbDescontoMax.Position.X := 8;
  lbDescontoMax.Position.Y := CardProduto.Height - 26;
  lbDescontoMax.Width := (CardProduto.Width * 0.5) - 26;
  lbDescontoMax.TextSettings.HorzAlign := TTextAlign.Leading;

  lbValorMin.Position.X := CardProduto.Width * 0.5;
  lbValorMin.Position.Y := CardProduto.Height - 26;
  lbValorMin.Width := (CardProduto.Width * 0.5) - 12;
  lbValorMin.TextSettings.HorzAlign := TTextAlign.Trailing;

  if LLandscape then
  begin
    // Em paisagem, total na mesma linha do bloco de edição
    LPrecoW := (LContentW - LGap) * 0.70;
    LTotalW := LContentW - LPrecoW - LGap;
    CardPreco.SetBounds(LX, CardProduto.Position.Y + CardProduto.Height + LGap, LPrecoW, LPrecoH);
    CardTotal.SetBounds(LX + LPrecoW + LGap, CardPreco.Position.Y, LTotalW, LTotalH);
  end
  else
  begin
    CardPreco.SetBounds(LX, CardProduto.Position.Y + CardProduto.Height + LGap, LContentW, LPrecoH);
    CardTotal.SetBounds(LX, CardPreco.Position.Y + CardPreco.Height + LGap, LContentW, LTotalH);
  end;

  CardPreco.Visible := True;
  CardTotal.Visible := True;

  // Reposiciona campos do CardPreco de forma responsiva
  LCol1W := (CardPreco.Width - (LPad * 2)) * 0.32;
  LCol2W := (CardPreco.Width - (LPad * 2)) * 0.26;
  LCol3W := (CardPreco.Width - (LPad * 2)) * 0.24;
  LX1 := LPad;
  LX2 := LX1 + LCol1W + 12;
  LX3 := LX2 + LCol2W + 12;

  LbPrecoTitulo.Position.X := LX1;
  LbPrecoTitulo.Position.Y := 13;
  EdPreco.Position.X := LX1;
  EdPreco.Position.Y := 37;
  EdPreco.Width := LCol1W;
  EdPreco.Height := 36;

  LbDescTitulo.Position.X := LX2;
  LbDescTitulo.Position.Y := 13;
  EdDescPct.Position.X := LX2;
  EdDescPct.Position.Y := 37;
  EdDescPct.Width := LCol2W;
  EdDescPct.Height := 36;

  if Assigned(LbQtdTitulo) then
  begin
    LbQtdTitulo.Position.X := LX3;
    LbQtdTitulo.Position.Y := 13;
  end;
  if Assigned(EdQtd) then
  begin
    EdQtd.Position.X := LX3;
    EdQtd.Position.Y := 37;
    EdQtd.Width := LCol3W;
    EdQtd.Height := 36;
  end;
  if Assigned(LbQtdUn) and Assigned(EdQtd) then
  begin
    LbQtdUn.Position.X := EdQtd.Position.X + EdQtd.Width + 8;
    LbQtdUn.Position.Y := 46;
  end;

  // Total: título acima do valor, sem corte
  LbTotalTitulo.AutoSize := False;
  LbTotalTitulo.Position.X := 20;
  LbTotalTitulo.Position.Y := 8;
  LbTotalTitulo.Width := CardTotal.Width - 24;
  LbTotalTitulo.Height := 22;
  LbTotalTitulo.TextSettings.HorzAlign := TTextAlign.Trailing;
  LbTotalTitulo.TextSettings.VertAlign := TTextAlign.Trailing;

  LbTotalValor.AutoSize := False;
  LbTotalValor.Width := CardTotal.Width - 24;
  LbTotalValor.Height := CardTotal.Height - 42;
  LbTotalValor.TextSettings.HorzAlign := TTextAlign.Trailing;
  LbTotalValor.TextSettings.VertAlign := TTextAlign.Trailing;
  if LLandscape then
  begin
    LbTotalValor.TextSettings.Font.Size := 20;
    LbTotalValor.Position.X := 8;
    LbTotalValor.Position.Y := 32;
    lyRodape.Margins.Bottom := 0;
  end
  else begin
    LbTotalValor.TextSettings.Font.Size := 24;
    LbTotalValor.Position.X := 20;
    LbTotalValor.Position.Y := 32;
  end;


  LRodapeBottom := 0;

  if LLandscape then
    LBtnY := LH - LRodapeH - LRodapeBottom - 6
  else begin
   // LBtnY := LH - LRodapeH - LRodapeBottom - 10;

    if IsXiaomiDevice then
      LRodapeBottom := 50
    else
      LRodapeBottom := 0;
  end;
  lyRodape.Margins.Bottom := LRodapeBottom;


  LBtnW := lyRodape.Width * 0.5;
  Layout2.Align := TAlignLayout.None;
  // Layout2 contém BtnAdicionar -> direita
  Layout2.SetBounds(LBtnW, 0, lyRodape.Width - LBtnW, lyRodape.Height);
  Layout3.Align := TAlignLayout.None;
  // Layout3 contém BtnCancelar -> esquerda
  Layout3.SetBounds(0, 0, LBtnW, lyRodape.Height);

  CardProduto.BringToFront;
  CardPreco.BringToFront;
  CardTotal.BringToFront;
  lyRodape.BringToFront;
end;

procedure TfrmPedidoItem.AddItemToOutbound;
var
  LPreco: Double;
  LDesc: Double;
  LQtd: Double;
  LTotal: Double;
  LObj: TJSONObject;
  LPedidoId: Integer;
begin
  if not Assigned(frmPedido) then
    raise Exception.Create('Pedido não está aberto.');

  LPedidoId := frmPedido.outboundPedidoId;
  if LPedidoId <= 0 then
    raise Exception.Create('Pedido outbound não inicializado.');

  if not ParseNumber(EdPreco.Text, LPreco) then
    LPreco := FPrecoBase;
  if not ParseNumber(EdDescPct.Text, LDesc) then
    LDesc := 0;
  if not ParseNumber(EdQtd.Text, LQtd) then
    LQtd := 1;
  if LQtd <= 0 then
    LQtd := 1;

  LTotal := LPreco * LQtd;

  LObj := TJSONObject.Create;
  try
    LObj.AddPair('cod_produto', StrToIntDef(FProdutoCodigo, 0).ToString);
    LObj.AddPair('nom_produto', FProdutoNome);
    LObj.AddPair('unidade', FUnidade);
    LObj.AddPair('qtd', TJSONNumber.Create(LQtd));
    LObj.AddPair('preco', TJSONNumber.Create(LPreco));
    LObj.AddPair('desconto_pct', TJSONNumber.Create(LDesc));
    LObj.AddPair('desconto_maximo', TJSONNumber.Create(FDescMax));
    LObj.AddPair('valor_minimo', TJSONNumber.Create(FValorMin));
    LObj.AddPair('total_item', TJSONNumber.Create(LTotal));

  if (FEditingPedidoId > 0) and (FEditingItemOrd > 0) then
  begin
    with TFDQuery.Create(nil) do
    try
      Connection := dmApp.FDConnection;
      SQL.Text := 'update outbound_pedido_item set vendas2_json = :p0 where pedido_id = :p1 and item_ord = :p2';
      ParamByName('p0').AsString := LObj.ToJSON;
      ParamByName('p1').AsInteger := FEditingPedidoId;
      ParamByName('p2').AsInteger := FEditingItemOrd;
      ExecSQL;
    finally
      Free;
    end;
  end
  else
    dmApp.AddOutboundPedidoItem(LPedidoId, LObj.ToJSON);
  finally
    LObj.Free;
  end;
end;

procedure TfrmPedidoItem.BtnAdicionarClick(Sender: TObject);
begin
  if FViewOnly then
    Exit;

  try
    if not ValidarLimitesEntrada(True) then
      Exit;
    if not AjustarEValidarQuantidade(True) then
      Exit;
    ValidarPreco;
    ValidarDesconto;
    AddItemToOutbound;
    if Assigned(frmPedido) then
      frmPedido.AtualizarContadorItensDigitados;
    Close;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TfrmPedidoItem.AvisarCampoInvalido(const AMsg: string; const AEdit: TEdit);
begin
  TDialogServiceAsync.MessageDialog(
    AMsg,
    TMsgDlgType.mtWarning,
    [TMsgDlgBtn.mbOK],
    TMsgDlgBtn.mbOK,
    0,
    procedure(const AResult: TModalResult)
    begin
      TThread.ForceQueue(nil,
        procedure
        begin
          if Assigned(AEdit) then
          begin
            AEdit.SetFocus;
            AEdit.SelectAll;
          end;
        end);
    end
  );
end;

function TfrmPedidoItem.ValidarLimitesEntrada(const AShowMessage: Boolean): Boolean;
var
  LPrecoDigitado: Double;
  LDescDigitado: Double;
begin
  Result := True;

  if (Trim(EdPreco.Text) <> '') and (not ParseNumber(EdPreco.Text, LPrecoDigitado)) then
  begin
    Result := False;
    if AShowMessage then
      AvisarCampoInvalido('Preço unitário inválido.', EdPreco);
    Exit;
  end;

  if (Trim(EdDescPct.Text) <> '') and (not ParseNumber(EdDescPct.Text, LDescDigitado)) then
  begin
    Result := False;
    if AShowMessage then
      AvisarCampoInvalido('% de desconto inválido.', EdDescPct);
    Exit;
  end;

  if ParseNumber(EdPreco.Text, LPrecoDigitado) and
     (RoundTo(LPrecoDigitado, -2) < RoundTo(FValorMin, -2)) then
  begin
    Result := False;
    if AShowMessage then
      AvisarCampoInvalido(
        Format('Preço abaixo do permitido. Mínimo: R$ %.2f', [FValorMin]),
        EdPreco
      );
    Exit;
  end;

  if ParseNumber(EdDescPct.Text, LDescDigitado) and
     (RoundTo(LDescDigitado, -2) > RoundTo(FDescMax, -2)) then
  begin
    Result := False;
    if AShowMessage then
      AvisarCampoInvalido(
        Format('Desconto acima do permitido. Máximo: %.2f%%', [FDescMax]),
        EdDescPct
      );
    Exit;
  end;
end;

procedure TfrmPedidoItem.BtnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPedidoItem.DoShow;
begin
  inherited;
  BtnAdicionar.OnClick := BtnAdicionarClick;
  BtnCancelar.OnClick := BtnCancelarClick;
  ApplyResponsiveLayout;
end;

procedure TfrmPedidoItem.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

function TfrmPedidoItem.ParseNumber(const AText: string; out AValue: Double): Boolean;
var
  S: string;
  LLastSep: Integer;
begin
  S := Trim(AText);
  S := StringReplace(S, 'R$', '', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, ' ', '', [rfReplaceAll]);

  if S = '' then
  begin
    AValue := 0;
    Exit(False);
  end;

  if (Pos('.', S) > 0) and (Pos(',', S) > 0) then
  begin
    LLastSep := LastDelimiter('.,', S);
    if (LLastSep > 0) and (S[LLastSep] = ',') then
    begin
      // formato 1.234,56
      S := StringReplace(S, '.', '', [rfReplaceAll]);
      S := StringReplace(S, ',', '.', [rfReplaceAll]);
    end
    else
    begin
      // formato 1,234.56
      S := StringReplace(S, ',', '', [rfReplaceAll]);
    end;
  end
  else if Pos(',', S) > 0 then
  begin
    // formato 1234,56
    S := StringReplace(S, '.', '', [rfReplaceAll]);
    S := StringReplace(S, ',', '.', [rfReplaceAll]);
  end;

  Result := TryStrToFloat(S, AValue, TFormatSettings.Create('en-US'));
end;

function TfrmPedidoItem.FmtNumero(const AValue: Double; const ADecimals: Integer): string;
var
  FS: TFormatSettings;
  LDecMask: string;
begin
  FS := TFormatSettings.Create('pt-BR');
  if ADecimals <= 0 then
    LDecMask := ''
  else
    LDecMask := '.' + StringOfChar('0', ADecimals);

  // força seção negativa explícita para manter o sinal "-"
  Result := FormatFloat('#,##0' + LDecMask + ';-#,##0' + LDecMask, AValue, FS);
end;

function TfrmPedidoItem.FmtMoeda(const AValue: Double): string;
begin
  Result := 'R$ ' + FmtNumero(AValue, 2);
end;

procedure TfrmPedidoItem.RecalcularTotal;
var
  LPreco: Double;
  LQtd: Double;
begin
  if not ParseNumber(EdPreco.Text, LPreco) then
    LPreco := FPrecoBase;
  LQtd := 1;
  if Assigned(EdQtd) then
  begin
    if not ParseNumber(EdQtd.Text, LQtd) then
      LQtd := 1;
    if LQtd <= 0 then
      LQtd := 1;
  end;

  LbTotalValor.Text := FmtMoeda(LPreco * LQtd);
end;

procedure TfrmPedidoItem.ValidarPreco;
var
  LPreco: Double;
  LDesc: Double;
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    if not ParseNumber(EdPreco.Text, LPreco) then
      LPreco := FPrecoBase;

    if RoundTo(LPreco, -2) < RoundTo(FValorMin, -2) then
      LPreco := FValorMin;

    if FPrecoBase > 0 then
      LDesc := (1 - (LPreco / FPrecoBase)) * 100
    else
      LDesc := 0;

    if RoundTo(LDesc, -2) > RoundTo(FDescMax, -2) then
    begin
      LDesc := FDescMax;
      LPreco := FValorMin;
    end;

    EdPreco.Text := FmtNumero(LPreco, 2);
    EdDescPct.Text := FmtNumero(LDesc, 2);
    RecalcularTotal;
  finally
    FUpdating := False;
  end;
end;

procedure TfrmPedidoItem.ValidarDesconto;
var
  LDesc: Double;
  LPreco: Double;
begin
  if FUpdating then
    Exit;
  FUpdating := True;
  try
    if not ParseNumber(EdDescPct.Text, LDesc) then
      LDesc := 0;

    if RoundTo(LDesc, -2) > RoundTo(FDescMax, -2) then
      LDesc := FDescMax;

    LPreco := FPrecoBase - (FPrecoBase * (LDesc / 100));
    if RoundTo(LPreco, -2) < RoundTo(FValorMin, -2) then
    begin
      LPreco := FValorMin;
      if FPrecoBase > 0 then
        LDesc := (1 - (LPreco / FPrecoBase)) * 100
      else
        LDesc := 0;
    end;

    EdDescPct.Text := FmtNumero(LDesc, 2);
    EdPreco.Text := FmtNumero(LPreco, 2);
    RecalcularTotal;
  finally
    FUpdating := False;
  end;
end;

procedure TfrmPedidoItem.EdPrecoEnter(Sender: TObject);
begin
  EdPreco.SelectAll;
end;

procedure TfrmPedidoItem.EdPrecoExit(Sender: TObject);
begin
  if not ValidarLimitesEntrada(True) then
    Exit;
  ValidarPreco;
end;

procedure TfrmPedidoItem.EdDescPctEnter(Sender: TObject);
begin
  EdDescPct.SelectAll;
end;

procedure TfrmPedidoItem.EdDescPctExit(Sender: TObject);
begin
  if not ValidarLimitesEntrada(True) then
    Exit;
  ValidarDesconto;
end;

procedure TfrmPedidoItem.EdQtdEnter(Sender: TObject);
begin
  EdQtd.SelectAll;
end;

procedure TfrmPedidoItem.EdQtdExit(Sender: TObject);
begin
  AjustarEValidarQuantidade(True);
end;

procedure TfrmPedidoItem.FocarProximoCampo(const AAtual: TControl);
var
  LVal: Double;
begin
  if not Assigned(AAtual) then
    Exit;

  if (AAtual = EdPreco) and Assigned(EdDescPct) and EdDescPct.Visible and EdDescPct.Enabled then
  begin
    if (Trim(EdPreco.Text) <> '') and (not ParseNumber(EdPreco.Text, LVal)) then
    begin
      AvisarCampoInvalido('Preço unitário inválido.', EdPreco);
      Exit;
    end;
    if ParseNumber(EdPreco.Text, LVal) and
       (RoundTo(LVal, -2) < RoundTo(FValorMin, -2)) then
    begin
      AvisarCampoInvalido(Format('Preço abaixo do permitido. Mínimo: R$ %.2f', [FValorMin]), EdPreco);
      Exit;
    end;
    ValidarPreco;
    EdDescPct.SetFocus;
    Exit;
  end;

  if (AAtual = EdDescPct) and Assigned(EdQtd) and EdQtd.Visible and EdQtd.Enabled then
  begin
    if (Trim(EdDescPct.Text) <> '') and (not ParseNumber(EdDescPct.Text, LVal)) then
    begin
      AvisarCampoInvalido('% de desconto inválido.', EdDescPct);
      Exit;
    end;
    if ParseNumber(EdDescPct.Text, LVal) and
       (RoundTo(LVal, -2) > RoundTo(FDescMax, -2)) then
    begin
      AvisarCampoInvalido(Format('Desconto acima do permitido. Máximo: %.2f%%', [FDescMax]), EdDescPct);
      Exit;
    end;
    ValidarDesconto;
    EdQtd.SetFocus;
    Exit;
  end;

  if (AAtual = EdQtd) and Assigned(BtnAdicionar) and BtnAdicionar.Visible and BtnAdicionar.Enabled then
  begin
    if not AjustarEValidarQuantidade(True) then
      Exit;
    BtnAdicionar.CanFocus := True;
    BtnAdicionar.TabStop := True;
    BtnAdicionar.SetFocus;
  end;
end;

function TfrmPedidoItem.ObterQtdMultiplaProduto(out AQtdMultipla: Double): Boolean;
var
  LQuery: TFDQuery;
begin
  Result := False;
  AQtdMultipla := 0;

  if (Trim(FProdutoCodigo) = '') or (not Assigned(dmApp)) then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select coalesce(qtd_multipla, 0) as qtd_multipla ' +
      'from produto where cod_produto = :p0';
    LQuery.ParamByName('p0').AsInteger := StrToIntDef(FProdutoCodigo, 0);
    LQuery.Open;
    if not LQuery.Eof then
    begin
      AQtdMultipla := LQuery.FieldByName('qtd_multipla').AsFloat;
      Result := True;
    end;
  finally
    LQuery.Free;
  end;
end;

function TfrmPedidoItem.ValidarQuantidadeMinima(const AShowMessage: Boolean): Boolean;
var
  LQtd: Double;
  LQtdMultipla: Double;
  LMsg: string;
  LDiv: Double;
  LTol: Double;
begin
  Result := True;

  if not Assigned(EdQtd) then
    Exit;

  if not ParseNumber(EdQtd.Text, LQtd) then
    LQtd := 1;
  if LQtd <= 0 then
    LQtd := 1;

  if not ObterQtdMultiplaProduto(LQtdMultipla) then
    Exit;

  if LQtdMultipla <= 0 then
    Exit;

  // Quantidade deve ser múltipla de qtd_multipla (ex.: 15, 30, 45...)
  LDiv := LQtd / LQtdMultipla;
  LTol := 0.000001;
  if Abs(LDiv - Round(LDiv)) > LTol then
  begin
    Result := False;
    if AShowMessage then
    begin
      LMsg := 'A quantidade deve ser múltipla de ' + FmtNumero(LQtdMultipla, 2);
      AvisarCampoInvalido(LMsg, EdQtd);
    end;
  end;
end;

function TfrmPedidoItem.AjustarEValidarQuantidade(const AShowMessage: Boolean): Boolean;
var
  LQtd: Double;
begin
  if not Assigned(EdQtd) then
  begin
    RecalcularTotal;
    Exit(True);
  end;

  if not ParseNumber(EdQtd.Text, LQtd) then
    LQtd := 1;
  if LQtd <= 0 then
    LQtd := 1;

  EdQtd.Text := FmtNumero(LQtd, 0);

  Result := ValidarQuantidadeMinima(AShowMessage);
  if Result then
    RecalcularTotal;
end;

procedure TfrmPedidoItem.EditsEnter(Sender: TObject);
begin
  if Sender is TEdit then
  begin
    TThread.Queue(nil,
      procedure
      var
        LEdit: TEdit;
      begin
        if Sender is TEdit then
        begin
          LEdit := TEdit(Sender);
          LEdit.SelectAll;
        end;
      end);
  end;
end;

procedure TfrmPedidoItem.EditsKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
var
  LCtrl: TControl;
begin
{$IFDEF ANDROID}
  if (Key = vkReturn) or (KeyChar = #13) or (KeyChar = #10) then
  begin
    Key := 0;
    KeyChar := #0;
    if Sender is TControl then
    begin
      LCtrl := TControl(Sender);
      TThread.Queue(nil,
        procedure
        begin
          FocarProximoCampo(LCtrl);
        end);
    end;
  end;
{$ENDIF}
end;

procedure TfrmPedidoItem.SetProdutoDados(const ACodigo, ANome, AUnidade,
  AEstoque: string; APrecoVenda, ADescMax: Double; const AImagem: TBytes);
var
  LStream: TBytesStream;
begin
  FViewOnly := False;
  FEditingPedidoId := 0;
  FEditingItemOrd := 0;
  if Assigned(EdPreco) then EdPreco.Enabled := True;
  if Assigned(EdDescPct) then EdDescPct.Enabled := True;
  if Assigned(EdQtd) then EdQtd.Enabled := True;
  if Assigned(BtnAdicionar) then BtnAdicionar.Visible := True;
  if Assigned(BtnCancelar) then BtnCancelar.Visible := True;
  if Assigned(LbAdicionar) then
    LbAdicionar.Text := 'Adicionar';
  if Assigned(LbCancelar) then
    LbCancelar.Text := 'Cancelar';
  FProdutoCodigo := ACodigo;
  FProdutoNome := ANome;
  FUnidade := AUnidade;
  LbProdNome.Text := ANome;
  if ACodigo <> '' then
    LbProdCodigo.Text := 'Codigo: ' + ACodigo
  else
    LbProdCodigo.Text := 'Codigo: --';

  if AEstoque <> '' then
    LbProdEstoque.Text := 'Estoque: ' + AEstoque
  else
    LbProdEstoque.Text := 'Estoque: --';

  FPrecoBase := APrecoVenda;
  FDescMax := ADescMax;
  FValorMin := FPrecoBase - (FPrecoBase * (FDescMax / 100));

  EdPreco.Text := FmtNumero(FPrecoBase, 2);
  EdPreco.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  EdDescPct.KeyboardType := TVirtualKeyboardType.DecimalNumberPad;
  EdPreco.TextSettings.HorzAlign := TTextAlign.Trailing;
  EdDescPct.TextSettings.HorzAlign := TTextAlign.Trailing;
  EdPreco.FilterChar := '0123456789,.';
  EdDescPct.FilterChar := '-0123456789,.';
  if Assigned(EdQtd) then
  begin
    EdQtd.Text := '1';
    EdQtd.KeyboardType := TVirtualKeyboardType.NumberPad;
    EdQtd.TextSettings.HorzAlign := TTextAlign.Trailing;
    EdQtd.FilterChar := '0123456789';
  end;
  if Assigned(LbQtdUn) then
  begin
    if AUnidade <> '' then
      LbQtdUn.Text := AUnidade
    else
      LbQtdUn.Text := 'UN';
  end;

  LbTotalValor.Text := FmtMoeda(FPrecoBase);
  lbDescontoMax.Text := 'Desconto M'#225'x.: ' + FmtNumero(FDescMax, 2) + '%';
  lbValorMin.Text := 'Valor Min.: ' + FmtMoeda(FValorMin);
  EdDescPct.Text := '0';

  EdPreco.OnExit := EdPrecoExit;
  EdDescPct.OnExit := EdDescPctExit;
  EdPreco.OnEnter := EditsEnter;
  EdDescPct.OnEnter := EditsEnter;
  EdPreco.OnKeyDown := EditsKeyDown;
  EdDescPct.OnKeyDown := EditsKeyDown;
  if Assigned(EdQtd) then
  begin
    EdQtd.OnExit := EdQtdExit;
    EdQtd.OnEnter := EditsEnter;
    EdQtd.OnKeyDown := EditsKeyDown;
  end;

  if Length(AImagem) > 0 then
  begin
    LStream := TBytesStream.Create(AImagem);
    try
      LStream.Position := 0;
      try
        ThumbProduto.Fill.Kind := TBrushKind.Bitmap;
        ThumbProduto.Fill.Bitmap.WrapMode := TWrapMode.TileStretch;
        ThumbProduto.Fill.Bitmap.Bitmap.LoadFromStream(LStream);
      except
        ThumbProduto.Fill.Kind := TBrushKind.Solid;
      end;
    finally
      LStream.Free;
    end;
  end
  else
    ThumbProduto.Fill.Kind := TBrushKind.Solid;

  RecalcularTotal;
end;

procedure TfrmPedidoItem.SetEdicaoItem(const APedidoId, AItemOrd: Integer; const AQtd, APreco, ADescPct: Double);
begin
  FViewOnly := False;
  FEditingPedidoId := APedidoId;
  FEditingItemOrd := AItemOrd;
  if Assigned(LbAdicionar) then
    LbAdicionar.Text := 'Salvar';
  if Assigned(LbCancelar) then
    LbCancelar.Text := 'Cancelar';
  if Assigned(BtnAdicionar) then BtnAdicionar.Visible := True;
  if Assigned(BtnCancelar) then BtnCancelar.Visible := True;
  if Assigned(EdPreco) then EdPreco.Enabled := True;
  if Assigned(EdDescPct) then EdDescPct.Enabled := True;
  if Assigned(EdQtd) then EdQtd.Enabled := True;
  EdQtd.Text := FmtNumero(AQtd, 0);
  EdPreco.Text := FmtNumero(APreco, 2);
  EdDescPct.Text := FmtNumero(ADescPct, 2);
  RecalcularTotal;
end;

procedure TfrmPedidoItem.SetModoVisualizacao(const AQtd, APreco, ADescPct: Double);
begin
  FViewOnly := True;
  FEditingPedidoId := 0;
  FEditingItemOrd := 0;
  if Assigned(EdQtd) then
  begin
    EdQtd.Text := FmtNumero(AQtd, 0);
    EdQtd.Enabled := False;
  end;
  if Assigned(EdPreco) then
  begin
    EdPreco.Text := FmtNumero(APreco, 2);
    EdPreco.Enabled := False;
  end;
  if Assigned(EdDescPct) then
  begin
    EdDescPct.Text := FmtNumero(ADescPct, 2);
    EdDescPct.Enabled := False;
  end;
  if Assigned(BtnAdicionar) then
    BtnAdicionar.Visible := False;
  if Assigned(BtnCancelar) then
    BtnCancelar.Visible := True;
  if Assigned(LbCancelar) then
    LbCancelar.Text := 'Voltar';
  RecalcularTotal;
  ApplyResponsiveLayout;
end;

end.
