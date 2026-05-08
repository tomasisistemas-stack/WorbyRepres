unit unPrazoPgto;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  Data.DB, FireDAC.Comp.Client;

type
  TfrmPrazoPgto = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LvPrazos: TListView;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    procedure FormShow(Sender: TObject);
    procedure LvPrazosItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure ImgVoltarClick(Sender: TObject);
  private
    procedure Listar;
    function GetTabelaCols(const ATabela: string): TArray<string>;
    function FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
  public
  end;

var
  frmPrazoPgto: TfrmPrazoPgto;

implementation

{$R *.fmx}

uses
  unDMApp,
  unPedido;

function TfrmPrazoPgto.GetTabelaCols(const ATabela: string): TArray<string>;
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

function TfrmPrazoPgto.FindCampo(const ACols: TArray<string>; const ACandidatos: array of string): string;
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

procedure TfrmPrazoPgto.Listar;
var
  LQuery: TFDQuery;
  LCols: TArray<string>;
  LCampoCodigo: string;
  LCampoNome: string;
  LItem: TListViewItem;
  LCodigo: string;
  LNome: string;
begin
  LCols := GetTabelaCols('prazo');
  if Length(LCols) = 0 then
    Exit;

  LCampoCodigo := FindCampo(LCols, ['id', 'cod_prazo', 'codigo']);
  LCampoNome := FindCampo(LCols, ['prazo', 'descricao', 'nom_prazo', 'nome']);

  if LCampoCodigo = '' then
    LCampoCodigo := LCols[0];
  if LCampoNome = '' then
    LCampoNome := LCampoCodigo;

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := dmApp.FDConnection;
    LQuery.SQL.Text := Format('select %s as codigo, %s as nome from prazo order by %s', [
      LCampoCodigo, LCampoNome, LCampoNome
    ]);
    LQuery.Open;

    LvPrazos.Items.Clear;
    while not LQuery.Eof do
    begin
      LCodigo := LQuery.FieldByName('codigo').AsString;
      LNome := LQuery.FieldByName('nome').AsString;

      LItem := LvPrazos.Items.Add;
      if LCodigo <> '' then
        LItem.Text := LCodigo + ' - ' + LNome
      else
        LItem.Text := LNome;

      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmPrazoPgto.FormShow(Sender: TObject);
begin
  Listar;
end;

procedure TfrmPrazoPgto.LvPrazosItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  LTexto: string;
  LCodigo: string;
  LNome: string;
begin
  if not Assigned(AItem) then
    Exit;
  LTexto := AItem.Text;
  LCodigo := '';
  LNome := LTexto;
  if Pos(' - ', LTexto) > 0 then
  begin
    LCodigo := Trim(Copy(LTexto, 1, Pos(' - ', LTexto) - 1));
    LNome := Trim(Copy(LTexto, Pos(' - ', LTexto) + 3, MaxInt));
  end;

  if Assigned(frmPedido) then
    frmPedido.SelecionarPrazoPgto(StrToIntDef(LCodigo, 0), LNome);

  Close;
end;

procedure TfrmPrazoPgto.ImgVoltarClick(Sender: TObject);
begin
  Close;
end;

end.
