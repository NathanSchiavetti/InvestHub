{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

-- | Módulo Repository: Camada de acesso ao banco de dados.
--   Todas as queries SQL ficam aqui, isoladas das regras de negócio.
--   Usa postgresql-simple para interagir com o PostgreSQL.
module Repository
    ( listarDicas
    , buscarDicaPorId
    , criarDica
    , atualizarDica
    , deletarDica
    , buscarEstatisticas
    , incrementarVoto
    , decrementarVoto
    , listarComentarios
    , criarComentario
    , atualizarComentario
    , deletarComentario
    ) where

import Database.PostgreSQL.Simple
import Database.PostgreSQL.Simple.Types (Query(..))
import qualified Data.ByteString.Char8 as BS
import Model
import Control.Exception (try, SomeException)

-- ---------------------------------------------------------------------------
-- Queries SQL organizadas como constantes
-- ---------------------------------------------------------------------------

sqlListarTodas :: Query
sqlListarTodas =
    "SELECT id, titulo, descricao, categoria, risco, autor, data_criacao, votos \
    \ FROM dicas_investimento \
    \ ORDER BY data_criacao DESC"

sqlListarPorCategoria :: Query
sqlListarPorCategoria =
    "SELECT id, titulo, descricao, categoria, risco, autor, data_criacao, votos \
    \ FROM dicas_investimento \
    \ WHERE LOWER(categoria) = LOWER(?) \
    \ ORDER BY data_criacao DESC"

sqlBuscarPorTitulo :: Query
sqlBuscarPorTitulo =
    "SELECT id, titulo, descricao, categoria, risco, autor, data_criacao, votos \
    \ FROM dicas_investimento \
    \ WHERE LOWER(titulo) LIKE LOWER(?) \
    \ ORDER BY data_criacao DESC"

sqlBuscarPorCategoriaETitulo :: Query
sqlBuscarPorCategoriaETitulo =
    "SELECT id, titulo, descricao, categoria, risco, autor, data_criacao, votos \
    \ FROM dicas_investimento \
    \ WHERE LOWER(categoria) = LOWER(?) \
    \   AND LOWER(titulo) LIKE LOWER(?) \
    \ ORDER BY data_criacao DESC"

sqlBuscarPorId :: Query
sqlBuscarPorId =
    "SELECT id, titulo, descricao, categoria, risco, autor, data_criacao, votos \
    \ FROM dicas_investimento \
    \ WHERE id = ?"

sqlCriar :: Query
sqlCriar =
    "INSERT INTO dicas_investimento (titulo, descricao, categoria, risco, autor) \
    \ VALUES (?, ?, ?, ?, ?) \
    \ RETURNING id, titulo, descricao, categoria, risco, autor, data_criacao, votos"

sqlAtualizar :: Query
sqlAtualizar =
    "UPDATE dicas_investimento \
    \ SET titulo = ?, descricao = ?, categoria = ?, risco = ?, autor = ? \
    \ WHERE id = ? \
    \ RETURNING id, titulo, descricao, categoria, risco, autor, data_criacao, votos"

sqlDeletar :: Query
sqlDeletar = "DELETE FROM dicas_investimento WHERE id = ?"

sqlEstatisticas :: Query
sqlEstatisticas =
    "SELECT categoria, COUNT(*) as quantidade \
    \ FROM dicas_investimento \
    \ GROUP BY categoria \
    \ ORDER BY quantidade DESC"

sqlVotar :: Query
sqlVotar =
    "UPDATE dicas_investimento \
    \ SET votos = votos + 1 \
    \ WHERE id = ? \
    \ RETURNING id, titulo, descricao, categoria, risco, autor, data_criacao, votos"

incrementarVoto :: Connection -> Int -> IO (Maybe DicaInvestimento)
incrementarVoto conn dicId = do
    resultados <- query conn sqlVotar (Only dicId)
    case resultados of
        []    -> return Nothing
        (d:_) -> return (Just d)

-- ---------------------------------------------------------------------------
-- Funções de acesso ao banco
-- ---------------------------------------------------------------------------

-- | Lista todas as dicas, com filtros opcionais por categoria e/ou título
listarDicas :: Connection -> Maybe String -> Maybe String -> IO [DicaInvestimento]
listarDicas conn Nothing Nothing =
    query_ conn sqlListarTodas

listarDicas conn (Just cat) Nothing =
    query conn sqlListarPorCategoria (Only cat)

listarDicas conn Nothing (Just busca) =
    query conn sqlBuscarPorTitulo (Only ("%" ++ busca ++ "%"))

listarDicas conn (Just cat) (Just busca) =
    query conn sqlBuscarPorCategoriaETitulo (cat, "%" ++ busca ++ "%")

-- | Busca uma dica pelo ID. Retorna Nothing se não encontrada.
buscarDicaPorId :: Connection -> Int -> IO (Maybe DicaInvestimento)
buscarDicaPorId conn dicId = do
    resultados <- query conn sqlBuscarPorId (Only dicId)
    case resultados of
        []    -> return Nothing
        (d:_) -> return (Just d)

-- | Cria uma nova dica e retorna o registro completo (com id e data gerados)
criarDica :: Connection -> NovaDica -> IO (Maybe DicaInvestimento)
criarDica conn nova = do
    resultados <- query conn sqlCriar
        ( novaTitulo nova
        , novaDescricao nova
        , novaCategoria nova
        , novaRisco nova
        , novaAutor nova
        )
    case resultados of
        []    -> return Nothing
        (d:_) -> return (Just d)

-- | Atualiza uma dica existente e retorna o registro atualizado
atualizarDica :: Connection -> Int -> NovaDica -> IO (Maybe DicaInvestimento)
atualizarDica conn dicId nova = do
    resultados <- query conn sqlAtualizar
        ( novaTitulo nova
        , novaDescricao nova
        , novaCategoria nova
        , novaRisco nova
        , novaAutor nova
        , dicId
        )
    case resultados of
        []    -> return Nothing
        (d:_) -> return (Just d)

-- | Remove uma dica pelo ID. Retorna o número de linhas afetadas.
deletarDica :: Connection -> Int -> IO Int
deletarDica conn dicId = do
    n <- execute conn sqlDeletar (Only dicId)
    return (fromIntegral n)

-- | Retorna estatísticas de quantidade de dicas por categoria
buscarEstatisticas :: Connection -> IO [Estatistica]
buscarEstatisticas conn = query_ conn sqlEstatisticas

sqlRemoverVoto :: Query
sqlRemoverVoto =
    "UPDATE dicas_investimento \
    \ SET votos = GREATEST(votos - 1, 0) \
    \ WHERE id = ? \
    \ RETURNING id, titulo, descricao, categoria, risco, autor, data_criacao, votos"

decrementarVoto :: Connection -> Int -> IO (Maybe DicaInvestimento)
decrementarVoto conn dicId = do
    resultados <- query conn sqlRemoverVoto (Only dicId)
    case resultados of
        []    -> return Nothing
        (d:_) -> return (Just d)

sqlListarComentarios :: Query
sqlListarComentarios =
    "SELECT id, dica_id, autor, texto, data_criacao \
    \ FROM comentarios \
    \ WHERE dica_id = ? \
    \ ORDER BY data_criacao ASC"

sqlCriarComentario :: Query
sqlCriarComentario =
    "INSERT INTO comentarios (dica_id, autor, texto) \
    \ VALUES (?, ?, ?) \
    \ RETURNING id, dica_id, autor, texto, data_criacao"

listarComentarios :: Connection -> Int -> IO [Comentario]
listarComentarios conn dicId = query conn sqlListarComentarios (Only dicId)

criarComentario :: Connection -> Int -> NovoComentario -> IO (Maybe Comentario)
criarComentario conn dicId novo = do
    resultados <- query conn sqlCriarComentario
        ( dicId
        , ncAutor novo
        , ncTexto novo
        )
    case resultados of
        []    -> return Nothing
        (c:_) -> return (Just c)

sqlDeletarComentario :: Query
sqlDeletarComentario =
    "DELETE FROM comentarios WHERE id = ? AND dica_id = ?"

deletarComentario :: Connection -> Int -> Int -> IO Int
deletarComentario conn dicId cid = do
    n <- execute conn sqlDeletarComentario (cid, dicId)
    return (fromIntegral n)

sqlAtualizarComentario :: Query
sqlAtualizarComentario =
    "UPDATE comentarios SET texto = ? WHERE id = ? AND dica_id = ? RETURNING id, dica_id, autor, texto, data_criacao"

atualizarComentario :: Connection -> Int -> Int -> NovoComentario -> IO (Maybe Comentario)
atualizarComentario conn dicId cid novo = do
    resultados <- query conn sqlAtualizarComentario
        ( ncTexto novo
        , cid
        , dicId
        )
    case resultados of
        []    -> return Nothing
        (c:_) -> return (Just c)