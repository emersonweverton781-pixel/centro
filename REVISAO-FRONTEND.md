# Revisão do frontend — etapa 6

## Correções
- O formador escolhido mantém-se ao navegar entre turmas, presenças e avaliações, e ao trocar temporariamente de perfil.
- O menu lateral fecha depois de selecionar uma área no telemóvel. A área selecionada é identificada para tecnologias de apoio, e existe um atalho de teclado para saltar ao conteúdo.
- A agenda inicial usa os horários das turmas da sessão. As inscrições recentes são ordenadas pela data de receção e a contagem de cursos acompanha o catálogo ativo.
- Uma turma existente continua editável depois de o respetivo curso ser desativado. Novas turmas continuam a exigir um curso ativo.
- O portal do aluno distingue o total de aulas registadas da percentagem de presença.
- A análise de certificado apresenta “Sem registo” quando não existe frequência, sem acrescentar um sinal de percentagem.
- Ajustados resumos, botões, textos longos, cabeçalho e janelas em ecrãs estreitos. Mantida a identidade visual do centro.

## Verificação realizada
- 33 testes aprovados: regras de inscrição, secretaria, turmas, notas, presenças, pagamentos, estornos e certificados.
- Incluído um percurso integrado: confirmar inscrição → associar turma → registar presença e nota → cobrar e pagar → emitir certificado → estornar pagamento, preservando o histórico.
- Regressões para edição de turmas de cursos inativos e frequência abaixo do mínimo, mesmo quando arredondada.
- Verificação de tipos e compilação da aplicação; resposta HTTP da página inicial.
- Revisão de código e estilos. Não foram realizados testes visuais ou de interação no navegador, nem ensaios com câmara física nesta etapa.

## Roteiro para análise do centro
1. Na Secretaria, abrir uma inscrição pendente, conferir os dados e simular a confirmação.
2. Em Turmas, criar uma turma compatível com o curso e período e associar essa inscrição.
3. No Formador, selecionar o responsável, abrir a turma e guardar presenças e avaliações. Mudar de menu e verificar que o responsável continua selecionado.
4. No Financeiro, criar uma cobrança, lançar um pagamento parcial, conferir o saldo, abrir o PDF e experimentar o estorno com motivo.
5. Na Secretaria, preencher duração e horas do curso; em Certificados, analisar os critérios e confirmar a conclusão demonstrativa.
6. O perfil Aluno representa Pedro Neto (DEMO10004); para verificar o seu portal, usar a turma Informática · Setembro A e a respetiva inscrição.
7. Na pré-inscrição pública, verificar os quatro passos, mensagens de campos obrigatórios, anexos fictícios e revisão antes do envio simulado.

## Limites antes do backend
Os dados permanecem em memória e desaparecem ao recarregar. A pré-inscrição pública é uma simulação independente e não alimenta a secretaria. Não existe autenticação real, controlo de permissões no servidor, armazenamento de anexos, envio de notificações ou validação oficial de pagamentos e documentos. O QR apenas identifica uma demonstração. A gestão de utilizadores está reservada à etapa de autenticação.

Supabase, integrações e lançamento dependem da aprovação desta revisão. Não utilizar dados reais ainda.
