unit unPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Threading,
  System.JSON, FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Memo,
  FMX.Memo.Types, FMX.ScrollBox, unFuncoes;

type
  TfrmPrincipal = class(TForm)
    LayoutRoot: TLayout;
    BackgroundRect: TRectangle;
    TopBar: TRectangle;
    LbTitulo: TLabel;
    Card: TRectangle;
    LbRepNome: TLabel;
    LbRepCodigo: TLabel;
    LbUsuario: TLabel;
    MenuGrid: TLayout;
    BtnConectar: TButton;
    ProgressBarSync: TProgressBar;
    LbProgresso: TLabel;
    MemoLog: TMemo;
    lbottom: TLayout;
    lySaidas: TLayout;
    rSaidas: TRectangle;
    ImSaidas: TImage;
    lbSaidas: TLabel;
    lySair: TLayout;
    rSair: TRectangle;
    imSair: TImage;
    lbSair: TLabel;
    imgOrdEd: TImage;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    procedure BtnConectarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure imSairClick(Sender: TObject);
    procedure MenuPedidosEnviadosClick(Sender: TObject);
  private
    FUsuarioLogin: string;
    FQueueLogText: string;
    FQueueDoneMsg: string;
    FQueueErrMsg: string;
    procedure AtualizarCabecalho;
    procedure SincronizarTudo;
    procedure EnsureSyncForm;
    procedure EnsurePedidoForm;
    procedure EnsurePedidoItemForm;
    procedure ApplyOrientationLayout;
    procedure DoQueueLog;
    procedure DoQueueDone;
    procedure DoQueueError;
  published
    procedure MenuClientesClick(Sender: TObject);
    procedure MenuPedidosClick(Sender: TObject);
    procedure MenuPedidosDigitadosClick(Sender: TObject);
    procedure MenuProdutosClick(Sender: TObject);
    procedure MenuVendasClick(Sender: TObject);
    procedure MenuTitulosClick(Sender: TObject);
    procedure MenuComissoesClick(Sender: TObject);
    procedure MenuConfigClick(Sender: TObject);
    procedure MenuSuporteClick(Sender: TObject);
  public
    id_representante: Integer;
    FRepNome: string;
    procedure AtualizarContextoUsuario(AUser: TJSONObject);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.fmx}

uses
  unDMApp,
  unClientes,
  unSync,
  unPedido,
  unPedidoItem,
  unPedidosDigitados,
  unPedidosEnviados;

const
  CTabelasSyncFiltradas: array[0..7] of string = (
    'representante',
    'cliente',
    'vendas1',
    'vendas2',
    'produto_representante',
    'grupo_representante',
    'produto_representante_inativos',
    'prazo_representante'
  );
  CTabelasSyncGlobais: array[0..4] of string = (
    'produto',
    'subcategoria',
    'fop',
    'prazo',
    'cidades'
  );

procedure TfrmPrincipal.AtualizarCabecalho;
begin
  LbUsuario.Text := 'Usuario: ' + FUsuarioLogin;
  LbRepNome.Text := 'Representante: ' + FRepNome;
  LbRepCodigo.Text := 'Codigo: ' + id_representante.ToString;
end;

procedure TfrmPrincipal.AtualizarContextoUsuario(AUser: TJSONObject);
var
  LUserValue: TJSONValue;
  LUserObj: TJSONObject;
  LRepresentanteValue: TJSONValue;
  LNomeValue: TJSONValue;
  LLoginValue: TJSONValue;
begin
  id_representante := 0;
  FRepNome := '';
  FUsuarioLogin := '';

  if Assigned(AUser) then
  begin
    LUserValue := AUser.GetValue('user');
    if LUserValue is TJSONObject then
    begin
      LUserObj := TJSONObject(LUserValue);

      LRepresentanteValue := LUserObj.GetValue('cod_representante');
      if Assigned(LRepresentanteValue) then
        id_representante := StrToIntDef(LRepresentanteValue.Value, 0);

      LNomeValue := LUserObj.GetValue('nome');
      if not Assigned(LNomeValue) then
        LNomeValue := LUserObj.GetValue('nomusu');
      if Assigned(LNomeValue) then
        FRepNome := LNomeValue.Value;

      LLoginValue := LUserObj.GetValue('logusu');
      if not Assigned(LLoginValue) then
        LLoginValue := LUserObj.GetValue('login');
      if Assigned(LLoginValue) then
        FUsuarioLogin := LLoginValue.Value;
    end;
  end;

  AtualizarCabecalho;
end;

procedure TfrmPrincipal.BtnConectarClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuClientesClick(Sender: TObject);
begin
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosClick(Sender: TObject);
begin
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  EnsurePedidoForm;
  frmClientes.Show;
end;

procedure TfrmPrincipal.MenuPedidosDigitadosClick(Sender: TObject);
begin
  if not Assigned(frmPedido) then
    Application.CreateForm(TfrmPedido, frmPedido);
  frmPedido.AtualizarOutboundPedido;
  if not Assigned(frmPedidosDigitados) then
    Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
  frmPedidosDigitados.Show;
end;

procedure TfrmPrincipal.MenuPedidosEnviadosClick(Sender: TObject);
begin
  if not Assigned(frmPedidosEnviados) then
    Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  frmPedidosEnviados.Show;
end;


procedure TfrmPrincipal.MenuProdutosClick(Sender: TObject);
begin
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuVendasClick(Sender: TObject);
begin
  EnsurePedidoForm;
  frmPedido.Show;
end;

procedure TfrmPrincipal.MenuTitulosClick(Sender: TObject);
begin
  EnsurePedidoItemForm;
  frmPedidoItem.Show;
