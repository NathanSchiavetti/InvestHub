{-# LANGUAGE OverloadedStrings #-}

-- | Módulo Server: Implementações dos handlers (manipuladores) da API.
--   Liga a definição de tipos da API (API.hs) às operações do banco (Repository.hs).
--   Contém as regras de negócio e o tratamento de erros HTTP.
module Server
    ( appServer
    , mkApp
    ) where

import Servant
import Network.Wai (Application)
import Network.Wai.Middleware.Cors
    ( cors
    , corsRequestHeaders
    , corsMethods
    , corsOrigins
    , simpleCorsResourcePolicy
    , CorsResourcePolicy(..)
    )
import Network.HTTP.Types.Method (methodGet, methodPost, methodPut, methodDelete, methodOptions, methodPatch)
import Database.PostgreSQL.Simple (Connection)
import Control.Monad.IO.Class (liftIO)
import API
import Model
import Repository

-- ---------------------------------------------------------------------------
-- Configuração de CORS (permite comunicação com o frontend)
-- ---------------------------------------------------------------------------

corsPolicy :: CorsResourcePolicy
corsPolicy = simpleCorsResourcePolicy
    { corsOrigins        = Nothing                  
    , corsMethods        = [ methodGet, methodPost
                           , methodPut, methodDelete
                           , methodPatch            
                           , methodOptions ]
    , corsRequestHeaders = [ "Content-Type"
                           , "Accept"
                           , "Authorization" ]
    }

-- ---------------------------------------------------------------------------
-- Handlers dos endpoints
-- ---------------------------------------------------------------------------

-- | Handler: GET /dicas?categoria=...&busca=...
handleListarDicas
    :: Connection
    -> Maybe String    -- ^ Filtro por categoria
    -> Maybe String    -- ^ Busca por título
    -> Handler [DicaInvestimento]
handleListarDicas conn mCat mBusca = do
    dicas <- liftIO $ listarDicas conn mCat mBusca
    return dicas

-- | Handler: GET /dicas/estatisticas
handleEstatisticas :: Connection -> Handler [Estatistica]
handleEstatisticas conn = do
    stats <- liftIO $ buscarEstatisticas conn
    return stats

-- | Handler: GET /dicas/:id
handleBuscarDica :: Connection -> Int -> Handler DicaInvestimento
handleBuscarDica conn dicId = do
    resultado <- liftIO $ buscarDicaPorId conn dicId

    case resultado of
        Nothing ->
            throwError err404

        Just dica ->
            return dica
 

-- | Handler: POST /dicas
handleCriarDica :: Connection -> NovaDica -> Handler DicaInvestimento
handleCriarDica conn nova = do
    -- Validação básica dos campos obrigatórios
    if null (novaTitulo nova) || null (novaDescricao nova)
        then throwError err400
            { errBody = "{ \"erro\": \"Título e descrição são obrigatórios\" }" }
        else do
            resultado <- liftIO $ criarDica conn nova
            case resultado of
                Nothing   -> throwError err500
                    { errBody = "{ \"erro\": \"Falha ao criar dica\" }" }
                Just dica -> return dica

-- | Handler: PUT /dicas/:id
handleAtualizarDica :: Connection -> Int -> NovaDica -> Handler DicaInvestimento
handleAtualizarDica conn dicId nova = do
    -- Verifica se a dica existe antes de atualizar
    existe <- liftIO $ buscarDicaPorId conn dicId
    case existe of
        Nothing -> throwError err404
            { errBody = "{ \"erro\": \"Dica não encontrada para atualizar\" }" }
        Just _  -> do
            resultado <- liftIO $ atualizarDica conn dicId nova
            case resultado of
                Nothing   -> throwError err500
                    { errBody = "{ \"erro\": \"Falha ao atualizar dica\" }" }
                Just dica -> return dica

-- | Handler: DELETE /dicas/:id
handleDeletarDica :: Connection -> Int -> Handler MensagemSucesso
handleDeletarDica conn dicId = do
    n <- liftIO $ deletarDica conn dicId
    if n == 0
        then throwError err404
            { errBody = "{ \"erro\": \"Dica não encontrada para excluir\" }" }
        else return (MensagemSucesso "Dica excluída com sucesso")

handleVotarDica :: Connection -> Int -> Handler DicaInvestimento
handleVotarDica conn dicId = do
    resultado <- liftIO $ incrementarVoto conn dicId
    case resultado of   
        Nothing   -> throwError err404
            { errBody = "{ \"erro\": \"Dica não encontrada\" }" }
        Just dica -> return dica

handleRemoverVoto :: Connection -> Int -> Handler DicaInvestimento
handleRemoverVoto conn dicId = do
    resultado <- liftIO $ decrementarVoto conn dicId
    case resultado of
        Nothing   -> throwError err404
            { errBody = "{ \"erro\": \"Dica não encontrada\" }" }
        Just dica -> return dica        
-- ---------------------------------------------------------------------------
-- Composição do servidor
-- ---------------------------------------------------------------------------

-- | Combina todos os handlers na ordem definida em API.hs
appServer :: Connection -> Server DicasAPI
appServer conn =
         handleListarDicas    conn
    :<|> handleEstatisticas   conn
    :<|> handleBuscarDica     conn
    :<|> handleCriarDica      conn
    :<|> handleAtualizarDica  conn
    :<|> handleDeletarDica    conn
    :<|> handleVotarDica      conn
    :<|> handleRemoverVoto    conn

-- | Cria a aplicação WAI com CORS configurado
mkApp :: Connection -> Application
mkApp conn =
    cors (const $ Just corsPolicy) $
    serve dicasAPI (appServer conn)
