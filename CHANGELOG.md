# CHANGELOG

## [0.1.0.0] - 2025

### Adicionado
- CRUD completo de DicaInvestimento (GET, POST, PUT, DELETE)
- Filtro por categoria via query param `?categoria=`
- Busca por título via query param `?busca=`
- Endpoint de estatísticas `/dicas/estatisticas`
- CORS configurado para comunicação com frontend
- Migration SQL automática ao iniciar
- Frontend em Tailwind CSS com design dark/glassmorphism
- Dockerfile multi-stage para deploy
- docker-compose com PostgreSQL
