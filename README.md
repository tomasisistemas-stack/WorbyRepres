# WorbyRep SQLite

Arquivo principal: `db.sqllite`

Objetivo:
- armazenar as tabelas sincronizadas (espelho do PostgreSQL)
- guardar sessao/login
- manter fila local de pedidos a enviar para `POST /api/pedido`
- registrar requests/responses da integracao

Tabelas de suporte:
- `app_config`
- `api_session`
- `sync_table_state`
- `outbound_pedido`
- `outbound_pedido_item`
- `request_log`

Fluxo sugerido:
1. autenticar em `POST /login`
2. sincronizar tabelas via `POST /api/list`
3. gravar retorno direto nas tabelas espelhadas
4. montar pedidos locais em `outbound_pedido` e `outbound_pedido_item`
5. enviar para `POST /api/pedido`
6. salvar `numdoc_remote`, `sent_at` e `status`
