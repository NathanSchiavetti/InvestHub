# Usando imagem oficial do Haskell com GHC 9.4 (LTS estável)
FROM haskell:9.4.7-slim AS builder

WORKDIR /app

# Copia os arquivos de projeto primeiro (para aproveitar cache do Docker)
COPY dicas-investimento.cabal cabal.project ./

# Atualiza o índice do Cabal e baixa dependências
RUN cabal update && cabal build --only-dependencies

# Copia o código fonte
COPY app/ ./app/
COPY migration.sql ./

# Compila o projeto em modo release
RUN cabal build -O2 exe:dicas-investimento

# Copia o binário para um local fixo
RUN cp $(cabal list-bin dicas-investimento) /app/servidor

# ─────────────────────────────────────────────
# Imagem final minimalista (sem GHC/Cabal)
# ─────────────────────────────────────────────
FROM debian:bookworm-slim

# Instala apenas as libs necessárias em runtime
RUN apt-get update && apt-get install -y \
    libpq5 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia binário e migration do stage anterior
COPY --from=builder /app/servidor ./servidor
COPY --from=builder /app/migration.sql ./migration.sql

EXPOSE 8080

CMD ["./servidor"]
