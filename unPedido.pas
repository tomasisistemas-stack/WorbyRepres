unit unPedido;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils,
  System.Math,
  System.JSON,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ScrollBox,
  FMX.TabControl, FMX.DialogService, FMX.DialogService.Async, FMX.ListView, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.Edit, FMX.ListBox, FMX.Memo,
  Data.DB, FireDAC.Comp.Client, FMX.Memo.Types, System.ImageList, FMX.ImgList,
  FMX.VirtualKeyboard;

type
  TfrmPedido = class(TForm)
    LayoutRoot: TLayout;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    PresentedScrollBox1: TPresentedScrollBox;
    CardPerfil: TRectangle;
    Layout4: TLayout;
    LbNome: TLabel;
    Layout5: TLayout;
    LbDoc: TLabel;
    LbDocDireita: TLabel;
    Layout6: TLayout;
    LbCidade: TLabel;
    CardSituacao: TRectangle;
    LayoutLimite: TLayout;
    LbLimite: TLabel;
    LayoutSaldo: TLayout;
    LbSaldo: TLabel;
    LayoutSituacaoTitulo: TLayout;
    LbSituacaoTitulo: TLabel;
    BackgroundRect: TRectangle;
    TabMenu: TTabControl;
    TabCliente: TTabItem;
    TabProdutos: TTabItem;
    CardFormaPgto: TRectangle;
    ImgFormaPgto: TImage;
    Layout8: TLayout;
    Layout10: TLayout;
    Layout9: TLayout;
    Label3: TLabel;
    Layout7: TLayout;
    lbFormaPgto: TLabel;
    Rectangle1: TRectangle;
    Layout11: TLayout;
    Layout12: TLayout;
    Label2: TLabel;
    Layout13: TLayout;
    lbPrazoPgto: TLabel;
    Layout14: TLayout;
    imgPrazoPgto: TImage;
    CardBuscaProd: TRectangle;
    LbBuscarProd: TLabel;
    EdBuscarProd: TEdit;
    CbModoBuscaProd: TComboBox;
    LayoutProdutosList: TLayout;
    LvProdutos: TListView;
    TabPromocao: TTabItem;
    LayoutPromocao: TLayout;
    CardBuscaPromocao: TRectangle;
    LbBuscarPromocao: TLabel;
    EdBuscarPromocao: TEdit;
    CbModoBuscaPromocao: TComboBox;
    BtnBuscarPromocao: TImage;
    LayoutPromocaoList: TLayout;
    LvPromocao: TListView;
    TabUltimasCompras: TTabItem;
    LayoutUltimasCompras: TLayout;
    CardBuscaUltimas: TRectangle;
    LbBuscarUltimas: TLabel;
    EdBuscarUltimas: TEdit;
    CbModoBuscaUltimas: TComboBox;
    BtnBuscarUltimas: TImage;
    LayoutUltimasList: TLayout;
    LvUltimasCompras: TListView;
    TabDigitados: TTabItem;
    LayoutDigitados: TLayout;
    CardBuscaDigitados: TRectangle;
    LbBuscarDigitados: TLabel;
    EdBuscarDigitados: TEdit;
    CbModoBuscaDigitados: TComboBox;
    BtnBuscarDigitados: TImage;
    LayoutDigitadosList: TLayout;
    LvDigitados: TListView;
    LayoutDigitadosAcoes: TLayout;
    BtnEditarDigitado: TRectangle;
    LbEditarDigitado: TLabel;
    BtnExcluirDigitado: TRectangle;
    LbExcluirDigitado: TLabel;
    TabTotal: TTabItem;
    ScrollTotal: TScrollBox;
    CardFormaPgtoTotal: TRectangle;
    LayoutFormaTotalTexto: TLayout;
    LbFormaTituloTotal: TLabel;
    LbFormaPgtoTotal: TLabel;
    LayoutFormaTotalIcone: TLayout;
    ImgFormaPgtoTotal: TImage;
    CardPrazoPgtoTotal: TRectangle;
    LayoutPrazoTotalTexto: TLayout;
    LbPrazoTituloTotal: TLabel;
    LbPrazoPgtoTotal: TLabel;
    LayoutPrazoTotalIcone: TLayout;
    ImgPrazoPgtoTotal: TImage;
    CardOrcamentoTotal: TRectangle;
    LayoutOrcamentoTotalTexto: TLayout;
    LbOrcamentoTituloTotal: TLabel;
    CbOrcamento: TComboBox;
    CardTotais: TRectangle;
    LayoutTotBruto: TLayout;
    LbTotBrutoTitulo: TLabel;
    LbTotBrutoValor: TLabel;
    LayoutTotDesc: TLayout;
    LbTotDescTitulo: TLabel;
    LbTotDescValor: TLabel;
    LayoutTotCV: TLayout;
    LbTotCVTitulo: TLabel;
    LbTotCVValor: TLabel;
    LayoutTotLiquido: TLayout;
    LbTotLiquidoTitulo: TLabel;
    LbTotLiquidoValor: TLabel;
    ScrollBox1: TScrollBox;
    ImageList1: TImageList;
    CardObservacoes: TRectangle;
    LbObsTitulo: TLabel;
    MemoObservacoes: TMemo;
    lyRodTotal: TLayout;
    BgRodTotal: TRectangle;
    LbRodTotTitulo: TLabel;
    LbRodTotValor: TLabel;
    BtnBuscarProd: TImage;
    procedure ImgFormaPgtoClick(Sender: TObject);
    procedure ImgPrazoPgtoClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnPedidoClick(Sender: TObject);
    procedure BtnBuscarProdClick(Sender: TObject);
    procedure BtnBuscarProdTap(Sender: TObject; const Point: TPointF);
    procedure CbModoBuscaProdChange(Sender: TObject);
    procedure BtnBuscarPromocaoClick(Sender: TObject);
    procedure BtnBuscarPromocaoTap(Sender: TObject; const Point: TPointF);
    procedure CbModoBuscaPromocaoChange(Sender: TObject);
    procedure BtnBuscarUltimasClick(Sender: TObject);
    procedure BtnBuscarUltimasTap(Sender: TObject; const Point: TPointF);
    procedure CbModoBuscaUltimasChange(Sender: TObject);
    procedure BtnBuscarDigitadosClick(Sender: TObject);
    procedure BtnBuscarDigitadosTap(Sender: TObject; const Point: TPointF);
    procedure CbModoBuscaDigitadosChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LvProdutosItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure LvUltimasComprasItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure BtnEditarDigitadoClick(Sender: TObject);
    procedure BtnExcluirDigitadoClick(Sender: TObject);
  private
    FTabHeader: TLayout;
    FTabButtons: array[0..5] of TSpeedButton;
    FTabImages: array[0..5] of TImage;
    FTabLabels: array[0..5] of TLabel;
    FClienteNome: string;
    FClienteCodigo: string;
    FClienteCidade: string;
    FClienteDoc: string;
    FContatoTelefone: string;
    FContatoEmail: string;
    FEndereco1: string;
    FEndereco2: string;
    CardContatoDyn: TRectangle;
    CardEnderecoDyn: TRectangle;
    LbContatoTituloDyn: TLabel;
    LbTelefoneDyn: TLabel;
    LbEmailDyn: TLabel;
    LbEnderecoTituloDyn: TLabel;
    LbEndereco1Dyn: TLabel;
    LbEndereco2Dyn: TLabel;
    FVoltarParaPedidosDigitados: Boolean;
    FProdutoImagemSubPorProduto: TDictionary<string, string>;
    FProdutoImagemCache: TObjectDictionary<string, TBitmap>;
    FProdutoImagemTimer: TTimer;
    FProdutoImagemCursor: Integer;
    FProdutoImagemCampoImagem: string;
    FProdutoImagemListView: TListView;
    FListarProdutosRodando: Boolean;
    FUltimaListarProdutos: TDateTime;
    FListarUltimasRodando: Boolean;
    FUltimaListarUltimas: TDateTime;
    procedure EnsureCardContatoEndereco;
    procedure AjustarCardContatoEndereco;
    function SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
    function SafeFieldAsCurrency(AQuery: TFDQuery; const ACampo: string): Currency;
    function FormatarNumero(const AValue: Double; const ADecimals: Integer = 2): string;
    function FormatarMoeda(const AValue: Double): string;
    function ObterCodRepresentanteLocal: Integer;
    function CalcularPercComissaoProduto(const ACodProduto: string; const ADescPct: Double;
      const ACodRepresentante: Integer; const AFuncionario: string): Double;
    procedure FecharPedido;
    procedure CancelarPedidoAtual;
    procedure CarregarSituacaoDoSqlite(const ACodigo: string);
    procedure ListarProdutos;
    procedure ListarPromocoes;
    procedure ListarUltimasCompras;
    procedure ListarItensDigitados;
    procedure AtualizarTotaisPedido;
    procedure AbrirPedidoItem(const ACodProduto: string; const ASomenteVisualizacao: Boolean = False;
      const AQtdVisualizacao: Double = 1; const APrecoVisualizacao: Double = 0;
      const ADescVisualizacao: Double = 0);
    procedure CriarOutboundPedidoDraft;
    procedure SincronizarOutboundPedidoDraft;
    function GetTabelaCols(const ATabela: string): TArray<string>;
    function FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
    function SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
    function TotalLiquidoAtual: Double;
    function OrcamentoSelecionado: Integer;
    procedure SetOrcamentoSelecionado(const AValue: Integer);
    procedure HandleClose(Sender: TObject; var Action: TCloseAction);
    procedure ApplyResponsiveLayout;
    procedure SyncCardsTotalPgtoTexto;
    procedure ConfigurarAbasComIcone;
    procedure EnsureTabHeader;
    procedure AtualizarEstadoCabecalhoAbas;
    procedure TabHeaderClick(Sender: TObject);
    function ProdutoJaDigitadoNoPedido(const ACodProduto: string): Boolean;
    function ObterItemDigitadoSelecionado(out AItemOrd: Integer; out AVendas2Json: string): Boolean;
    procedure EditarItemDigitado(const AItemOrd: Integer; const AVendas2Json: string);
    procedure ExcluirItemDigitado(const AItemOrd: Integer);
    procedure PararCargaImagensProdutos;
    procedure IniciarCargaImagensProdutos(const ACampoImagem: string; AListView: TListView = nil);
    procedure ProdutoImagemTimer(Sender: TObject);
    function CarregarImagemSubcategoria(const ASubId, ACampoImagem: string): TBitmap;
    procedure AtribuirImagemProduto(AItem: TListViewItem; ABmp: TBitmap);

    function CountPrazosFormaPgto(const ACodFop: Integer): Integer;
    function PrazoPertenceFormaPgto(const ACodFop, ACodPrazo: Integer): Boolean;
    procedure AplicarPrazoFormaPgto;
  protected
    procedure DoShow; override;
    procedure Resize; override;
  public
    codCliente   : integer;
    codFormaPgto : integer;
    codPrazoPgto : integer;
    outboundPedidoId: Integer;
    procedure SelecionarFormaPgto(const ACodigo: Integer; const ANome: string);
    procedure SelecionarPrazoPgto(const ACodigo: Integer; const ANome: string);
    procedure SetCliente(const ANome, ACodigo, ACidade: string);
    procedure CarregarPedidoDigitado(const APedidoId: Integer);
    procedure PrepararNovoPedido;
    procedure AtualizarOutboundPedido;
    procedure AtualizarContadorItensDigitados;
    procedure RestaurarPedidoItem(const AExtraJson: string);
  end;

var
  frmPedido: TfrmPedido;
  GFormaPgtoCodigo: string;

implementation

{$R *.fmx}

uses
  unFormaPgto,
  unPrazoPgto, unDMApp, unPedidoItem, unFuncoes, unPedidosDigitados,
  unAndroidComboFix;

procedure TfrmPedido.DoShow;
begin
  inherited;
  OnClose := HandleClose;
  ApplyResponsiveLayout;
end;

procedure TfrmPedido.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

function TfrmPedido.OrcamentoSelecionado: Integer;
begin
  Result := 0;
  if Assigned(CbOrcamento) and (CbOrcamento.ItemIndex = 0) then
    Result := 1;
end;

procedure TfrmPedido.SetOrcamentoSelecionado(const AValue: Integer);
begin
  if not Assigned(CbOrcamento) then
    Exit;
  if AValue = 1 then
    CbOrcamento.ItemIndex := 0
  else
    CbOrcamento.ItemIndex := 1;
end;

function TfrmPedido.TotalLiquidoAtual: Double;
var
  S: string;
begin
  Result := 0;
  if not Assigned(LbTotLiquidoValor) then
    Exit;

  S := Trim(LbTotLiquidoValor.Text);
  S := StringReplace(S, 'R$', '', [rfIgnoreCase, rfReplaceAll]);
  S := StringReplace(S, '.', '', [rfReplaceAll]);
  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  S := Trim(S);
  Result := StrToFloatDef(S, 0, TFormatSettings.Invariant);
end;

procedure TfrmPedido.HandleClose(Sender: TObject; var Action: TCloseAction);
begin
  PararCargaImagensProdutos;
  FreeAndNil(FProdutoImagemTimer);
  FreeAndNil(FProdutoImagemSubPorProduto);
  FreeAndNil(FProdutoImagemCache);
  AtualizarTotaisPedido;
  if (outboundPedidoId > 0) and (TotalLiquidoAtual <= 0) then
    CancelarPedidoAtual;
  Action := TCloseAction.caFree;
  frmPedido := nil;
end;

procedure TfrmPedido.EnsureTabHeader;
var
  I: Integer;
  LCaptions: array[0..5] of string;
  LImageIndexes: array[0..5] of Integer;
begin
  LCaptions[0] := 'Cliente';
  LCaptions[1] := 'Produtos';
  LCaptions[2] := 'Promoção';
  LCaptions[3] := 'Últimas';
  LCaptions[4] := 'Digitados';
  LCaptions[5] := 'Total';

  LImageIndexes[0] := 0;
  LImageIndexes[1] := 1;
  LImageIndexes[2] := 2;
  LImageIndexes[3] := 3;
  LImageIndexes[4] := 4;
  LImageIndexes[5] := 5;

  if not Assigned(LayoutRoot) then
    Exit;

  if not Assigned(FTabHeader) then
  begin
    FTabHeader := TLayout.Create(Self);
    FTabHeader.Parent := LayoutRoot;
    FTabHeader.Stored := False;
    FTabHeader.Align := TAlignLayout.None;
    FTabHeader.Height := 54;

    for I := 0 to High(FTabButtons) do
    begin
      FTabButtons[I] := TSpeedButton.Create(Self);
      FTabButtons[I].Parent := FTabHeader;
      FTabButtons[I].Stored := False;
      FTabButtons[I].Align := TAlignLayout.None;
      FTabButtons[I].Text := '';
      FTabButtons[I].CanFocus := False;
      FTabButtons[I].Tag := I;
      FTabButtons[I].OnClick := TabHeaderClick;
      FTabButtons[I].Images := ImageList1;
      FTabButtons[I].ImageIndex := LImageIndexes[I];
      FTabButtons[I].StyledSettings := [];
      FTabButtons[I].TintColor := TAlphaColor($FF5B6578);
      FTabButtons[I].Text := '';

      FTabImages[I] := TImage.Create(Self);
      FTabImages[I].Parent := FTabButtons[I];
      FTabImages[I].Stored := False;
      FTabImages[I].Align := TAlignLayout.Top;
      FTabImages[I].HitTest := False;
      FTabImages[I].Margins.Top := 2;
      FTabImages[I].Margins.Bottom := 0;
      FTabImages[I].Width := 22;
      FTabImages[I].Height := 22;
      if Assigned(ImageList1) and (ImageList1.Source <> nil) and
         (LImageIndexes[I] >= 0) and (LImageIndexes[I] < ImageList1.Source.Count) then
        FTabImages[I].MultiResBitmap.Assign(ImageList1.Source.Items[LImageIndexes[I]].MultiResBitmap);

      FTabLabels[I] := TLabel.Create(Self);
      FTabLabels[I].Parent := FTabHeader;
      FTabLabels[I].Stored := False;
      FTabLabels[I].Align := TAlignLayout.None;
      FTabLabels[I].HitTest := False;
      FTabLabels[I].Text := LCaptions[I];
      FTabLabels[I].StyledSettings := [];
      FTabLabels[I].TextSettings.HorzAlign := TTextAlign.Center;
      FTabLabels[I].TextSettings.VertAlign := TTextAlign.Center;
      FTabLabels[I].TextSettings.Font.Size := 11;
      FTabLabels[I].Height := 18;
    end;
  end;
end;

procedure TfrmPedido.AtualizarEstadoCabecalhoAbas;
var
  I: Integer;
begin
  for I := 0 to High(FTabButtons) do
    if Assigned(FTabButtons[I]) then
    begin
      if Assigned(TabMenu) and (TabMenu.TabIndex = I) then
      begin
        FTabButtons[I].Opacity := 1;
        FTabButtons[I].TintColor := TAlphaColor($FF00A79D);
        if Assigned(FTabImages[I]) then
          FTabImages[I].Opacity := 1;
        if Assigned(FTabLabels[I]) then
          FTabLabels[I].TextSettings.FontColor := TAlphaColor($FF00A79D);
      end
      else
      begin
        FTabButtons[I].Opacity := 0.8;
        FTabButtons[I].TintColor := TAlphaColor($FF5B6578);
        if Assigned(FTabImages[I]) then
          FTabImages[I].Opacity := 0.75;
        if Assigned(FTabLabels[I]) then
          FTabLabels[I].TextSettings.FontColor := TAlphaColor($FF5B6578);
      end;
    end;
end;

procedure TfrmPedido.TabHeaderClick(Sender: TObject);
var
  LIdx: Integer;
begin
  if not (Sender is TSpeedButton) then
    Exit;
  if not Assigned(TabMenu) then
    Exit;

  LIdx := TSpeedButton(Sender).Tag;
  if (LIdx >= 0) and (LIdx < TabMenu.TabCount) then
    TabMenu.TabIndex := LIdx;

  AtualizarEstadoCabecalhoAbas;

  if TabMenu.ActiveTab = TabProdutos then
    ListarProdutos
  else if TabMenu.ActiveTab = TabPromocao then
    ListarPromocoes
  else if TabMenu.ActiveTab = TabUltimasCompras then
    ListarUltimasCompras;
