{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
{-# LANGUAGE OverloadedStrings #-}

-- | Módulo Model: Define os tipos de dados (entidades) do sistema.
--   Contém as instâncias de JSON (Aeson) e de banco de dados (postgresql-simple).
module Model
    ( DicaInvestimento(..)
    , NovaDica(..)
    , Estatistica(..)
    , MensagemSucesso(..)
    , SimulacaoInput(..)
    , SimulacaoResult(..)
    , ComparacaoItem(..)
    , EvolucaoMensal(..)
    , HealthStatus(..)
    ) where

import GHC.Generics (Generic)
import Data.Aeson
    ( ToJSON(..)
    , FromJSON(..)
    , genericToJSON
    , genericParseJSON
    , defaultOptions
    , fieldLabelModifier
    )
import Data.Char (toLower)
import Data.Time (UTCTime)
import Database.PostgreSQL.Simple.FromRow (FromRow(..), field)

-- ---------------------------------------------------------------------------
-- Helpers: remove o prefixo Haskell e deixa o nome limpo no JSON
-- ---------------------------------------------------------------------------

stripPrefix :: Int -> String -> String
stripPrefix n s =
    let rest = drop n s
    in case rest of
        []     -> s
        (c:cs) -> toLower c : cs

prefixDica :: String -> String
prefixDica = stripPrefix 4

prefixNova :: String -> String
prefixNova = stripPrefix 4

prefixEst :: String -> String
prefixEst = stripPrefix 3

-- ---------------------------------------------------------------------------
-- | Entidade principal: DicaInvestimento
-- ---------------------------------------------------------------------------
data DicaInvestimento = DicaInvestimento
    { dicaId        :: Int
    , dicaTitulo    :: String
    , dicaDescricao :: String
    , dicaCategoria :: String
    , dicaRisco     :: String
    , dicaAutor     :: String
    , dicaCriacao   :: UTCTime
    , dicaVotos     :: Int
    } deriving (Generic, Show)

instance ToJSON DicaInvestimento where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = prefixDica }

instance FromJSON DicaInvestimento where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = prefixDica }

instance FromRow DicaInvestimento where
    fromRow = DicaInvestimento
        <$> field
        <*> field
        <*> field
        <*> field
        <*> field
        <*> field
        <*> field
        <*> field

-- ---------------------------------------------------------------------------
-- | Payload de criação/atualização
-- ---------------------------------------------------------------------------
data NovaDica = NovaDica
    { novaTitulo    :: String
    , novaDescricao :: String
    , novaCategoria :: String
    , novaRisco     :: String
    , novaAutor     :: String
    } deriving (Generic, Show)

instance ToJSON NovaDica where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = prefixNova }

instance FromJSON NovaDica where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = prefixNova }

-- ---------------------------------------------------------------------------
-- | Resultado do endpoint de estatísticas
-- ---------------------------------------------------------------------------
data Estatistica = Estatistica
    { estCategoria  :: String
    , estQuantidade :: Int
    } deriving (Generic, Show)

instance ToJSON Estatistica where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = prefixEst }

instance FromJSON Estatistica where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = prefixEst }

instance FromRow Estatistica where
    fromRow = Estatistica <$> field <*> field

-- ---------------------------------------------------------------------------
-- | Resposta genérica de sucesso
-- ---------------------------------------------------------------------------
data MensagemSucesso = MensagemSucesso
    { mensagem :: String
    } deriving (Generic, Show)

instance ToJSON MensagemSucesso
instance FromJSON MensagemSucesso

-- ---------------------------------------------------------------------------
-- | Simulador de Investimento
-- ---------------------------------------------------------------------------

data SimulacaoInput = SimulacaoInput
    { valorInicial   :: Double
    , tipoIndexador  :: String
    , taxaAnual      :: Double
    , periodoAnos    :: Int
    } deriving (Generic, Show)

instance ToJSON SimulacaoInput
instance FromJSON SimulacaoInput

data EvolucaoMensal = EvolucaoMensal
    { mes   :: Int
    , valor :: Double
    } deriving (Generic, Show)

instance ToJSON EvolucaoMensal
instance FromJSON EvolucaoMensal

data ComparacaoItem = ComparacaoItem
    { nomeInvestimento :: String
    , valorFinalComp   :: Double
    , rendimentoComp   :: Double
    , rendLiquidoComp  :: Double
    } deriving (Generic, Show)

instance ToJSON ComparacaoItem where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "nomeInvestimento" -> "nome"
            "valorFinalComp"   -> "valorFinal"
            "rendimentoComp"   -> "rendimento"
            "rendLiquidoComp"  -> "rendimentoLiquido"
            other              -> other
        }

instance FromJSON ComparacaoItem where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "nomeInvestimento" -> "nome"
            "valorFinalComp"   -> "valorFinal"
            "rendimentoComp"   -> "rendimento"
            "rendLiquidoComp"  -> "rendimentoLiquido"
            other              -> other
        }

data SimulacaoResult = SimulacaoResult
    { simValorFinal        :: Double
    , simRendimentoBruto   :: Double
    , simRendimentoLiquido :: Double
    , simAliquotaIR        :: Double
    , simComparacoes       :: [ComparacaoItem]
    , simEvolucaoMensal    :: [EvolucaoMensal]
    } deriving (Generic, Show)

instance ToJSON SimulacaoResult where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "simValorFinal"        -> "valorFinal"
            "simRendimentoBruto"   -> "rendimentoBruto"
            "simRendimentoLiquido" -> "rendimentoLiquido"
            "simAliquotaIR"        -> "aliquotaIR"
            "simComparacoes"       -> "comparacoes"
            "simEvolucaoMensal"    -> "evolucaoMensal"
            other                  -> other
        }

instance FromJSON SimulacaoResult where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "simValorFinal"        -> "valorFinal"
            "simRendimentoBruto"   -> "rendimentoBruto"
            "simRendimentoLiquido" -> "rendimentoLiquido"
            "simAliquotaIR"        -> "aliquotaIR"
            "simComparacoes"       -> "comparacoes"
            "simEvolucaoMensal"    -> "evolucaoMensal"
            other                  -> other
        }

-- ---------------------------------------------------------------------------
-- | Health check
-- ---------------------------------------------------------------------------
data HealthStatus = HealthStatus
    { healthStatus :: String   -- ^ "ok" | "degraded"
    , healthDb     :: String   -- ^ "connected" | "error"
    , healthVersion :: String  -- ^ versao da app
    } deriving (Generic, Show)

instance ToJSON HealthStatus where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "healthStatus"  -> "status"
            "healthDb"      -> "db"
            "healthVersion" -> "version"
            other           -> other
        }

instance FromJSON HealthStatus where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = \s -> case s of
            "healthStatus"  -> "status"
            "healthDb"      -> "db"
            "healthVersion" -> "version"
            other           -> other
        }