-- ============================================================
-- Remove dicas duplicadas mantendo apenas a mais antiga (menor ID)
-- Execute este script no pgAdmin
-- ============================================================

-- 1) Ver quantas duplicatas existem antes de apagar
SELECT titulo, COUNT(*) AS qtd
FROM dicas_investimento
GROUP BY titulo
HAVING COUNT(*) > 1
ORDER BY qtd DESC;

-- 2) Deletar os duplicados (mantém o de menor ID)
DELETE FROM dicas_investimento
WHERE id NOT IN (
    SELECT MIN(id)
    FROM dicas_investimento
    GROUP BY titulo
);

-- 3) Adiciona constraint UNIQUE no titulo para nunca mais duplicar
ALTER TABLE dicas_investimento
ADD CONSTRAINT uq_dica_titulo UNIQUE (titulo);

-- 4) Confirmar resultado
SELECT COUNT(*) AS total_restantes FROM dicas_investimento;