end;
procedure TfrmPedido.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LIsTabletPortrait: Boolean;
  LBottomMargin: Single;
  LFooterH: Single;
  LFooterTotalH: Single;
  LFooterW: Single;
  LFooterTotalW: Single;
  LBtnW: Single;
  LGap: Single;
  LTabH: Single;
  LTabTop: Single;
  LTabsHeaderH: Single;
  LFooter: TLayout;
  LFooterTotal: TLayout;
  LLeftArea: TLayout;
  LRightArea: TLayout;
  LProdutosRoot: TControl;
  LPromocaoRoot: TControl;
  LPromocaoList: TControl;
  LProdutosScroll: TControl;
  LListW: Single;
  LListX: Single;
  I: Integer;
  procedure AjustarLarguraListView(ALv: TListView; AReservaDireita: Single = 100);
  var
    LTextW: Single;
  begin
    if not Assigned(ALv) then
      Exit;
    LTextW := Max(200, ALv.Width - AReservaDireita);
    ALv.ItemAppearanceObjects.ItemObjects.Text.Width := LTextW;
    ALv.ItemAppearanceObjects.ItemObjects.Detail.Width := LTextW;
    ALv.ItemAppearanceObjects.ItemEditObjects.Text.Width := LTextW;
    ALv.ItemAppearanceObjects.ItemEditObjects.Detail.Width := LTextW;
  end;
  procedure AjustarAparenciaProdutos;
    procedure AjustarLista(ALv: TListView);
    begin
      if not Assigned(ALv) then
        Exit;

      if LIsLandscape or LIsTabletPortrait then
        ALv.ItemAppearance.ItemHeight := 76
      else
        ALv.ItemAppearance.ItemHeight := 82;
      ALv.EditMode := False;
      ALv.ItemAppearanceObjects.ItemObjects.Accessory.Visible := False;

      if LIsLandscape or LIsTabletPortrait then
      begin
        ALv.ItemAppearanceObjects.ItemObjects.Image.Width := 56;
        ALv.ItemAppearanceObjects.ItemObjects.Image.Height := 56;
      end
      else
      begin
        ALv.ItemAppearanceObjects.ItemObjects.Image.Width := 50;
        ALv.ItemAppearanceObjects.ItemObjects.Image.Height := 50;
      end;
      ALv.ItemAppearanceObjects.ItemObjects.Image.PlaceOffset.X := 0;
      ALv.ItemAppearanceObjects.ItemObjects.Image.PlaceOffset.Y := 0;

      if LIsLandscape or LIsTabletPortrait then
        ALv.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 13
      else
        ALv.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 12;
      ALv.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
      ALv.ItemAppearanceObjects.ItemObjects.Text.Height := 40;
      if LIsLandscape or LIsTabletPortrait then
        ALv.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := 64
      else
        ALv.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := 50;
      ALv.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 10;

      if LIsLandscape or LIsTabletPortrait then
        ALv.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 11
      else
        ALv.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 10.5;
      ALv.ItemAppearanceObjects.ItemObjects.Detail.Height := 20;
      if LIsLandscape or LIsTabletPortrait then
        ALv.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 64
      else
        ALv.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 50;
      ALv.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 50;
      ALv.ItemAppearanceObjects.ItemObjects.Detail.TextVertAlign := TTextAlign.Leading;
    end;
  begin
    AjustarLista(LvProdutos);
    AjustarLista(LvPromocao);
  end;
  procedure AjustarProdutosPaisagem;
  var
    LInnerW: Single;
    LComboW: Single;
    LBtnW: Single;
    LEditW: Single;
  begin
    if not Assigned(LvProdutos) then
      Exit;

    AjustarAparenciaProdutos;

    if LIsLandscape or LIsTabletPortrait then
    begin
      if Assigned(CardBuscaProd) then
      begin
        if LIsTabletPortrait then
        begin
          CardBuscaProd.Height := 76;
          CardBuscaProd.Margins.Left := 12;
          CardBuscaProd.Margins.Right := 12;
          if Assigned(CardBuscaPromocao) then
          begin
            CardBuscaPromocao.Height := CardBuscaProd.Height;
            CardBuscaPromocao.Margins.Left := CardBuscaProd.Margins.Left;
            CardBuscaPromocao.Margins.Right := CardBuscaProd.Margins.Right;
          end;
        end
        else
        begin
          CardBuscaProd.Height := 48;
          CardBuscaProd.Margins.Left := 8;
          CardBuscaProd.Margins.Right := 8;
          if Assigned(CardBuscaPromocao) then
          begin
            CardBuscaPromocao.Height := CardBuscaProd.Height;
            CardBuscaPromocao.Margins.Left := CardBuscaProd.Margins.Left;
            CardBuscaPromocao.Margins.Right := CardBuscaProd.Margins.Right;
          end;
        end;
      end;

      if Assigned(CardBuscaProd) then
        LInnerW := Max(220, CardBuscaProd.Width - 36)
      else
        LInnerW := 320;

      if LIsTabletPortrait then
      begin
        LBtnW := 58;
        LComboW := 132;
      end
      else
      begin
        LBtnW := 95;
        LComboW := 120;
      end;
      LEditW := Max(120, LInnerW - (LComboW + LBtnW + 8));

      if Assigned(LbBuscarProd) then
      begin
        LbBuscarProd.Visible := LIsTabletPortrait;
        if LIsTabletPortrait then
          LbBuscarProd.Position.Y := 4;
      end;
      if Assigned(LbBuscarPromocao) then
      begin
        LbBuscarPromocao.Visible := LIsTabletPortrait;
        if LIsTabletPortrait then
          LbBuscarPromocao.Position.Y := 4;
      end;
      if Assigned(EdBuscarProd) then
      begin
        EdBuscarProd.Position.X := 18;
        if LIsTabletPortrait then
          EdBuscarProd.Position.Y := 30
        else
          EdBuscarProd.Position.Y := 8;
        EdBuscarProd.Width := LEditW;
      end;
      if Assigned(EdBuscarPromocao) then
      begin
        EdBuscarPromocao.Position.X := 18;
        if LIsTabletPortrait then
          EdBuscarPromocao.Position.Y := 30
        else
          EdBuscarPromocao.Position.Y := 8;
        EdBuscarPromocao.Width := LEditW;
      end;

      if Assigned(CbModoBuscaProd) then
      begin
        if Assigned(EdBuscarProd) then
          CbModoBuscaProd.Position.X := EdBuscarProd.Position.X + LEditW + 4;
        if LIsTabletPortrait then
          CbModoBuscaProd.Position.Y := 30
        else
          CbModoBuscaProd.Position.Y := 8;
        CbModoBuscaProd.Width := LComboW;
      end;
      if Assigned(CbModoBuscaPromocao) then
      begin
        if Assigned(EdBuscarPromocao) then
          CbModoBuscaPromocao.Position.X := EdBuscarPromocao.Position.X + LEditW + 4;
        if LIsTabletPortrait then
          CbModoBuscaPromocao.Position.Y := 30
        else
          CbModoBuscaPromocao.Position.Y := 8;
        CbModoBuscaPromocao.Width := LComboW;
      end;
      if Assigned(BtnBuscarProd) then
      begin
        if LIsTabletPortrait then
          BtnBuscarProd.Position.Y := 30
        else
          BtnBuscarProd.Position.Y := 8;
        BtnBuscarProd.Width := LBtnW;
        if Assigned(CbModoBuscaProd) then
          BtnBuscarProd.Position.X := CbModoBuscaProd.Position.X + LComboW + 4;
      end;
      if Assigned(BtnBuscarPromocao) then
      begin
        if LIsTabletPortrait then
          BtnBuscarPromocao.Position.Y := 30
        else
          BtnBuscarPromocao.Position.Y := 8;
        BtnBuscarPromocao.Width := LBtnW;
        if Assigned(CbModoBuscaPromocao) then
          BtnBuscarPromocao.Position.X := CbModoBuscaPromocao.Position.X + LComboW + 4;
      end;

      if Assigned(LayoutProdutosList) then
        LayoutProdutosList.Margins.Top := 2;
      if Assigned(LayoutPromocaoList) then
        LayoutPromocaoList.Margins.Top := 2;

      if LIsTabletPortrait then
      begin
        AjustarLarguraListView(LvProdutos, 96);
        AjustarLarguraListView(LvPromocao, 96);
      end
      else
      begin
        AjustarLarguraListView(LvProdutos, 92);
        AjustarLarguraListView(LvPromocao, 92);
      end;
    end
    else
    begin
      if Assigned(CardBuscaProd) then
      begin
        CardBuscaProd.Height := 96;
        CardBuscaProd.Margins.Left := 10;
        CardBuscaProd.Margins.Right := 10;
        if Assigned(CardBuscaPromocao) then
        begin
          CardBuscaPromocao.Height := CardBuscaProd.Height;
          CardBuscaPromocao.Margins.Left := CardBuscaProd.Margins.Left;
          CardBuscaPromocao.Margins.Right := CardBuscaProd.Margins.Right;
        end;
      end;
      if Assigned(CardBuscaProd) then
        LInnerW := Max(240, CardBuscaProd.Width - 36)
      else
        LInnerW := Max(240, ClientWidth - 56);
      if Assigned(LbBuscarProd) then
      begin
        LbBuscarProd.Visible := True;
        LbBuscarProd.Position.Y := 4;
      end;
      if Assigned(LbBuscarPromocao) then
      begin
        LbBuscarPromocao.Visible := True;
        LbBuscarPromocao.Position.Y := 4;
      end;
      if Assigned(EdBuscarProd) then
      begin
        EdBuscarProd.Position.X := 18;
        EdBuscarProd.Position.Y := 20.8;
        EdBuscarProd.Width := LInnerW;
      end;
      if Assigned(EdBuscarPromocao) then
      begin
        EdBuscarPromocao.Position.X := 18;
        EdBuscarPromocao.Position.Y := 20.8;
        EdBuscarPromocao.Width := LInnerW;
      end;
      if Assigned(CbModoBuscaProd) then
      begin
        CbModoBuscaProd.Position.X := 18;
        CbModoBuscaProd.Position.Y := 59.2;
        CbModoBuscaProd.Width := Max(160, LInnerW - 68);
      end;
      if Assigned(CbModoBuscaPromocao) then
      begin
        CbModoBuscaPromocao.Position.X := 18;
        CbModoBuscaPromocao.Position.Y := 59.2;
        CbModoBuscaPromocao.Width := Max(160, LInnerW - 68);
      end;
      if Assigned(BtnBuscarProd) then
      begin
        BtnBuscarProd.Position.Y := 59.2;
        BtnBuscarProd.Width := 61.5;
        if Assigned(CbModoBuscaProd) then
          BtnBuscarProd.Position.X := CbModoBuscaProd.Position.X + CbModoBuscaProd.Width + 6
        else
          BtnBuscarProd.Position.X := 246;
      end;
      if Assigned(BtnBuscarPromocao) then
      begin
        BtnBuscarPromocao.Position.Y := 59.2;
        BtnBuscarPromocao.Width := 61.5;
        if Assigned(CbModoBuscaPromocao) then
          BtnBuscarPromocao.Position.X := CbModoBuscaPromocao.Position.X + CbModoBuscaPromocao.Width + 6
        else
          BtnBuscarPromocao.Position.X := 246;
      end;

      if Assigned(LayoutProdutosList) then
        LayoutProdutosList.Margins.Top := 10;
      if Assigned(LayoutPromocaoList) then
        LayoutPromocaoList.Margins.Top := 10;

      AjustarLarguraListView(LvProdutos, 110);
      AjustarLarguraListView(LvPromocao, 110);
    end;
  end;
  procedure AjustarClientePaisagem;
  var
    LGap: Single;
    LLeftX: Single;
    LTopY: Single;
    LColW: Single;
    LRightX: Single;
  begin
    if not Assigned(CardContatoDyn) or not Assigned(CardEnderecoDyn) then
      Exit;

    if LIsLandscape then
    begin
      LGap := 12;
      LColW := (ClientWidth - 48) / 2;
      LLeftX := 16;
      LRightX := LLeftX + LColW + 16;
      LTopY := 8;

      CardPerfil.Align := TAlignLayout.None;
      CardContatoDyn.Align := TAlignLayout.None;
      CardEnderecoDyn.Align := TAlignLayout.None;
      if Assigned(CardSituacao) then
        CardSituacao.Align := TAlignLayout.None;

      if Assigned(CardPerfil) then CardPerfil.Height := 120;
      if Assigned(CardSituacao) then CardSituacao.Height := 102;
      if Assigned(CardContatoDyn) then CardContatoDyn.Height := 96;
      if Assigned(CardEnderecoDyn) then CardEnderecoDyn.Height := 96;
      if Assigned(CardFormaPgto) then CardFormaPgto.Height := 72;
      if Assigned(Rectangle1) then Rectangle1.Height := 72;

      CardPerfil.Width := LColW;
      CardContatoDyn.Width := LColW;
      CardEnderecoDyn.Width := LColW;

      CardPerfil.Position.X := LLeftX;
      CardPerfil.Position.Y := LTopY;
      CardContatoDyn.Position.X := LLeftX;
      CardContatoDyn.Position.Y := LTopY + CardPerfil.Height + LGap;
      CardEnderecoDyn.Position.X := LRightX;
      CardEnderecoDyn.Position.Y := LTopY;

      if Assigned(LbNome) then LbNome.TextSettings.Font.Size := 18;
      if Assigned(LbDoc) then LbDoc.TextSettings.Font.Size := 16;
      if Assigned(LbCidade) then LbCidade.TextSettings.Font.Size := 16;
      if Assigned(LbSituacaoTitulo) then LbSituacaoTitulo.TextSettings.Font.Size := 17;
      if Assigned(LbLimite) then LbLimite.TextSettings.Font.Size := 16;
      if Assigned(LbSaldo) then LbSaldo.TextSettings.Font.Size := 16;
      if Assigned(LbContatoTituloDyn) then LbContatoTituloDyn.TextSettings.Font.Size := 17;
      if Assigned(LbTelefoneDyn) then LbTelefoneDyn.TextSettings.Font.Size := 16;
      if Assigned(LbEmailDyn) then LbEmailDyn.TextSettings.Font.Size := 16;
      if Assigned(LbEnderecoTituloDyn) then LbEnderecoTituloDyn.TextSettings.Font.Size := 17;
      if Assigned(LbEndereco1Dyn) then LbEndereco1Dyn.TextSettings.Font.Size := 16;
      if Assigned(LbEndereco2Dyn) then LbEndereco2Dyn.TextSettings.Font.Size := 16;
      if Assigned(lbFormaPgto) then lbFormaPgto.TextSettings.Font.Size := 16;
      if Assigned(lbPrazoPgto) then lbPrazoPgto.TextSettings.Font.Size := 16;
      if Assigned(Label3) then Label3.TextSettings.Font.Size := 16;
      if Assigned(Label2) then Label2.TextSettings.Font.Size := 16;
    end
    else if LIsTabletPortrait then
    begin
      LGap := 12;
      LColW := Min(ClientWidth - 36, 560);
      LLeftX := (ClientWidth - LColW) / 2;
      LTopY := 10;

      CardPerfil.Align := TAlignLayout.None;
      CardContatoDyn.Align := TAlignLayout.None;
      CardEnderecoDyn.Align := TAlignLayout.None;
      if Assigned(CardSituacao) then
        CardSituacao.Align := TAlignLayout.None;

      if Assigned(CardPerfil) then CardPerfil.Height := 112;
      if Assigned(CardSituacao) then CardSituacao.Height := 86;
      if Assigned(CardContatoDyn) then CardContatoDyn.Height := 96;
      if Assigned(CardEnderecoDyn) then CardEnderecoDyn.Height := 96;
      if Assigned(CardFormaPgto) then CardFormaPgto.Height := 66;
      if Assigned(Rectangle1) then Rectangle1.Height := 66;

      CardPerfil.Width := LColW;
      CardContatoDyn.Width := LColW;
      CardEnderecoDyn.Width := LColW;

      CardPerfil.Position.X := LLeftX;
      CardPerfil.Position.Y := LTopY;
      CardContatoDyn.Position.X := LLeftX;
      CardContatoDyn.Position.Y := CardPerfil.Position.Y + CardPerfil.Height + LGap;
      CardEnderecoDyn.Position.X := LLeftX;
      CardEnderecoDyn.Position.Y := CardContatoDyn.Position.Y + CardContatoDyn.Height + LGap;

      if Assigned(LbNome) then LbNome.TextSettings.Font.Size := 16;
      if Assigned(LbDoc) then LbDoc.TextSettings.Font.Size := 14;
      if Assigned(LbCidade) then LbCidade.TextSettings.Font.Size := 14;
      if Assigned(LbSituacaoTitulo) then LbSituacaoTitulo.TextSettings.Font.Size := 15;
      if Assigned(LbLimite) then LbLimite.TextSettings.Font.Size := 14;
      if Assigned(LbSaldo) then LbSaldo.TextSettings.Font.Size := 14;
      if Assigned(LbContatoTituloDyn) then LbContatoTituloDyn.TextSettings.Font.Size := 15;
      if Assigned(LbTelefoneDyn) then LbTelefoneDyn.TextSettings.Font.Size := 14;
      if Assigned(LbEmailDyn) then LbEmailDyn.TextSettings.Font.Size := 14;
      if Assigned(LbEnderecoTituloDyn) then LbEnderecoTituloDyn.TextSettings.Font.Size := 15;
      if Assigned(LbEndereco1Dyn) then LbEndereco1Dyn.TextSettings.Font.Size := 14;
      if Assigned(LbEndereco2Dyn) then LbEndereco2Dyn.TextSettings.Font.Size := 14;
      if Assigned(lbFormaPgto) then lbFormaPgto.TextSettings.Font.Size := 14;
      if Assigned(lbPrazoPgto) then lbPrazoPgto.TextSettings.Font.Size := 14;
      if Assigned(Label3) then Label3.TextSettings.Font.Size := 15;
      if Assigned(Label2) then Label2.TextSettings.Font.Size := 15;
    end
    else
    begin
      CardPerfil.Align := TAlignLayout.None;
      CardContatoDyn.Align := TAlignLayout.None;
      CardEnderecoDyn.Align := TAlignLayout.None;
      if Assigned(CardSituacao) then
        CardSituacao.Align := TAlignLayout.None;

      if Assigned(CardPerfil) then CardPerfil.Height := 95;
      if Assigned(CardSituacao) then CardSituacao.Height := 80;
      if Assigned(CardContatoDyn) then CardContatoDyn.Height := 88;
      if Assigned(CardEnderecoDyn) then CardEnderecoDyn.Height := 88;
      if Assigned(CardFormaPgto) then CardFormaPgto.Height := 60;
      if Assigned(Rectangle1) then Rectangle1.Height := 60;

      LGap := 10;
      CardPerfil.Width := 324;
      CardContatoDyn.Width := 324;
      CardEnderecoDyn.Width := 324;

      CardPerfil.Position.X := 18;
      CardPerfil.Position.Y := 10;
      CardContatoDyn.Position.X := 18;
      CardContatoDyn.Position.Y := CardPerfil.Position.Y + CardPerfil.Height + LGap;
      CardEnderecoDyn.Position.X := 18;
      CardEnderecoDyn.Position.Y := CardContatoDyn.Position.Y + CardContatoDyn.Height + LGap;

      if Assigned(LbNome) then LbNome.TextSettings.Font.Size := 15;
      if Assigned(LbDoc) then LbDoc.TextSettings.Font.Size := 13;
      if Assigned(LbCidade) then LbCidade.TextSettings.Font.Size := 13;
      if Assigned(LbSituacaoTitulo) then LbSituacaoTitulo.TextSettings.Font.Size := 14;
      if Assigned(LbLimite) then LbLimite.TextSettings.Font.Size := 13;
      if Assigned(LbSaldo) then LbSaldo.TextSettings.Font.Size := 13;
      if Assigned(LbContatoTituloDyn) then LbContatoTituloDyn.TextSettings.Font.Size := 14;
      if Assigned(LbTelefoneDyn) then LbTelefoneDyn.TextSettings.Font.Size := 13;
      if Assigned(LbEmailDyn) then LbEmailDyn.TextSettings.Font.Size := 13;
      if Assigned(LbEnderecoTituloDyn) then LbEnderecoTituloDyn.TextSettings.Font.Size := 14;
      if Assigned(LbEndereco1Dyn) then LbEndereco1Dyn.TextSettings.Font.Size := 13;
      if Assigned(LbEndereco2Dyn) then LbEndereco2Dyn.TextSettings.Font.Size := 13;
      if Assigned(lbFormaPgto) then lbFormaPgto.TextSettings.Font.Size := 13;
      if Assigned(lbPrazoPgto) then lbPrazoPgto.TextSettings.Font.Size := 13;
      if Assigned(Label3) then Label3.TextSettings.Font.Size := 14;
      if Assigned(Label2) then Label2.TextSettings.Font.Size := 14;
    end;

    if Assigned(CardFormaPgto) and (not CardFormaPgto.Visible) then
      CardFormaPgto.Height := 0;
    if Assigned(Rectangle1) and (not Rectangle1.Visible) then
      Rectangle1.Height := 0;
  end;
