unit unVisitaCheckin;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Math, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts,
  FireDAC.Comp.Client;

type
  TfrmVisitaCheckin = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    LbSubtitulo: TLabel;
    CardCliente: TRectangle;
    LbClienteNome: TLabel;
    LbClienteCodigo: TLabel;
    LbClienteDoc: TLabel;
    LbClienteCidade: TLabel;
    BadgeRaio: TRectangle;
    LbBadgeRaio: TLabel;
    LbDistancia: TLabel;
    CardRegistro: TRectangle;
    LbRegistroTitulo: TLabel;
    LbChegadaTitulo: TLabel;
    LbChegadaValor: TLabel;
    LbGpsTitulo: TLabel;
    LbGpsValor: TLabel;
    LbVelocidadeTitulo: TLabel;
    LbVelocidadeValor: TLabel;
    LbPrecisaoTitulo: TLabel;
    LbPrecisaoValor: TLabel;
    CardAcoes: TRectangle;
    LbAcoesTitulo: TLabel;
    BtnIniciarPedido: TRectangle;
    LbIniciarPedido: TLabel;
    lbottom: TLayout;
    LyVoltar: TLayout;
    ImgVoltar: TImage;
    BtnFinalizar: TRectangle;
    LbFinalizar: TLabel;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnIniciarPedidoClick(Sender: TObject);
    procedure BtnVendaExternaClick(Sender: TObject);
    procedure BtnSemVendaClick(Sender: TObject);
    procedure BtnFinalizarClick(Sender: TObject);
    procedure LyVoltarClick(Sender: TObject);
  private
    FCodCliente: Integer;
    FNomeCliente: string;
    FCidadeCliente: string;
    FDocCliente: string;
    FUltimaVenda: string;
    FDistancia: Double;
    FLatitude: Double;
    FLongitude: Double;
    FVelocidade: Double;
    FPrecisao: Double;
    FInicioAtendimento: TDateTime;
    function CodRepresentanteAtual: Integer;
    function TextoDistancia(ADistancia: Double): string;
    procedure ApplyResponsiveLayout;
    procedure CarregarCliente;
    procedure RenderDados;
    procedure RegistrarVisita(const AVendeu: string; AFechar: Boolean);
  public
    procedure SetCheckin(ACodCliente: Integer; ADistancia, ALatitude, ALongitude,
      AVelocidade, APrecisao: Double);
  end;

var
  frmVisitaCheckin: TfrmVisitaCheckin;

implementation

{$R *.fmx}

uses
  unDMApp, unPedido, unVisitaResultado, unFuncoes;

function TfrmVisitaCheckin.CodRepresentanteAtual: Integer;
begin
  Result := 0;
  try
    Result := StrToIntDef(Trim(dmApp.FDConnection.ExecSQLScalar(
      'select coalesce(value, '''') from app_config where key = ''cod_representante''')), 0);
  except
    Result := 0;
  end;
end;

function TfrmVisitaCheckin.TextoDistancia(ADistancia: Double): string;
begin
  if ADistancia = MaxDouble then
    Exit('Sem GPS');

  if ADistancia < 1000 then
    Result := FormatFloat('0', ADistancia) + ' m'
  else
    Result := FormatFloat('0.0', ADistancia / 1000) + ' km';
end;

procedure TfrmVisitaCheckin.SetCheckin(ACodCliente: Integer; ADistancia, ALatitude,
  ALongitude, AVelocidade, APrecisao: Double);
begin
  FCodCliente := ACodCliente;
  FInicioAtendimento := Now;
  FDistancia := ADistancia;
  FLatitude := ALatitude;
  FLongitude := ALongitude;
  FVelocidade := AVelocidade;
  FPrecisao := APrecisao;
  CarregarCliente;
  RenderDados;
end;

procedure TfrmVisitaCheckin.CarregarCliente;
var
  Q: TFDQuery;
