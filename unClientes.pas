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
    BtnBuscar: TImage;
    Label1: TLabel;
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnBuscarTap(Sender: TObject; const Point: TPointF);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnNovoClick(Sender: TObject);
  private
    FBuscarPorCodigo: Boolean;
    FAtualizandoFiltros: Boolean;
    procedure EnsureMesAnoCombo;
    procedure PopularMeses;
    procedure FiltrosChange(Sender: TObject);
    procedure AtualizarTecladoBusca;
    function MesAnoSelecionado: string;
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
begin
  if not Assigned(EdBuscar) then
    Exit;

  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) and
     SameText(CbModoBusca.Items[CbModoBusca.ItemIndex], 'Código') then
    EdBuscar.KeyboardType := TVirtualKeyboardType.NumberPad
  else
    EdBuscar.KeyboardType := TVirtualKeyboardType.Default;
end;
procedure TfrmClientes.FiltrosChange(Sender: TObject);
begin
  AtualizarTecladoBusca;
  if FAtualizandoFiltros then
    Exit;
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
begin
  if csDestroying in ComponentState then
    Exit;
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  LIsLandscape := ClientWidth > ClientHeight;
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 600);
  LBottomMargin := 0;
  if not LIsLandscape then
    LBottomMargin := 50;
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
    if LIsTabletPortrait then
      CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 82)
    else
      CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 112);

    LBtnW := 90;
    BtnBuscar.Width := LBtnW;
    BtnBuscar.Height := 28;
    BtnBuscar.Position.X := CardBusca.Width - LBtnW - 18;
    if LIsTabletPortrait then
      BtnBuscar.Position.Y := 38
    else
      BtnBuscar.Position.Y := 59;

    EdBuscar.Position.X := 18;
    EdBuscar.Width := CardBusca.Width - 36;
    if LIsTabletPortrait then
      EdBuscar.Position.Y := 12
    else
      EdBuscar.Position.Y := 20.8;

    CbModoBusca.Position.X := 18;
    CbMesAno.Position.X := 18;
    if Assigned(LbMesAno) then
    begin
      LbMesAno.Align := TAlignLayout.None;
      LbMesAno.Visible := True;
    end;
    CbModoBusca.Height := 32;
    CbMesAno.Height := 32;
    CbModoBusca.Align := TAlignLayout.None;
    CbMesAno.Align := TAlignLayout.None;

    if LIsTabletPortrait then
    begin
      CbModoBusca.Position.Y := 42;
      CbMesAno.Position.Y := CbModoBusca.Position.Y;
      if Assigned(LbMesAno) then
      begin
        LbMesAno.Position.X := CbMesAno.Position.X;
        LbMesAno.Position.Y := CbMesAno.Position.Y - 16;
        LbMesAno.Width := 210;
        LbMesAno.TextSettings.Font.Size := 11;
      end;
      CbModoBusca.Width := 118;
      CbMesAno.Width := 108;
      CbMesAno.Position.X := CbModoBusca.Position.X + CbModoBusca.Width + 8;
      if Assigned(LbMesAno) then
        LbMesAno.Position.X := CbMesAno.Position.X;
      EdBuscar.Position.X := CbMesAno.Position.X + CbMesAno.Width + 8;
      EdBuscar.Position.Y := 42;
      EdBuscar.Width := BtnBuscar.Position.X - EdBuscar.Position.X - 8;
      if EdBuscar.Width < 120 then
        EdBuscar.Width := 120;
    end
    else
    begin
      if Assigned(Label1) then
      begin
        Label1.Align := TAlignLayout.None;
        Label1.Position.X := 18;
        Label1.Position.Y := 56;
        Label1.Width := 70;
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
    end;

    LFooterH := 56;
    lbottom.Align := TAlignLayout.None;
    lbottom.SetBounds(LX, ClientHeight - LFooterH - LBottomMargin - 4, LContentW, LFooterH);
    lbottom.Margins.Bottom := LBottomMargin;

    Layout1.Align := TAlignLayout.None;
    LY := CardBusca.Position.Y + CardBusca.Height + 8;
    LListH := lbottom.Position.Y - LY - 8;
    if LListH < 120 then
      LListH := 120;
    Layout1.SetBounds(LX, LY, LContentW, LListH);
  end
  else
  begin
    EnsureMesAnoCombo;
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    CardBusca.Align := TAlignLayout.Top;
    CardBusca.Height := 142;
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
    BtnBuscar.Position.Y := 94;
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
      LvClientes.ItemAppearance.ItemHeight := 56
    else
      LvClientes.ItemAppearance.ItemHeight := 48;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Font.Size := 10;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.Height := 16;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.PlaceOffset.Y := 5;
    LvClientes.ItemAppearanceObjects.ItemObjects.Text.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Text.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Font.Size := 9;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.Height := 30;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.PlaceOffset.Y := 18;
    LvClientes.ItemAppearanceObjects.ItemObjects.Detail.WordWrap := True;
    LvClientes.ItemAppearanceObjects.ItemEditObjects.Detail.WordWrap := True;
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
  Listar;
end;

procedure TfrmClientes.BtnBuscarTap(Sender: TObject; const Point: TPointF);
begin
  Listar;
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
  LMesAno: string;
  LMes: Integer;
  LAno: Integer;
  LDataIni: string;
  LDataFim: string;
  LSql: string;

  function DataBR(const AValue: string): string;
  var
    LValue: string;
  begin
    LValue := Trim(AValue);
    Result := '';
    if Length(LValue) >= 10 then
      Result := Copy(LValue, 9, 2) + '/' + Copy(LValue, 6, 2) + '/' + Copy(LValue, 1, 4);
  end;
