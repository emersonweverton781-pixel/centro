# Etapa 8 — comprovativos e comunicação

## Entregue

- A confirmação manual cria um registo de comprovativo no Supabase, na mesma transação da matrícula. Inscrições já confirmadas são incluídas pela migração.
- O registo conserva nome, curso, matrícula, período, início pretendido e data da confirmação. Uma alteração posterior da ficha não muda o documento emitido.
- Administração e Secretaria consultam e descarregam o PDF na inscrição ou no menu Documentos. O PDF inclui espaço para assinatura e carimbo físicos, contactos e QR.
- A consulta `/verificar?ref=<token>` valida um código aleatório no Supabase. Não devolve nome, telefone, identificação, anexos ou URL de download. Uma matrícula sequencial não permite enumerar documentos.
- O acesso ao comprovativo completo exige autorização. A função também permite ao aluno consultar apenas o próprio documento.
- Confirmação e rejeição têm mensagem WhatsApp preparada para envio manual. Abrir o WhatsApp não é apresentado como mensagem enviada ou entregue.
- Corrigidos os botões de submissão dos formulários de cobrança, pagamento e critérios, que usavam o tipo de botão errado.

## Limites e próximo passo

- O WhatsApp automático ainda depende da configuração de uma conta Business/API e dos modelos de mensagem aprovados. Nenhuma mensagem foi enviada durante os testes.
- A privacidade atual do site foi preservada. A página de verificação só fica disponível a visitantes externos quando o proprietário autorizar o acesso externo do site.
- Os PDFs de pagamentos e certificados continuam como modelos; esta entrega converte apenas o comprovativo de inscrição.
- O PDF é gerado a partir do registo preservado no servidor. O QR confirma os metadados da matrícula, não uma assinatura digital do ficheiro.

## Validação

- 40 testes locais passaram; verificação de tipos e compilação concluídas.
- Teste transacional no Supabase: emissão após confirmação, dados preservados, acesso da Secretaria, isolamento de alunos, bloqueio de Financeiro/conta suspensa e privacidade da consulta pública. Todos os dados de teste são revertidos.
- PDFs com dados fictícios normais e extensos renderizados para inspeção de leitura e paginação.

Migração aplicada: `202609130004_documents.sql`. Não reaplicar migrações existentes.
