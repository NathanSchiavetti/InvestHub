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
import Database.PostgreSQL.Simple (Connection, query_)
import Database.PostgreSQL.Simple.Types (Query(..))
import Control.Monad.IO.Class (liftIO)
import Control.Exception (try, SomeException)
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
-- | Handler: POST /simulador
--   Calcula rendimento com juros compostos + IR regressivo + comparacoes
-- ---------------------------------------------------------------------------

-- | Taxa CDI de referência anual (% a.a.)
cdiReferencia :: Double
cdiReferencia = 13.75

-- | Taxa da poupança anual (70% do CDI quando Selic > 8,5%)
poupancaAnual :: Double
poupancaAnual = cdiReferencia * 0.70

-- | Alíquota IR pela tabela regressiva
aliquotaIR :: Int -> Double
aliquotaIR dias
    | dias <= 180  = 22.5
    | dias <= 360  = 20.0
    | dias <= 720  = 17.5
    | otherwise    = 15.0

-- | Converte taxa anual (%) para taxa mensal
taxaMensal :: Double -> Double
taxaMensal taxaAa = (1 + taxaAa / 100) ** (1/12) - 1

-- | Calcula valor final com juros compostos
jurosCompostos :: Double -> Double -> Int -> Double
jurosCompostos vi taxaAa meses =
    vi * (1 + taxaMensal taxaAa) ^ meses

-- | Gera evolução mensal
gerarEvolucao :: Double -> Double -> Int -> [EvolucaoMensal]
gerarEvolucao vi taxaAa meses =
    [ EvolucaoMensal m (arred2 $ vi * (1 + taxaMensal taxaAa) ^ m)
    | m <- [1..meses] ]

arred2 :: Double -> Double
arred2 x = fromIntegral (round (x * 100) :: Int) / 100

-- | Calcula rendimento líquido após IR
rendLiquido :: Double -> Double -> Int -> Double
rendLiquido vi taxaAa meses =
    let vf     = jurosCompostos vi taxaAa meses
        bruto  = vf - vi
        dias   = meses * 30
        aliq   = aliquotaIR dias / 100
        imposto = bruto * aliq
    in bruto - imposto

-- | IPCA de referencia anual (% a.a.)
ipcarReferencia :: Double
ipcarReferencia = 4.62

-- | Converte taxaAnual + tipoIndexador para taxa efetiva anual em %
--   CDI:       taxaAnual = % do CDI  (ex: 110 => 110% × 13.75% = 15.125% a.a.)
--   IPCA+:     taxaAnual = spread    (ex: 6.0 => IPCA 4.62% + 6% = 10.62% a.a.)
--   Prefixado: taxaAnual = taxa direta em % a.a.
taxaEfetiva :: String -> Double -> Double
taxaEfetiva "CDI"      pct    = cdiReferencia * pct / 100
taxaEfetiva "IPCA+"    spread = ipcarReferencia + spread
taxaEfetiva _          taxa   = taxa   -- Prefixado ou outros

handleSimular :: SimulacaoInput -> Handler SimulacaoResult
handleSimular input = do
    let vi       = valorInicial  input
        modo     = tipoIndexador input
        taxaAa   = taxaEfetiva modo (taxaAnual input)  -- taxa efetiva real
        anos     = periodoAnos   input
        meses    = anos * 12
        dias     = anos * 365

        -- Valor final do investimento escolhido
        vf      = jurosCompostos vi taxaAa meses
        rendB   = vf - vi
        aliq    = aliquotaIR dias
        imposto = rendB * (aliq / 100)
        rendL   = rendB - imposto

        -- Poupanca
        vfPoup    = jurosCompostos vi poupancaAnual meses
        rendPoup  = vfPoup - vi
        rendPoupL = rendPoup   -- poupanca e isenta de IR para PF

        -- CDI 100% (sempre como referencia)
        vfCdi    = jurosCompostos vi cdiReferencia meses
        rendCdi  = vfCdi - vi
        rendCdiL = rendCdi - rendCdi * (aliquotaIR dias / 100)

        -- Nome descritivo do investimento escolhido
        nomeEscolhido = case modo of
            "CDI"      -> "CDI " ++ show (round (taxaAnual input) :: Int) ++ "%"
            "IPCA+"    -> "IPCA+ " ++ show (taxaAnual input) ++ "%"
            _          -> "Pre-fixado " ++ show (taxaAnual input) ++ "%"

        comparacoes =
            [ ComparacaoItem "Poupanca"      (arred2 vfPoup) (arred2 rendPoup) (arred2 rendPoupL)
            , ComparacaoItem "CDI 100%"      (arred2 vfCdi)  (arred2 rendCdi)  (arred2 rendCdiL)
            , ComparacaoItem nomeEscolhido   (arred2 vf)     (arred2 rendB)    (arred2 rendL)
            ]

        evolucao = gerarEvolucao vi taxaAa meses

    return SimulacaoResult
        { simValorFinal        = arred2 vf
        , simRendimentoBruto   = arred2 rendB
        , simRendimentoLiquido = arred2 rendL
        , simAliquotaIR        = aliq
        , simComparacoes       = comparacoes
        , simEvolucaoMensal    = evolucao
        }

-- ---------------------------------------------------------------------------
-- | Handler: GET /health
--   Verifica conectividade com o banco (SELECT 1) e retorna status
-- ---------------------------------------------------------------------------
handleHealth :: Connection -> Handler HealthStatus
handleHealth conn = do
    dbStatus <- liftIO $ do
        result <- try (query_ conn (Query "SELECT 1") :: IO [[Int]])
        return $ case (result :: Either SomeException [[Int]]) of
            Left  _ -> "error"
            Right _ -> "connected"
    return HealthStatus
        { healthStatus  = if dbStatus == "connected" then "ok" else "degraded"
        , healthDb      = dbStatus
        , healthVersion = "1.0.0"
        }
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
    :<|> handleSimular
    :<|> handleHealth         conn

-- | Cria a aplicação WAI com CORS configurado
mkApp :: Connection -> Application
mkApp conn =
    cors (const $ Just corsPolicy) $
    serve dicasAPI (appServer conn)
