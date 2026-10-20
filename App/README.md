# WorbyRepApp

Aplicativo FireMonkey para Windows e Android, usando o SQLite `db.sqllite` e a API Horse criada em `WorbyRepRest`.

## Fluxo

1. Login em `POST /login`
2. Sincronizacao de tabelas via `POST /api/list`
3. Gravacao direta nas tabelas espelhadas no SQLite
4. Montagem de pedidos offline
5. Envio de pedidos via `POST /api/pedido`

## Arquivos principais

- `WorbyRepApp.dpr`
- `WorbyRepApp.dproj`
- `unDMApp.pas`
- `unLogin.pas` / `unLogin.fmx`
- `unPrincipal.pas` / `unPrincipal.fmx`

## Observacoes

- No Windows, o app usa `..\db.sqllite` em relacao ao executavel.
- No Android, o banco e criado em `Documents`.
- O projeto foi modelado visualmente com top bar escura e navegacao inferior, seguindo a linha do `CanhotoRapidoApp`.
