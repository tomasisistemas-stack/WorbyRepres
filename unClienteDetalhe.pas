unit unClienteDetalhe;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.DialogService.Async, Data.DB,
  FireDAC.Comp.Client, FMX.ScrollBox;

type
  TfrmClienteDetalhe = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    CardPerfil: TRectangle;
    LbNome: TLabel;
    LbDoc: TLabel;
    LbCidade: TLabel;
    CardContato: TRectangle;
    LbContatoTitulo: TLabel;
    LbTelefone: TLabel;
    LbEmail: TLabel;
    CardEndereco: TRectangle;
    LbEnderecoTitulo: TLabel;
    LbEndereco1: TLabel;
    LbEndereco2: TLabel;
    CardSituacao: TRectangle;
    BtnCancelar: TRectangle;
    LbCancelar: TLabel;
    BtnPedido: TRectangle;
    LbPedido: TLabel;
    layout1: TLayout;
    Layout2: TLayout;
    Layout3: TLayout;
    PresentedScrollBox1: TPresentedScrollBox;
    Layout4: TLayout;
    Layout5: TLayout;
    LbDocDireita: TLabel;
    Layout6: TLayout;
    LayoutLimite: TLayout;
    LbLimite: TLabel;
    LayoutSaldo: TLayout;
    LbSaldo: TLabel;
    LayoutSituacaoTitulo: TLayout;
    LbSituacaoTitulo: TLabel;
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnPedidoClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FNome: string;
    FCodigo: string;
    FCidade: string;
    FDocDireita: string;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure RenderCliente;
    procedure CarregarDoSqlite(const AId: string);
    function SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
    function SafeFieldAsCurrency(AQuery: TFDQuery; const ACampo: string): Currency;
    procedure ApplyOrientationLayout;
  protected
    procedure DoShow; override;
  public
    procedure SetCliente(const ANome, ACodigo, ACidade: string);
  end;

var
  frmClienteDetalhe: TfrmClienteDetalhe;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

uses
  unDMApp,
  unPedido,
  unFuncoes;

procedure TfrmClienteDetalhe.BtnCancelarClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmClienteDetalhe.BtnPedidoClick(Sender: TObject);
var
  LMsg: string;
begin
  if Assigned(dmApp) and dmApp.IsDailySyncRequired(LMsg) then
  begin
    TDialogServiceAsync.ShowMessage(LMsg);
    Exit;
  end;

  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.SetCliente(FNome, FCodigo, FCidade);
  frmPedido.Show;
end;

procedure TfrmClienteDetalhe.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmClienteDetalhe.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LScale: Single;
  LCardW: Single;
  LCardX: Single;
  LTop: Single;
  LGap: Single;
  LBtnW: Single;
  LBtnY: Single;
  LColW: Single;
  LLeftX: Single;
  LRightX: Single;
  LBottomSafe: Single;
