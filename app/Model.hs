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
-- Ex: dicaTitulo → "titulo" | novaTitulo → "titulo" | estCategoria → "categoria"
-- ---------------------------------------------------------------------------

-- Remove os primeiros N caracteres e coloca a primeira letra em minúsculo
stripPrefix :: Int -> String -> String
stripPrefix n s =
    let rest = drop n s
    in case rest of
        []     -> s
        (c:cs) -> toLower c : cs

-- DicaInvestimento: prefixo "dica" = 4 chars
--   dicaId        → "id"
--   dicaTitulo    → "titulo"
--   dicaDescricao → "descricao"
--   dicaCategoria → "categoria"
--   dicaRisco     → "risco"
--   dicaAutor     → "autor"
--   dicaCriacao   → "criacao"
prefixDica :: String -> String
prefixDica = stripPrefix 4

-- NovaDica: prefixo "nova" = 4 chars
--   novaTitulo    → "titulo"
--   novaDescricao → "descricao"
--   novaCategoria → "categoria"
--   novaRisco     → "risco"
--   novaAutor     → "autor"
prefixNova :: String -> String
prefixNova = stripPrefix 4

-- Estatistica: prefixo "est" = 3 chars
--   estCategoria  → "categoria"
--   estQuantidade → "quantidade"
prefixEst :: String -> String
prefixEst = stripPrefix 3

-- ---------------------------------------------------------------------------
-- | Entidade principal: DicaInvestimento
-- ---------------------------------------------------------------------------
data DicaInvestimento = DicaInvestimento
    { dicaId        :: Int      -- ^ id
    , dicaTitulo    :: String   -- ^ titulo
    , dicaDescricao :: String   -- ^ descricao
    , dicaCategoria :: String   -- ^ categoria
    , dicaRisco     :: String   -- ^ risco
    , dicaAutor     :: String   -- ^ autor
    , dicaCriacao   :: UTCTime  -- ^ criacao
    } deriving (Generic, Show)

-- JSON: { "id": 1, "titulo": "...", "descricao": "...", ... }
instance ToJSON DicaInvestimento where
    toJSON = genericToJSON defaultOptions
        { fieldLabelModifier = prefixDica }

instance FromJSON DicaInvestimento where
    parseJSON = genericParseJSON defaultOptions
        { fieldLabelModifier = prefixDica }

-- Leitura do banco de dados (mapeamento linha → tipo)
instance FromRow DicaInvestimento where
    fromRow = DicaInvestimento
        <$> field   -- id
        <*> field   -- titulo
        <*> field   -- descricao
        <*> field   -- categoria
        <*> field   -- risco
        <*> field   -- autor
        <*> field   -- data_criacao

-- ---------------------------------------------------------------------------
-- | Payload de criação/atualização — JSON simples sem prefixo
-- ---------------------------------------------------------------------------
data NovaDica = NovaDica
    { novaTitulo    :: String   -- ^ "titulo"
    , novaDescricao :: String   -- ^ "descricao"
    , novaCategoria :: String   -- ^ "categoria"
    , novaRisco     :: String   -- ^ "risco"
    , novaAutor     :: String   -- ^ "autor"
    } deriving (Generic, Show)

-- JSON: { "titulo": "...", "descricao": "...", "categoria": "...", ... }
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
    { estCategoria  :: String   -- ^ "categoria"
    , estQuantidade :: Int      -- ^ "quantidade"
    } deriving (Generic, Show)

-- JSON: { "categoria": "Ações", "quantidade": 3 }
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