begin
  EnsureCardContatoEndereco;

  SyncCardsTotalPgtoTexto;

  if Assigned(CardSituacao) then
    CardSituacao.Visible := False;

  if Assigned(CardFormaPgtoTotal) then
    CardFormaPgtoTotal.Index := 0;
  if Assigned(CardPrazoPgtoTotal) then
    CardPrazoPgtoTotal.Index := 1;
  if Assigned(CardOrcamentoTotal) then
    CardOrcamentoTotal.Index := 2;
  if Assigned(CardTotais) then
    CardTotais.Index := 3;
  if Assigned(CardObservacoes) then
    CardObservacoes.Index := 4;

  if csDestroying in ComponentState then
    Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  LIsLandscape := ClientWidth > ClientHeight;
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 600);
  LBottomMargin := 0;

  if LIsLandscape then
    TopBar.Height := 72
  else begin
    TopBar.Height := 96;
    LBottomMargin := 50;
  end;
  LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) * 0.75;

  LFooterH := 50;
  LFooterTotalH := 36;
  LFooterW := Min(ClientWidth - 16, 560);
  if LFooterW < 260 then
    LFooterW := ClientWidth - 8;

  if LIsLandscape then
    LFooterTotalW := Min(ClientWidth - 32, 980)
  else
    LFooterTotalW := LFooterW;
  if LFooterTotalW < 260 then
    LFooterTotalW := ClientWidth - 8;

  LFooter := FindComponent('lyRod') as TLayout;
  if not Assigned(LFooter) then
    LFooter := FindComponent('layout1') as TLayout;
  LFooterTotal := FindComponent('lyRodTotal') as TLayout;

  if Assigned(LFooter) then
  begin
    LFooter.Align := TAlignLayout.None;
    LFooter.SetBounds((ClientWidth - LFooterW) * 0.5,
                      ClientHeight - LFooterH - LBottomMargin - 8,
                      LFooterW, LFooterH);
    LFooter.Margins.Bottom := LBottomMargin;

    LLeftArea := FindComponent('Layout2') as TLayout;
    LRightArea := FindComponent('Layout3') as TLayout;
    LBtnW := LFooter.Width * 0.5;
    if Assigned(LLeftArea) then
    begin
      LLeftArea.Align := TAlignLayout.None;
      // Layout2 contém BtnPedido (Gravar) -> direita
      LLeftArea.SetBounds(LBtnW, 0, LFooter.Width - LBtnW, LFooter.Height);
    end;
    if Assigned(LRightArea) then
    begin
      LRightArea.Align := TAlignLayout.None;
      // Layout3 contém BtnCancelar -> esquerda
      LRightArea.SetBounds(0, 0, LBtnW, LFooter.Height);
    end;
  end;

  if Assigned(LFooterTotal) and Assigned(LFooter) then
  begin
    LFooterTotal.Align := TAlignLayout.None;
    LFooterTotal.SetBounds((ClientWidth - LFooterTotalW) * 0.5,
                           LFooter.Position.Y - LFooterTotalH - 6,
                           LFooterTotalW, LFooterTotalH);
  end;

  LGap := 8;
  LTabsHeaderH := 54;
  LTabTop := TopBar.Height;

  EnsureTabHeader;
  if Assigned(FTabHeader) then
  begin
    FTabHeader.SetBounds(0, TopBar.Height, ClientWidth, LTabsHeaderH);
    FTabHeader.BringToFront;
    LTabTop := TopBar.Height + LTabsHeaderH;

    LBtnW := ClientWidth / (High(FTabButtons) + 1);
    for I := 0 to High(FTabButtons) do
      if Assigned(FTabButtons[I]) then
      begin
        FTabButtons[I].SetBounds(I * LBtnW, 0, LBtnW, FTabHeader.Height);
        if Assigned(FTabLabels[I]) then
        begin
          FTabLabels[I].SetBounds(I * LBtnW, 30, LBtnW, 18);
          FTabLabels[I].BringToFront;
        end;
      end;
  end;

  TabMenu.Align := TAlignLayout.None;
  TabMenu.TabPosition := TTabPosition.None;
  if Assigned(LFooterTotal) then
    LTabH := LFooterTotal.Position.Y - LTabTop - LGap
  else if Assigned(LFooter) then
    LTabH := LFooter.Position.Y - LTabTop - LGap
  else
    LTabH := ClientHeight - LTabTop - LGap;
  if LTabH < 120 then
    LTabH := 120;
  TabMenu.SetBounds(0, LTabTop, ClientWidth, LTabH);
  AtualizarEstadoCabecalhoAbas;

  // Em paisagem, amplia a largura útil de texto das ListViews para evitar cortes.
  if LIsLandscape then
  begin
    AjustarLarguraListView(LvUltimasCompras, 78);
    AjustarLarguraListView(LvDigitados, 78);
  end
  else
  begin
    AjustarLarguraListView(LvUltimasCompras, 105);
    AjustarLarguraListView(LvDigitados, 105);
  end;

  LProdutosScroll := FindComponent('ScrollBox1') as TControl;
  LProdutosRoot := FindComponent('LayoutProdutosRoot') as TControl;
  LPromocaoRoot := FindComponent('LayoutPromocao') as TControl;
  LPromocaoList := FindComponent('LayoutPromocaoList') as TControl;
  if LIsLandscape or LIsTabletPortrait then
  begin
    if LIsLandscape then
      LListW := Min(ClientWidth - 32, 980)
    else
      LListW := Min(ClientWidth - 32, 680);
    if LListW < 320 then
      LListW := ClientWidth - 20;
    LListX := Max(10, (ClientWidth - LListW) / 2);

    if Assigned(LProdutosScroll) then
    begin
      LProdutosScroll.Align := TAlignLayout.None;
      LProdutosScroll.SetBounds(0, 0, ClientWidth, TabMenu.Height);
    end;
    if Assigned(LProdutosRoot) then
    begin
      LProdutosRoot.Align := TAlignLayout.None;
      LProdutosRoot.SetBounds(LListX, 0, LListW, TabMenu.Height);
    end;
    if Assigned(CardBuscaProd) then
    begin
      CardBuscaProd.Align := TAlignLayout.None;
      CardBuscaProd.SetBounds(0, 8, LListW, CardBuscaProd.Height);
    end;
    if Assigned(LayoutProdutosList) and Assigned(CardBuscaProd) then
    begin
      LayoutProdutosList.Align := TAlignLayout.None;
      LayoutProdutosList.SetBounds(0, CardBuscaProd.Position.Y + CardBuscaProd.Height + 6,
        LListW, Max(120, TabMenu.Height - CardBuscaProd.Position.Y - CardBuscaProd.Height - 16));
    end;
    if Assigned(LvProdutos) and Assigned(LayoutProdutosList) then
    begin
      LvProdutos.Align := TAlignLayout.None;
      LvProdutos.SetBounds(0, 0, LayoutProdutosList.Width, LayoutProdutosList.Height);
    end;
    if Assigned(LPromocaoRoot) then
    begin
      LPromocaoRoot.Align := TAlignLayout.None;
      LPromocaoRoot.SetBounds(LListX, 8, LListW, Max(120, TabMenu.Height - 16));
    end;
    if Assigned(CardBuscaPromocao) then
    begin
      CardBuscaPromocao.Align := TAlignLayout.None;
      CardBuscaPromocao.SetBounds(0, 0, LListW, CardBuscaPromocao.Height);
    end;
    if Assigned(LPromocaoList) and Assigned(CardBuscaPromocao) then
    begin
      LPromocaoList.Align := TAlignLayout.None;
      LPromocaoList.SetBounds(0, CardBuscaPromocao.Position.Y + CardBuscaPromocao.Height + 6,
        LListW, Max(120, LPromocaoRoot.Height - CardBuscaPromocao.Position.Y - CardBuscaPromocao.Height - 8));
    end;
    if Assigned(LvPromocao) and Assigned(LPromocaoList) then
    begin
      LvPromocao.Align := TAlignLayout.None;
      LvPromocao.SetBounds(0, 0, LPromocaoList.Width, LPromocaoList.Height);
    end;
  end
  else
  begin
    if Assigned(LProdutosScroll) then
      LProdutosScroll.Align := TAlignLayout.Client;
    if Assigned(LProdutosRoot) then
      LProdutosRoot.Align := TAlignLayout.Client;
    if Assigned(CardBuscaProd) then
      CardBuscaProd.Align := TAlignLayout.Top;
    if Assigned(LayoutProdutosList) then
      LayoutProdutosList.Align := TAlignLayout.Client;
    if Assigned(LvProdutos) then
      LvProdutos.Align := TAlignLayout.Client;
    if Assigned(LPromocaoRoot) then
      LPromocaoRoot.Align := TAlignLayout.Client;
    if Assigned(CardBuscaPromocao) then
      CardBuscaPromocao.Align := TAlignLayout.Top;
    if Assigned(LPromocaoList) then
      LPromocaoList.Align := TAlignLayout.Client;
    if Assigned(LvPromocao) then
      LvPromocao.Align := TAlignLayout.Client;
  end;

  AjustarProdutosPaisagem;

  if LIsLandscape or LIsTabletPortrait then
  begin
    if Assigned(LayoutProdutosList) and Assigned(CardBuscaProd) then
      LayoutProdutosList.SetBounds(0, CardBuscaProd.Position.Y + CardBuscaProd.Height + 6,
        LListW, Max(120, TabMenu.Height - CardBuscaProd.Position.Y - CardBuscaProd.Height - 16));
    if Assigned(LvProdutos) and Assigned(LayoutProdutosList) then
      LvProdutos.SetBounds(0, 0, LayoutProdutosList.Width, LayoutProdutosList.Height);
    if Assigned(LPromocaoRoot) then
      LPromocaoRoot.SetBounds(LListX, 8, LListW, Max(120, TabMenu.Height - 16));
    if Assigned(CardBuscaPromocao) then
      CardBuscaPromocao.SetBounds(0, 0, LListW, CardBuscaPromocao.Height);
    if Assigned(LPromocaoList) and Assigned(CardBuscaPromocao) then
      LPromocaoList.SetBounds(0, CardBuscaPromocao.Position.Y + CardBuscaPromocao.Height + 6,
        LListW, Max(120, LPromocaoRoot.Height - CardBuscaPromocao.Position.Y - CardBuscaPromocao.Height - 8));
    if Assigned(LvPromocao) and Assigned(LPromocaoList) then
      LvPromocao.SetBounds(0, 0, LPromocaoList.Width, LPromocaoList.Height);
    AjustarLarguraListView(LvProdutos, 112);
    AjustarLarguraListView(LvPromocao, 112);
  end;

  if Assigned(PresentedScrollBox1) then
    PresentedScrollBox1.Padding.Bottom := 8;

  AjustarClientePaisagem;
  AjustarCardContatoEndereco;

  if Assigned(LayoutDigitadosAcoes) and Assigned(BtnEditarDigitado) and Assigned(BtnExcluirDigitado) then
  begin
    BtnEditarDigitado.Align := TAlignLayout.None;
    BtnExcluirDigitado.Align := TAlignLayout.None;
    BtnEditarDigitado.Margins.Left := 0;
    BtnEditarDigitado.Margins.Right := 0;
    BtnExcluirDigitado.Margins.Left := 0;
    BtnExcluirDigitado.Margins.Right := 0;

    LGap := 12;
    LBtnW := (LayoutDigitadosAcoes.Width - LGap) / 2;
    if LBtnW < 80 then
      LBtnW := 80;
    // Invertido: Excluir à esquerda, Editar à direita
    BtnExcluirDigitado.SetBounds(0, 0, LBtnW, LayoutDigitadosAcoes.Height);
    BtnEditarDigitado.SetBounds(LBtnW + LGap, 0, LBtnW, LayoutDigitadosAcoes.Height);
  end;

  if Assigned(LFooterTotal) then
    LFooterTotal.BringToFront;
  if Assigned(LFooter) then
    LFooter.BringToFront;
end;

procedure TfrmPedido.AjustarCardContatoEndereco;
var
  LIsLandscape: Boolean;
  LIsTabletPortrait: Boolean;
  LInnerContato: Single;
  LInnerEndereco: Single;
  LEndereco1H: Single;
  LEndereco2H: Single;
begin
  if not Assigned(CardContatoDyn) or not Assigned(CardEnderecoDyn) then
    Exit;

  LIsLandscape := ClientWidth > ClientHeight;
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 430);

  LInnerContato := Max(120, CardContatoDyn.Width - 40);
  LInnerEndereco := Max(120, CardEnderecoDyn.Width - 40);

  if Assigned(LbContatoTituloDyn) then
    LbContatoTituloDyn.SetBounds(20, 10, LInnerContato, 20);
  if Assigned(LbTelefoneDyn) then
    LbTelefoneDyn.SetBounds(20, 36, LInnerContato, 20);
  if Assigned(LbEmailDyn) then
  begin
    LbEmailDyn.TextSettings.WordWrap := False;
    LbEmailDyn.SetBounds(20, 58, LInnerContato, 20);
  end;

  if Assigned(LbEnderecoTituloDyn) then
    LbEnderecoTituloDyn.SetBounds(20, 12, LInnerEndereco, 20);

  if LIsLandscape then
  begin
    LEndereco1H := 24;
    LEndereco2H := 24;
    CardEnderecoDyn.Height := 96;
  end
  else if LIsTabletPortrait then
  begin
    LEndereco1H := 34;
    LEndereco2H := 30;
    CardEnderecoDyn.Height := 116;
  end
  else
  begin
    LEndereco1H := 38;
    LEndereco2H := 34;
    CardEnderecoDyn.Height := 124;
  end;

  if Assigned(LbEndereco1Dyn) then
  begin
    LbEndereco1Dyn.TextSettings.WordWrap := True;
    LbEndereco1Dyn.SetBounds(20, 40, LInnerEndereco, LEndereco1H);
  end;
  if Assigned(LbEndereco2Dyn) then
  begin
    LbEndereco2Dyn.TextSettings.WordWrap := True;
    LbEndereco2Dyn.SetBounds(20, 40 + LEndereco1H + 4, LInnerEndereco, LEndereco2H);
  end;