begin
  if Assigned(CardSituacao) then
    CardSituacao.Visible := False;

  LIsLandscape := Width > Height;

  if LIsLandscape then
  begin
    TopBar.Height := 56;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) / 2;
    LbTitulo.Visible := True;
    LbTitulo.BringToFront;

    LBottomSafe := AndroidNavigationInset(False);
    if LBottomSafe < 56 then
      LBottomSafe := 56;

    PresentedScrollBox1.Padding.Top := 8;
    Layout1.Align := TAlignLayout.Bottom;
    Layout1.Height := 50;
    Layout1.Margins.Bottom := LBottomSafe;
    PresentedScrollBox1.Padding.Bottom := Layout1.Height + LBottomSafe + 8;

    LGap := 12;
    LColW := (Width - 48) / 2;
    LLeftX := 16;
    LRightX := LLeftX + LColW + 16;
    LTop := TopBar.Height + LGap;

    CardPerfil.Align := TAlignLayout.None;
    CardContato.Align := TAlignLayout.None;
    CardEndereco.Align := TAlignLayout.None;
    CardSituacao.Align := TAlignLayout.None;

    CardPerfil.Scale.X := 1;
    CardPerfil.Scale.Y := 1;
    CardContato.Scale.X := 1;
    CardContato.Scale.Y := 1;
    CardEndereco.Scale.X := 1;
    CardEndereco.Scale.Y := 1;
    CardSituacao.Scale.X := 1;
    CardSituacao.Scale.Y := 1;

    CardPerfil.Width := LColW;
    CardContato.Width := LColW;
    CardEndereco.Width := LColW;
    CardSituacao.Width := LColW;

    CardPerfil.Position.X := LLeftX;
    CardPerfil.Position.Y := LTop;
    CardContato.Position.X := LLeftX;
    CardContato.Position.Y := LTop + CardPerfil.Height + LGap;

    CardEndereco.Position.X := LRightX;
    CardEndereco.Position.Y := LTop;
    CardSituacao.Position.X := LRightX;
    CardSituacao.Position.Y := LTop + CardEndereco.Height + LGap;

    Layout2.Align := TAlignLayout.MostRight; // Pedido/Gravar à direita
    Layout3.Align := TAlignLayout.MostLeft;  // Cancelar à esquerda
    Layout2.Width := Width / 2;
    Layout3.Width := Width / 2;
    BtnPedido.Align := TAlignLayout.Client;
    BtnCancelar.Align := TAlignLayout.Client;
    BtnPedido.Margins.Bottom := 5;
    BtnCancelar.Margins.Bottom := 5;
    LBtnW := (Width - 32 - 8) / 2;
    BtnPedido.Width := LBtnW;
    BtnCancelar.Width := LBtnW;
    LBtnY := Layout1.Position.Y + 8;
    BtnPedido.Position.Y := LBtnY;
    BtnCancelar.Position.Y := LBtnY;
  end
  else
  begin
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;
    LbTitulo.Visible := True;

    PresentedScrollBox1.Padding.Top := 0;
    LBottomSafe := 58;

    Layout1.Align := TAlignLayout.MostBottom;
    Layout1.Height := 58 + LBottomSafe;
    Layout1.Margins.Bottom := 0;
    PresentedScrollBox1.Padding.Bottom := Layout1.Height + 8;

    CardPerfil.Align := TAlignLayout.MostTop;
    CardContato.Align := TAlignLayout.MostTop;
    CardEndereco.Align := TAlignLayout.MostTop;
    CardSituacao.Align := TAlignLayout.MostTop;

    CardPerfil.Scale.X := 1;
    CardPerfil.Scale.Y := 1;
    CardContato.Scale.X := 1;
    CardContato.Scale.Y := 1;
    CardEndereco.Scale.X := 1;
    CardEndereco.Scale.Y := 1;
    CardSituacao.Scale.X := 1;
    CardSituacao.Scale.Y := 1;

    CardPerfil.Width := 324;
    CardContato.Width := 324;
    CardEndereco.Width := 324;
    CardSituacao.Width := 324;

    CardPerfil.Position.X := 18;
    CardContato.Position.X := 18;
    CardEndereco.Position.X := 18;
    CardSituacao.Position.X := 18;

    CardPerfil.Position.Y := 112;
    CardContato.Position.Y := 256;
    CardEndereco.Position.Y := 384;
    CardSituacao.Position.Y := 512;

    Layout2.Align := TAlignLayout.MostRight; // Pedido/Gravar à direita
    Layout3.Align := TAlignLayout.MostLeft;  // Cancelar à esquerda
    Layout2.Width := Width / 2;
    Layout3.Width := Width / 2;
    BtnPedido.Align := TAlignLayout.Client;
    BtnCancelar.Align := TAlignLayout.Client;
    BtnCancelar.Width := 0;
    BtnPedido.Width := 0;
    BtnCancelar.Position.Y := 0;
    BtnPedido.Position.Y := 0;
    BtnCancelar.Margins.Bottom := LBottomSafe + 5;
    BtnPedido.Margins.Bottom := LBottomSafe + 5;

  end;
end;

function TfrmClienteDetalhe.SafeFieldAsString(AQuery: TFDQuery; const ACampo: string): string;
begin
  if AQuery.FindField(ACampo) <> nil then
    Result := AQuery.FieldByName(ACampo).AsString
  else
    Result := '';
end;

function TfrmClienteDetalhe.SafeFieldAsCurrency(AQuery: TFDQuery; const ACampo: string): Currency;
begin
  if AQuery.FindField(ACampo) <> nil then
    Result := AQuery.FieldByName(ACampo).AsCurrency
  else
    Result := 0;
end;

