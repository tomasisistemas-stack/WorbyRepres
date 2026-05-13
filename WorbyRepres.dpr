program WorbyRepres;

uses
  System.StartUpCopy,
  FMX.Forms,
  unLogin in 'unLogin.pas' {frmLogin},
  unPrincipal in 'unPrincipal.pas' {frmPrincipal},
  unDMApp in 'unDMApp.pas' {dmApp: TDataModule},
  unSync in 'unSync.pas' {frmSync},
  unClientes in 'unClientes.pas' {frmClientes},
  unClienteDetalhe in 'unClienteDetalhe.pas' {frmClienteDetalhe},
  unPedido in 'unPedido.pas' {frmPedido},
  unPedidoItem in 'unPedidoItem.pas' {frmPedidoItem},
  unPedidosDigitados in 'unPedidosDigitados.pas' {frmPedidosDigitados},
  unFuncoes in 'unFuncoes.pas',
  unFormaPgto in 'unFormaPgto.pas',
  unPrazoPgto in 'unPrazoPgto.pas' {frmPrazoPgto},
  unPedidosEnviados in 'unPedidosEnviados.pas' {frmPedidosEnviados},
  unClienteCadastro in 'unClienteCadastro.pas' {frmClienteCadastro};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmApp, dmApp);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmPrazoPgto, frmPrazoPgto);
  Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  Application.CreateForm(TfrmClienteCadastro, frmClienteCadastro);
  Application.Run;

end.

