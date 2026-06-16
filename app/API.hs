{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE TypeOperators     #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Módulo API: Define os tipos da API REST usando Servant.
--   Responsável apenas por descrever os endpoints e tipos HTTP.
module API
    ( DicasAPI
    , dicasAPI
    ) where

import Servant
import Model

-- | Tipo principal da API: agrupa todos os endpoints
-- 
--   Endpoints disponíveis:
--   GET    /dicas                          → Lista todas as dicas (com filtros opcionais)
--   GET    /dicas/:id                      → Busca dica por ID
--   POST   /dicas                          → Cria nova dica
--   PUT    /dicas/:id                      → Atualiza dica existente
--   DELETE /dicas/:id                      → Remove dica
--   GET    /dicas/estatisticas             → Estatísticas por categoria
--   POST   /simulador                      → Simula rendimento de investimento
--   GET    /health                         → Health check da API + banco
type DicasAPI =
    -- GET /dicas?categoria=...&busca=...
    "dicas" :> QueryParam "categoria" String
            :> QueryParam "busca" String
            :> Get '[JSON] [DicaInvestimento]

    -- GET /dicas/estatisticas
    :<|> "dicas" :> "estatisticas"
                 :> Get '[JSON] [Estatistica]

    -- GET /dicas/:id
    :<|> "dicas" :> Capture "id" Int
                 :> Get '[JSON] DicaInvestimento

    -- POST /dicas
    :<|> "dicas" :> ReqBody '[JSON] NovaDica
                 :> Post '[JSON] DicaInvestimento

    -- PUT /dicas/:id
    :<|> "dicas" :> Capture "id" Int
                 :> ReqBody '[JSON] NovaDica
                 :> Put '[JSON] DicaInvestimento

    -- DELETE /dicas/:id
    :<|> "dicas" :> Capture "id" Int
                 :> Delete '[JSON] MensagemSucesso

    -- GET /dicas/:id/comentarios
    :<|> "dicas" :> Capture "id" Int
                 :> "comentarios"
                 :> Get '[JSON] [Comentario]

    -- POST /dicas/:id/comentarios
    :<|> "dicas" :> Capture "id" Int
                 :> "comentarios"
                 :> ReqBody '[JSON] NovoComentario
                 :> Post '[JSON] Comentario

    -- DELETE /dicas/:id/comentarios/:cid
    :<|> "dicas" :> Capture "id" Int
                 :> "comentarios"
                 :> Capture "cid" Int
                 :> Delete '[JSON] MensagemSucesso

    -- PUT /dicas/:id/comentarios/:cid
    :<|> "dicas" :> Capture "id" Int
                 :> "comentarios"
                 :> Capture "cid" Int
                 :> ReqBody '[JSON] NovoComentario
                 :> Put '[JSON] Comentario

    -- PATCH /dicas/:id/voto
    :<|> "dicas" :> Capture "id" Int
                 :> "voto"
                 :> Patch '[JSON] DicaInvestimento

    -- PATCH /dicas/:id/remover-voto
    :<|> "dicas" :> Capture "id" Int
                 :> "remover-voto"
                 :> Patch '[JSON] DicaInvestimento

    -- POST /simulador
    :<|> "simulador"
                 :> ReqBody '[JSON] SimulacaoInput
                 :> Post '[JSON] SimulacaoResult

    -- GET /health
    :<|> "health"
                 :> Get '[JSON] HealthStatus

-- | Proxy para o tipo da API (necessário para Servant)
dicasAPI :: Proxy DicasAPI
dicasAPI = Proxy