end;
procedure TfrmPedido.EnsureCardContatoEndereco;
begin
  if not Assigned(PresentedScrollBox1) then
    Exit;

  if not Assigned(CardContatoDyn) then
  begin
    CardContatoDyn := TRectangle.Create(Self);
    CardContatoDyn.Parent := PresentedScrollBox1;
    CardContatoDyn.Align := TAlignLayout.MostTop;
    CardContatoDyn.Margins.Left := 10;
    CardContatoDyn.Margins.Top := 10;
    CardContatoDyn.Margins.Right := 10;
    CardContatoDyn.Margins.Bottom := 10;
    CardContatoDyn.Height := 80;
    CardContatoDyn.Fill.Color := TAlphaColorRec.White;
    CardContatoDyn.Stroke.Kind := TBrushKind.None;
    CardContatoDyn.XRadius := 15;
    CardContatoDyn.YRadius := 15;
    CardContatoDyn.Visible := True;

    LbContatoTituloDyn := TLabel.Create(Self);
    LbContatoTituloDyn.Parent := CardContatoDyn;
    LbContatoTituloDyn.Align := TAlignLayout.None;
    LbContatoTituloDyn.Margins.Left := 20;
    LbContatoTituloDyn.Margins.Top := 10;
    LbContatoTituloDyn.Margins.Right := 20;
    LbContatoTituloDyn.SetBounds(20, 10, CardContatoDyn.Width - 40, 18);
    LbContatoTituloDyn.StyledSettings := [];
    LbContatoTituloDyn.TextSettings.Font.Size := 14;
    LbContatoTituloDyn.TextSettings.FontColor := TAlphaColor($FF1D2939);
    LbContatoTituloDyn.Text := 'Contato';

    LbTelefoneDyn := TLabel.Create(Self);
    LbTelefoneDyn.Parent := CardContatoDyn;
    LbTelefoneDyn.Align := TAlignLayout.None;
    LbTelefoneDyn.SetBounds(20, 36, CardContatoDyn.Width - 40, 16);
    LbTelefoneDyn.StyledSettings := [];
    LbTelefoneDyn.TextSettings.Font.Size := 13;
    LbTelefoneDyn.TextSettings.FontColor := TAlphaColor($FF6B7280);

    LbEmailDyn := TLabel.Create(Self);
    LbEmailDyn.Parent := CardContatoDyn;
    LbEmailDyn.Align := TAlignLayout.None;
    LbEmailDyn.SetBounds(20, 56, CardContatoDyn.Width - 40, 16);
    LbEmailDyn.StyledSettings := [];
    LbEmailDyn.TextSettings.Font.Size := 13;
    LbEmailDyn.TextSettings.FontColor := TAlphaColor($FF6B7280);
  end;

  if not Assigned(CardEnderecoDyn) then
  begin
    CardEnderecoDyn := TRectangle.Create(Self);
    CardEnderecoDyn.Parent := PresentedScrollBox1;
    CardEnderecoDyn.Align := TAlignLayout.MostTop;
    CardEnderecoDyn.Margins.Left := 10;
    CardEnderecoDyn.Margins.Top := 10;
    CardEnderecoDyn.Margins.Right := 10;
    CardEnderecoDyn.Margins.Bottom := 10;
    CardEnderecoDyn.Height := 80;
    CardEnderecoDyn.Fill.Color := TAlphaColorRec.White;
    CardEnderecoDyn.Stroke.Kind := TBrushKind.None;
    CardEnderecoDyn.XRadius := 15;
    CardEnderecoDyn.YRadius := 15;
    CardEnderecoDyn.Visible := True;

    LbEnderecoTituloDyn := TLabel.Create(Self);
    LbEnderecoTituloDyn.Parent := CardEnderecoDyn;
    LbEnderecoTituloDyn.Align := TAlignLayout.None;
    LbEnderecoTituloDyn.Margins.Left := 20;
    LbEnderecoTituloDyn.Margins.Top := 10;
    LbEnderecoTituloDyn.Margins.Right := 20;
    LbEnderecoTituloDyn.SetBounds(20, 10, CardEnderecoDyn.Width - 40, 18);
    LbEnderecoTituloDyn.StyledSettings := [];
    LbEnderecoTituloDyn.TextSettings.Font.Size := 14;
    LbEnderecoTituloDyn.TextSettings.FontColor := TAlphaColor($FF1D2939);
    LbEnderecoTituloDyn.Text := 'Endereço';

    LbEndereco1Dyn := TLabel.Create(Self);
    LbEndereco1Dyn.Parent := CardEnderecoDyn;
    LbEndereco1Dyn.Align := TAlignLayout.None;
    LbEndereco1Dyn.SetBounds(20, 36, CardEnderecoDyn.Width - 40, 16);
    LbEndereco1Dyn.StyledSettings := [];
    LbEndereco1Dyn.TextSettings.WordWrap := True;
    LbEndereco1Dyn.TextSettings.Font.Size := 13;
    LbEndereco1Dyn.TextSettings.FontColor := TAlphaColor($FF6B7280);

    LbEndereco2Dyn := TLabel.Create(Self);
    LbEndereco2Dyn.Parent := CardEnderecoDyn;
    LbEndereco2Dyn.Align := TAlignLayout.None;
    LbEndereco2Dyn.SetBounds(20, 56, CardEnderecoDyn.Width - 40, 16);
    LbEndereco2Dyn.StyledSettings := [];
    LbEndereco2Dyn.TextSettings.WordWrap := True;
    LbEndereco2Dyn.TextSettings.Font.Size := 13;
    LbEndereco2Dyn.TextSettings.FontColor := TAlphaColor($FF6B7280);
  end;

  // Mantém ordem igual ao unClienteDetalhe: Perfil -> Contato -> Endereço.
  if Assigned(CardPerfil) then
  begin
    CardContatoDyn.Index := CardPerfil.Index + 1;
    CardEnderecoDyn.Index := CardContatoDyn.Index + 1;
  end;

  CardContatoDyn.Visible := True;
  CardEnderecoDyn.Visible := True;

  if Assigned(LbTelefoneDyn) then
  begin
    if FContatoTelefone <> '' then
      LbTelefoneDyn.Text := 'Telefone: ' + FContatoTelefone
    else
      LbTelefoneDyn.Text := 'Telefone: --';
  end;
  if Assigned(LbEmailDyn) then
  begin
    if FContatoEmail <> '' then
      LbEmailDyn.Text := 'Email: ' + FContatoEmail
    else
      LbEmailDyn.Text := 'Email: --';
  end;
  if Assigned(LbEndereco1Dyn) then
  begin
    if FEndereco1 <> '' then
      LbEndereco1Dyn.Text := FEndereco1
    else
      LbEndereco1Dyn.Text := '--';
  end;
  if Assigned(LbEndereco2Dyn) then
  begin
    if FEndereco2 <> '' then
      LbEndereco2Dyn.Text := FEndereco2
    else
      LbEndereco2Dyn.Text := '--';
  end;

  AjustarCardContatoEndereco;
end;

procedure TfrmPedido.SyncCardsTotalPgtoTexto;
begin
{  if Assigned(ImgFormaPgtoTotal) and Assigned(ImgFormaPgto) and
     Assigned(ImgFormaPgto.MultiResBitmap) and Assigned(ImgFormaPgtoTotal.MultiResBitmap) then
    ImgFormaPgtoTotal.MultiResBitmap.Assign(ImgFormaPgto.MultiResBitmap);
  if Assigned(ImgPrazoPgtoTotal) and Assigned(imgPrazoPgto) and
     Assigned(imgPrazoPgto.MultiResBitmap) and Assigned(ImgPrazoPgtoTotal.MultiResBitmap) then
    ImgPrazoPgtoTotal.MultiResBitmap.Assign(imgPrazoPgto.MultiResBitmap);}

  if Assigned(LbFormaPgtoTotal) and Assigned(lbFormaPgto) then
    LbFormaPgtoTotal.Text := lbFormaPgto.Text;
  if Assigned(LbPrazoPgtoTotal) and Assigned(lbPrazoPgto) then
    LbPrazoPgtoTotal.Text := lbPrazoPgto.Text;
end;

function TfrmPedido.CountPrazosFormaPgto(const ACodFop: Integer): Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  if ACodFop <= 0 then
    Exit;
  if not Assigned(dmApp) then
    Exit;
  if not dmApp.FDConnection.Connected then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select count(*) as total from fop_prazo where cod_fop = :p0';
    Q.ParamByName('p0').AsInteger := ACodFop;
    Q.Open;
    Result := Q.FieldByName('total').AsInteger;
  finally
    Q.Free;
  end;
end;

function TfrmPedido.PrazoPertenceFormaPgto(const ACodFop, ACodPrazo: Integer): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  if (ACodFop <= 0) or (ACodPrazo <= 0) then
    Exit;
  if not Assigned(dmApp) then
    Exit;
  if not dmApp.FDConnection.Connected then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select 1 from fop_prazo where cod_fop = :p0 and id_prazo = :p1 limit 1';
    Q.ParamByName('p0').AsInteger := ACodFop;
    Q.ParamByName('p1').AsInteger := ACodPrazo;
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TfrmPedido.AplicarPrazoFormaPgto;
var
  Q: TFDQuery;
  LTotal: Integer;
  LCodPrazo: Integer;
  LNomePrazo: string;
begin
  if codFormaPgto <= 0 then
    Exit;

  LTotal := CountPrazosFormaPgto(codFormaPgto);
  if LTotal <= 0 then
    Exit;

  if LTotal > 1 then
  begin
    if (codPrazoPgto > 0) and (not PrazoPertenceFormaPgto(codFormaPgto, codPrazoPgto)) then
      SelecionarPrazoPgto(0, '');
    Exit;
  end;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select p.id as codigo, p.prazo as nome ' +
      'from fop_prazo fp inner join prazo p on p.id = fp.id_prazo ' +
      'where fp.cod_fop = :p0 limit 1';
    Q.ParamByName('p0').AsInteger := codFormaPgto;
    Q.Open;
    if not Q.Eof then
    begin
      LCodPrazo := Q.FieldByName('codigo').AsInteger;
      LNomePrazo := Q.FieldByName('nome').AsString;
      SelecionarPrazoPgto(LCodPrazo, LNomePrazo);
    end;
  finally
    Q.Free;
  end;
end;
procedure TfrmPedido.SelecionarFormaPgto(const ACodigo: Integer; const ANome: string);
begin
  codFormaPgto := ACodigo;
  if Trim(ANome) <> '' then
    lbFormaPgto.Text := ANome
  else if ACodigo > 0 then
    lbFormaPgto.Text := ACodigo.ToString
  else
    lbFormaPgto.Text := 'Clique para Selecionar';

  AplicarPrazoFormaPgto;
  SyncCardsTotalPgtoTexto;
  AtualizarOutboundPedido;
end;

procedure TfrmPedido.SelecionarPrazoPgto(const ACodigo: Integer; const ANome: string);
begin
  codPrazoPgto := ACodigo;
  if Trim(ANome) <> '' then
    lbPrazoPgto.Text := ANome
  else if ACodigo > 0 then
    lbPrazoPgto.Text := ACodigo.ToString
  else
    lbPrazoPgto.Text := 'Clique para Selecionar';

  SyncCardsTotalPgtoTexto;
  AtualizarOutboundPedido;
end;

procedure TfrmPedido.FecharPedido;
begin
  if FVoltarParaPedidosDigitados then
  begin
    if not Assigned(frmPedidosDigitados) then
      Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
    frmPedidosDigitados.Show;
    FVoltarParaPedidosDigitados := False;
  end;
  Close;
end;

procedure TfrmPedido.CancelarPedidoAtual;
var
  Q: TFDQuery;
begin
  // Somente para novo pedido: remove o draft ao cancelar
  if FVoltarParaPedidosDigitados then
    Exit;
  if outboundPedidoId <= 0 then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'delete from outbound_pedido_item where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := outboundPedidoId;
    Q.ExecSQL;

    Q.SQL.Text := 'delete from outbound_pedido where id = :p0';
    Q.ParamByName('p0').AsInteger := outboundPedidoId;
    Q.ExecSQL;

    outboundPedidoId := 0;
    dmApp.ClearAppState('pedido');
  finally
    Q.Free;
  end;
end;

function TfrmPedido.GetTabelaCols(const ATabela: string): TArray<string>;
var
  LQuery: TFDQuery;
  LList: TList<string>;
begin
  LList := TList<string>.Create;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := 'PRAGMA table_info("' + ATabela + '")';
    LQuery.Open;
    while not LQuery.Eof do
    begin
      LList.Add(LQuery.FieldByName('name').AsString.ToLower);
      LQuery.Next;
    end;
    Result := LList.ToArray;
  finally
    LQuery.Free;
    LList.Free;
  end;
end;

function TfrmPedido.FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
var
  C: string;
  Col: string;
begin
  Result := '';
  for C in ACandidatos do
  begin
    for Col in ACols do
      if SameText(Col, C) then
        Exit(C);
  end;
end;

function TfrmPedido.SafeFieldAsFloat(AQuery: TFDQuery; const ACampo: string): Double;
begin
  if AQuery.FindField(ACampo) <> nil then
    Result := AQuery.FieldByName(ACampo).AsFloat
  else
    Result := 0;
end;

function SafeFieldAsDate(AQuery: TFDQuery; const ACampo: string): TDateTime;
var
  LField: TField;
  S: string;
  FS: TFormatSettings;
begin
  Result := 0;
  LField := AQuery.FindField(ACampo);
  if (LField = nil) or LField.IsNull then
    Exit;

  if LField.DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
  begin
    Result := LField.AsDateTime;
    Exit;
  end;

  S := Trim(LField.AsString);
  if S = '' then
    Exit;

  if TryISO8601ToDate(S, Result, True) then
    Exit;

  FS := TFormatSettings.Create('pt-BR');
  if not TryStrToDateTime(S, Result, FS) then
  begin
    FS.DateSeparator := '-';
    FS.ShortDateFormat := 'yyyy-mm-dd';
    FS.TimeSeparator := ':';
    FS.LongTimeFormat := 'hh:nn:ss';
    TryStrToDateTime(S, Result, FS);
  end;
end;

function TfrmPedido.SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
begin
  if AQuery.FindField(ACampo) <> nil then
    Result := AQuery.FieldByName(ACampo).AsString
  else
    Result := '';
end;

function TfrmPedido.SafeFieldAsCurrency(AQuery: TFDQuery; const ACampo: string): Currency;
begin
  if AQuery.FindField(ACampo) <> nil then
    Result := AQuery.FieldByName(ACampo).AsCurrency
  else
    Result := 0;
end;

function TfrmPedido.FormatarNumero(const AValue: Double; const ADecimals: Integer): string;
var
  LMask: string;
begin
  if ADecimals <= 0 then
    LMask := '#,##0'
  else
    LMask := '#,##0.' + StringOfChar('0', ADecimals);
  Result := FormatFloat(LMask, AValue);
end;

function TfrmPedido.FormatarMoeda(const AValue: Double): string;
begin
  Result := 'R$ ' + FormatarNumero(AValue, 2);
end;

function TfrmPedido.ObterCodRepresentanteLocal: Integer;
var
  LQuery: TFDQuery;
