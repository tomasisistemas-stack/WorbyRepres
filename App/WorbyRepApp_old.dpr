program WorbyRepApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  FireDAC.FMXUI.Wait,
  unLogin in 'unLogin.pas' {frmLogin},
  unPrincipal in 'unPrincipal.pas' {frmPrincipal},
  unClientes in 'unClientes.pas' {frmClientes},
  unClienteDetalhe in 'unClienteDetalhe.pas' {frmClienteDetalhe},
  unSync in 'unSync.pas' {frmSync},
  unPedido in 'unPedido.pas' {frmPedido},
  unPedidoItem in 'unPedidoItem.pas' {frmPedidoItem},
  unDMApp in 'unDMApp.pas' {dmApp: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmApp, dmApp);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