begin
  LTexto := Trim(EdBuscar.Text);
  if Assigned(CbModoBusca) and (CbModoBusca.ItemIndex >= 0) then
  begin
    FBuscarPorCodigo := SameText(CbModoBusca.Items[CbModoBusca.ItemIndex], 'Código');
    LCampoCidade := CbModoBusca.Items[CbModoBusca.ItemIndex];
  end
  else
  begin
    FBuscarPorCodigo := False;
    LCampoCidade := '';
  end;

  LMesAno := MesAnoSelecionado;
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
      'select * from (' +
      '  select c.cod_cliente, c.nom_cliente, coalesce(c.nom_fantasia, '''') as nom_fantasia, cd.nom_cidade||''-''||cd.uf as cidade_desc, ' +
      '         (select max(date(coalesce(nullif(vu.dta_emissao, ''''), nullif(vu.dtadoc, '''')))) ' +
      '            from vendas1 vu ' +
      '           where vu.cod_cliente = c.cod_cliente ' +
      '             and coalesce(cast(vu.faturado as text), ''0'') in (''1'', ''S'') ' +
      '             and coalesce(cast(vu.nfeentradasaida as text), ''0'') in (''0'', ''N'', '''') ' +
      '             and coalesce(cast(vu.orcamento as text), ''0'') in (''0'', ''N'', '''') ' +
      '             and (:dtafim_filtro = '''' or date(coalesce(nullif(vu.dta_emissao, ''''), nullif(vu.dtadoc, ''''))) <= :dtafim_filtro) ' +
      '         ) as ultima_venda ' +
      '    from cliente c ' +
      '    left outer join cidades cd on cd.cod_cidade = c.cod_cidade ' +
      ') x where 1=1 ';

    if FBuscarPorCodigo then
      LSql := LSql + 'and x.cod_cliente = :p0 '
    else if SameText(LCampoCidade, 'Cidade') then
      LSql := LSql + 'and upper(coalesce(x.cidade_desc, '''')) like :p0 '
    else if SameText(LCampoCidade, 'Fantasia') then
      LSql := LSql + 'and upper(coalesce(x.nom_fantasia, '''')) like :p0 '
    else
      LSql := LSql + 'and upper(coalesce(x.nom_cliente, '''')) like :p0 ';

    if LDataIni <> '' then
      LSql := LSql +
        'and not exists (' +
        '  select 1 from vendas1 v1 ' +
        '   where v1.cod_cliente = x.cod_cliente ' +
        '     and coalesce(cast(v1.faturado as text), ''0'') in (''1'', ''S'') ' +
        '     and coalesce(cast(v1.nfeentradasaida as text), ''0'') in (''0'', ''N'', '''') ' +
        '     and coalesce(cast(v1.orcamento as text), ''0'') in (''0'', ''N'', '''') ' +
        '     and date(coalesce(nullif(v1.dta_emissao, ''''), nullif(v1.dtadoc, ''''))) between :dtaini and :dtafim ' +
        ') ';

    LSql := LSql + 'order by x.ultima_venda desc, x.nom_cliente limit 200';
    LQuery.SQL.Text := LSql;

    if FBuscarPorCodigo then
      LQuery.ParamByName('p0').AsString := LTexto
    else
      LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    if LDataIni <> '' then
    begin
      LQuery.ParamByName('dtafim_filtro').AsString := LDataFim;
      LQuery.ParamByName('dtaini').AsString := LDataIni;
      LQuery.ParamByName('dtafim').AsString := LDataFim;
    end
    else
      LQuery.ParamByName('dtafim_filtro').AsString := '';
    LQuery.Open;

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

      LItem := LvClientes.Items.Add;
      if LCodigo <> '' then
        LItem.Text := LCodigo + ' - ' + LNome
      else
        LItem.Text := LNome;

      if LCidade = '' then
        LCidade := '--';
      if LUltimaVenda = '' then
        LUltimaVenda := '--';
      if trim(LFantasia) <> '' then
        LItem.Detail := LFantasia + sLineBreak + LCidade + ' | Ult. venda: ' + LUltimaVenda
      else
        LItem.Detail := LCidade + ' | Ult. venda: ' + LUltimaVenda;

      LQuery.Next;
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
  EnsureMesAnoCombo;
  UseAndroidSafeComboPicker([CbModoBusca, CbMesAno]);
  if Assigned(CbModoBusca) then
  begin
    CbModoBusca.Items.Clear;
    CbModoBusca.Items.Add('Nome');
    CbModoBusca.Items.Add('Código');
    CbModoBusca.Items.Add('Cidade');
    CbModoBusca.Items.Add('Fantasia');
    CbModoBusca.ItemIndex := 0;
    CbModoBusca.OnChange := FiltrosChange;
  end;
  AtualizarTecladoBusca;
  PopularMeses;
  FBuscarPorCodigo := False;
  ApplyResponsiveLayout;
  Listar;
end;

procedure TfrmClientes.FormClose(Sender: TObject; var Action: TCloseAction);
begin
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

  if not Assigned(frmClienteDetalhe) then
    Application.CreateForm(TfrmClienteDetalhe, frmClienteDetalhe);
  frmClienteDetalhe.SetCliente(LNome, LCodigo, LCidade);
  frmClienteDetalhe.Show;
end;

end.
