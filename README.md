# Estado atual: etapa 7

Supabase integrado para autenticação, permissões, inscrições com anexos e persistência. Consulte [ETAPA-7.md](ETAPA-7.md) para funcionamento, validação e limites. As secções seguintes registam a evolução histórica do frontend e descrevem estados anteriores.

# BEZA INOVAÇÕES — Centro de Formação

Etapas 1 a 5: identidade visual, painéis demonstrativos, pré-inscrição pública em `/inscricao`, secretaria, gestão académica, financeiro e documentos.

## Financeiro, documentos e relatórios (etapa 5)
- Administrador/Financeiro: cobranças de inscrição ou propina por mês; pagamentos parciais; saldo, atraso, histórico e estorno com motivo, sem apagar o movimento original. Montantes calculados em cêntimos inteiros.
- Administrador/Secretaria: menu Documentos com PDF das inscrições confirmadas; menu Certificados com análise de frequência/média, duração/carga horária do curso e confirmação manual de conclusão.
- Administrador configura os critérios de emissão. Os valores iniciais de 75% e 10/20 são apenas exemplos. Os certificados preservam os dados e critérios da emissão, mesmo se as notas mudarem depois.
- O aluno fictício Pedro Neto pode consultar o certificado emitido para a sua inscrição em Meus certificados.
- Relatórios por curso/período com datas, pendentes/rejeitadas/confirmadas, taxa, recebimentos e saldos, exportáveis em CSV. Datas filtram receção das inscrições e pagamentos; saldo atual inclui cobranças de todas as datas para os filtros de aluno/curso/período.
- PDFs gerados localmente no navegador (pdf-lib e qrcode), com logótipo e identificação DEMONSTRAÇÃO — SEM VALIDADE OFICIAL. Pré-visualização, download e impressão pelo leitor de PDF.
- O QR contém somente referência demonstrativa e aponta para `/verificar?ref=...`. A página não consulta a base de dados nem autentica documentos reais.
- As cobranças iniciais são valores fictícios, sem relação com preços oficiais. Nada é enviado ao Supabase, bancos ou WhatsApp.
- Validação: 30 testes das regras passaram; TypeScript, compilação estática, revisão visual de três modelos PDF e descodificação do QR da inscrição; navegação WebMCP válida/inválida. Sem QA visual da aplicação no navegador.

## Gestão académica (etapa 4)
- Administrador/Secretaria: menu Turmas, criação e edição de turmas, curso, período, formador, datas, dias da semana, horas e sala. Deteta sobreposições de sala ou formador.
- Associação manual de inscrições confirmadas do mesmo curso/período, sem duplicação. Turmas com alunos preservam curso e calendário nesta demonstração.
- Formador: seleção explícita entre dois perfis fictícios; cada um vê apenas as turmas atribuídas. Presenças por aula/data e avaliações na escala 0–20. Datas futuras e fora do período da turma são bloqueadas.
- Aluno: consulta do exemplo Pedro Neto (DEMO10004), com horário, frequência, notas e média simples informativa. Os registos guardados pelo formador refletem-se neste portal ao trocar de perfil.
- Presenças exigem uma marca por aluno; editar uma data substitui o registo. Notas em branco ficam por lançar e não contam para a média.
- Todos os dados continuam apenas na memória do painel. Sem autenticação efetiva, automatização de matrícula ou alterações no Supabase. Avaliações, presenças e calendário iniciais são exemplos.
- Verificação: 23 testes passaram e TypeScript sem erros. Navegação WebMCP para Turmas testada com entrada válida e inválida. Sem QA visual de navegador nesta etapa.

## Secretaria, alunos e cursos (etapa 3)
- Nos perfis Administrador e Secretaria, abrir Inscrições, Alunos ou Cursos no menu.
- Fila por ordem de receção, pesquisa por nome/BI, filtros por estado, curso, período e datas, com paginação.
- Análise dos dados, documentos ilustrativos, associação de curso e confirmação ou rejeição com motivo. Matrícula de demonstração apenas ao confirmar; histórico com perfil e data.
- Ficha única por BI/Passaporte, edição e histórico de várias inscrições. Exemplo: DEMO10001 tem dois cursos.
- Criar, editar, ativar e desativar cursos, preservando as inscrições existentes. Valores originais por definir.
- Dados mantidos na memória do painel, incluindo ao alternar módulos. Recarregar ou sair repõe os exemplos. A pré-inscrição pública ainda é uma simulação independente; documentos e alterações do catálogo não são partilhados entre páginas.
- Não existe autenticação efetiva, persistência, envio WhatsApp ou documento oficial. PDF/QR demonstrativo na etapa 5; integrações no backend depois de concluído o front-end.
- Validação: 16 testes das regras de inscrição e secretaria, TypeScript e compilação estática. WebMCP de navegação verificado com entrada válida e inválida. Sem testes visuais de navegador nesta etapa.

## Pré-inscrição
- Quatro passos: dados pessoais, curso e período, documentos, revisão.
- Catálogo de 25 cursos e pedido de outro curso; valores e durações por definir.
- Fotografia por ficheiro ou câmara; BI/passaporte e comprovativo de pagamento obrigatórios.
- JPG/PNG e PDF (documentos), até 5 MB por ficheiro, com verificação do formato.
- Revisão editável e protocolo temporário de demonstração. Sem matrícula oficial.
- Dados e documentos ficam apenas na memória da página; sair ou atualizar descarta-os. Não há envio nem armazenamento no Supabase.
- Usar somente dados e documentos fictícios nesta demonstração.

## Validação da etapa 2
Verificação TypeScript, compilação estática e testes das regras de datas, campos e anexos. Navegação WebMCP verificada com passo válido, passo inválido e avanço bloqueado por dados em falta. Câmara e aparência em dispositivos reais ficam disponíveis para revisão do utilizador.

## Estado
- Dados inteiramente fictícios; nenhuma autenticação, operação financeira ou envio de email real.
- Menus de módulos futuros apresentam a etapa prevista.
- Supabase será integrado somente após aprovação de todo o front-end.
- Contactos e identidade visual fornecidos pelo centro.

## Desenvolvimento
Node.js >=22.13 e pnpm. Instalar com `pnpm install`, iniciar com `pnpm dev`, compilar com `pnpm build`.

## Etapas seguintes (dependem de aprovação)
6. Revisão do front-end; 7–9. Supabase, integrações e lançamento.

Repositório: https://github.com/emersonweverton781-pixel/centro

## Revisão do frontend (etapa 6)
Formador preservado entre menus; navegação móvel ajustada; agenda e catálogo coerentes com a sessão; edição de turmas preservada após desativar curso; resumos e textos adaptados a ecrãs estreitos. 33 testes aprovados, incluindo o percurso integrado entre secretaria, formação, financeiro e certificados. Ver detalhes e roteiro em REVISAO-FRONTEND.md. Sem testes visuais de navegador nesta etapa. Backend continua pendente de aprovação.

## Inscrições no atendimento
Administrador e Secretaria dispõem de Nova inscrição em Inscrições. O formulário permite novo aluno ou ficha existente, curso ativo, período, início pretendido e três anexos fictícios. Os anexos são verificados (formato, tamanho e leitura de imagem) e ficam disponíveis na análise enquanto a sessão durar. A inscrição entra pendente, preserva a ficha existente e impede duplicações de BI e de inscrição ativa no mesmo curso/período. 37 testes aprovados. Ainda sem persistência nem Supabase.
