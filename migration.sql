-- ============================================================
-- Schema PostgreSQL: Dicas de Investimento
-- ============================================================

-- Garante que a extensão de UUID esteja disponível (opcional)
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabela principal de dicas de investimento
CREATE TABLE IF NOT EXISTS dicas_investimento (
    id           SERIAL PRIMARY KEY,
    titulo       VARCHAR(200) NOT NULL,
    descricao    TEXT NOT NULL,
    categoria    VARCHAR(100) NOT NULL,
    risco        VARCHAR(20)  NOT NULL CHECK (risco IN ('Baixo', 'Médio', 'Alto')),
    autor        VARCHAR(100) NOT NULL,
    data_criacao TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Índices para melhorar performance das buscas e filtros
CREATE INDEX IF NOT EXISTS idx_dicas_categoria
    ON dicas_investimento (LOWER(categoria));

CREATE INDEX IF NOT EXISTS idx_dicas_titulo
    ON dicas_investimento (LOWER(titulo));

CREATE INDEX IF NOT EXISTS idx_dicas_data_criacao
    ON dicas_investimento (data_criacao DESC);

-- ============================================================
-- Dados iniciais para demonstração
-- ============================================================
INSERT INTO dicas_investimento (titulo, descricao, categoria, risco, autor)
VALUES
    (
        'Tesouro Selic: segurança e liquidez para a reserva de emergência',
        'O Tesouro Selic é a melhor opção para guardar sua reserva de emergência. '
        'Acompanha a taxa básica de juros, tem liquidez diária e baixíssimo risco, '
        'sendo garantido pelo governo federal.',
        'Renda Fixa',
        'Baixo',
        'Prof. Alexandre'
    ),
    (
        'Fundos Imobiliários (FIIs): renda passiva mensal',
        'Os FIIs permitem investir em imóveis de forma fracionada e receber dividendos '
        'mensais isentos de IR para pessoa física. Indicados para quem busca renda passiva '
        'sem precisar administrar imóveis físicos.',
        'FIIs',
        'Médio',
        'Prof. Alexandre'
    ),
    (
        'ETFs de Ações: diversificação com baixo custo',
        'Os ETFs (fundos de índice) como BOVA11 permitem investir em dezenas de empresas '
        'com uma única operação, oferecendo diversificação automática e taxas de administração '
        'muito menores que fundos tradicionais.',
        'Ações',
        'Alto',
        'Prof. Alexandre'
    ),
    (
        'CDB com liquidez diária: alternativa ao Tesouro Selic',
        'Bancos digitais oferecem CDBs com liquidez diária pagando 100% ou mais do CDI. '
        'São garantidos pelo FGC até R$ 250.000 e podem render mais que o Tesouro Selic '
        'dependendo da instituição.',
        'Renda Fixa',
        'Baixo',
        'Prof. Alexandre'
    ),
    (
        'Ações de dividendos: empresas que pagam bem',
        'Empresas consolidadas como bancos, elétricas e saneamento costumam distribuir '
        'dividendos generosos. Analise o Dividend Yield (DY) histórico e a consistência '
        'dos pagamentos antes de investir.',
        'Ações',
        'Médio',
        'Prof. Alexandre'
    ),
    (
        'Previdência Privada PGBL: benefício fiscal para quem declara IR completo',
        'O PGBL permite deduzir até 12% da renda bruta anual na declaração de IR. '
        'É indicado para quem usa o modelo completo e está na faixa de 27,5% de alíquota, '
        'gerando um benefício fiscal imediato.',
        'Previdência',
        'Baixo',
        'Prof. Alexandre'
    )
ON CONFLICT DO NOTHING;