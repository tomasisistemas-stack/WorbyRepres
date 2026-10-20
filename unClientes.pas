unit unClientes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  System.Math,
  System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  Data.DB, FireDAC.Comp.Client, FMX.ListBox;

type
  TfrmClientes = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    Layout1: TLayout;
    LvClientes: TListView;
    LyNovo: TLayout;
    BtnNovo: TRectangle;
    LbNovo: TLabel;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    CbModoBusca: TComboBox;
    LbMesAno: TLabel;
    CbMesAno: TComboBox;
    LbOrdenacao: TLabel;
    CbOrdenacao: TComboBox;
    BtnBuscar: TImage;
    Label1: TLabel;
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnBuscarTap(Sender: TObject; const Point: TPointF);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnNovoClick(Sender: TObject);
  private
    FBuscarPorCodigo: Boolean;
    FAtualizandoFiltros: Boolean;
    FAplicandoMascaraData: Boolean;
    FListarTimer: TTimer;
    procedure EnsureMesAnoCombo;
    procedure PopularMeses;
    procedure FiltrosChange(Sender: TObject);
    procedure ListarTimerTimer(Sender: TObject);
    procedure AgendarListar;
    procedure AtualizarTecladoBusca;
    function MesAnoSelecionado: string;
    function OrdenacaoSelecionada: string;
    procedure Listar;
    function GetTabelaCols(const ATabela: string): TArray<string>;
    function FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
    procedure ApplyResponsiveLayout;
  protected
    procedure DoShow; override;
    procedure Resize; override;
  published

    procedure LbBtnBuscarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LvClientesItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure EdBuscarChangeTracking(Sender: TObject);
  public
  end;

var
  frmClientes: TfrmClientes;

implementation

{$R *.fmx}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.SmXhdpiPh.fmx ANDROID}

uses
  unDMApp,
  unClienteCadastro,
  unClienteDetalhe,
  unFuncoes,
  unAndroidComboFix;

procedure TfrmClientes.EnsureMesAnoCombo;
begin
  if not Assigned(CbMesAno) then
    Exit;
  CbMesAno.OnChange := FiltrosChange;
  CbMesAno.Visible := True;
end;

procedure TfrmClientes.PopularMeses;
var
  I: Integer;
  LMesAtual: string;
  LIndex: Integer;
begin
  EnsureMesAnoCombo;
  LMesAtual := FormatDateTime('mm/yyyy', Date);
  FAtualizandoFiltros := True;
  try
    CbMesAno.Items.Clear;
    CbMesAno.Items.Add('TODOS');
    for I := -6 to 6 do
      CbMesAno.Items.Add(FormatDateTime('mm/yyyy', IncMonth(Date, I)));
   { LIndex := CbMesAno.Items.IndexOf(LMesAtual);
    if LIndex < 0 then}
      LIndex := 0;
    CbMesAno.ItemIndex := LIndex;
  finally
    FAtualizandoFiltros := False;
  end;
end;

procedure TfrmClientes.AtualizarTecladoBusca;
var
  LTipoBusca: string;
