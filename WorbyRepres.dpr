program WorbyRepres;

uses
  System.StartUpCopy,
  FMX.Forms,
  {$IFDEF ANDROID}
  ServiceGeoWorker in '..\Service\ServiceGeoWorker.pas',
  ServiceUnit in '..\Service\ServiceUnit.pas' {LocationTrackingModule: TAndroidService},
  {$ENDIF}
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
  unClienteCadastro in 'unClienteCadastro.pas' {frmClienteCadastro},
  unCidadeBusca in 'unCidadeBusca.pas' {frmCidadeBusca},
  unOffline in 'unOffline.pas' {frmOffline},
  unDashBoard in 'unDashBoard.pas' {frmDashBoard};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmApp, dmApp);
  Application.CreateForm(TfrmLogin, frmLogin);
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmSync, frmSync);
  Application.CreateForm(TfrmClientes, frmClientes);
  Application.CreateForm(TfrmClienteDetalhe, frmClienteDetalhe);
  Application.CreateForm(TfrmPedido, frmPedido);
  Application.CreateForm(TfrmPedidoItem, frmPedidoItem);
  Application.CreateForm(TfrmPedidosDigitados, frmPedidosDigitados);
  Application.CreateForm(TfrmFormaPgto, frmFormaPgto);
  Application.CreateForm(TfrmPrazoPgto, frmPrazoPgto);
  Application.CreateForm(TfrmPedidosEnviados, frmPedidosEnviados);
  Application.CreateForm(TfrmClienteCadastro, frmClienteCadastro);
  Application.CreateForm(TfrmCidadeBusca, frmCidadeBusca);
  Application.CreateForm(TfrmOffline, frmOffline);
  Application.CreateForm(TfrmDashBoard, frmDashBoard);
  Application.Run;

end.