procedure TfrmClienteDetalhe.CarregarDoSqlite(const AId: string);
var
  Q: TFDQuery;
  LNome: string;
  LFantasia: string;
  LEmail: string;
  LEmailNFE: string;
  LTel: string;
  LCel: string;
  LEndereco: string;
  LComplemento: string;
  LBairro: string;
  LCidade: string;
  LCEP: string;
  LNumero: string;
  LStatus: string;
  LBloqueado: string;
  LCNPJ: string;
  LCPF: string;
  LDoc: string;
  LLimite: Currency;
  LSaldo: Currency;
begin
  if AId = '' then
    Exit;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := dmApp.FDConnection;
    Q.SQL.Text :=
      'SELECT A.COD_CLIENTE, A.SUSPENSAO_PIS_CONFINS, A.CELULAR, A.ULTCONSSERASA, A.DTA_CAD, A.PRI_COMPRA, A.NOM_CLIENTE, A.NOM_FANTASIA, A.EMAIL_END_NFE, ' +
      'A.ENDERECO, A.CONSTRUTORA, A.COMPLEMENTO, A.PROXIMO, A.BAIRRO, A.CEP, A.COD_CIDADE, A.TIP_PESSOA, A.CONSUMIDOR_FINAL, ' +
      'A.TELEFONE, A.EMAIL, A.AVISO, A.CNPJ, A.IE, A.IM, A.PROD_RURAL, A.CONTATO, A.FONE_CONTATO, A.OPERADORA, ' +
      'A.LIMITE, A.CPF, A.RG, A.NATURALIDADE, A.EST_CIVIL, A.PAI, A.MAE, A.TIP_RESIDENCIA, A.ALUGUEL, A.PRONAUTICA, A.PROEMPREGO, ' +
      'A.EMPRESA, A.END_TRACLI, A.BAIRRO_TRABALHO, A.CID_TRABALHO, A.FONE_TRABALHO, A.CARGO, A.SALARIO, ' +
      'A.NOM_CONJUGUE, A.EMP_CONJ, A.END_EMP_CONJ, A.CID_EMP_CONJ, A.FONE_EMP_CONJ, A.CARGO_CONJ, ' +
      'A.NOM_REF1, A.FONE_REF1, A.OBS_REF1, A.NOM_REF2, A.FONE_REF2, A.OBS_REF2, A.CAD_SPC, A.DTA_CAD_SPC, ' +
      'A.DTA_ANIVERSARIO, A.ACEITA_NOTA_SIMPLES, A.OBSERVACOES, A.FAX, A.MANEQUIM, A.CALCADO, A.COR_PREFERIDA, ' +
      'A.CONTATO_PREFERIDO, A.ESTILO, A.CONTATO_FONE, A.CONTATO_EMAIL, A.CONTATO_CORRESPONDENCIA, ' +
      'A.ID_ANTIGO, A.PONTO_FIDELIDADE, A.ID_REPRESENTANTE, A.ID_FOP, A.PRAZO_MAXIMO, A.DESCONTO_MAXIMO, A.DESCONTO_ESPECIAL, ' +
      'A.CLIENTE_BLOQUEADO, A.STATUS, A.COD_EMPRESA, A.NR_ENDERECO, A.NFE_EMAIL, A.SINCRONIZAR_PALM, A.EMAIL_ADICIONAL1, EMAIL_ADICIONAL2, EMAIL_ADICIONAL3, ' +
      'A.WHASTAPP, A.PRE_CADASTRO, a.COD_CIDADE, C.NOM_CIDADE||''-''||C.UF AS CID_NOME, A.SALDO FROM CLIENTE A ' +
      'LEFT JOIN CIDADES C ON C.COD_CIDADE = A.COD_CIDADE ' +
      'WHERE A.COD_CLIENTE = :ID';
    Q.ParamByName('id').AsString := AId;
    Q.Open;
    if not Q.Eof then
    begin
      LNome := SafeFieldAsString(Q, 'NOM_CLIENTE');
      LFantasia := SafeFieldAsString(Q, 'NOM_FANTASIA');
      LEmail := SafeFieldAsString(Q, 'EMAIL');
      LEmailNFE := SafeFieldAsString(Q, 'EMAIL_END_NFE');
      LTel := SafeFieldAsString(Q, 'TELEFONE');
      LCel := SafeFieldAsString(Q, 'CELULAR');
      LEndereco := SafeFieldAsString(Q, 'ENDERECO');
      LComplemento := SafeFieldAsString(Q, 'COMPLEMENTO');
      LBairro := SafeFieldAsString(Q, 'BAIRRO');
      LCEP := SafeFieldAsString(Q, 'CEP');
      LNumero := SafeFieldAsString(Q, 'NR_ENDERECO');
      LCidade := SafeFieldAsString(Q, 'CID_NOME');
      LStatus := SafeFieldAsString(Q, 'STATUS');
      LBloqueado := SafeFieldAsString(Q, 'CLIENTE_BLOQUEADO');
      LCNPJ := SafeFieldAsString(Q, 'CNPJ');
      LCPF := SafeFieldAsString(Q, 'CPF');
      LLimite := SafeFieldAsCurrency(Q, 'LIMITE');
      LSaldo := SafeFieldAsCurrency(Q, 'SALDO');

      if LNome <> '' then
        LbNome.Text := LNome
      else if LFantasia <> '' then
        LbNome.Text := LFantasia;

      LDoc := '';
      if LCNPJ <> '' then
        LDoc := 'CNPJ: ' + LCNPJ
      else if LCPF <> '' then
        LDoc := 'CPF: ' + LCPF;

      FDocDireita := LDoc;
      LbDoc.Text := 'Codigo ' + AId;
      if Assigned(LbDocDireita) then
        LbDocDireita.Text := FDocDireita;

      if LCidade <> '' then
        LbCidade.Text := 'Cidade: ' + LCidade
      else
        LbCidade.Text := 'Cidade: --';

      if (LTel <> '') and (LCel <> '') then
        LbTelefone.Text := 'Telefone: ' + LTel + ' | ' + LCel
      else if LTel <> '' then
        LbTelefone.Text := 'Telefone: ' + LTel
      else if LCel <> '' then
        LbTelefone.Text := 'Telefone: ' + LCel
      else
        LbTelefone.Text := 'Telefone: --';

      if LEmail <> '' then
        LbEmail.Text := 'Email: ' + LEmail
      else if LEmailNFE <> '' then
        LbEmail.Text := 'Email: ' + LEmailNFE
      else
        LbEmail.Text := 'Email: --';

      if LEndereco <> '' then
      begin
        LbEndereco1.Text := LEndereco;
        if LNumero <> '' then
          LbEndereco1.Text := LbEndereco1.Text + ', ' + LNumero;
      end
      else
        LbEndereco1.Text := '--';

      LbEndereco2.Text := '';
      if LBairro <> '' then
        LbEndereco2.Text := LBairro;
      if LCEP <> '' then
      begin
        if LbEndereco2.Text <> '' then
          LbEndereco2.Text := LbEndereco2.Text + ' - ' + LCEP
        else
          LbEndereco2.Text := LCEP;
      end;
      if LComplemento <> '' then
      begin
        if LbEndereco2.Text <> '' then
          LbEndereco2.Text := LbEndereco2.Text + ' | ' + LComplemento
        else
          LbEndereco2.Text := LComplemento;
      end;
      if LbEndereco2.Text = '' then
        LbEndereco2.Text := '--';

      if (LStatus <> '') or (LBloqueado <> '') then
        LbSituacaoTitulo.Text := 'Situacao: ' + Trim(LStatus + ' ' + LBloqueado)
      else
        LbSituacaoTitulo.Text := 'Situacao: --';

      LbLimite.Text := Format('Limite: R$ %.2f', [LLimite]);
      LbSaldo.Text := Format('Saldo: R$ %.2f', [LSaldo]);

      FNome := LbNome.Text;
      FCidade := LCidade;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmClienteDetalhe.RenderCliente;
begin
  if FNome <> '' then
    LbNome.Text := FNome;
  if FCodigo <> '' then
    LbDoc.Text := 'Codigo ' + FCodigo;
  if Assigned(LbDocDireita) then
    LbDocDireita.Text := FDocDireita;
  if FCidade <> '' then
    LbCidade.Text := 'Cidade: ' + FCidade;
end;

procedure TfrmClienteDetalhe.SetCliente(const ANome, ACodigo, ACidade: string);
begin
  FNome := ANome;
  FCodigo := ACodigo;
  FCidade := ACidade;
  FDocDireita := '';
  RenderCliente;
  CarregarDoSqlite(ACodigo);
  ApplyOrientationLayout;
end;

procedure TfrmClienteDetalhe.DoShow;
begin
  inherited;
  OnClose := FormClose;
end;

procedure TfrmClienteDetalhe.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmClienteDetalhe := nil;
end;

end.