end;

procedure TfrmPrincipal.MenuComissoesClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuConfigClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.MenuSuporteClick(Sender: TObject);
begin
  EnsureSyncForm;
  frmSync.Show;
end;

procedure TfrmPrincipal.EnsureSyncForm;
begin
  if not Assigned(frmSync) then
    Application.CreateForm(TfrmSync, frmSync);
end;

procedure TfrmPrincipal.EnsurePedidoForm;
begin
  if not Assigned(frmClientes) then
    Application.CreateForm(TfrmClientes, frmClientes);
end;

procedure TfrmPrincipal.EnsurePedidoItemForm;
begin
  if not Assigned(frmPedidoItem) then
    Application.CreateForm(TfrmPedidoItem, frmPedidoItem);
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);
begin
  AtualizarCabecalho;
  lySaidas.Visible := False;
  ProgressBarSync.Value := 0;
  LbProgresso.Text := 'Aguardando sincronizacao';
  ApplyOrientationLayout;
end;

procedure TfrmPrincipal.FormResize(Sender: TObject);
begin
  ApplyOrientationLayout;
end;

procedure TfrmPrincipal.ApplyOrientationLayout;
var
  LIsLandscape: Boolean;
  LScale: Single;
  LCardW: Single;
  LCardH: Single;
  LGridW: Single;
begin
  LIsLandscape := Width > Height;

  if LIsLandscape then
  begin
    TopBar.Height := 56;
    LbTitulo.Position.Y := (TopBar.Height - LbTitulo.Height) / 2;

    LScale := 0.8;
    Card.Scale.X := LScale;
    Card.Scale.Y := LScale;
    LCardW := Card.Width * LScale;
    LCardH := Card.Height * LScale;
    Card.Position.X := (Width - LCardW) / 2;
    Card.Position.Y := TopBar.Height + 8;

    MenuGrid.Scale.X := LScale;
    MenuGrid.Scale.Y := LScale;
    LGridW := MenuGrid.Width * LScale;
    MenuGrid.Position.X := (Width - LGridW) / 2;
    MenuGrid.Position.Y := Card.Position.Y + LCardH + 12;

    lbottom.Align := TAlignLayout.Bottom;
    lbottom.Margins.Bottom := 4;
    lbottom.Height := 48;
    lbottom.Width := Width - 10;
    lbottom.Position.X := 0;
  end
  else
  begin
    TopBar.Height := 96;
    LbTitulo.Position.Y := 53;

    Card.Scale.X := 1;
    Card.Scale.Y := 1;
    Card.Position.X := 18;
    Card.Position.Y := 112;
    Card.Width := 324;
    Card.Height := 128;

    MenuGrid.Scale.X := 1;
    MenuGrid.Scale.Y := 1;
    MenuGrid.Position.X := 18;
    MenuGrid.Position.Y := 256;
    MenuGrid.Width := 324;
    MenuGrid.Height := 225;

    lbottom.Align := TAlignLayout.MostBottom;
    if IsXiaomiDevice then
      lbottom.Margins.Bottom := 50
    else
      lbottom.Margins.Bottom := 0;
    lbottom.Height := 72;
    lbottom.Width := 350;
    lbottom.Position.X := 0;
  end;
end;

procedure TfrmPrincipal.imSairClick(Sender: TObject);
begin
  SairdoSistema;
end;

procedure TfrmPrincipal.SincronizarTudo;
begin
  if id_representante <= 0 then
  begin
    ShowMessage('Representante invalido para sincronizacao.');
    Exit;
  end;

  MemoLog.Lines.Clear;
  ProgressBarSync.Min := 0;
  ProgressBarSync.Max := 1;
  ProgressBarSync.Value := 0;
  LbProgresso.Text := 'Sincronizando dados...';

  TThread.CreateAnonymousThread(
    procedure
    var
      LCount: Integer;
      LMsg: string;
      procedure QueueLog(const AText: string);
      begin
        FQueueLogText := AText;
        TThread.Queue(nil, DoQueueLog);
      end;
    begin
      try
        dmApp.ClearSyncData;
        QueueLog('Banco local limpo.');

        LCount := 0;
        LCount := LCount + dmApp.SyncTable('representante', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('cliente', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('vendas1', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('vendas2', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('produto_representante', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('grupo_representante', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('produto_representante_inativos', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('prazo_representante', id_representante.ToString, 0);
        LCount := LCount + dmApp.SyncTable('produto', '', 0);
        LCount := LCount + dmApp.SyncTable('fop', '', 0);
        LCount := LCount + dmApp.SyncTable('prazo', '', 0);
        LCount := LCount + dmApp.SyncTable('cidades', '', 0);
        LMsg := 'Sincronizacao total: ' + LCount.ToString + ' registro(s)';

        FQueueDoneMsg := LMsg;
        TThread.Queue(nil, DoQueueDone);
      except
        on E: Exception do
        begin
          FQueueErrMsg := E.Message;
          TThread.Queue(nil, DoQueueError);
        end;
      end;
    end).Start;
end;

procedure TfrmPrincipal.DoQueueLog;
begin
  MemoLog.Lines.Add(FQueueLogText);
end;

procedure TfrmPrincipal.DoQueueDone;
begin
  MemoLog.Lines.Add(FQueueDoneMsg);
  ProgressBarSync.Value := 1;
  LbProgresso.Text := 'Sincronizacao concluida';
end;

procedure TfrmPrincipal.DoQueueError;
begin
  MemoLog.Lines.Add('Erro na sincronizacao: ' + FQueueErrMsg);
  LbProgresso.Text := 'Erro na sincronizacao: ' + FQueueErrMsg;
end;

end.