begin
  Result := 0;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;

    LQuery.SQL.Text := 'select coalesce(value, '''') as value from app_config where key = :p0';
    LQuery.ParamByName('p0').AsString := 'cod_representante';
    LQuery.Open;
    if not LQuery.Eof then
      Result := StrToIntDef(Trim(LQuery.FieldByName('value').AsString), 0);
    LQuery.Close;

    if Result <= 0 then
    begin
      LQuery.SQL.Text := 'select id from representante where id is not null order by id limit 1';
      LQuery.Open;
      if not LQuery.Eof then
        Result := LQuery.FieldByName('id').AsInteger;
    end;
  finally
    LQuery.Free;
  end;
end;

function TfrmPedido.CalcularPercComissaoProduto(const ACodProduto: string; const ADescPct: Double;
  const ACodRepresentante: Integer; const AFuncionario: string): Double;
var
  LQuery: TFDQuery;
  LInicial: Double;
  LEscalaComissao: Double;
  LEscalaDesconto: Double;
  LInterno: Boolean;
  LPercFixo: Double;
begin
  Result := 0;
  if Trim(ACodProduto) = '' then
    Exit;

  LInterno := SameText(Trim(AFuncionario), '1');
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select perc_comissao_func, perc_comissao_terc ' +
      'from escala_comissao ' +
      'where desconto <= :pdesc ' +
      'order by desconto desc ' +
      'limit 1';
    LQuery.ParamByName('pdesc').AsFloat := ADescPct;
    try
      LQuery.Open;
    except
      LQuery.Close;
    end;
    if (LQuery.Active) and (not LQuery.Eof) then
    begin
      if LInterno then
        Result := SafeFieldAsFloat(LQuery, 'perc_comissao_func')
      else
        Result := SafeFieldAsFloat(LQuery, 'perc_comissao_terc');
      if Result > 0 then
        Exit;
    end;
    LQuery.Close;

    LQuery.SQL.Text :=
      'select ' +
      '  case when :interno = 1 then coalesce(gc.comissao_interno, 0) ' +
      '       else coalesce(gc.comissao_outros, 0) end as perc_comissao ' +
      'from produto p ' +
      'inner join grade_comissao gc on upper(trim(gc.tipo)) = upper(trim(p.grade_comissao)) ' +
      'where p.cod_produto = :prod ' +
      '  and :pdesc between coalesce(gc.inicio, 0) and coalesce(gc.fim, 999999) ' +
      'order by gc.inicio desc ' +
      'limit 1';
    LQuery.ParamByName('interno').AsInteger := Ord(LInterno);
    LQuery.ParamByName('prod').AsString := ACodProduto;
    LQuery.ParamByName('pdesc').AsFloat := ADescPct;
    try
      LQuery.Open;
    except
      LQuery.Close;
    end;
    if (LQuery.Active) and (not LQuery.Eof) then
    begin
      Result := SafeFieldAsFloat(LQuery, 'perc_comissao');
      if Result > 0 then
        Exit;
    end;
    LQuery.Close;

    LQuery.SQL.Text :=
      'select ' +
      ' coalesce(pr.comissao_inicial_interno, p.comissao_inicial_interno, gr.comissao_inicial_interno, 0) as com_ini_int, ' +
      ' coalesce(pr.comissao_inicial_outros, p.comissao_inicial_outros, gr.comissao_inicial_outros, 0) as com_ini_out, ' +
      ' coalesce(pr.escala_comissao_interno, p.escala_comissao_interno, gr.escala_comissao_interno, 0) as esc_com_int, ' +
      ' coalesce(pr.escala_comissao_outros, p.escala_comissao_outros, gr.escala_comissao_outros, 0) as esc_com_out, ' +
      ' coalesce(pr.escala_desconto, p.escala_desconto, gr.escala_desconto, 0) as esc_desc ' +
      'from produto p ' +
      'left join produto_representante pr on pr.cod_produto = p.cod_produto and pr.id_representante = :rep ' +
      'left join grupo_representante gr on gr.cod_grupo = p.cod_grupo and gr.id_representante = :rep ' +
      'where p.cod_produto = :prod ' +
      'limit 1';
    LQuery.ParamByName('rep').AsInteger := ACodRepresentante;
    LQuery.ParamByName('prod').AsString := ACodProduto;
    try
      LQuery.Open;
    except
      Exit;
    end;
    if LQuery.Eof then
      Exit;

    if LInterno then
    begin
      LInicial := SafeFieldAsFloat(LQuery, 'com_ini_int');
      LEscalaComissao := SafeFieldAsFloat(LQuery, 'esc_com_int');
    end
    else
    begin
      LInicial := SafeFieldAsFloat(LQuery, 'com_ini_out');
      LEscalaComissao := SafeFieldAsFloat(LQuery, 'esc_com_out');
    end;
    LEscalaDesconto := SafeFieldAsFloat(LQuery, 'esc_desc');

    Result := LInicial;
    if (LEscalaDesconto > 0) and (LEscalaComissao <> 0) and (ADescPct > 0) then
      Result := Result - ((ADescPct / LEscalaDesconto) * LEscalaComissao);

    if Result < 0 then
      Result := 0;

    if Result <= 0 then
    begin
      LQuery.Close;
      LQuery.SQL.Text :=
        'select coalesce(perc_comissao_fixa, 0) as perc_comissao_fixa ' +
        'from representante where id = :rep limit 1';
      LQuery.ParamByName('rep').AsInteger := ACodRepresentante;
      try
        LQuery.Open;
      except
        Exit;
      end;
      if not LQuery.Eof then
      begin
        LPercFixo := SafeFieldAsFloat(LQuery, 'perc_comissao_fixa');
        if LPercFixo > 0 then
          Result := LPercFixo;
      end;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPedido.CarregarSituacaoDoSqlite(const ACodigo: string);
var
  Q: TFDQuery;
  LStatus: string;
  LBloqueado: string;
  LCNPJ: string;
  LCPF: string;
  LLimite: Currency;
  LSaldo: Currency;
begin
  if ACodigo = '' then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'SELECT A.STATUS, A.CLIENTE_BLOQUEADO, A.LIMITE, A.SALDO, A.CNPJ, A.CPF, ' +
      'A.TELEFONE, A.CELULAR, A.EMAIL, A.EMAIL_END_NFE, A.ENDERECO, A.NR_ENDERECO, ' +
      'A.BAIRRO, A.CEP, A.COMPLEMENTO, C.NOM_CIDADE ' +
      'FROM CLIENTE A ' +
      'LEFT JOIN CIDADES C ON C.COD_CIDADE = A.COD_CIDADE ' +
      'WHERE A.COD_CLIENTE = :ID';
    Q.ParamByName('id').AsString := ACodigo;
    Q.Open;
    if not Q.Eof then
    begin
      LStatus := SafeFieldAsString(Q, 'STATUS');
      LBloqueado := SafeFieldAsString(Q, 'CLIENTE_BLOQUEADO');
      LCNPJ := SafeFieldAsString(Q, 'CNPJ');
      LCPF := SafeFieldAsString(Q, 'CPF');
      LLimite := SafeFieldAsCurrency(Q, 'LIMITE');
      LSaldo := SafeFieldAsCurrency(Q, 'SALDO');

      if LCNPJ <> '' then
        FClienteDoc := 'CNPJ: ' + LCNPJ
      else if LCPF <> '' then
        FClienteDoc := 'CPF: ' + LCPF
      else
        FClienteDoc := '';

      if Assigned(LbDocDireita) then
        LbDocDireita.Text := FClienteDoc;

      if (LStatus <> '') or (LBloqueado <> '') then
        LbSituacaoTitulo.Text := 'Situacao: ' + Trim(LStatus + ' ' + LBloqueado)
      else
        LbSituacaoTitulo.Text := 'Situacao: --';

      LbLimite.Text := 'Limite: ' + FormatarMoeda(LLimite);
      LbSaldo.Text := 'Saldo: ' + FormatarMoeda(LSaldo);

      FContatoTelefone := Trim(SafeFieldAsString(Q, 'TELEFONE'));
      if FContatoTelefone = '' then
        FContatoTelefone := Trim(SafeFieldAsString(Q, 'CELULAR'));

      FContatoEmail := Trim(SafeFieldAsString(Q, 'EMAIL'));
      if FContatoEmail = '' then
        FContatoEmail := Trim(SafeFieldAsString(Q, 'EMAIL_END_NFE'));

      FEndereco1 := Trim(SafeFieldAsString(Q, 'ENDERECO'));
      if Trim(SafeFieldAsString(Q, 'NR_ENDERECO')) <> '' then
        FEndereco1 := Trim(FEndereco1 + ', ' + SafeFieldAsString(Q, 'NR_ENDERECO'));

      FEndereco2 := Trim(SafeFieldAsString(Q, 'BAIRRO'));
      if Trim(SafeFieldAsString(Q, 'CEP')) <> '' then
        FEndereco2 := Trim(FEndereco2 + ' - ' + SafeFieldAsString(Q, 'CEP'));
      if Trim(SafeFieldAsString(Q, 'COMPLEMENTO')) <> '' then
        FEndereco2 := Trim(FEndereco2 + ' | ' + SafeFieldAsString(Q, 'COMPLEMENTO'));
      if Trim(SafeFieldAsString(Q, 'NOM_CIDADE')) <> '' then
        FEndereco2 := Trim(FEndereco2 + ' | ' + SafeFieldAsString(Q, 'NOM_CIDADE'));

      EnsureCardContatoEndereco;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmPedido.PararCargaImagensProdutos;
begin
  if Assigned(FProdutoImagemTimer) then
    FProdutoImagemTimer.Enabled := False;
  FProdutoImagemCursor := 0;
  FProdutoImagemListView := nil;
end;

procedure TfrmPedido.IniciarCargaImagensProdutos(const ACampoImagem: string; AListView: TListView);
var
  LListView: TListView;
begin
  PararCargaImagensProdutos;

  LListView := AListView;
  if LListView = nil then
    LListView := LvProdutos;

  if (Trim(ACampoImagem) = '') or (not Assigned(LListView)) or (LListView.Items.Count = 0) then
    Exit;

  FProdutoImagemListView := LListView;
  FProdutoImagemCampoImagem := ACampoImagem;
  FProdutoImagemCursor := 0;

  if not Assigned(FProdutoImagemCache) then
    FProdutoImagemCache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);

  if not Assigned(FProdutoImagemTimer) then
  begin
    FProdutoImagemTimer := TTimer.Create(Self);
    FProdutoImagemTimer.Interval := 250;
    FProdutoImagemTimer.OnTimer := ProdutoImagemTimer;
  end;

  FProdutoImagemTimer.Enabled := True;
end;

function TfrmPedido.CarregarImagemSubcategoria(const ASubId, ACampoImagem: string): TBitmap;
var
  LQuery: TFDQuery;
  LField: TField;
  LStream: TMemoryStream;
  LBmp: TBitmap;
begin
  Result := nil;
  if (Trim(ASubId) = '') or (Trim(ACampoImagem) = '') then
    Exit;

  if Assigned(FProdutoImagemCache) and FProdutoImagemCache.TryGetValue(ASubId, Result) then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := Format('select %s as imagem_bd from subcategoria where id = :p0 limit 1', [ACampoImagem]);
    LQuery.ParamByName('p0').AsString := ASubId;
    LQuery.Open;

    if LQuery.Eof then
      Exit;

    LField := LQuery.FindField('imagem_bd');
    if (LField = nil) or LField.IsNull or not (LField is TBlobField) then
      Exit;

    LStream := TMemoryStream.Create;
    LBmp := TBitmap.Create;
    try
      TBlobField(LField).SaveToStream(LStream);
      if LStream.Size <= 0 then
      begin
        LBmp.Free;
        Exit;
      end;
      LStream.Position := 0;
      try
        LBmp.LoadFromStream(LStream);
        ReduzirBitmapParaMaximo(LBmp, 192, 192);
      except
        LBmp.Free;
        Exit;
      end;

      if not Assigned(FProdutoImagemCache) then
        FProdutoImagemCache := TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
      FProdutoImagemCache.Add(ASubId, LBmp);
      Result := LBmp;
    finally
      LStream.Free;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPedido.AtribuirImagemProduto(AItem: TListViewItem; ABmp: TBitmap);
var
  LImgObj: TListItemImage;
begin
  if (AItem = nil) or (ABmp = nil) then
    Exit;

  LImgObj := AItem.Objects.FindObjectT<TListItemImage>('image');
  if LImgObj <> nil then
  begin
    LImgObj.Bitmap.Assign(ABmp);
    LImgObj.OwnsBitmap := True;
  end
  else
    AItem.Bitmap.Assign(ABmp);
end;

procedure TfrmPedido.ProdutoImagemTimer(Sender: TObject);
var
  LListView: TListView;
  LItem: TListViewItem;
  LCodProduto: string;
  LSubId: string;
  LBmp: TBitmap;
  LTentativas: Integer;
begin
  LListView := FProdutoImagemListView;
  if LListView = nil then
    LListView := LvProdutos;

  if (not Assigned(LListView)) or (not Assigned(FProdutoImagemSubPorProduto)) then
  begin
    PararCargaImagensProdutos;
    Exit;
  end;

  LTentativas := 0;
  while (FProdutoImagemCursor < LListView.Items.Count) and (LTentativas < 1) do
  begin
    LItem := LListView.Items[FProdutoImagemCursor];
    Inc(FProdutoImagemCursor);
    Inc(LTentativas);

    if LItem = nil then
      Continue;

    LCodProduto := Trim(LItem.TagString);
    if (LCodProduto = '') or (not FProdutoImagemSubPorProduto.TryGetValue(LCodProduto, LSubId)) then
      Continue;

    LBmp := CarregarImagemSubcategoria(LSubId, FProdutoImagemCampoImagem);
    if LBmp <> nil then
    begin
      AtribuirImagemProduto(LItem, LBmp);
      Break;
    end;
  end;

  if FProdutoImagemCursor >= LListView.Items.Count then
    PararCargaImagensProdutos;
end;
procedure TfrmPedido.ListarProdutos;
var
  LQuery: TFDQuery;
  LColsProd: TArray<string>;
  LColsSub: TArray<string>;
  LCampoCodigo: string;
  LCampoNome: string;
  LCampoPreco: string;
  LCampoDescMax: string;
  LCampoUn: string;
  LCampoEstoque: string;
  LCampoSubFk: string;
  LCampoImagem: string;
  LTexto: string;
  LBuscarPorCodigo: Boolean;
  LBuscarPorAmbos: Boolean;
  LItem: TListViewItem;
  LCodigo: string;
  LNome: string;
  LUn: string;
  LEstoque: string;
  LPreco: Double;
  LDescMax: Double;
  LMin: Double;
  LDetail: string;
  LSql: string;
  LImgField: TField;
  LStream: TMemoryStream;
  LBmp: TBitmap;
  LImgObj: TListItemImage;
  LSubId: string;
begin
  if LvProdutos = nil then
    Exit;

  if FListarProdutosRodando then
    Exit;
  if (FUltimaListarProdutos > 0) and (MilliSecondsBetween(Now, FUltimaListarProdutos) < 500) then
    Exit;

  FListarProdutosRodando := True;
  FUltimaListarProdutos := Now;
  try
    LColsProd := GetTabelaCols('produto');
    if Length(LColsProd) = 0 then
      Exit;

  LCampoCodigo := FindCampo(LColsProd, ['cod_produto', 'codigo', 'id']);
  LCampoNome := FindCampo(LColsProd, ['nom_produto', 'nome', 'produto']);
  LCampoPreco := FindCampo(LColsProd, ['preco_venda', 'preco', 'valor']);
  LCampoDescMax := FindCampo(LColsProd, ['desconto_maximo', 'desconto', 'desc_max']);
  LCampoUn := FindCampo(LColsProd, ['un', 'unidade', 'un_medida']);
  LCampoEstoque := FindCampo(LColsProd, ['estoque', 'qtd_estoque', 'saldo_estoque', 'saldo']);
  LCampoSubFk := FindCampo(LColsProd, ['id_subcategoria', 'cod_subcategoria', 'subcategoria', 'id_subcat']);

  LColsSub := GetTabelaCols('subcategoria');
  LCampoImagem := FindCampo(LColsSub, ['imagem_bd']);
  // O BLOB da imagem e carregado depois, em pequenos lotes, para evitar ANR no Android.

  if LCampoCodigo = '' then
    LCampoCodigo := LColsProd[0];
  if LCampoNome = '' then
    LCampoNome := LCampoCodigo;

  LTexto := Trim(EdBuscarProd.Text);
  LBuscarPorCodigo := Assigned(CbModoBuscaProd) and SameText(CbModoBuscaProd.Selected.Text, 'Código');
  LBuscarPorAmbos := Assigned(CbModoBuscaProd) and SameText(CbModoBuscaProd.Selected.Text, 'Ambos');

  LSql := Format('select p.%s as cod_produto, p.%s as nom_produto', [LCampoCodigo, LCampoNome]);
  if LCampoPreco <> '' then
    LSql := LSql + Format(', p.%s as preco_venda', [LCampoPreco]);
  if LCampoDescMax <> '' then
    LSql := LSql + Format(', p.%s as desconto_maximo', [LCampoDescMax]);
  if LCampoUn <> '' then
    LSql := LSql + Format(', p.%s as unidade', [LCampoUn]);
  if LCampoEstoque <> '' then
    LSql := LSql + Format(', p.%s as estoque', [LCampoEstoque]);
  LSql := LSql + ', null as imagem_bd';
  if (LCampoSubFk <> '') and (LCampoImagem <> '') then
    LSql := LSql + Format(', p.%s as imagem_sub_id', [LCampoSubFk]);

  LSql := LSql + ' from produto p';

  if LTexto <> '' then
  begin
    if LBuscarPorCodigo then
      LSql := LSql + Format(' where p.%s = :p0', [LCampoCodigo])
    else if LBuscarPorAmbos then
      LSql := LSql + Format(
        ' where (upper(coalesce(p.%s, '''')) like :p0 or cast(p.%s as text) = :p1)',
        [LCampoNome, LCampoCodigo]
      )
    else
      LSql := LSql + Format(' where upper(coalesce(p.%s, '''')) like :p0', [LCampoNome]);
  end;
  LSql := LSql + ' order by nom_produto limit 100';

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := LSql;
    if LTexto <> '' then
    begin
      if LBuscarPorCodigo then
        LQuery.ParamByName('p0').AsString := LTexto
      else if LBuscarPorAmbos then
      begin
        LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
        LQuery.ParamByName('p1').AsString := LTexto;
      end
      else
        LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    end;
    LQuery.Open;

    PararCargaImagensProdutos;
    if not Assigned(FProdutoImagemSubPorProduto) then
      FProdutoImagemSubPorProduto := TDictionary<string, string>.Create
    else
      FProdutoImagemSubPorProduto.Clear;

    LvProdutos.Items.BeginUpdate;
    try
      LvProdutos.Items.Clear;
      while not LQuery.Eof do
      begin
      LCodigo := LQuery.FieldByName('cod_produto').AsString;
      LNome := LQuery.FieldByName('nom_produto').AsString;
      LUn := SafeFieldAsString(LQuery, 'unidade');
      LEstoque := SafeFieldAsString(LQuery, 'estoque');
      LPreco := SafeFieldAsFloat(LQuery, 'preco_venda');
      LDescMax := SafeFieldAsFloat(LQuery, 'desconto_maximo');
      LSubId := SafeFieldAsString(LQuery, 'imagem_sub_id');
      if (LCodigo <> '') and (LSubId <> '') and Assigned(FProdutoImagemSubPorProduto) then
      begin
        if FProdutoImagemSubPorProduto.ContainsKey(LCodigo) then
          FProdutoImagemSubPorProduto[LCodigo] := LSubId
        else
          FProdutoImagemSubPorProduto.Add(LCodigo, LSubId);
      end;
      LMin := LPreco - (LPreco * (LDescMax / 100));

      LItem := LvProdutos.Items.Add;
      LItem.TagString := LCodigo;
      if LCodigo <> '' then
        LItem.Text := LCodigo + ' - ' + LNome
      else
        LItem.Text := LNome;

      if LUn = '' then
        LUn := '--';
      if LEstoque = '' then
        LEstoque := '--';

      LDetail := Format('UN=%s  %s  Min=%s  DM=%s%%  E=%s', [
        LUn, FormatarMoeda(LPreco), FormatarMoeda(LMin), FormatarNumero(LDescMax, 0), LEstoque
      ]);
      LItem.Detail := LDetail;

      LImgField := LQuery.FindField('imagem_bd');
      if (LImgField <> nil) and (not LImgField.IsNull) then
      begin
        LStream := TMemoryStream.Create;
        LBmp := TBitmap.Create;
        try
          if LImgField is TBlobField then
            TBlobField(LImgField).SaveToStream(LStream)
          else
            LStream.Size := 0;
          LStream.Position := 0;
          try
            LBmp.LoadFromStream(LStream);
        ReduzirBitmapParaMaximo(LBmp, 192, 192);
            LImgObj := LItem.Objects.FindObjectT<TListItemImage>('image');
            if LImgObj <> nil then
            begin
              LImgObj.Bitmap.Assign(LBmp);
              LImgObj.OwnsBitmap := True;
            end
            else
              LItem.Bitmap.Assign(LBmp);
          except
            // ignore imagem inválida
          end;
        finally
          LBmp.Free;
          LStream.Free;
        end;
      end;

        LQuery.Next;
      end;
    finally
      LvProdutos.Items.EndUpdate;
    end;

    if (LCampoSubFk <> '') and (LCampoImagem <> '') then
      IniciarCargaImagensProdutos(LCampoImagem);
  finally
    LQuery.Free;
  end;
  finally
    FListarProdutosRodando := False;
  end;
end;

procedure TfrmPedido.ListarPromocoes;
var
  LQuery: TFDQuery;
  LItem: TListViewItem;
  LImgField: TField;
  LStream: TMemoryStream;
  LBmp: TBitmap;
  LImgObj: TListItemImage;
  LCodigo: string;
  LNome: string;
  LUn: string;
  LEstoque: string;
  LPrecoVenda: Double;
  LPrecoPromocao: Double;
  LPrecoBasePromo: Double;
  LTexto: string;
  LBuscarPorCodigo: Boolean;
  LBuscarPorAmbos: Boolean;
begin
  if LvPromocao = nil then
    Exit;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;

    if Assigned(EdBuscarPromocao) then
      LTexto := Trim(EdBuscarPromocao.Text)
    else
      LTexto := '';
    LBuscarPorCodigo := Assigned(CbModoBuscaPromocao) and SameText(CbModoBuscaPromocao.Selected.Text, 'Código');
    LBuscarPorAmbos := Assigned(CbModoBuscaPromocao) and SameText(CbModoBuscaPromocao.Selected.Text, 'Ambos');

    LQuery.SQL.Text :=
      'select p.cod_produto, p.nom_produto, p.unidade, p.preco_venda, ' +
      '       p.preco_promocao, p.qtd_estoque, s.imagem_bd ' +
      'from produto p ' +
      'left join subcategoria s on s.id = p.subcategoria ' +
      'where coalesce(p.promocao, ''N'') = ''S'' ' +
      '  and coalesce(p.preco_promocao, 0) > 0 ';

    if LTexto <> '' then
    begin
      if LBuscarPorCodigo then
        LQuery.SQL.Text := LQuery.SQL.Text + ' and p.cod_produto = :p0 '
      else if LBuscarPorAmbos then
        LQuery.SQL.Text := LQuery.SQL.Text +
          ' and (upper(coalesce(p.nom_produto, '''')) like :p0 or cast(p.cod_produto as text) = :p1) '
      else
        LQuery.SQL.Text := LQuery.SQL.Text + ' and upper(coalesce(p.nom_produto, '''')) like :p0 ';
    end;

    LQuery.SQL.Text := LQuery.SQL.Text + 'order by p.nom_produto limit 100';

    if LTexto <> '' then
    begin
      if LBuscarPorCodigo then
        LQuery.ParamByName('p0').AsString := LTexto
      else if LBuscarPorAmbos then
      begin
        LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
        LQuery.ParamByName('p1').AsString := LTexto;
      end
      else
        LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    end;

    LQuery.Open;

    LvPromocao.Items.Clear;
    while not LQuery.Eof do
    begin
      LCodigo := LQuery.FieldByName('cod_produto').AsString;
      LNome := LQuery.FieldByName('nom_produto').AsString;
      LUn := SafeFieldAsString(LQuery, 'unidade');
      LEstoque := SafeFieldAsString(LQuery, 'qtd_estoque');
      LPrecoVenda := SafeFieldAsFloat(LQuery, 'preco_venda');
      LPrecoPromocao := SafeFieldAsFloat(LQuery, 'preco_promocao');
      if LPrecoPromocao > 0 then
        LPrecoBasePromo := LPrecoPromocao / 0.65
      else
        LPrecoBasePromo := LPrecoVenda;

      if LUn = '' then
        LUn := '--';
      if LEstoque = '' then
        LEstoque := '--';

      LItem := LvPromocao.Items.Add;
      LItem.TagString := LCodigo;
      if LCodigo <> '' then
        LItem.Text := LCodigo + ' - ' + LNome
      else
        LItem.Text := LNome;
      LItem.Detail := Format('UN=%s  Promo=%s  Base=%s  DM=35%%  E=%s', [
        LUn, FormatarMoeda(LPrecoPromocao), FormatarMoeda(LPrecoBasePromo), LEstoque
      ]);

      LImgField := LQuery.FindField('imagem_bd');
      if (LImgField <> nil) and (not LImgField.IsNull) then
      begin
        LStream := TMemoryStream.Create;
        LBmp := TBitmap.Create;
        try
          if LImgField is TBlobField then
            TBlobField(LImgField).SaveToStream(LStream)
          else
            LStream.Size := 0;
          LStream.Position := 0;
          try
            LBmp.LoadFromStream(LStream);
        ReduzirBitmapParaMaximo(LBmp, 192, 192);
            LImgObj := LItem.Objects.FindObjectT<TListItemImage>('image');
            if LImgObj <> nil then
            begin
              LImgObj.Bitmap.Assign(LBmp);
              LImgObj.OwnsBitmap := True;
            end
            else
              LItem.Bitmap.Assign(LBmp);
          except
          end;
        finally
          LBmp.Free;
          LStream.Free;
        end;
      end;

      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPedido.AbrirPedidoItem(const ACodProduto: string; const ASomenteVisualizacao: Boolean;
  const AQtdVisualizacao: Double; const APrecoVisualizacao: Double;
  const ADescVisualizacao: Double);
var
  LQuery: TFDQuery;
  LSql: string;
  LBytes: TBytes;
  LField: TField;
  LPrecoVisualizacao: Double;
begin
  if Trim(ACodProduto) = '' then
    Exit;

  LSql :=
    'select p.cod_produto, p.nom_produto, p.unidade, p.preco_venda, p.desconto_maximo, p.qtd_estoque, s.imagem_bd ' +
    'from produto p ' +
    'left outer join subcategoria s on s.id = p.subcategoria ' +
    'where p.cod_produto = :p0 ' +
    'limit 1';

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := LSql;
    LQuery.ParamByName('p0').AsString := ACodProduto;
    LQuery.Open;
    if LQuery.Eof then
      Exit;

    SetLength(LBytes, 0);
    LField := LQuery.FindField('imagem_bd');
    if (LField <> nil) and (not LField.IsNull) and (LField is TBlobField) then
      LBytes := TBlobField(LField).AsBytes;

    if not Assigned(frmPedidoItem) then
      Application.CreateForm(TfrmPedidoItem, frmPedidoItem);

    frmPedidoItem.SetProdutoDados(
      LQuery.FieldByName('cod_produto').AsString,
      LQuery.FieldByName('nom_produto').AsString,
      SafeFieldAsString(LQuery, 'unidade'),
      SafeFieldAsString(LQuery, 'qtd_estoque'),
      SafeFieldAsFloat(LQuery, 'preco_venda'),
      SafeFieldAsFloat(LQuery, 'desconto_maximo'),
      LBytes
    );
    if ASomenteVisualizacao then
    begin
      LPrecoVisualizacao := APrecoVisualizacao;
      if LPrecoVisualizacao <= 0 then
        LPrecoVisualizacao := SafeFieldAsFloat(LQuery, 'preco_venda');
      frmPedidoItem.SetModoVisualizacao(
        AQtdVisualizacao,
        LPrecoVisualizacao,
        ADescVisualizacao
      );
    end;
    frmPedidoItem.Show;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPedido.ListarItensDigitados;
var
  LQuery: TFDQuery;
  LImgQuery: TFDQuery;
  LItem: TListViewItem;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LValue: TJSONValue;
  LImgField: TField;
  LStream: TMemoryStream;
  LBmp: TBitmap;
  LImgObj: TListItemImage;
  LCod: string;
  LNome: string;
  LUn: string;
  LQtd: Double;
  LPreco: Double;
  LDesc: Double;
  LTotal: Double;
  LData: string;
  LTextoFiltro: string;
  LBuscaCodigo: Boolean;
  LBuscaAmbos: Boolean;
  LPassaFiltro: Boolean;
begin
  if not Assigned(LvDigitados) then
    Exit;

  LvDigitados.Items.Clear;
  if Assigned(EdBuscarDigitados) then
    LTextoFiltro := Trim(EdBuscarDigitados.Text)
  else
    LTextoFiltro := '';
  LBuscaCodigo := Assigned(CbModoBuscaDigitados) and SameText(CbModoBuscaDigitados.Selected.Text, 'Código');
  LBuscaAmbos := Assigned(CbModoBuscaDigitados) and SameText(CbModoBuscaDigitados.Selected.Text, 'Ambos');

  if outboundPedidoId <= 0 then
    Exit;

  LQuery := TFDQuery.Create(nil);
  LImgQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select item_ord, vendas2_json, created_at ' +
      'from outbound_pedido_item where pedido_id = :p0 order by item_ord desc';
    LQuery.ParamByName('p0').AsInteger := outboundPedidoId;
    LQuery.Open;

    LImgQuery.Connection := dmApp.FDConnection;
    LImgQuery.SQL.Text :=
      'select s.imagem_bd ' +
      'from produto p ' +
      'left outer join subcategoria s on s.id = p.subcategoria ' +
      'where p.cod_produto = :p0 ' +
      'limit 1';

    while not LQuery.Eof do
    begin
      LCod := '';
      LNome := '';
      LUn := '';
      LQtd := 0;
      LPreco := 0;
      LDesc := 0;
      LTotal := 0;
      LData := LQuery.FieldByName('created_at').AsString;

      LJson := TJSONObject.ParseJSONValue(LQuery.FieldByName('vendas2_json').AsString);
      try
        if LJson is TJSONObject then
        begin
          LObj := TJSONObject(LJson);
          LValue := LObj.GetValue('cod_produto');
          if Assigned(LValue) then
            LCod := LValue.Value;
          LValue := LObj.GetValue('nom_produto');
          if Assigned(LValue) then
            LNome := LValue.Value;
          LValue := LObj.GetValue('unidade');
          if Assigned(LValue) then
            LUn := LValue.Value;
          LValue := LObj.GetValue('qtd');
          if Assigned(LValue) then
            LQtd := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
          LValue := LObj.GetValue('preco');
          if Assigned(LValue) then
            LPreco := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
          LValue := LObj.GetValue('desconto_pct');
          if Assigned(LValue) then
            LDesc := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
          LValue := LObj.GetValue('total_item');
          if Assigned(LValue) then
            LTotal := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
        end;
      finally
        LJson.Free;
      end;

      if LTextoFiltro <> '' then
      begin
        if LBuscaCodigo then
          LPassaFiltro := Pos(UpperCase(LTextoFiltro), UpperCase(LCod)) > 0
        else if LBuscaAmbos then
          LPassaFiltro := (Pos(UpperCase(LTextoFiltro), UpperCase(LNome)) > 0) or
            (Pos(UpperCase(LTextoFiltro), UpperCase(LCod)) > 0)
        else
          LPassaFiltro := Pos(UpperCase(LTextoFiltro), UpperCase(LNome)) > 0;

        if not LPassaFiltro then
        begin
          LQuery.Next;
          Continue;
        end;
      end;

      LItem := LvDigitados.Items.Add;
      LItem.Tag := LQuery.FieldByName('item_ord').AsInteger;
      if LCod <> '' then
        LItem.Text := LCod + ' - ' + LNome
      else
        LItem.Text := LNome;
      LItem.TagString := LQuery.FieldByName('vendas2_json').AsString;
      LItem.Detail := Format('UN=%s  Qtd=%s  Preço=%s  Desc=%s%%%sTotal=%s  Data=%s',
        [LUn, FormatarNumero(LQtd, 2), FormatarMoeda(LPreco), FormatarNumero(LDesc, 2),
         sLineBreak, FormatarMoeda(LTotal), LData]);

      if LCod <> '' then
      begin
        LImgQuery.Close;
        LImgQuery.ParamByName('p0').AsString := LCod;
        LImgQuery.Open;
        LImgField := LImgQuery.FindField('imagem_bd');
        if (LImgField <> nil) and (not LImgField.IsNull) and (LImgField is TBlobField) then
        begin
          LStream := TMemoryStream.Create;
          LBmp := TBitmap.Create;
          try
            TBlobField(LImgField).SaveToStream(LStream);
            LStream.Position := 0;
            try
              LBmp.LoadFromStream(LStream);
        ReduzirBitmapParaMaximo(LBmp, 192, 192);
              LImgObj := LItem.Objects.FindObjectT<TListItemImage>('image');
              if LImgObj <> nil then
              begin
                LImgObj.Bitmap.Assign(LBmp);
                LImgObj.OwnsBitmap := True;
              end
              else
                LItem.Bitmap.Assign(LBmp);
            except
              // ignora imagem inválida
            end;
          finally
            LBmp.Free;
            LStream.Free;
          end;
        end;
      end;

      LQuery.Next;
    end;
  finally
    LImgQuery.Free;
    LQuery.Free;
  end;

  if LvDigitados.Items.Count > 0 then
    LvDigitados.ItemIndex := 0
  else
    LvDigitados.ItemIndex := -1;
end;

function TfrmPedido.ObterItemDigitadoSelecionado(out AItemOrd: Integer; out AVendas2Json: string): Boolean;
var
  LItem: TListViewItem;
begin
  Result := False;
  AItemOrd := 0;
  AVendas2Json := '';

  if not Assigned(LvDigitados) then
    Exit;
  if (LvDigitados.ItemIndex < 0) or (LvDigitados.ItemIndex >= LvDigitados.Items.Count) then
    Exit;

  LItem := LvDigitados.Items[LvDigitados.ItemIndex];
  if not Assigned(LItem) then
    Exit;

  AItemOrd := LItem.Tag;
  AVendas2Json := LItem.TagString;
  Result := AItemOrd > 0;
end;

procedure TfrmPedido.EditarItemDigitado(const AItemOrd: Integer; const AVendas2Json: string);
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LValue: TJSONValue;
  LCod: string;
  LNome: string;
  LUn: string;
  LQtd: Double;
  LPreco: Double;
  LDesc: Double;
  LQuery: TFDQuery;
  LBytes: TBytes;
begin
  if (AItemOrd <= 0) or (Trim(AVendas2Json) = '') then
    Exit;

  LCod := '';
  LNome := '';
  LUn := '';
  LQtd := 1;
  LPreco := 0;
  LDesc := 0;

  LJson := TJSONObject.ParseJSONValue(AVendas2Json);
  try
    if LJson is TJSONObject then
    begin
      LObj := TJSONObject(LJson);
      LValue := LObj.GetValue('cod_produto');
      if Assigned(LValue) then
        LCod := LValue.Value;
      LValue := LObj.GetValue('nom_produto');
      if Assigned(LValue) then
        LNome := LValue.Value;
      LValue := LObj.GetValue('unidade');
      if Assigned(LValue) then
        LUn := LValue.Value;
      LValue := LObj.GetValue('qtd');
      if Assigned(LValue) then
        LQtd := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 1);
      LValue := LObj.GetValue('preco');
      if Assigned(LValue) then
        LPreco := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
      LValue := LObj.GetValue('desconto_pct');
      if Assigned(LValue) then
        LDesc := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);
    end;
  finally
    LJson.Free;
  end;

  if LCod = '' then
    Exit;

  LBytes := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select p.cod_produto, p.nom_produto, p.unidade, p.qtd_estoque, p.preco_venda, p.desconto_maximo, s.imagem_bd ' +
      'from produto p ' +
      'left outer join subcategoria s on s.id = p.subcategoria ' +
      'where p.cod_produto = :p0 ' +
      'limit 1';
    LQuery.ParamByName('p0').AsString := LCod;
    LQuery.Open;
    if LQuery.IsEmpty then
      Exit;

    if (LQuery.FindField('imagem_bd') <> nil) and (not LQuery.FieldByName('imagem_bd').IsNull) and
       (LQuery.FieldByName('imagem_bd') is TBlobField) then
      LBytes := TBlobField(LQuery.FieldByName('imagem_bd')).AsBytes;

    if not Assigned(frmPedidoItem) then
      Application.CreateForm(TfrmPedidoItem, frmPedidoItem);

    frmPedidoItem.SetProdutoDados(
      LQuery.FieldByName('cod_produto').AsString,
      LQuery.FieldByName('nom_produto').AsString,
      SafeFieldAsString(LQuery, 'unidade'),
      SafeFieldAsString(LQuery, 'qtd_estoque'),
      SafeFieldAsFloat(LQuery, 'preco_venda'),
      SafeFieldAsFloat(LQuery, 'desconto_maximo'),
      LBytes
    );
    frmPedidoItem.SetEdicaoItem(outboundPedidoId, AItemOrd, LQtd, LPreco, LDesc);
    frmPedidoItem.Show;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPedido.RestaurarPedidoItem(const AExtraJson: string);
var
  LJson: TJSONValue;
  LObj: TJSONObject;
  LValue: TJSONValue;
  LModo: string;
  LCodProduto: string;
  LItemOrd: Integer;
  LQtd: Double;
  LPreco: Double;
  LDesc: Double;
  LVendas2Json: string;
  LQuery: TFDQuery;

  function JsonStr(const AName: string): string;
  var
    V: TJSONValue;
  begin
    Result := '';
    if not Assigned(LObj) then
      Exit;
    V := LObj.GetValue(AName);
    if Assigned(V) then
      Result := V.Value;
  end;

  function JsonFloat(const AName: string; const ADefault: Double): Double;
  begin
    Result := StrToFloatDef(StringReplace(JsonStr(AName), '.', ',', [rfReplaceAll]), ADefault);
  end;

begin
  if outboundPedidoId <= 0 then
    Exit;
  if Trim(AExtraJson) = '' then
    Exit;

  Show;

  LJson := TJSONObject.ParseJSONValue(AExtraJson);
  try
    if not (LJson is TJSONObject) then
      Exit;
    LObj := TJSONObject(LJson);

    LModo := JsonStr('modo');
    LCodProduto := JsonStr('cod_produto');
    LItemOrd := StrToIntDef(JsonStr('item_ord'), 0);
    LQtd := JsonFloat('qtd', 1);
    LPreco := JsonFloat('preco', 0);
    LDesc := JsonFloat('desc_pct', 0);

    if SameText(LModo, 'edicao') and (LItemOrd > 0) then
    begin
      LVendas2Json := '';
      LQuery := TFDQuery.Create(nil);
      try
        LQuery.Connection := dmApp.FDConnection;
        LQuery.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0 and item_ord = :p1';
        LQuery.ParamByName('p0').AsInteger := outboundPedidoId;
        LQuery.ParamByName('p1').AsInteger := LItemOrd;
        LQuery.Open;
        if not LQuery.IsEmpty then
          LVendas2Json := LQuery.FieldByName('vendas2_json').AsString;
      finally
        LQuery.Free;
      end;

      if LVendas2Json <> '' then
      begin
        EditarItemDigitado(LItemOrd, LVendas2Json);
        Exit;
      end;
    end;

    if LCodProduto <> '' then
      AbrirPedidoItem(LCodProduto, True, LQtd, LPreco, LDesc);
  finally
    LJson.Free;
  end;
end;

procedure TfrmPedido.ExcluirItemDigitado(const AItemOrd: Integer);
var
  Q: TFDQuery;
begin
  if (outboundPedidoId <= 0) or (AItemOrd <= 0) then
    Exit;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'delete from outbound_pedido_item where pedido_id = :p0 and item_ord = :p1';
    Q.ParamByName('p0').AsInteger := outboundPedidoId;
    Q.ParamByName('p1').AsInteger := AItemOrd;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
  AtualizarContadorItensDigitados;
end;

procedure TfrmPedido.BtnEditarDigitadoClick(Sender: TObject);
var
  LItemOrd: Integer;
  LVendas2Json: string;
begin
  if not ObterItemDigitadoSelecionado(LItemOrd, LVendas2Json) then
  begin
    TDialogServiceAsync.ShowMessage('Selecione um item digitado.');
    Exit;
  end;
  EditarItemDigitado(LItemOrd, LVendas2Json);
end;

procedure TfrmPedido.BtnExcluirDigitadoClick(Sender: TObject);
var
  LItemOrd: Integer;
  LVendas2Json: string;
begin
  if not ObterItemDigitadoSelecionado(LItemOrd, LVendas2Json) then
  begin
    TDialogServiceAsync.ShowMessage('Selecione um item digitado.');
    Exit;
  end;

  TDialogServiceAsync.MessageDialog(
    'Deseja excluir este item digitado?',
    System.UITypes.TMsgDlgType.mtConfirmation,
    [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
    System.UITypes.TMsgDlgBtn.mbNo,
    0,
    procedure(const AResult: System.UITypes.TModalResult)
    begin
      if AResult = mrYes then
        ExcluirItemDigitado(LItemOrd);
    end
  );
end;

procedure TfrmPedido.AtualizarTotaisPedido;
var
  LQuery: TFDQuery;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LValue: TJSONValue;
  LQtd: Double;
  LPreco: Double;
  LDescPct: Double;
  LTotalItem: Double;
  LItemBruto: Double;
  LFactor: Double;
  LTotBruto: Double;
  LTotLiquido: Double;
  LTotDescAcresc: Double;
  LTotComissao: Double;
  LPercComissao: Double;
  LPercComissaoMedio: Double;
  LCodProduto: string;
  LCodRepresentante: Integer;
  LFuncionario: string;
begin
  if not Assigned(LbTotBrutoValor) or not Assigned(LbTotDescValor) or not Assigned(LbTotLiquidoValor) then
    Exit;

  LTotBruto := 0;
  LTotLiquido := 0;
  LTotDescAcresc := 0;
  LTotComissao := 0;
  LCodRepresentante := ObterCodRepresentanteLocal;
  LFuncionario := '0';

  if LCodRepresentante > 0 then
  begin
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := dmApp.FDConnection;
      LQuery.SQL.Text := 'select coalesce(funcionario, ''0'') as funcionario from representante where id = :p0';
      LQuery.ParamByName('p0').AsInteger := LCodRepresentante;
      LQuery.Open;
      if not LQuery.Eof then
        LFuncionario := Trim(LQuery.FieldByName('funcionario').AsString);
    finally
      LQuery.Free;
    end;
  end;

  if outboundPedidoId > 0 then
  begin
    LQuery := TFDQuery.Create(nil);
    try
      LQuery.Connection := dmApp.FDConnection;
      LQuery.SQL.Text := 'select vendas2_json from outbound_pedido_item where pedido_id = :p0';
      LQuery.ParamByName('p0').AsInteger := outboundPedidoId;
      LQuery.Open;
      while not LQuery.Eof do
      begin
        LQtd := 0;
        LPreco := 0;
        LDescPct := 0;
        LTotalItem := 0;
        LCodProduto := '';

        LJson := TJSONObject.ParseJSONValue(LQuery.FieldByName('vendas2_json').AsString);
        try
          if LJson is TJSONObject then
          begin
            LObj := TJSONObject(LJson);

            LValue := LObj.GetValue('qtd');
            if Assigned(LValue) then
              LQtd := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);

            LValue := LObj.GetValue('preco');
            if Assigned(LValue) then
              LPreco := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);

            LValue := LObj.GetValue('desconto_pct');
            if Assigned(LValue) then
              LDescPct := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);

            LValue := LObj.GetValue('total_item');
            if Assigned(LValue) then
              LTotalItem := StrToFloatDef(StringReplace(LValue.Value, '.', ',', [rfReplaceAll]), 0);

            LValue := LObj.GetValue('cod_produto');
            if Assigned(LValue) then
              LCodProduto := Trim(LValue.Value);
          end;
        finally
          LJson.Free;
        end;

        if LQtd <= 0 then
          LQtd := 1;
        if LTotalItem <= 0 then
          LTotalItem := LPreco * LQtd;

        LFactor := 1 - (LDescPct / 100);
        if Abs(LFactor) < 0.000001 then
          LItemBruto := LTotalItem
        else
          LItemBruto := (LPreco / LFactor) * LQtd;

        LTotBruto := LTotBruto + LItemBruto;
        LTotLiquido := LTotLiquido + LTotalItem;
        // Convenção: desconto negativo, acréscimo positivo
        LTotDescAcresc := LTotDescAcresc + (LTotalItem - LItemBruto);
        LPercComissao := CalcularPercComissaoProduto(LCodProduto, LDescPct, LCodRepresentante, LFuncionario);
        LTotComissao := LTotComissao + (LTotalItem * (LPercComissao / 100));

        LQuery.Next;
      end;
    finally
      LQuery.Free;
    end;
  end;

  LbTotBrutoValor.Text := FormatarMoeda(LTotBruto);
  LbTotDescValor.Text := FormatarMoeda(LTotDescAcresc);
  if Assigned(LbTotCVValor) then
  begin
    if LTotLiquido > 0 then
      LPercComissaoMedio := (LTotComissao / LTotLiquido) * 100
    else
      LPercComissaoMedio := 0;
    LbTotCVValor.Text := FormatarNumero(LPercComissaoMedio, 2) + '% / ' + FormatarMoeda(LTotComissao);
  end;
  LbTotLiquidoValor.Text := FormatarMoeda(LTotLiquido);
  if Assigned(LbRodTotValor) then
    LbRodTotValor.Text := LbTotLiquidoValor.Text;
end;

procedure TfrmPedido.ListarUltimasCompras;
var
  LQuery: TFDQuery;
  LItem: TListViewItem;
  LSql: string;
  LColsProd: TArray<string>;
  LColsSub: TArray<string>;
  LCampoSubFk: string;
  LCampoImagem: string;
  LCodigo: string;
  LSubId: string;
  LNome: string;
  LUn: string;
  LPrecoVenda: Double;
  LDescMax: Double;
  LMin: Double;
  LEstoque: string;
  LData: TDateTime;
  LQtd: Double;
  LPreco: Double;
  LDetail: string;
  LTextoFiltro: string;
  LBuscaCodigo: Boolean;
  LBuscaAmbos: Boolean;
  LCarregarImagens: Boolean;
begin
  if (LvUltimasCompras = nil) or (codCliente <= 0) then
    Exit;

  if FListarUltimasRodando then
    Exit;
  if (FUltimaListarUltimas > 0) and (MilliSecondsBetween(Now, FUltimaListarUltimas) < 500) then
    Exit;

  FListarUltimasRodando := True;
  FUltimaListarUltimas := Now;
  try
    LCarregarImagens := Assigned(TabMenu) and (TabMenu.ActiveTab = TabUltimasCompras);
    LColsProd := GetTabelaCols('produto');
    LCampoSubFk := FindCampo(LColsProd, ['id_subcategoria', 'cod_subcategoria', 'subcategoria', 'id_subcat']);
    LColsSub := GetTabelaCols('subcategoria');
    LCampoImagem := FindCampo(LColsSub, ['imagem_bd']);

    LSql :=
      'select ' +
      '  p.cod_produto, p.nom_produto, p.unidade, p.preco_venda, p.desconto_maximo, p.qtd_estoque, ' +
      '  coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, '''')) as dtadoc, v2.qtd, v2.preco ';
    if (LCampoSubFk <> '') and (LCampoImagem <> '') then
      LSql := LSql + Format(', p.%s as imagem_sub_id ', [LCampoSubFk]);

    LSql := LSql +
      'from vendas2 v2 ' +
      'inner join produto p on p.cod_produto = v2.cod_produto ' +
      'inner join vendas1 v1 on v2.numdoc = v1.numdoc ' +
      'where v1.cod_cliente = :p0 ' +
      '  and not exists ( ' +
      '    select 1 ' +
      '      from vendas2 v2x ' +
      '      inner join vendas1 v1x on v2x.numdoc = v1x.numdoc ' +
      '     where v1x.cod_cliente = v1.cod_cliente ' +
      '       and v2x.cod_produto = v2.cod_produto ' +
      '       and ( ' +
      '         date(coalesce(nullif(v1x.dta_emissao, ''''), nullif(v1x.dtadoc, ''''), nullif(v2x.dtadoc, ''''))) > date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, ''''))) ' +
      '         or (date(coalesce(nullif(v1x.dta_emissao, ''''), nullif(v1x.dtadoc, ''''), nullif(v2x.dtadoc, ''''))) = date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, ''''))) and cast(v1x.numdoc as integer) > cast(v1.numdoc as integer)) ' +
      '         or (date(coalesce(nullif(v1x.dta_emissao, ''''), nullif(v1x.dtadoc, ''''), nullif(v2x.dtadoc, ''''))) = date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, ''''))) and v1x.numdoc = v1.numdoc and v2x.id > v2.id) ' +
      '       ) ' +
      '  ) ';

  if Assigned(EdBuscarUltimas) then
    LTextoFiltro := Trim(EdBuscarUltimas.Text)
  else
    LTextoFiltro := '';
  LBuscaCodigo := Assigned(CbModoBuscaUltimas) and SameText(CbModoBuscaUltimas.Selected.Text, 'Código');
  LBuscaAmbos := Assigned(CbModoBuscaUltimas) and SameText(CbModoBuscaUltimas.Selected.Text, 'Ambos');

  if LTextoFiltro <> '' then
  begin
    if LBuscaCodigo then
      LSql := LSql + ' and cast(p.cod_produto as text) = :p1 '
    else if LBuscaAmbos then
      LSql := LSql + ' and (upper(coalesce(p.nom_produto, '''')) like :p1 or cast(p.cod_produto as text) = :p2) '
    else
      LSql := LSql + ' and upper(coalesce(p.nom_produto, '''')) like :p1 ';
  end;

  LSql := LSql + 'order by date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, ''''))) desc, cast(v1.numdoc as integer) desc limit 100';

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := LSql;
    LQuery.ParamByName('p0').AsInteger := codCliente;
    if LTextoFiltro <> '' then
    begin
      if LBuscaCodigo then
        LQuery.ParamByName('p1').AsString := LTextoFiltro
      else if LBuscaAmbos then
      begin
        LQuery.ParamByName('p1').AsString := '%' + UpperCase(LTextoFiltro) + '%';
        LQuery.ParamByName('p2').AsString := LTextoFiltro;
      end
      else
        LQuery.ParamByName('p1').AsString := '%' + UpperCase(LTextoFiltro) + '%';
    end;
    LQuery.Open;

    if LCarregarImagens then
    begin
      PararCargaImagensProdutos;
      if not Assigned(FProdutoImagemSubPorProduto) then
        FProdutoImagemSubPorProduto := TDictionary<string, string>.Create
      else
        FProdutoImagemSubPorProduto.Clear;
    end;

    LvUltimasCompras.Items.BeginUpdate;
    try
      LvUltimasCompras.Items.Clear;
      while not LQuery.Eof do
    begin
      LCodigo := LQuery.FieldByName('cod_produto').AsString;
      LNome := LQuery.FieldByName('nom_produto').AsString;
      LUn := LQuery.FieldByName('unidade').AsString;
      LPrecoVenda := SafeFieldAsFloat(LQuery, 'preco_venda');
      LDescMax := SafeFieldAsFloat(LQuery, 'desconto_maximo');
      LMin := LPrecoVenda - (LPrecoVenda * (LDescMax / 100));
      LEstoque := SafeFieldAsString(LQuery, 'qtd_estoque');
      LData := SafeFieldAsDate(LQuery, 'dtadoc');
      LQtd := SafeFieldAsFloat(LQuery, 'qtd');
      LPreco := SafeFieldAsFloat(LQuery, 'preco');
      LSubId := SafeFieldAsString(LQuery, 'imagem_sub_id');
      if LCarregarImagens and (LCodigo <> '') and (LSubId <> '') and Assigned(FProdutoImagemSubPorProduto) then
      begin
        if FProdutoImagemSubPorProduto.ContainsKey(LCodigo) then
          FProdutoImagemSubPorProduto[LCodigo] := LSubId
        else
          FProdutoImagemSubPorProduto.Add(LCodigo, LSubId);
      end;

      LItem := LvUltimasCompras.Items.Add;
      LItem.TagString := LCodigo;
      LItem.Text := LNome;

      if LUn = '' then
        LUn := '--';
      if LEstoque = '' then
        LEstoque := '--';

      LDetail := Format('PC=%s  Min=%s  E=%s%sData %s  Qtde %s  Preço %s',
        [FormatarMoeda(LPrecoVenda), FormatarMoeda(LMin), LEstoque, sLineBreak,
         FormatDateTime('dd/mm/yy', LData), FormatarNumero(LQtd, 2), FormatarMoeda(LPreco)]);
      LItem.Detail := LDetail;

      LQuery.Next;
      end;
    finally
      LvUltimasCompras.Items.EndUpdate;
    end;

    if LCarregarImagens and (LCampoSubFk <> '') and (LCampoImagem <> '') then
      IniciarCargaImagensProdutos(LCampoImagem, LvUltimasCompras);
  finally
    LQuery.Free;
  end;
  finally
    FListarUltimasRodando := False;
  end;
end;

procedure TfrmPedido.CriarOutboundPedidoDraft;
var
  LVenda1: TJSONObject;
begin
  if codCliente <= 0 then
    Exit;

  LVenda1 := TJSONObject.Create;
  try
    LVenda1.AddPair('cod_cliente', TJSONNumber.Create(codCliente));
    LVenda1.AddPair('nom_cliente', FClienteNome);
    LVenda1.AddPair('cidade', FClienteCidade);
    LVenda1.AddPair('id_fop', TJSONNumber.Create(codFormaPgto));
    LVenda1.AddPair('id_prazo', TJSONNumber.Create(codPrazoPgto));
    LVenda1.AddPair('orcamento', TJSONNumber.Create(OrcamentoSelecionado));
    LVenda1.AddPair('dta_pedido', FormatDateTime('yyyy-mm-dd', Date));
    LVenda1.AddPair('hora_pedido', FormatDateTime('hh:nn:ss', Now));
    LVenda1.AddPair('origem', 'APP');
    if Assigned(MemoObservacoes) then
      LVenda1.AddPair('observacoes', MemoObservacoes.Lines.Text)
    else
      LVenda1.AddPair('observacoes', '');

    outboundPedidoId := dmApp.CreateOutboundPedidoDraft(LVenda1.ToJSON, '');
    dmApp.SetAppState('pedido', outboundPedidoId, '');
    dmApp.AddRequestLog('DB', 'outbound_pedido_open', LVenda1.ToJSON, 'id=' + outboundPedidoId.ToString, 0);
  finally
    LVenda1.Free;
  end;
end;

procedure TfrmPedido.SincronizarOutboundPedidoDraft;
var
  LVenda1: TJSONObject;
begin
  if outboundPedidoId <= 0 then
    Exit;

  LVenda1 := TJSONObject.Create;
  try
    LVenda1.AddPair('cod_cliente', TJSONNumber.Create(codCliente));
    LVenda1.AddPair('nom_cliente', FClienteNome);
    LVenda1.AddPair('cidade', FClienteCidade);
    LVenda1.AddPair('id_fop', TJSONNumber.Create(codFormaPgto));
    LVenda1.AddPair('id_prazo', TJSONNumber.Create(codPrazoPgto));
    LVenda1.AddPair('orcamento', TJSONNumber.Create(OrcamentoSelecionado));
    LVenda1.AddPair('dta_pedido', FormatDateTime('yyyy-mm-dd', Date));
    LVenda1.AddPair('hora_pedido', FormatDateTime('hh:nn:ss', Now));
    LVenda1.AddPair('origem', 'APP');
    if Assigned(MemoObservacoes) then
      LVenda1.AddPair('observacoes', MemoObservacoes.Lines.Text)
    else
      LVenda1.AddPair('observacoes', '');

    dmApp.UpdateOutboundPedidoDraft(outboundPedidoId, LVenda1.ToJSON, '');
    dmApp.SetAppState('pedido', outboundPedidoId, '');
  finally
    LVenda1.Free;
  end;
end;

procedure TfrmPedido.AtualizarOutboundPedido;
begin
  SincronizarOutboundPedidoDraft;
end;

procedure TfrmPedido.PrepararNovoPedido;
begin
  outboundPedidoId := 0;
  FVoltarParaPedidosDigitados := False;

  if Assigned(MemoObservacoes) then
    MemoObservacoes.Lines.Clear;
  if Assigned(LbTitulo) then
    LbTitulo.Text := 'Novo Pedido';
end;

procedure TfrmPedido.AtualizarContadorItensDigitados;
var
  LCount: Int64;
begin
  if outboundPedidoId > 0 then
    LCount := dmApp.CountOutboundPedidoItens(outboundPedidoId)
  else
    LCount := 0;

  if FVoltarParaPedidosDigitados then
    LbTitulo.Text := 'Editar Pedido'
  else
    LbTitulo.Text := 'Novo Pedido';

  ListarItensDigitados;
  AtualizarTotaisPedido;
end;

procedure TfrmPedido.FormShow(Sender: TObject);
begin
  ConfigurarAbasComIcone;
  UseAndroidSafeComboPicker([
    CbModoBuscaProd,
    CbModoBuscaPromocao,
    CbModoBuscaUltimas,
    CbModoBuscaDigitados,
    CbOrcamento
  ]);

  if Assigned(CbModoBuscaProd) then
  begin
    CbModoBuscaProd.Items.Clear;
    CbModoBuscaProd.Items.Add('Nome');
    CbModoBuscaProd.Items.Add('Código');
    CbModoBuscaProd.Items.Add('Ambos');
    CbModoBuscaProd.ItemIndex := 1;
    CbModoBuscaProd.OnChange := CbModoBuscaProdChange;
  end;
  CbModoBuscaProdChange(CbModoBuscaProd);

  if Assigned(CbModoBuscaPromocao) then
  begin
    CbModoBuscaPromocao.Items.Clear;
    CbModoBuscaPromocao.Items.Add('Nome');
    CbModoBuscaPromocao.Items.Add('Código');
    CbModoBuscaPromocao.Items.Add('Ambos');
    CbModoBuscaPromocao.ItemIndex := 1;
    CbModoBuscaPromocao.OnChange := CbModoBuscaPromocaoChange;
  end;
  CbModoBuscaPromocaoChange(CbModoBuscaPromocao);
  if Assigned(BtnBuscarPromocao) then
  begin
    BtnBuscarPromocao.OnClick := BtnBuscarPromocaoClick;
    BtnBuscarPromocao.OnTap := BtnBuscarPromocaoTap;
    if Assigned(BtnBuscarProd) then
      BtnBuscarPromocao.MultiResBitmap.Assign(BtnBuscarProd.MultiResBitmap);
  end;
  if Assigned(CbModoBuscaUltimas) then
  begin
    CbModoBuscaUltimas.Items.Clear;
    CbModoBuscaUltimas.Items.Add('Nome');
    CbModoBuscaUltimas.Items.Add('Código');
    CbModoBuscaUltimas.Items.Add('Ambos');
    CbModoBuscaUltimas.ItemIndex := 1;
    CbModoBuscaUltimas.OnChange := CbModoBuscaUltimasChange;
  end;
  CbModoBuscaUltimasChange(CbModoBuscaUltimas);
  if Assigned(BtnBuscarUltimas) then
  begin
    BtnBuscarUltimas.OnClick := BtnBuscarUltimasClick;
    BtnBuscarUltimas.OnTap := BtnBuscarUltimasTap;
    if Assigned(BtnBuscarProd) then
      BtnBuscarUltimas.MultiResBitmap.Assign(BtnBuscarProd.MultiResBitmap);
  end;

  if Assigned(CbModoBuscaDigitados) then
  begin
    CbModoBuscaDigitados.Items.Clear;
    CbModoBuscaDigitados.Items.Add('Nome');
    CbModoBuscaDigitados.Items.Add('Código');
    CbModoBuscaDigitados.Items.Add('Ambos');
    CbModoBuscaDigitados.ItemIndex := 1;
    CbModoBuscaDigitados.OnChange := CbModoBuscaDigitadosChange;
  end;
  CbModoBuscaDigitadosChange(CbModoBuscaDigitados);
  if Assigned(BtnBuscarDigitados) then
  begin
    BtnBuscarDigitados.OnClick := BtnBuscarDigitadosClick;
    BtnBuscarDigitados.OnTap := BtnBuscarDigitadosTap;
    if Assigned(BtnBuscarProd) then
      BtnBuscarDigitados.MultiResBitmap.Assign(BtnBuscarProd.MultiResBitmap);
  end;
  if Assigned(CbOrcamento) then
  begin
    if CbOrcamento.Items.Count = 0 then
    begin
      CbOrcamento.Items.Add('SIM');
      CbOrcamento.Items.Add('NÃO');
    end;
    if CbOrcamento.ItemIndex < 0 then
      CbOrcamento.ItemIndex := 1;
  end;
  LvProdutos.OnItemClick := LvProdutosItemClick;
  if Assigned(LvPromocao) then
    LvPromocao.OnItemClick := LvProdutosItemClick;
  if Assigned(LvUltimasCompras) then
    LvUltimasCompras.OnItemClick := LvUltimasComprasItemClick;
  if Assigned(CbModoBuscaProd) and (CbModoBuscaProd.Items.Count > 2) then
  begin
    CbModoBuscaProd.ItemIndex := 2;
    CbModoBuscaProdChange(CbModoBuscaProd);
  end;
  ListarProdutos;
  if Assigned(CbModoBuscaProd) and (CbModoBuscaProd.Items.Count > 1) then
  begin
    CbModoBuscaProd.ItemIndex := 1;
    CbModoBuscaProdChange(CbModoBuscaProd);
  end;
  ListarPromocoes;
  ListarUltimasCompras;
  AtualizarContadorItensDigitados;
end;

procedure TfrmPedido.CbModoBuscaProdChange(Sender: TObject);
begin
  if not Assigned(EdBuscarProd) then
    Exit;

  if Assigned(CbModoBuscaProd) and (CbModoBuscaProd.ItemIndex = 1) then
    EdBuscarProd.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscarProd.KeyboardType := TVirtualKeyboardType.Default;
end;

procedure TfrmPedido.ConfigurarAbasComIcone;
  procedure AplicarIcone(ATab: TTabItem; AIndex: Integer);
  begin
    if not Assigned(ATab) then
      Exit;
    ATab.Text := #$200B;
    ATab.ImageIndex := AIndex;
    ATab.Width := 72;
    if ATab.StyleLookup = '' then
      ATab.StyleLookup := 'tabitemstyle';
  end;
begin
  if Assigned(TabMenu) then
    TabMenu.Images := ImageList1;

  AplicarIcone(TabCliente, 0);
  AplicarIcone(TabProdutos, 1);
  AplicarIcone(TabPromocao, 2);
  AplicarIcone(TabUltimasCompras, 3);
  AplicarIcone(TabDigitados, 4);
  AplicarIcone(TabTotal, 5);
end;

procedure TfrmPedido.BtnBuscarProdClick(Sender: TObject);
begin
  ListarProdutos;
end;

procedure TfrmPedido.BtnBuscarProdTap(Sender: TObject; const Point: TPointF);
begin
  ListarProdutos;
end;

procedure TfrmPedido.BtnBuscarPromocaoClick(Sender: TObject);
begin
  ListarPromocoes;
end;

procedure TfrmPedido.BtnBuscarPromocaoTap(Sender: TObject; const Point: TPointF);
begin
  ListarPromocoes;
end;

procedure TfrmPedido.CbModoBuscaPromocaoChange(Sender: TObject);
begin
  if not Assigned(EdBuscarPromocao) then
    Exit;

  if Assigned(CbModoBuscaPromocao) and (CbModoBuscaPromocao.ItemIndex = 1) then
    EdBuscarPromocao.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscarPromocao.KeyboardType := TVirtualKeyboardType.Default;
end;
procedure TfrmPedido.BtnBuscarUltimasClick(Sender: TObject);
begin
  ListarUltimasCompras;
end;

procedure TfrmPedido.BtnBuscarUltimasTap(Sender: TObject; const Point: TPointF);
begin
  ListarUltimasCompras;
end;

procedure TfrmPedido.CbModoBuscaUltimasChange(Sender: TObject);
begin
  if not Assigned(EdBuscarUltimas) then
    Exit;

  if Assigned(CbModoBuscaUltimas) and (CbModoBuscaUltimas.ItemIndex = 1) then
    EdBuscarUltimas.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscarUltimas.KeyboardType := TVirtualKeyboardType.Default;
end;

procedure TfrmPedido.BtnBuscarDigitadosClick(Sender: TObject);
begin
  ListarItensDigitados;
end;

procedure TfrmPedido.BtnBuscarDigitadosTap(Sender: TObject; const Point: TPointF);
begin
  ListarItensDigitados;
end;

procedure TfrmPedido.CbModoBuscaDigitadosChange(Sender: TObject);
begin
  if not Assigned(EdBuscarDigitados) then
    Exit;

  if Assigned(CbModoBuscaDigitados) and (CbModoBuscaDigitados.ItemIndex = 1) then
    EdBuscarDigitados.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscarDigitados.KeyboardType := TVirtualKeyboardType.Default;
end;
function TfrmPedido.ProdutoJaDigitadoNoPedido(const ACodProduto: string): Boolean;
var
  Q: TFDQuery;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LValue: TJSONValue;
  LCod: string;
begin
  Result := False;
  if (outboundPedidoId <= 0) or (Trim(ACodProduto) = '') then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select vendas2_json from outbound_pedido_item ' +
      'where pedido_id = :p0';
    Q.ParamByName('p0').AsInteger := outboundPedidoId;
    Q.Open;
    while not Q.Eof do
    begin
      LCod := '';
      LJson := TJSONObject.ParseJSONValue(Q.FieldByName('vendas2_json').AsString);
      try
        if LJson is TJSONObject then
        begin
          LObj := TJSONObject(LJson);
          LValue := LObj.GetValue('cod_produto');
          if Assigned(LValue) then
            LCod := Trim(LValue.Value);
        end;
      finally
        LJson.Free;
      end;

      if (LCod <> '') and SameText(LCod, Trim(ACodProduto)) then
        Exit(True);

      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmPedido.LvProdutosItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LCod: string;
  P: Integer;
begin
  if AItem = nil then
    Exit;

  LCod := Trim(AItem.TagString);
  if LCod = '' then
  begin
    P := Pos(' - ', AItem.Text);
    if P > 1 then
      LCod := Trim(Copy(AItem.Text, 1, P - 1));
  end;

  if ProdutoJaDigitadoNoPedido(LCod) then
  begin
    TDialogServiceAsync.ShowMessage('Este produto já foi incluído no pedido.');
    Exit;
  end;

  AbrirPedidoItem(LCod);
end;

procedure TfrmPedido.LvUltimasComprasItemClick(const Sender: TObject;
  const AItem: TListViewItem);
var
  LCod: string;
  LQuery: TFDQuery;
  LQtd: Double;
  LPreco: Double;
  LPrecoVenda: Double;
  LDesc: Double;
begin
  if AItem = nil then
    Exit;

  LCod := Trim(AItem.TagString);
  if (LCod = '') or (codCliente <= 0) then
    Exit;

  LQtd := 1;
  LPreco := 0;
  LDesc := 0;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text :=
      'select v2.qtd, v2.preco, p.preco_venda ' +
      'from vendas2 v2 ' +
      'inner join vendas1 v1 on v1.numdoc = v2.numdoc ' +
      'inner join produto p on p.cod_produto = v2.cod_produto ' +
      'where v1.cod_cliente = :p0 and v2.cod_produto = :p1 ' +
      'order by date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''), nullif(v2.dtadoc, ''''))) desc, cast(v1.numdoc as integer) desc, v2.id desc ' +
      'limit 1';
    LQuery.ParamByName('p0').AsInteger := codCliente;
    LQuery.ParamByName('p1').AsString := LCod;
    LQuery.Open;
    if not LQuery.Eof then
    begin
      LQtd := SafeFieldAsFloat(LQuery, 'qtd');
      LPreco := SafeFieldAsFloat(LQuery, 'preco');
      LPrecoVenda := SafeFieldAsFloat(LQuery, 'preco_venda');
      if LQtd <= 0 then
        LQtd := 1;
      if LPrecoVenda > 0 then
        LDesc := ((LPrecoVenda - LPreco) / LPrecoVenda) * 100;
    end;
  finally
    LQuery.Free;
  end;

  AbrirPedidoItem(LCod, True, LQtd, LPreco, LDesc);
end;

procedure TfrmPedido.SetCliente(const ANome, ACodigo, ACidade: string);
begin
  FClienteNome := ANome;
  FClienteCodigo := ACodigo;
  FClienteCidade := ACidade;
  FClienteDoc := '';

  if FClienteCodigo <> '' then
    codCliente := StrToIntDef(FClienteCodigo, 0)
  else
  codCliente := 0;
  codFormaPgto := 0;
  codPrazoPgto := 0;
  SetOrcamentoSelecionado(0);
  outboundPedidoId := 0;
  FVoltarParaPedidosDigitados := False;

  if LbNome <> nil then
    LbNome.Text := FClienteNome;
  if LbDoc <> nil then
  begin
    if FClienteCodigo <> '' then
      LbDoc.Text := 'Codigo ' + FClienteCodigo
    else
      LbDoc.Text := 'Codigo --';
  end;
  if Assigned(LbDocDireita) then
    LbDocDireita.Text := '';
  if LbCidade <> nil then
  begin
    if FClienteCidade <> '' then
      LbCidade.Text := 'Cidade: ' + FClienteCidade
    else
      LbCidade.Text := 'Cidade: --';
  end;

  CarregarSituacaoDoSqlite(FClienteCodigo);
  ApplyResponsiveLayout;
  ListarUltimasCompras;
  CriarOutboundPedidoDraft;
  AtualizarContadorItensDigitados;
end;

procedure TfrmPedido.CarregarPedidoDigitado(const APedidoId: Integer);
var
  Q: TFDQuery;
  LJson: TJSONValue;
  LObj: TJSONObject;
  LColsFop: TArray<string>;
  LColsPrazo: TArray<string>;
  LCampoFopCod: string;
  LCampoFopNome: string;
  LCampoPrazoCod: string;
  LCampoPrazoNome: string;
  LCodCliente: string;
  LNomeCliente: string;
  LCidade: string;
  LObs: string;
  LCodFop: Integer;
  LCodPrazo: Integer;
  LOrcamento: Integer;
begin
  if APedidoId <= 0 then
    Exit;

  FVoltarParaPedidosDigitados := True;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text := 'select id, vendas1_json from outbound_pedido where id = :p0';
    Q.ParamByName('p0').AsInteger := APedidoId;
    Q.Open;
    if Q.Eof then
      Exit;

    outboundPedidoId := APedidoId;
    LCodCliente := '';
    LNomeCliente := '';
    LCidade := '';
    LObs := '';
    LCodFop := 0;
    LCodPrazo := 0;
    LOrcamento := 0;

    LJson := TJSONObject.ParseJSONValue(Q.FieldByName('vendas1_json').AsString);
    try
      if LJson is TJSONObject then
      begin
        LObj := TJSONObject(LJson);
        if Assigned(LObj.GetValue('cod_cliente')) then
          LCodCliente := LObj.GetValue('cod_cliente').Value;
        if Assigned(LObj.GetValue('nom_cliente')) then
          LNomeCliente := LObj.GetValue('nom_cliente').Value;
        if Assigned(LObj.GetValue('cidade')) then
          LCidade := LObj.GetValue('cidade').Value;
        if Assigned(LObj.GetValue('id_fop')) then
          LCodFop := StrToIntDef(LObj.GetValue('id_fop').Value, 0);
        if Assigned(LObj.GetValue('id_prazo')) then
          LCodPrazo := StrToIntDef(LObj.GetValue('id_prazo').Value, 0);
        if Assigned(LObj.GetValue('orcamento')) then
          LOrcamento := StrToIntDef(LObj.GetValue('orcamento').Value, 0);
        if Assigned(LObj.GetValue('observacoes')) then
          LObs := LObj.GetValue('observacoes').Value;
      end;
    finally
      LJson.Free;
    end;

    FClienteCodigo := LCodCliente;
    FClienteNome := LNomeCliente;
    FClienteCidade := LCidade;
    codCliente := StrToIntDef(LCodCliente, 0);
    codFormaPgto := LCodFop;
    codPrazoPgto := LCodPrazo;
    SetOrcamentoSelecionado(LOrcamento);

    if Assigned(LbNome) then
      LbNome.Text := FClienteNome;
    if Assigned(LbDoc) then
      LbDoc.Text := 'Codigo ' + FClienteCodigo;
    if Assigned(LbDocDireita) then
      LbDocDireita.Text := '';
    if Assigned(LbCidade) then
      LbCidade.Text := 'Cidade: ' + FClienteCidade;

    if Assigned(MemoObservacoes) then
      MemoObservacoes.Lines.Text := LObs;

    LColsFop := GetTabelaCols('fop');
    LCampoFopCod := FindCampo(LColsFop, ['id', 'cod_fop', 'codigo']);
    LCampoFopNome := FindCampo(LColsFop, ['fop', 'nom_fop', 'descricao', 'nome']);
    if LCampoFopCod = '' then
      LCampoFopCod := 'id';
    if LCampoFopNome = '' then
      LCampoFopNome := LCampoFopCod;

    LColsPrazo := GetTabelaCols('prazo');
    LCampoPrazoCod := FindCampo(LColsPrazo, ['id', 'cod_prazo', 'codigo']);
    LCampoPrazoNome := FindCampo(LColsPrazo, ['prazo', 'descricao', 'nome']);
    if LCampoPrazoCod = '' then
      LCampoPrazoCod := 'id';
    if LCampoPrazoNome = '' then
      LCampoPrazoNome := LCampoPrazoCod;

    if codFormaPgto > 0 then
    begin
      Q.Close;
      Q.SQL.Text := Format('select %s as nome from fop where %s = :p0', [
        LCampoFopNome, LCampoFopCod
      ]);
      Q.ParamByName('p0').AsInteger := codFormaPgto;
      Q.Open;
      if not Q.Eof then
        lbFormaPgto.Text := Q.FieldByName('nome').AsString
      else
        lbFormaPgto.Text := codFormaPgto.ToString;
    end
    else
      lbFormaPgto.Text := 'Clique para Selecionar';

    if codPrazoPgto > 0 then
    begin
      Q.Close;
      Q.SQL.Text := Format('select %s as nome from prazo where %s = :p0', [
        LCampoPrazoNome, LCampoPrazoCod
      ]);
      Q.ParamByName('p0').AsInteger := codPrazoPgto;
      Q.Open;
      if not Q.Eof then
        lbPrazoPgto.Text := Q.FieldByName('nome').AsString
      else
        lbPrazoPgto.Text := codPrazoPgto.ToString;
    end
    else
      lbPrazoPgto.Text := 'Clique para Selecionar';

    CarregarSituacaoDoSqlite(FClienteCodigo);
    ApplyResponsiveLayout;
    ListarUltimasCompras;
    AtualizarContadorItensDigitados;
    if Assigned(TabMenu) and Assigned(TabCliente) then
      TabMenu.ActiveTab := TabCliente;
    AtualizarEstadoCabecalhoAbas;
    dmApp.SetAppState('pedido', outboundPedidoId, '');
  finally
    Q.Free;
  end;
end;

procedure TfrmPedido.ImgFormaPgtoClick(Sender: TObject);
begin
  if not Assigned(frmFormaPgto) then
    Application.CreateForm(TfrmFormaPgto, frmFormaPgto);
  frmFormaPgto.Show;
end;

procedure TfrmPedido.ImgPrazoPgtoClick(Sender: TObject);
begin
  if not Assigned(frmPrazoPgto) then
    Application.CreateForm(TfrmPrazoPgto, frmPrazoPgto);
  if CountPrazosFormaPgto(codFormaPgto) > 0 then
    frmPrazoPgto.CodFopFiltro := codFormaPgto
  else
    frmPrazoPgto.CodFopFiltro := 0;
  frmPrazoPgto.Show;
end;

procedure TfrmPedido.BtnCancelarClick(Sender: TObject);
begin
  TDialogServiceAsync.MessageDialog(
    'Deseja cancelar o pedido?',
    System.UITypes.TMsgDlgType.mtConfirmation,
    [System.UITypes.TMsgDlgBtn.mbYes, System.UITypes.TMsgDlgBtn.mbNo],
    System.UITypes.TMsgDlgBtn.mbNo,
    0,
    procedure(const AResult: System.UITypes.TModalResult)
    begin
      if AResult = mrYes then
      begin
        CancelarPedidoAtual;
        dmApp.ClearAppState('pedido');
        FecharPedido;
      end;
    end
  );
end;

procedure TfrmPedido.BtnPedidoClick(Sender: TObject);
var
  LQtdItens: Integer;
begin
  if codCliente <= 0 then
  begin
    TDialogServiceAsync.ShowMessage('Cliente inválido.');
    Exit;
  end;

  if codFormaPgto <= 0 then
  begin
    TDialogServiceAsync.ShowMessage('Selecione a forma de pagamento.');
    Exit;
  end;

  if codPrazoPgto <= 0 then
  begin
    TDialogServiceAsync.ShowMessage('Selecione o prazo de pagamento.');
    Exit;
  end;

  LQtdItens := dmApp.CountOutboundPedidoItens(outboundPedidoId);
  if LQtdItens <= 0 then
  begin
    TDialogServiceAsync.ShowMessage('Inclua ao menos um item no pedido.');
    Exit;
  end;

  AtualizarOutboundPedido;
  dmApp.ClearAppState('pedido');
  TDialogServiceAsync.MessageDialog('Pedido gravado com sucesso.',
    System.UITypes.TMsgDlgType.mtInformation,
    [System.UITypes.TMsgDlgBtn.mbOK],
    System.UITypes.TMsgDlgBtn.mbOK,
    0,
    procedure(const AResult: System.UITypes.TModalResult)
    begin
      FecharPedido;
    end);
end;

end.