begin
  if not Assigned(EdBuscar) then
    Exit;

  LTipoBusca := '';
  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) then
    LTipoBusca := CbModoBusca.Items[CbModoBusca.ItemIndex];

  if SameText(LTipoBusca, 'C' + #243 + 'digo') or
    SameText(LTipoBusca, 'M' + #233 + 'dia pedido') then
    EdBuscar.KeyboardType := TVirtualKeyboardType.NumberPad
  else if SameText(LTipoBusca, #218 + 'ltima venda') then
    EdBuscar.KeyboardType := TVirtualKeyboardType.NumbersAndPunctuation
  else
    EdBuscar.KeyboardType := TVirtualKeyboardType.Default;

  if SameText(LTipoBusca, 'M' + #233 + 'dia pedido') then
    EdBuscar.TextPrompt := 'Valor m' + #237 + 'nimo da m' + #233 + 'dia'
  else if SameText(LTipoBusca, #218 + 'ltima venda') then
    EdBuscar.TextPrompt := 'Data da ' + #250 + 'ltima venda (DD/MM/AAAA)'
  else
    EdBuscar.TextPrompt := 'Descri' + #231 + #227 + 'o ou c' + #243 + 'digo';
end;

procedure TfrmClientes.EdBuscarChangeTracking(Sender: TObject);
var
  I: Integer;
  LDigitos: string;
  LTextoFormatado: string;
begin
  if FAplicandoMascaraData or not Assigned(EdBuscar) or
    not Assigned(CbModoBusca) or (CbModoBusca.ItemIndex < 0) or
    not SameText(CbModoBusca.Items[CbModoBusca.ItemIndex], #218 + 'ltima venda') then
    Exit;

  LDigitos := '';
  for I := 1 to Length(EdBuscar.Text) do
    if (EdBuscar.Text[I] >= '0') and (EdBuscar.Text[I] <= '9') then
      LDigitos := LDigitos + EdBuscar.Text[I];
  if Length(LDigitos) > 8 then
    SetLength(LDigitos, 8);

  LTextoFormatado := Copy(LDigitos, 1, 2);
  if Length(LDigitos) > 2 then
    LTextoFormatado := LTextoFormatado + '/' + Copy(LDigitos, 3, 2);
  if Length(LDigitos) > 4 then
    LTextoFormatado := LTextoFormatado + '/' + Copy(LDigitos, 5, 4);

  if EdBuscar.Text <> LTextoFormatado then
  begin
    FAplicandoMascaraData := True;
    try
      EdBuscar.Text := LTextoFormatado;
      EdBuscar.CaretPosition := Length(LTextoFormatado);
    finally
      FAplicandoMascaraData := False;
    end;
  end;
end;
procedure TfrmClientes.FiltrosChange(Sender: TObject);
begin
  AtualizarTecladoBusca;
  if FAtualizandoFiltros then
    Exit;
  AgendarListar;
end;

procedure TfrmClientes.AgendarListar;
begin
  if not Assigned(FListarTimer) then
  begin
    FListarTimer := TTimer.Create(Self);
    FListarTimer.Enabled := False;
    FListarTimer.Interval := 350;
    FListarTimer.OnTimer := ListarTimerTimer;
  end;
  FListarTimer.Enabled := False;
  FListarTimer.Enabled := True;
end;

procedure TfrmClientes.ListarTimerTimer(Sender: TObject);
begin
  if Assigned(FListarTimer) then
    FListarTimer.Enabled := False;
  Listar;
end;

function TfrmClientes.MesAnoSelecionado: string;
begin
  Result := '';
  if Assigned(CbMesAno) and (CbMesAno.ItemIndex >= 0) then
    Result := Trim(CbMesAno.Items[CbMesAno.ItemIndex]);
  if SameText(Result, 'TODOS') then
    Result := '';
end;

function TfrmClientes.OrdenacaoSelecionada: string;
begin
  Result := 'ultima_venda';
  if Assigned(CbOrdenacao) and (CbOrdenacao.ItemIndex >= 0) then
  begin
    case CbOrdenacao.ItemIndex of
      0: Result := 'codigo';
      1: Result := 'nome';
      2: Result := 'ultima_venda';
      3: Result := 'media_valor_pedido';
    end;
  end;
end;

procedure TfrmClientes.DoShow;
begin
  inherited;
  OnClose := FormClose;
  ApplyResponsiveLayout;
end;

procedure TfrmClientes.Resize;
begin
  inherited;
  ApplyResponsiveLayout;
end;

procedure TfrmClientes.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LIsTabletPortrait: Boolean;
  LBottomMargin: Single;
  LContentW: Single;
  LX: Single;
  LY: Single;
  LFooterH: Single;
  LBtnW: Single;
  LListH: Single;
  LFieldsW: Single;
  LColumnW: Single;
begin
  if csDestroying in ComponentState then
    Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  LIsLandscape := ClientWidth > ClientHeight;
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 600);
  LBottomMargin := AndroidBottomSafeMargin(LIsLandscape);
  if LIsLandscape or LIsTabletPortrait then
  begin
    if LIsLandscape then
      TopBar.Height := 64
    else
      TopBar.Height := 82;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) * 0.78;

    if Min(ClientWidth, ClientHeight) >= 600 then
      LContentW := Min(ClientWidth - 28, 760)
    else
      LContentW := Min(ClientWidth - 20, 620);
    if LContentW < 280 then
      LContentW := ClientWidth - 8;
    LX := (ClientWidth - LContentW) * 0.5;

    EnsureMesAnoCombo;
    CardBusca.Align := TAlignLayout.None;
    CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 166);

    LBtnW := 90;
    BtnBuscar.Width := LBtnW;
    BtnBuscar.Height := 28;
    BtnBuscar.Position.X := CardBusca.Width - LBtnW - 18;
    BtnBuscar.Position.Y := 76;

    EdBuscar.Position.X := 18;
    EdBuscar.Width := CardBusca.Width - 36;
    EdBuscar.Position.Y := 30;

    CbModoBusca.Position.X := 18;
    CbMesAno.Position.X := 18;
    CbOrdenacao.Position.X := 18;
    if Assigned(LbMesAno) then
    begin
      LbMesAno.Align := TAlignLayout.None;
      LbMesAno.Visible := True;
    end;
    CbModoBusca.Height := 32;
    CbMesAno.Height := 32;
    CbModoBusca.Align := TAlignLayout.None;
    CbMesAno.Align := TAlignLayout.None;
    CbOrdenacao.Align := TAlignLayout.None;
    CbOrdenacao.Height := 32;
    if Assigned(LbOrdenacao) then
    begin
      LbOrdenacao.Align := TAlignLayout.None;
      LbOrdenacao.Position.X := 18;
      LbOrdenacao.Position.Y := 112;
      LbOrdenacao.Visible := True;
    end;

    if LIsTabletPortrait then
    begin
      if Assigned(LbBuscar) then
      begin
        LbBuscar.Align := TAlignLayout.None;
        LbBuscar.Position.X := 18;
        LbBuscar.Position.Y := 8;
        LbBuscar.Visible := True;
      end;
      if Assigned(Label1) then
      begin
        Label1.Align := TAlignLayout.None;
        Label1.Position.X := 18;
        Label1.Position.Y := 64;
        Label1.Width := 118;
        Label1.Visible := True;
      end;
      CbModoBusca.Position.Y := 82;
      CbMesAno.Position.Y := CbModoBusca.Position.Y;
      if Assigned(LbMesAno) then
      begin
        LbMesAno.Position.X := CbMesAno.Position.X;
        LbMesAno.Position.Y := CbMesAno.Position.Y - 18;
        LbMesAno.Width := 210;
        LbMesAno.TextSettings.Font.Size := 11;
      end;
      CbModoBusca.Width := 118;
      CbMesAno.Width := 108;
      CbMesAno.Position.X := CbModoBusca.Position.X + CbModoBusca.Width + 8;
      if Assigned(LbMesAno) then
        LbMesAno.Position.X := CbMesAno.Position.X;
      EdBuscar.Position.X := 18;
      EdBuscar.Position.Y := 30;
      EdBuscar.Width := CardBusca.Width - 36;
      if EdBuscar.Width < 120 then
        EdBuscar.Width := 120;
      CbOrdenacao.Position.Y := 130;
      CbOrdenacao.Width := 180;
      if Assigned(LbOrdenacao) then
        LbOrdenacao.Position.Y := 112;
    end
    else
    begin
      if Assigned(Label1) then
      begin
        Label1.Align := TAlignLayout.None;
        Label1.Position.X := 18;
        Label1.Position.Y := 56;
        Label1.Width := 118;
        Label1.Visible := True;
      end;
      CbModoBusca.Position.Y := 74;
      CbModoBusca.Width := 118;
      CbMesAno.Position.Y := 74;
      CbMesAno.Width := 108;
      CbMesAno.Position.X := CbModoBusca.Position.X + CbModoBusca.Width + 14;
      if Assigned(LbMesAno) then
      begin
        LbMesAno.Position.X := CbMesAno.Position.X;
        LbMesAno.Position.Y := 56;
        LbMesAno.Width := 210;
        LbMesAno.TextSettings.Font.Size := 11;
      end;
      BtnBuscar.Position.Y := 68;
      BtnBuscar.Height := 36;
      CbOrdenacao.Position.Y := 130;
      CbOrdenacao.Width := 180;
      if Assigned(LbOrdenacao) then
        LbOrdenacao.Position.Y := 112;
    end;

    if LIsLandscape then
    begin
      CardBusca.Height := 138;
      LBtnW := 90;
      BtnBuscar.Width := LBtnW;
      BtnBuscar.Height := 36;
      BtnBuscar.Position.X := CardBusca.Width - LBtnW - 18;
      BtnBuscar.Position.Y := 84;

      LFieldsW := BtnBuscar.Position.X - 18;
      LColumnW := (LFieldsW - 16) / 3;
      if LColumnW < 110 then
        LColumnW := 110;

      CbModoBusca.Position.X := 18;
      CbModoBusca.Position.Y := 90;
      CbModoBusca.Width := LColumnW;
      CbMesAno.Position.X := CbModoBusca.Position.X + LColumnW + 8;
      CbMesAno.Position.Y := 90;
      CbMesAno.Width := LColumnW;
      CbOrdenacao.Position.X := CbMesAno.Position.X + LColumnW + 8;
      CbOrdenacao.Position.Y := 90;
      CbOrdenacao.Width := LColumnW;

      if Assigned(Label1) then
      begin
        Label1.Position.X := CbModoBusca.Position.X;
        Label1.Position.Y := 70;
        Label1.Width := LColumnW;
      end;
      if Assigned(LbMesAno) then
      begin
        LbMesAno.Position.X := CbMesAno.Position.X;
        LbMesAno.Position.Y := 70;
        LbMesAno.Width := LColumnW;
      end;
      if Assigned(LbOrdenacao) then
      begin
        LbOrdenacao.Position.X := CbOrdenacao.Position.X;
        LbOrdenacao.Position.Y := 70;
        LbOrdenacao.Width := LColumnW;
      end;
    end;

    if LIsLandscape then
      LFooterH := 64
    else
      LFooterH := 56;
    lbottom.Align := TAlignLayout.None;
    lbottom.SetBounds(LX, ClientHeight - LFooterH - LBottomMargin - 4, LContentW, LFooterH);
    lbottom.Margins.Bottom := LBottomMargin;

    Layout1.Align := TAlignLayout.None;
    LY := CardBusca.Position.Y + CardBusca.Height + 8;
    LListH := lbottom.Position.Y - LY - 16;
    if LIsLandscape then
    begin
      if LListH < 48 then
        LListH := 48;
    end
    else if LListH < 120 then
      LListH := 120;
    Layout1.SetBounds(LX, LY, LContentW, LListH);
  end
  else
  begin
    EnsureMesAnoCombo;
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    CardBusca.Align := TAlignLayout.Top;
    CardBusca.Height := 188;
    LbBuscar.Position.X := 18;
    LbBuscar.Position.Y := 8;
    EdBuscar.Position.X := 18;
    EdBuscar.Position.Y := 30;
    EdBuscar.Width := CardBusca.Width - 36;
    CbModoBusca.Align := TAlignLayout.None;
    CbModoBusca.Position.X := 18;
    CbModoBusca.Position.Y := 94;
    CbModoBusca.Width := 118;
    CbModoBusca.Height := 32;
    CbMesAno.Align := TAlignLayout.None;
    CbMesAno.Position.X := CbModoBusca.Position.X + CbModoBusca.Width + 16;
    CbMesAno.Position.Y := CbModoBusca.Position.Y;
    CbMesAno.Width := 108;
    CbMesAno.Height := 32;
    CbOrdenacao.Align := TAlignLayout.None;
    CbOrdenacao.Position.X := 18;
    CbOrdenacao.Position.Y := 148;
    CbOrdenacao.Width := 180;
    CbOrdenacao.Height := 32;
    if Assigned(LbOrdenacao) then
    begin
      LbOrdenacao.Align := TAlignLayout.None;
      LbOrdenacao.Position.X := 18;
      LbOrdenacao.Position.Y := 130;
      LbOrdenacao.Width := 180;
      LbOrdenacao.Height := 16;
      LbOrdenacao.Visible := True;
    end;
    if Assigned(LbMesAno) then
    begin
      LbMesAno.Align := TAlignLayout.None;
      LbMesAno.Position.X := CbMesAno.Position.X;
      LbMesAno.Position.Y := 74;
      LbMesAno.Width := 210;
      LbMesAno.Height := 18;
      LbMesAno.TextSettings.Font.Size := 11;
      LbMesAno.Visible := True;
    end;
    BtnBuscar.Position.X := CardBusca.Width - 72;
    BtnBuscar.Position.Y := 148;
    BtnBuscar.Width := 54;
    BtnBuscar.Height := 32;

    Layout1.Align := TAlignLayout.Client;
    Layout1.Margins.Bottom := 10;

    lbottom.Align := TAlignLayout.MostBottom;
    lbottom.Margins.Bottom := LBottomMargin;
    lbottom.Height := 72;
  end;

  if Assigned(LvClientes) then
  begin
    if LIsLandscape then
      LvClientes.ItemAppearance.ItemHeight := 46
    else if LIsTabletPortrait then
      LvClientes.ItemAppearance.ItemHeight := 58
    else
      LvClientes.ItemAppearance.ItemHeight := 48;
    LvClientes.ItemAppearance.ItemEditHeight := LvClientes.ItemAppearance.ItemHeight;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Align := TListItemAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.TextAlign := TTextAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 10;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Height := 32;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.X := 1;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 5;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Width := Layout1.Width - 44;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Text.Align := TListItemAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Text.TextAlign := TTextAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Text.Width := Layout1.Width - 44;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Text.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Align := TListItemAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.TextAlign := TTextAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 9;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Height := 28;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.X := 1;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 18;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Width := Layout1.Width - 44;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Detail.Align := TListItemAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Detail.TextAlign := TTextAlign.Leading;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Detail.Width := Layout1.Width - 44;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Detail.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemObjects.Accessory.Visible := True;
    LvClientes.ItemAppearanceObjects.ItemObjects.Accessory.Width := 34;
    LvClientes.ItemAppearanceObjects.ItemObjects.Accessory.Height := 30;
    LvClientes.ItemAppearanceObjects.ItemObjects.Accessory.PlaceOffset.Y := 2;
  end;

end;

function TfrmClientes.GetTabelaCols(const ATabela: string): TArray<string>;
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

procedure TfrmClientes.ImgVoltarClick(Sender: TObject);
begin
  close;
end;

procedure TfrmClientes.BtnNovoClick(Sender: TObject);
begin
  if not Assigned(frmClienteCadastro) then
    Application.CreateForm(TfrmClienteCadastro, frmClienteCadastro);
  frmClienteCadastro.Show;
end;

procedure TfrmClientes.BtnBuscarClick(Sender: TObject);
begin
  AgendarListar;
end;

procedure TfrmClientes.BtnBuscarTap(Sender: TObject; const Point: TPointF);
begin
  AgendarListar;
end;

function TfrmClientes.FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
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

procedure TfrmClientes.Listar;
var
  LQuery: TFDQuery;
  LCampoCidade: string;
  LTexto: string;
  LItem: TListViewItem;
  LNome: string;
  LFantasia: string;
  LCidade: string;
  LCodigo: string;
  LUltimaVenda: string;
  LDTAUltimaVenda: string;
  LMediaValorPedido: Double;
  LMediaValor: string;
  LMesAno: string;
  LMes: Integer;
  LAno: Integer;
  LDataIni: string;
  LDataFim: string;
  LSql: string;
  LOrdenacao: string;
  LBuscaMedia: Boolean;
  LBuscaMediaValida: Boolean;
  LBuscaUltimaVenda: Boolean;
  LValorBusca: Double;
  LDataBusca: string;
  LBoletoAtraso: Boolean;
  LBoletoAberto: Boolean;

  function DataBR(const AValue: string): string;
  var
    LValue: string;
  begin
    LValue := Trim(AValue);
    Result := '';
    if Length(LValue) >= 10 then
      Result := Copy(LValue, 9, 2) + '/' + Copy(LValue, 6, 2) + '/' + Copy(LValue, 1, 4);
  end;

  function DataBuscaSql(const AValue: string): string;
  var
    I: Integer;
    LDigitos: string;
    LDia: Integer;
    LMes: Integer;
    LAno: Integer;
    LData: TDateTime;
  begin
    LDigitos := '';
    for I := 1 to Length(AValue) do
      if (AValue[I] >= '0') and (AValue[I] <= '9') then
        LDigitos := LDigitos + AValue[I];

    Result := '';
    if Length(LDigitos) <> 8 then
      Exit;

    LDia := StrToIntDef(Copy(LDigitos, 1, 2), 0);
    LMes := StrToIntDef(Copy(LDigitos, 3, 2), 0);
    LAno := StrToIntDef(Copy(LDigitos, 5, 4), 0);
    if TryEncodeDate(LAno, LMes, LDia, LData) then
      Result := FormatDateTime('yyyy-mm-dd', LData);
  end;

  function TryValorBusca(const AValue: string; out AValor: Double): Boolean;
  var
    LTextoValor: string;
    LFormatSettings: TFormatSettings;
  begin
    LTextoValor := Trim(AValue);
    LFormatSettings := TFormatSettings.Create;
    if Pos(',', LTextoValor) > 0 then
      LTextoValor := StringReplace(LTextoValor, '.', '', [rfReplaceAll]);
    LTextoValor := StringReplace(LTextoValor, ',', LFormatSettings.DecimalSeparator, [rfReplaceAll]);
    Result := TryStrToFloat(LTextoValor, AValor, LFormatSettings);
  end;
begin
  LTexto := Trim(EdBuscar.Text);
  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) then
  begin
    FBuscarPorCodigo := SameText(CbModoBusca.Items[CbModoBusca.ItemIndex], 'C' + #243 + 'digo');
    LCampoCidade := CbModoBusca.Items[CbModoBusca.ItemIndex];
  end
  else
  begin
    FBuscarPorCodigo := False;
    LCampoCidade := '';
  end;
  LBuscaMedia := SameText(LCampoCidade, 'M' + #233 + 'dia pedido');
  LBuscaUltimaVenda := SameText(LCampoCidade, #218 + 'ltima venda');
  LValorBusca := 0;
  LDataBusca := '';
  LBuscaMediaValida := not LBuscaMedia;
  if LBuscaMedia and (LTexto <> '') then
    LBuscaMediaValida := TryValorBusca(LTexto, LValorBusca);
  if LBuscaUltimaVenda and (LTexto <> '') then
    LDataBusca := DataBuscaSql(LTexto);

  LMesAno := MesAnoSelecionado;
  LOrdenacao := OrdenacaoSelecionada;
  LDataIni := '';
  LDataFim := '';
  if Length(LMesAno) = 7 then
  begin
    LMes := StrToIntDef(Copy(LMesAno, 1, 2), 0);
    LAno := StrToIntDef(Copy(LMesAno, 4, 4), 0);
    if (LMes >= 1) and (LMes <= 12) and (LAno > 1900) then
    begin
      LDataIni := FormatDateTime('yyyy-mm-dd', EncodeDate(LAno, LMes, 1));
      LDataFim := FormatDateTime('yyyy-mm-dd', EndOfTheMonth(EncodeDate(LAno, LMes, 1)));
    end;
  end;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LSql :=
      'select c.cod_cliente, c.nom_cliente, coalesce(c.nom_fantasia, '''') as nom_fantasia, ' +
      '       cd.nom_cidade||''-''||cd.uf as cidade_desc, uv.ultima_venda, ' +
      '       c.dta_ultima_venda, c.media_valor_pedido, ' +
      '       case when exists (select 1 from cr1 b ' +
      '         where b.cod_cliente = c.cod_cliente ' +
      '           and trim(coalesce(b.dtarec, '''')) = '''' ' +
      '           and date(case ' +
      '             when substr(trim(b.dtaven), 5, 1) = ''-'' then substr(trim(b.dtaven), 1, 10) ' +
      '             when substr(trim(b.dtaven), 3, 1) = ''/'' then substr(trim(b.dtaven), 7, 4) || ''-'' || ' +
      '                  substr(trim(b.dtaven), 4, 2) || ''-'' || substr(trim(b.dtaven), 1, 2) ' +
      '             else trim(b.dtaven) end) < date(''now'', ''localtime'')) ' +
       '         then 1 else 0 end as boleto_atraso, ' +
       '       case when exists (select 1 from cr1 bo ' +
       '         where bo.cod_cliente = c.cod_cliente ' +
       '           and trim(coalesce(bo.dtarec, '''')) = '''') ' +
       '         then 1 else 0 end as boleto_aberto ' +
      '  from cliente c ' +
      '  left outer join cidades cd on cd.cod_cidade = c.cod_cidade ' +
      '  left outer join ( ' +
      '    select cod_cliente, max(date(coalesce(nullif(dta_emissao, ''''), nullif(dtadoc, '''')))) as ultima_venda, ';

    if LDataIni <> '' then
      LSql := LSql +
        '           sum(case when date(coalesce(nullif(dta_emissao, ''''), nullif(dtadoc, ''''))) between :dtaini and :dtafim then 1 else 0 end) as vendas_periodo '
    else
      LSql := LSql +
        '           0 as vendas_periodo ';

    LSql := LSql +
      '      from vendas1 ' +
      '     where coalesce(cast(faturado as text), ''0'') in (''1'', ''S'') ' +
      '       and coalesce(cast(nfeentradasaida as text), ''0'') in (''0'', ''N'', '''') ' +
      '       and coalesce(cast(orcamento as text), ''0'') in (''0'', ''N'', '''') ';

    if LDataIni <> '' then
      LSql := LSql +
        '       and date(coalesce(nullif(dta_emissao, ''''), nullif(dtadoc, ''''))) <= :dtafim_filtro ';

    LSql := LSql +
      '     group by cod_cliente ' +
      '  ) uv on uv.cod_cliente = c.cod_cliente ' +
      ' where 1=1 ';

    if LTexto <> '' then
    begin
      if FBuscarPorCodigo then
        LSql := LSql + 'and c.cod_cliente = :p0 '
      else if SameText(LCampoCidade, 'Cidade') then
        LSql := LSql + 'and upper(coalesce(cd.nom_cidade, '''') || ''-'' || coalesce(cd.uf, '''')) like :p0 '
      else if SameText(LCampoCidade, 'Fantasia') then
        LSql := LSql + 'and upper(coalesce(c.nom_fantasia, '''')) like :p0 '
      else if LBuscaMedia then
      begin
        if LBuscaMediaValida then
          LSql := LSql + 'and coalesce(c.media_valor_pedido, 0) >= :p0 '
        else
          LSql := LSql + 'and 1 = 0 ';
      end
      else if LBuscaUltimaVenda then
      begin
        if LDataBusca <> '' then
          LSql := LSql + 'and date(coalesce(c.dta_ultima_venda, uv.ultima_venda)) <= :p0 '
        else
          LSql := LSql + 'and 1 = 0 ';
      end
      else
        LSql := LSql + 'and upper(coalesce(c.nom_cliente, '''')) like :p0 ';
    end;

    if LDataIni <> '' then
      LSql := LSql + 'and coalesce(uv.vendas_periodo, 0) = 0 ';

    if LOrdenacao = 'codigo' then
      LSql := LSql + 'order by c.cod_cliente '
    else if LOrdenacao = 'nome' then
      LSql := LSql + 'order by c.nom_cliente '
    else if LOrdenacao = 'media_valor_pedido' then
      LSql := LSql + 'order by coalesce(c.media_valor_pedido, 0) desc, c.nom_cliente '
    else
      LSql := LSql + 'order by coalesce(c.dta_ultima_venda, uv.ultima_venda) desc, c.nom_cliente ';
    LSql := LSql + 'limit 120';
    LQuery.SQL.Text := LSql;

    if LTexto <> '' then
    begin
      if FBuscarPorCodigo then
        LQuery.ParamByName('p0').AsString := LTexto
      else if LBuscaMedia and LBuscaMediaValida then
        LQuery.ParamByName('p0').AsFloat := LValorBusca
      else if LBuscaUltimaVenda and (LDataBusca <> '') then
        LQuery.ParamByName('p0').AsString := LDataBusca
      else if (LBuscaMedia and not LBuscaMediaValida) or
        (LBuscaUltimaVenda and (LDataBusca = '')) then
      begin
      end
      else
        LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    end;
    if LDataIni <> '' then
    begin
      LQuery.ParamByName('dtafim_filtro').AsString := LDataFim;
      LQuery.ParamByName('dtaini').AsString := LDataIni;
      LQuery.ParamByName('dtafim').AsString := LDataFim;
    end;
    LQuery.Open;

    LvClientes.Items.BeginUpdate;
    try
      LvClientes.Items.Clear;
      while not LQuery.Eof do
      begin
        LNome := LQuery.FieldByName('nom_cliente').AsString;
        LFantasia := Trim(LQuery.FieldByName('nom_fantasia').AsString);
        LCodigo := LQuery.FieldByName('cod_cliente').AsString;
        if (LQuery.FindField('cidade_desc') <> nil) then
          LCidade := LQuery.FieldByName('cidade_desc').AsString
        else
          LCidade := '';
        LUltimaVenda := DataBR(LQuery.FieldByName('ultima_venda').AsString);

        LDTAUltimaVenda := '';
        if LQuery.FindField('dta_ultima_venda') <> nil then
          LDTAUltimaVenda := DataBR(LQuery.FieldByName('dta_ultima_venda').AsString);
        if LDTAUltimaVenda = '' then
          LDTAUltimaVenda := LUltimaVenda;

        LBoletoAtraso := LQuery.FindField('boleto_atraso') <> nil;
        if LBoletoAtraso then
          LBoletoAtraso := LQuery.FieldByName('boleto_atraso').AsInteger = 1;

        LBoletoAberto := LQuery.FindField('boleto_aberto') <> nil;
        if LBoletoAberto then
          LBoletoAberto := LQuery.FieldByName('boleto_aberto').AsInteger = 1;

        LMediaValorPedido := 0;
        if LQuery.FindField('media_valor_pedido') <> nil then
          LMediaValorPedido := LQuery.FieldByName('media_valor_pedido').AsFloat;
        if LMediaValorPedido > 0 then
          LMediaValor := FormatFloat('#,##0.00', LMediaValorPedido)
        else
          LMediaValor := '';

        LItem := LvClientes.Items.Add;
        if LCodigo <> '' then
          LItem.Text := LCodigo + ' - ' + LNome
        else
          LItem.Text := LNome;

        if LCidade = '' then
          LCidade := '--';
        if LDTAUltimaVenda = '' then
          LDTAUltimaVenda := '--';
        if trim(LFantasia) <> '' then
          LItem.Detail := LFantasia + sLineBreak + LCidade + ' | ' + #218 + 'lt. venda: ' + LDTAUltimaVenda
        else
          LItem.Detail := LCidade + ' | ' + #218 + 'lt. venda: ' + LDTAUltimaVenda;
        if LMediaValor <> '' then
          LItem.Detail := LItem.Detail + ' | ' + 'M' + #233 + 'dia pedido: R$ ' + LMediaValor;
        if LBoletoAtraso then
        begin
          if Assigned(LItem.Objects.TextObject) then
            LItem.Objects.TextObject.TextColor := TAlphaColor($FFFF0000);
          if Assigned(LItem.Objects.DetailObject) then
            LItem.Objects.DetailObject.TextColor := TAlphaColor($FFFF0000);
        end
        else if LBoletoAberto then
        begin
          if Assigned(LItem.Objects.TextObject) then
            LItem.Objects.TextObject.TextColor := TAlphaColor($FF008000);
          if Assigned(LItem.Objects.DetailObject) then
            LItem.Objects.DetailObject.TextColor := TAlphaColor($FF008000);
        end;

        LQuery.Next;
      end;
    finally
      LvClientes.Items.EndUpdate;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmClientes.LbBtnBuscarClick(Sender: TObject);
begin
end;

procedure TfrmClientes.FormShow(Sender: TObject);
begin
  if Assigned(EdBuscar) then
    EdBuscar.TextPrompt := 'Descri' + #231 + #227 + 'o ou c' + #243 + 'digo';
  EnsureMesAnoCombo;
  UseAndroidSafeComboPicker([CbModoBusca, CbMesAno, CbOrdenacao]);
  if Assigned(CbModoBusca) then
  begin
    CbModoBusca.Items.Clear;
    CbModoBusca.Items.Add('Nome');
    CbModoBusca.Items.Add('C' + #243 + 'digo');
    CbModoBusca.Items.Add('Cidade');
    CbModoBusca.Items.Add('Fantasia');
    CbModoBusca.Items.Add('M' + #233 + 'dia pedido');
    CbModoBusca.Items.Add(#218 + 'ltima venda');
    CbModoBusca.ItemIndex := 0;
    CbModoBusca.OnChange := FiltrosChange;
  end;
  if Assigned(CbOrdenacao) then
  begin
    CbOrdenacao.Items.Clear;
    CbOrdenacao.Items.Add('C' + #243 + 'digo');
    CbOrdenacao.Items.Add('Nome');
    CbOrdenacao.Items.Add(#218 + 'ltima venda');
    CbOrdenacao.Items.Add('M' + #233 + 'dia pedido');
    CbOrdenacao.ItemIndex := 2;
    CbOrdenacao.OnChange := FiltrosChange;
  end;
  AtualizarTecladoBusca;
  PopularMeses;
  FBuscarPorCodigo := False;
  ApplyResponsiveLayout;
  Listar;
end;

procedure TfrmClientes.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FListarTimer) then
    FListarTimer.Enabled := False;
  Action := TCloseAction.caFree;
  frmClientes := nil;
end;

procedure TfrmClientes.LvClientesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  LNome: string;
  LCodigo: string;
  LCidade: string;
  LDetail: string;
begin
  if not Assigned(AItem) then
    Exit;
  LNome := AItem.Text;
  LDetail := AItem.Detail;
  LCodigo := '';
  LCidade := '';
  if Pos(' - ', LNome) > 0 then
  begin
    LCodigo := Trim(Copy(LNome, 1, Pos(' - ', LNome) - 1));
    LNome := Trim(Copy(LNome, Pos(' - ', LNome) + 3, MaxInt));
  end;

  if Pos(sLineBreak, LDetail) > 0 then
    LDetail := Copy(LDetail, Pos(sLineBreak, LDetail) + Length(sLineBreak), MaxInt);
  if Pos(' | ', LDetail) > 0 then
    LDetail := Copy(LDetail, 1, Pos(' | ', LDetail) - 1);
  if LDetail <> '' then
     LCidade := LDetail;

  if Assigned(dmApp) then
  begin
    try
      dmApp.SetAppState('cliente_detalhe', StrToIntDef(LCodigo, 0), '');
    except
    end;
  end;

  if not Assigned(frmClienteDetalhe) then
    Application.CreateForm(TfrmClienteDetalhe, frmClienteDetalhe);
  frmClienteDetalhe.SetCliente(LNome, LCodigo, LCidade);
  frmClienteDetalhe.Show;
end;

end.

