{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Server (mkApp)
import Network.Wai.Handler.Warp (run)
import Database.PostgreSQL.Simple
import Control.Monad (void)
import Control.Exception (try, SomeException)
import System.IO (hPutStrLn, stderr)
import System.Environment (lookupEnv)
import Data.Maybe (fromMaybe)

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
            \        CHECK (risco IN ('Baixo','Médio','Alto')),\
            \    autor        VARCHAR(100) NOT NULL,         \
            \    votos        INT DEFAULT 0,                 \
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

-- Função para construir a configuração lendo as variáveis de ambiente do Render
configurarConexao :: IO ConnectInfo
configurarConexao = do
    envHost <- fromMaybe "localhost" <$> lookupEnv "DB_HOST"
    envPort <- fromMaybe "5432"      <$> lookupEnv "DB_PORT"
    envName <- fromMaybe "dicas_db"   <$> lookupEnv "DB_NAME"
    envUser <- fromMaybe "postgres"   <$> lookupEnv "DB_USER"
    envPass <- fromMaybe "ROOT"       <$> lookupEnv "DB_PASSWORD"
    
    return defaultConnectInfo
        { connectHost     = envHost
        , connectPort     = read envPort
        , connectDatabase = envName
        , connectUser     = envUser
        , connectPassword = envPass
        }

main :: IO ()
main = do
    putStrLn "Dicas de Investimento API"
    putStrLn ""

    putStrLn "Conectando ao banco de dados PostgreSQL..."
    dbConfig <- configurarConexao
    conn <- connect dbConfig
    putStrLn "Conexão estabelecida!"

    putStrLn "Executando migration..."
    runMigration conn

    -- O Render define a porta automaticamente na variável PORT
    envPorta <- lookupEnv "PORT"
    let port = maybe 8080 read envPorta

    putStrLn $ "Servidor rodando na porta " ++ show port
    putStrLn ""

    run port (mkApp conn)