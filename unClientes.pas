unit unClientes;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  System.Math,
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
    BtnBuscar: TImage;
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnBuscarTap(Sender: TObject; const Point: TPointF);
    procedure ImgVoltarClick(Sender: TObject);
    procedure BtnNovoClick(Sender: TObject);
  private
    FBuscarPorCodigo: Boolean;
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

uses
  unDMApp,
  unClienteCadastro,
  unClienteDetalhe,
  unFuncoes;

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
  LIsTabletPortrait := (not LIsLandscape) and (ClientWidth >= 430);
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

    CardBusca.Align := TAlignLayout.None;
    if LIsTabletPortrait then
      CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 78)
    else
      CardBusca.SetBounds(LX, TopBar.Height + 8, LContentW, 96);

    EdBuscar.Position.X := 18;
    if LIsTabletPortrait then
      EdBuscar.Position.Y := 32
    else
      EdBuscar.Position.Y := 20.8;

    LBtnW := 90;
    BtnBuscar.Width := LBtnW;
    BtnBuscar.Height := 28;
    BtnBuscar.Position.X := CardBusca.Width - LBtnW - 18;
    if LIsTabletPortrait then
      BtnBuscar.Position.Y := 35
    else
      BtnBuscar.Position.Y := 59;

    if LIsTabletPortrait then
    begin
      CbModoBusca.Position.X := 18;
      CbModoBusca.Position.Y := 32;
      CbModoBusca.Width := 130;
      EdBuscar.Position.X := CbModoBusca.Position.X + CbModoBusca.Width + 8;
      EdBuscar.Width := BtnBuscar.Position.X - EdBuscar.Position.X - 8;
    end
    else
    begin
      EdBuscar.Width := CardBusca.Width - 36;
      CbModoBusca.Position.X := 18;
      CbModoBusca.Position.Y := 59;
      CbModoBusca.Width := BtnBuscar.Position.X - 24;
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
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    CardBusca.Align := TAlignLayout.Top;
    Layout1.Align := TAlignLayout.Client;
    Layout1.Margins.Bottom := 10;

    lbottom.Align := TAlignLayout.MostBottom;
    lbottom.Margins.Bottom := LBottomMargin;
    lbottom.Height := 72;
  end;

  if Assigned(LvClientes) then
  begin
    if LIsLandscape then
      LvClientes.ItemAppearance.ItemHeight := 40
    else if LIsTabletPortrait then
      LvClientes.ItemAppearance.ItemHeight := 52
    else
      LvClientes.ItemAppearance.ItemHeight := 45;
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
  LCols: TArray<string>;
  LCampoNome: string;
  LCampoCidade: string;
  LCampoCodigo: string;
  LTexto: string;
  LItem: TListViewItem;
  LNome: string;
  LCidade: string;
  LCodigo: string;
begin
  LCols := GetTabelaCols('cliente');
  if Length(LCols) = 0 then
    Exit;

  LCampoCodigo := FindCampo(LCols, ['cod_cliente']);
  LCampoNome := FindCampo(LCols, ['nom_cliente']);

  LTexto := Trim(EdBuscar.Text);
  if Assigned(CbModoBusca) then
  begin
    FBuscarPorCodigo := SameText(CbModoBusca.Selected.Text, 'Código');
    LCampoCidade := CbModoBusca.Selected.Text;
  end
  else
  begin
    FBuscarPorCodigo := False;
    LCampoCidade := '';
  end;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    if FBuscarPorCodigo then
    begin
      LQuery.SQL.Text := Format('select c.cod_cliente, c.nom_cliente, cd.nom_cidade||''-''||cd.uf as cidade_desc from cliente c left outer join cidades cd on cd.cod_cidade = c.cod_cidade where %s = :p0 order by nom_cliente limit 200', [LCampoCodigo]);
      LQuery.ParamByName('p0').AsString := LTexto;
    end
    else if SameText(LCampoCidade, 'Cidade') then
    begin
      LQuery.SQL.Text :=
        'select c.cod_cliente, c.nom_cliente, cd.nom_cidade||''-''||cd.uf as cidade_desc '+
        'from cliente c '+
        'left outer join cidades cd on cd.cod_cidade = c.cod_cidade '+
        'where upper(coalesce(cd.nom_cidade, '''') || ''-'' || coalesce(cd.uf, '''')) like :p0 '+
        'order by cd.nom_cidade, c.nom_cliente limit 200';
      LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    end
    else
    begin
      LQuery.SQL.Text := Format('select c.cod_cliente, c.nom_cliente, cd.nom_cidade||''-''||cd.uf as cidade_desc from cliente C left outer join cidades cd on cd.cod_cidade = c.cod_cidade  where upper(coalesce(%s, '''')) like :p0 order by nom_cliente limit 200', [LCampoNome]);
      LQuery.ParamByName('p0').AsString := '%' + UpperCase(LTexto) + '%';
    end;
    LQuery.Open;

    //LCampoCidade := FindCampo(LCols, ['cidade_desc']);

    if LCampoCodigo = '' then
      LCampoCodigo := LCols[0];
    if LCampoNome = '' then
      LCampoNome := LCampoCodigo;


    LvClientes.Items.Clear;
    while not LQuery.Eof do
    begin
      LNome := LQuery.FieldByName(LCampoNome).AsString;
      LCodigo := LQuery.FieldByName(LCampoCodigo).AsString;
      if (LQuery.FindField('cidade_desc') <> nil) then
        LCidade := LQuery.FieldByName('cidade_desc').AsString
      else
        LCidade := '';

      LItem := LvClientes.Items.Add;
      if LCodigo <> '' then
        LItem.Text := LCodigo + ' - ' + LNome
      else
        LItem.Text := LNome;

      if LCidade <> '' then
        LItem.Detail := LCidade
      else
        LItem.Detail := '--';

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
  if Assigned(CbModoBusca) then
  begin
    CbModoBusca.Items.Clear;
    CbModoBusca.Items.Add('Nome');
    CbModoBusca.Items.Add('Código');
    CbModoBusca.Items.Add('Cidade');
    CbModoBusca.ItemIndex := 0;
  end;
  FBuscarPorCodigo := False;
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

  if LDetail <> '' then
     LCidade := LDetail;

  if not Assigned(frmClienteDetalhe) then
    Application.CreateForm(TfrmClienteDetalhe, frmClienteDetalhe);
  frmClienteDetalhe.SetCliente(LNome, LCodigo, LCidade);
  frmClienteDetalhe.Show;
end;

end.