begin
  FNomeCliente := '';
  FCidadeCliente := '';
  FDocCliente := '';
  FUltimaVenda := '';

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'select c.cod_cliente, c.nom_cliente, coalesce(c.cnpj, '''') as cnpj, ' +
      '       trim(coalesce(cid.nom_cidade, '''') || case when coalesce(cid.uf, '''') <> '''' then ''-'' || cid.uf else '''' end) as cidade, ' +
      '       max(date(coalesce(nullif(v.dta_emissao, ''''), nullif(v.dtadoc, '''')))) as ultima_venda ' +
      'from cliente c ' +
      'left join cidades cid on cid.cod_cidade = c.cod_cidade ' +
      'left join vendas1 v on v.cod_cliente = c.cod_cliente ' +
      'where c.cod_cliente = :p0 ' +
      'group by c.cod_cliente, c.nom_cliente, c.cnpj, cid.nom_cidade, cid.uf';
    Q.ParamByName('p0').AsInteger := FCodCliente;
    Q.Open;
    if not Q.Eof then
    begin
      FNomeCliente := Trim(Q.FieldByName('nom_cliente').AsString);
      FDocCliente := Trim(Q.FieldByName('cnpj').AsString);
      FCidadeCliente := Trim(Q.FieldByName('cidade').AsString);
      FUltimaVenda := Trim(Q.FieldByName('ultima_venda').AsString);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVisitaCheckin.RenderDados;
var
  LUltima: string;
begin
  if FUltimaVenda <> '' then
    LUltima := Copy(FUltimaVenda, 9, 2) + '/' + Copy(FUltimaVenda, 6, 2) + '/' + Copy(FUltimaVenda, 1, 4)
  else
    LUltima := 'Sem venda';

  LbClienteNome.Text := FNomeCliente;
  LbClienteCodigo.Text := 'Codigo ' + FCodCliente.ToString;
  LbClienteDoc.Text := 'CNPJ: ' + FDocCliente;
  LbClienteCidade.Text := FCidadeCliente + ' | Ult. venda: ' + LUltima;
  LbDistancia.Text := 'Distancia: ' + TextoDistancia(FDistancia);
  if FDistancia <= 200 then
  begin
    LbBadgeRaio.Text := 'No raio';
    BadgeRaio.Fill.Color := $FF079669
  end
  else
  begin
    LbBadgeRaio.Text := 'Fora do raio';
    BadgeRaio.Fill.Color := $FFE5484D;
  end;

  LbChegadaValor.Text := FormatDateTime('hh:nn', Now);
  LbGpsValor.Text := Format('%.4f, %.4f', [FLatitude, FLongitude]);
  LbVelocidadeValor.Text := FormatFloat('0.0', FVelocidade) + ' km/h';
  if FPrecisao > 0 then
    LbPrecisaoValor.Text := FormatFloat('0', FPrecisao) + ' m'
  else
    LbPrecisaoValor.Text := '--';
end;

procedure TfrmVisitaCheckin.RegistrarVisita(const AVendeu: string; AFechar: Boolean);
var
  Q: TFDQuery;
  LDataHora: string;
begin
  if FCodCliente <= 0 then
  begin
    ShowMessage('Cliente nao informado.');
    Exit;
  end;

  LDataHora := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
  Q := TFDQuery.Create(nil);
  try
    try
      Q.Connection := dmApp.FDConnection;
      Q.SQL.Text :=
        'insert or replace into cliente_visitas ' +
        '(cod_cliente, data, vendeu, enviado, valor_pedido, datahora, cod_representante, status_visita) ' +
        'values (:p0, :p1, :p2, ''N'', 0, :p3, :p4, :p5)';
      Q.ParamByName('p0').AsInteger := FCodCliente;
      Q.ParamByName('p1').AsString := FormatDateTime('yyyy-mm-dd', Date);
      Q.ParamByName('p2').AsString := AVendeu;
      Q.ParamByName('p3').AsString := LDataHora;
      Q.ParamByName('p4').AsInteger := CodRepresentanteAtual;
      if SameText(AVendeu, 'S') then
        Q.ParamByName('p5').AsString := 'Venda'
      else
        Q.ParamByName('p5').AsString := 'VISITA IMPOSSIBILITADA';
      Q.ExecSQL;
      ShowMessage('Visita registrada.');
      if AFechar then
        Close;
    except
      on E: Exception do
        ShowMessage('Erro ao registrar visita: ' + E.Message);
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmVisitaCheckin.ApplyResponsiveLayout;
var
  LIsLandscape: Boolean;
  LContentW: Single;
  LPad: Single;
  LGap: Single;
  LTop: Single;
  LCardW: Single;
  LLeftX: Single;
  LRightX: Single;
  LBottomSafe: Single;
  LBtnH: Single;
begin
  if (Width <= 0) or (Height <= 0) then
    Exit;

  LIsLandscape := Width > Height;
  LPad := 22;
  LGap := IfThen(LIsLandscape, 12, 10);
  LBottomSafe := AndroidBottomSafeMargin(LIsLandscape);

  TopBar.Align := TAlignLayout.None;
  TopBar.SetBounds(0, 0, Width, IfThen(LIsLandscape, 58, 106));
  LbTitulo.SetBounds(28, IfThen(LIsLandscape, 10, 38), Width - 56, 32);
  LbSubtitulo.SetBounds(30, LbTitulo.Position.Y + IfThen(LIsLandscape, 26, 30), Width - 60, 20);
  LbTitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 21, 26);
  LbSubtitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 11, 13);

  lbottom.Align := TAlignLayout.None;
  lbottom.SetBounds(0, Height - IfThen(LIsLandscape, 54, 76) - LBottomSafe,
    Width, IfThen(LIsLandscape, 54, 76));
  LyVoltar.SetBounds(18, 0, 112, lbottom.Height);
  ImgVoltar.SetBounds(0, IfThen(LIsLandscape, 0, 2), IfThen(LIsLandscape, 58, 72), IfThen(LIsLandscape, 42, 48));
  ImgVoltar.WrapMode := TImageWrapMode.Fit;
  BtnFinalizar.SetBounds(Width - IfThen(LIsLandscape, 204, 184), IfThen(LIsLandscape, 4, 10),
    IfThen(LIsLandscape, 184, 164), 44);

  LContentW := Width - (LPad * 2);
  if LContentW > 720 then
    LContentW := 720;
  LTop := TopBar.Height + LGap;

  if LIsLandscape then
  begin
    LCardW := (LContentW - LGap) / 2;
    LLeftX := (Width - LContentW) / 2;
    LRightX := LLeftX + LCardW + LGap;

    CardCliente.SetBounds(LLeftX, LTop, LCardW, 94);
    CardRegistro.SetBounds(LRightX, LTop, LCardW, 94);
    CardAcoes.SetBounds(LLeftX, CardCliente.Position.Y + CardCliente.Height + LGap,
      LContentW, lbottom.Position.Y - (CardCliente.Position.Y + CardCliente.Height + LGap + 8));
    if CardAcoes.Height < 104 then
      CardAcoes.Height := 104;
  end
  else
  begin
    LLeftX := (Width - LContentW) / 2;
    CardCliente.SetBounds(LLeftX, LTop, LContentW, 124);
    CardRegistro.SetBounds(LLeftX, CardCliente.Position.Y + CardCliente.Height + LGap, LContentW, 144);
    CardAcoes.SetBounds(LLeftX, CardRegistro.Position.Y + CardRegistro.Height + LGap,
      LContentW, lbottom.Position.Y - (CardRegistro.Position.Y + CardRegistro.Height + LGap + 8));
    if CardAcoes.Height < 142 then
      CardAcoes.Height := 142;
  end;

  LbClienteNome.SetBounds(24, IfThen(LIsLandscape, 14, 18), CardCliente.Width - 48, 24);
  LbClienteCodigo.SetBounds(26, IfThen(LIsLandscape, 38, 48), 124, 20);
  LbClienteDoc.SetBounds(158, IfThen(LIsLandscape, 38, 48), CardCliente.Width - 184, 20);
  LbClienteCidade.SetBounds(26, IfThen(LIsLandscape, 72, 72), CardCliente.Width - 52, 20);
  BadgeRaio.SetBounds(26, IfThen(LIsLandscape, 62, 94), IfThen(LIsLandscape, 82, 96), 24);
  LbBadgeRaio.SetBounds(0, 0, BadgeRaio.Width, BadgeRaio.Height);
  LbDistancia.SetBounds(BadgeRaio.Position.X + BadgeRaio.Width + 12, IfThen(LIsLandscape, 63, 96),
    CardCliente.Width - (BadgeRaio.Position.X + BadgeRaio.Width + 38), 22);
  LbClienteNome.TextSettings.Font.Size := IfThen(LIsLandscape, 13, 14);
  LbClienteCodigo.TextSettings.Font.Size := 10;
  LbClienteDoc.TextSettings.Font.Size := 10;
  LbClienteCidade.TextSettings.Font.Size := 10;
  LbDistancia.TextSettings.Font.Size := 11;

  LbRegistroTitulo.SetBounds(24, IfThen(LIsLandscape, 16, 18), CardRegistro.Width - 48, 24);
  LbChegadaTitulo.SetBounds(26, IfThen(LIsLandscape, 48, 52), 100, 18);
  LbChegadaValor.SetBounds(26, IfThen(LIsLandscape, 66, 70), 100, 24);
  LbGpsTitulo.SetBounds(CardRegistro.Width * 0.42, IfThen(LIsLandscape, 48, 52), CardRegistro.Width * 0.52, 18);
  LbGpsValor.SetBounds(CardRegistro.Width * 0.42, IfThen(LIsLandscape, 66, 70), CardRegistro.Width * 0.52, 24);
  LbVelocidadeTitulo.SetBounds(26, 98, 100, 18);
  LbVelocidadeValor.SetBounds(26, 116, 100, 24);
  LbPrecisaoTitulo.SetBounds(CardRegistro.Width * 0.42, 98, 100, 18);
  LbPrecisaoValor.SetBounds(CardRegistro.Width * 0.42, 116, 100, 24);
  LbRegistroTitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 13, 14);
  LbChegadaTitulo.TextSettings.Font.Size := 10;
  LbGpsTitulo.TextSettings.Font.Size := 10;
  LbVelocidadeTitulo.TextSettings.Font.Size := 10;
  LbPrecisaoTitulo.TextSettings.Font.Size := 10;
  LbChegadaValor.TextSettings.Font.Size := IfThen(LIsLandscape, 14, 15);
  LbGpsValor.TextSettings.Font.Size := IfThen(LIsLandscape, 9, 10);
  LbVelocidadeValor.TextSettings.Font.Size := 13;
  LbPrecisaoValor.TextSettings.Font.Size := 13;

  if LIsLandscape then
  begin
    LbClienteCidade.Visible := False;
    LbVelocidadeTitulo.Visible := False;
    LbVelocidadeValor.Visible := False;
    LbPrecisaoTitulo.Visible := False;
    LbPrecisaoValor.Visible := False;
  end
  else
  begin
    LbClienteCidade.Visible := True;
    LbVelocidadeTitulo.Visible := True;
    LbVelocidadeValor.Visible := True;
    LbPrecisaoTitulo.Visible := True;
    LbPrecisaoValor.Visible := True;
  end;

  LbAcoesTitulo.SetBounds(24, IfThen(LIsLandscape, 16, 14), CardAcoes.Width - 48, 24);
  LbAcoesTitulo.TextSettings.Font.Size := IfThen(LIsLandscape, 13, 14);

  LBtnH := IfThen(LIsLandscape, 40, 34);
  BtnIniciarPedido.SetBounds(24, IfThen(LIsLandscape, 52, 42), CardAcoes.Width - 48, LBtnH);
  LbIniciarPedido.SetBounds(0, 0, BtnIniciarPedido.Width, BtnIniciarPedido.Height);
  LbIniciarPedido.TextSettings.Font.Size := IfThen(LIsLandscape, 12, 12);

  if LIsLandscape then
    BtnIniciarPedido.SetBounds(24, 50, CardAcoes.Width - 48, 40);
end;

procedure TfrmVisitaCheckin.FormShow(Sender: TObject);
begin
  OnClose := FormClose;
  ApplyResponsiveLayout;
  RenderDados;
end;

procedure TfrmVisitaCheckin.FormResize(Sender: TObject);
begin
  ApplyResponsiveLayout;
end;

procedure TfrmVisitaCheckin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmVisitaCheckin := nil;
end;

procedure TfrmVisitaCheckin.BtnIniciarPedidoClick(Sender: TObject);
begin
  if FCodCliente <= 0 then
    Exit;
  dmApp.SetAppConfigValue('visita_pedido_cod_cliente', FCodCliente.ToString);
  dmApp.SetAppConfigValue('visita_pedido_nome_cliente', FNomeCliente);
  dmApp.SetAppConfigValue('visita_pedido_inicio', FloatToStr(FInicioAtendimento, TFormatSettings.Invariant));
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.SetCliente(FNomeCliente, FCodCliente.ToString, FCidadeCliente);
  frmPedido.Show;
  Close;
end;

procedure TfrmVisitaCheckin.BtnVendaExternaClick(Sender: TObject);
begin
  RegistrarVisita('S', True);
end;

procedure TfrmVisitaCheckin.BtnSemVendaClick(Sender: TObject);
begin
  RegistrarVisita('N', True);
end;

procedure TfrmVisitaCheckin.BtnFinalizarClick(Sender: TObject);
begin
  if not Assigned(frmVisitaResultado) then
    Application.CreateForm(TfrmVisitaResultado, frmVisitaResultado);
  frmVisitaResultado.SetResultado(FCodCliente, FNomeCliente, FInicioAtendimento);
  frmVisitaResultado.Show;
  Close;
end;

procedure TfrmVisitaCheckin.LyVoltarClick(Sender: TObject);
begin
  Close;
end;

end.

