-- ============================================================
-- Novas dicas para todas as categorias
-- Cole no Query Tool do pgAdmin e pressione F5
-- ============================================================

INSERT INTO dicas_investimento (titulo, descricao, categoria, risco, autor) VALUES

-- ── RENDA FIXA ──
('LCI e LCA: isencao de IR para pessoa fisica',
 'Letras de Credito Imobiliario e do Agronegocio sao isentas de Imposto de Renda para pessoa fisica. Oferecem rentabilidade proxima ou acima do CDI e sao garantidas pelo FGC ate R$ 250.000 por CPF por instituicao.',
 'Renda Fixa', 'Baixo', 'Prof. Alexandre'),

('Debentures incentivadas: renda fixa com isencao de IR',
 'Debentures de empresas de infraestrutura sao isentas de IR para pessoa fisica. Rendem acima do CDI e financiam projetos como rodovias, energia e saneamento. Risco maior que CDB mas com premio de retorno atrativo.',
 'Renda Fixa', 'Médio', 'Prof. Alexandre'),

('Tesouro IPCA+: protecao contra inflacao no longo prazo',
 'O Tesouro IPCA+ garante uma taxa real acima da inflacao. Ideal para objetivos de longo prazo como aposentadoria. Quanto maior o prazo, maior a sensibilidade a variacao das taxas de juros.',
 'Renda Fixa', 'Baixo', 'Prof. Alexandre'),

-- ── ACOES ──
('Como analisar empresas pelo P/L e P/VP',
 'O Preco/Lucro indica quantos anos levaria para recuperar o investimento. O Preco/Valor Patrimonial mostra se a acao esta cara ou barata em relacao ao patrimonio. Combine com outros indicadores como ROE e divida liquida.',
 'Ações', 'Alto', 'Prof. Alexandre'),

('Estrategia de Small Caps: alto risco, alto retorno',
 'Empresas de menor porte (Small Caps) tendem a crescer mais rapidamente do que as grandes. Sao menos analisadas pelo mercado, criando oportunidades de compra abaixo do valor justo. Exige maior tolerancia a volatilidade.',
 'Ações', 'Alto', 'Prof. Alexandre'),

('Buy and Hold: a estrategia dos grandes investidores',
 'Comprar e segurar acoes de otimas empresas por muitos anos e a estrategia de Warren Buffett. O tempo e o maior aliado do investidor: juros compostos, reinvestimento de dividendos e crescimento dos lucros geram riqueza no longo prazo.',
 'Ações', 'Médio', 'Prof. Alexandre'),

-- ── FIIs ──
('FIIs de Papel vs FIIs de Tijolo: qual escolher?',
 'FIIs de Tijolo investem em imoveis fisicos (shoppings, galpoes, lajes). FIIs de Papel investem em CRIs e CRAs. Em alta de juros, FIIs de Papel tendem a se beneficiar. Em baixa de juros, FIIs de Tijolo valorizam mais.',
 'FIIs', 'Médio', 'Prof. Alexandre'),

('Galpoes logisticos: o FII mais promissor da decada',
 'Com o crescimento do e-commerce, galpoes de alto padrao (A+) proximos a grandes centros urbanos estao em alta demanda. FIIs como XPML11, BRCO11 e LVBI11 sao referencias no setor de logistica.',
 'FIIs', 'Médio', 'Prof. Alexandre'),

('Como avaliar um FII: P/VP e Dividend Yield',
 'Um FII com P/VP abaixo de 1 pode indicar desconto sobre o valor dos imoveis. O Dividend Yield mensal deve ser avaliado junto a qualidade dos contratos de locacao, vacancia e solidez dos inquilinos.',
 'FIIs', 'Baixo', 'Prof. Alexandre'),

-- ── PREVIDENCIA ──
('VGBL vs PGBL: qual e o certo para voce?',
 'O PGBL e indicado para quem declara IR no modelo completo (deduz ate 12% da renda bruta). O VGBL e melhor para quem usa o modelo simplificado ou e isento. No resgate, o IR incide so sobre o rendimento no VGBL.',
 'Previdência', 'Baixo', 'Prof. Alexandre'),

('Tabela regressiva ou progressiva na previdencia?',
 'Na tabela regressiva, quanto mais tempo o dinheiro fica investido, menor a aliquota de IR (chegando a 10% apos 10 anos). Na progressiva, a aliquota segue a tabela do IR. Para horizontes longos, a regressiva e quase sempre vantajosa.',
 'Previdência', 'Baixo', 'Prof. Alexandre'),

-- ── CRIPTOMOEDAS ──
('Bitcoin: reserva de valor digital do seculo XXI',
 'Com oferta maxima de 21 milhoes de unidades, o Bitcoin e deflacionario por natureza. Seu halving a cada 4 anos reduz a emissao de novos BTC, historicamente impulsionando o preco. Indicado como reserva de valor de longo prazo com pequena alocacao da carteira.',
 'Criptomoedas', 'Alto', 'Prof. Alexandre'),

('DCA em cripto: reduzindo o risco da volatilidade',
 'A estrategia Dollar Cost Averaging consiste em comprar um valor fixo periodicamente, independente do preco. Em mercados volateis como cripto, o DCA reduz o impacto de comprar no pico e melhora o preco medio de aquisicao.',
 'Criptomoedas', 'Alto', 'Prof. Alexandre'),

('Staking e renda passiva em criptomoedas',
 'Algumas blockchains Proof of Stake permitem travar seus tokens para validar transacoes e receber recompensas. Ethereum, Solana e Cardano oferecem rendimentos anuais entre 3% e 7%. Atencao aos riscos de custoria e volatilidade do ativo.',
 'Criptomoedas', 'Alto', 'Prof. Alexandre'),

-- ── EXTERIOR ──
('ETFs americanos: S&P 500 para investidores brasileiros',
 'ETFs como IVVB11 permitem investir no indice S&P 500 pela bolsa brasileira sem precisar abrir conta no exterior. Oferecem exposicao a 500 maiores empresas dos EUA com diversificacao cambial e geografica.',
 'Exterior', 'Médio', 'Prof. Alexandre'),

('Como abrir conta em corretora internacional',
 'Plataformas como Avenue, Nomad e Interactive Brokers permitem ao brasileiro investir diretamente no exterior. E possivel comprar acoes, ETFs e BDRs. Atencao as regras de declaracao ao Banco Central e Receita Federal acima de USD 1.000.',
 'Exterior', 'Médio', 'Prof. Alexandre'),

('REITs: os FIIs americanos com maior historico',
 'Real Estate Investment Trusts sao obrigados por lei a distribuir 90% do lucro como dividendos. Com historico de mais de 50 anos, REITs como Realty Income (O), Simon Property e Prologis sao referencia em renda passiva em dolar.',
 'Exterior', 'Alto', 'Prof. Alexandre');
