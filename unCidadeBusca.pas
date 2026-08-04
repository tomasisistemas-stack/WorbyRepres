unit unCidadeBusca;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Edit, FMX.ListView,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  Data.DB, FireDAC.Comp.Client;

type
  TfrmCidadeBusca = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    CardBusca: TRectangle;
    LbBuscar: TLabel;
    EdBuscar: TEdit;
    BtnBuscar: TRectangle;
    LbBtnBuscar: TLabel;
    LvCidades: TListView;
    LyRodape: TLayout;
    BtnVoltar: TRectangle;
    LbVoltar: TLabel;
    procedure FormShow(Sender: TObject);
    procedure BtnBuscarClick(Sender: TObject);
    procedure BtnVoltarClick(Sender: TObject);
    procedure LvCidadesItemClick(const Sender: TObject; const AItem: TListViewItem);
  private
    procedure Listar;
  public
  end;

var
  frmCidadeBusca: TfrmCidadeBusca;

implementation

{$R *.fmx}

uses
  unDMApp,
  unClienteCadastro;

procedure TfrmCidadeBusca.FormShow(Sender: TObject);
begin
  Listar;
end;

procedure TfrmCidadeBusca.BtnBuscarClick(Sender: TObject);
begin
  Listar;
end;

procedure TfrmCidadeBusca.BtnVoltarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCidadeBusca.Listar;
var
  Q: TFDQuery;
  LBusca: string;
  LItem: TListViewItem;
begin
  LvCidades.Items.Clear;
  LBusca := Trim(EdBuscar.Text);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    if not Q.Connection.Connected then
      Q.Connection.Connected := True;

    if LBusca = '' then
    begin
      Q.SQL.Text :=
        'select cod_cidade, cod_ibge, nom_cidade, uf from cidades ' +
        'order by nom_cidade, uf limit 200';
    end
    else if CharInSet(LBusca[1], ['0'..'9']) then
    begin
      Q.SQL.Text :=
        'select cod_cidade, cod_ibge, nom_cidade, uf from cidades ' +
        'where cast(cod_cidade as text) like :p0 or cast(coalesce(cod_ibge, 0) as text) like :p0 ' +
        'order by nom_cidade, uf limit 200';
      Q.ParamByName('p0').AsString := LBusca + '%';
    end
    else
    begin
      Q.SQL.Text :=
        'select cod_cidade, cod_ibge, nom_cidade, uf from cidades ' +
        'where upper(coalesce(nom_cidade, '''')) like :p0 ' +
        'order by nom_cidade, uf limit 200';
      Q.ParamByName('p0').AsString := '%' + UpperCase(LBusca) + '%';
    end;

    Q.Open;
    while not Q.Eof do
    begin
      LItem := LvCidades.Items.Add;
      LItem.Tag := Q.FieldByName('cod_cidade').AsInteger;
      LItem.Text := Q.FieldByName('nom_cidade').AsString + '-' + Q.FieldByName('uf').AsString;
      LItem.Detail := 'Cod. Cidade IBGE: ' + Q.FieldByName('cod_ibge').AsString;
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmCidadeBusca.LvCidadesItemClick(const Sender: TObject; const AItem: TListViewItem);
var
  LTexto: string;
  LUf: string;
  LNome: string;
  P: Integer;
begin
  if not Assigned(AItem) then
    Exit;

  LTexto := AItem.Text;
  P := LastDelimiter('-', LTexto);
  if P > 0 then
  begin
    LNome := Trim(Copy(LTexto, 1, P - 1));
    LUf := Trim(Copy(LTexto, P + 1, MaxInt));
  end
  else
  begin
    LNome := LTexto;
    LUf := '';
  end;

  if Assigned(frmClienteCadastro) then
    frmClienteCadastro.SelecionarCidade(Integer(AItem.Tag), LNome, LUf);
  Close;
end;

end.

