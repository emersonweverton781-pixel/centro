# BEZA INOVAÇÕES — Centro de Formação

Etapas 1 a 3: identidade visual, cinco painéis demonstrativos, pré-inscrição pública em `/inscricao` e gestão da secretaria no painel inicial.

## Secretaria, alunos e cursos (etapa 3)
- Nos perfis Administrador e Secretaria, abrir Inscrições, Alunos ou Cursos no menu.
- Fila por ordem de receção, pesquisa por nome/BI, filtros por estado, curso, período e datas, com paginação.
- Análise dos dados, documentos ilustrativos, associação de curso e confirmação ou rejeição com motivo. Matrícula de demonstração apenas ao confirmar; histórico com perfil e data.
- Ficha única por BI/Passaporte, edição e histórico de várias inscrições. Exemplo: DEMO10001 tem dois cursos.
- Criar, editar, ativar e desativar cursos, preservando as inscrições existentes. Valores originais por definir.
- Dados mantidos na memória do painel, incluindo ao alternar módulos. Recarregar ou sair repõe os exemplos. A pré-inscrição pública ainda é uma simulação independente; documentos e alterações do catálogo não são partilhados entre páginas.
- Não existe autenticação efetiva, persistência, envio WhatsApp ou documento oficial. PDF/QR é previsto na etapa 5; integrações no backend depois de concluído o front-end.
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
4. Gestão académica; 5. Financeiro e documentos; 6. Revisão do front-end; 7–9. Supabase, integrações e lançamento.

Repositório: https://github.com/emersonweverton781-pixel/centro
