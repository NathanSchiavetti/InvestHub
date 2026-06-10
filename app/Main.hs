{-# LANGUAGE OverloadedStrings #-}

-- | Módulo Main: Ponto de entrada da aplicação.
module Main (main) where

import Server (mkApp)
import Network.Wai.Handler.Warp (run)
import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.Types (Query(..))
import Control.Monad (void)
import Control.Exception (try, SomeException)
import System.IO (hPutStrLn, stderr)

-- ---------------------------------------------------------------------------
-- | Executa a migration do schema diretamente no banco.
--   SQL embutido no codigo para evitar problemas de encoding de arquivo.
-- ---------------------------------------------------------------------------
runMigration :: Connection -> IO ()
runMigration conn = do
    result <- (try $ do
        void $ execute_ conn
            "CREATE TABLE IF NOT EXISTS dicas_investimento ( \
            \    id           SERIAL PRIMARY KEY,            \
            \    titulo       VARCHAR(200) NOT NULL,         \
            \    descricao    TEXT NOT NULL,                 \
            \    categoria    VARCHAR(100) NOT NULL,         \
            \    risco        VARCHAR(20) NOT NULL           \
            \        CHECK (risco IN ('Baixo','Medio','Alto')),\
            \    autor        VARCHAR(100) NOT NULL,         \
            \    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL \
            \)"
        void $ execute_ conn
            "CREATE INDEX IF NOT EXISTS idx_dicas_categoria \
            \    ON dicas_investimento (LOWER(categoria))"
        void $ execute_ conn
            "CREATE INDEX IF NOT EXISTS idx_dicas_titulo \
            \    ON dicas_investimento (LOWER(titulo))"
        void $ execute_ conn
            "CREATE INDEX IF NOT EXISTS idx_dicas_data_criacao \
            \    ON dicas_investimento (data_criacao DESC)"
        ) :: IO (Either SomeException ())
    case result of
        Left err -> hPutStrLn stderr $ "[AVISO] Migration: " ++ show err
        Right _  -> putStrLn "Migration executada com sucesso!"

-- ---------------------------------------------------------------------------
-- | Configuração de conexão com o PostgreSQL
-- ---------------------------------------------------------------------------
dbConfig :: ConnectInfo
dbConfig = defaultConnectInfo
    { connectHost     = "localhost"
    , connectPort     = 5432
    , connectDatabase = "dicas_db"
    , connectUser     = "postgres"
    , connectPassword = "ROOT"
    }

-- ---------------------------------------------------------------------------
-- | Ponto de entrada principal
-- ---------------------------------------------------------------------------
main :: IO ()
main = do
    putStrLn "Dicas de Investimento API"
    putStrLn ""

    putStrLn "Conectando ao banco de dados PostgreSQL..."
    conn <- connect dbConfig
    putStrLn "Conexao estabelecida!"

    putStrLn "Executando migration..."
    runMigration conn

    let port = 8080
    putStrLn $ "Servidor rodando na porta " ++ show port
    putStrLn "API: http://localhost:8080/dicas"
    putStrLn ""

    run port (mkApp conn)