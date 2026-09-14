# Etapa 10 — financeiro e comprovativos

## Entregue

- Guardar um pagamento cria, na mesma transação, um comprovativo interno com número único e QR. A migração inclui pagamentos anteriores sem os alterar.
- O PDF preserva os dados da emissão: aluno, curso, matrícula, cobrança, valor, data, método e referência do movimento.
- Administrador e Financeiro podem consultar o PDF no histórico de pagamentos e no novo **Extrato por aluno**.
- O extrato reúne todos os cursos do aluno, cobranças, pagamentos parciais, estornos, total recebido e saldo em falta. Não usa os filtros de data/curso da listagem geral.
- Estornar exige motivo de 5 a 500 caracteres; responsável e data são atribuídos pelo servidor. O pagamento original é preservado e o QR passa a indicar **Estornado**.
- O PDF obtido depois do estorno fica marcado como histórico. Uma cópia anterior conserva a apresentação original; o seu QR consulta sempre o estado atual.
- A consulta pública do pagamento mostra apenas referência, emissão e estado. Não revela aluno, valor, método, dados bancários ou motivo do estorno.
- Validações no servidor impedem referências/identificadores duplicados, cobranças repetidas, valores fracionários em cêntimos, datas futuras de pagamento e alterações às cobranças originais. A validação existente impede pagamentos acima do saldo.
- Os relatórios descontam estornos dos recebimentos. A exportação passou a usar o nome de relatório financeiro, sem a indicação de demonstração.

## Validação

- 43 testes locais passaram, incluindo agregação de vários cursos do mesmo aluno, isolamento de outros alunos, pagamentos parciais e estornos.
- Testes transacionais no Supabase verificaram gravação de pagamentos, limites, duplicados, preservação de comprovativos, motivo de estorno, identificação do responsável, estado do QR, saldo e permissões.
- Regressões dos comprovativos de inscrição e certificados passaram.
- PDFs de pagamento ativo e estornado renderizados, inspecionados e com QR descodificado. Nenhum pagamento real foi registado durante os testes.

Migração aplicada: `202609140006_payment_documents.sql`; não reaplicar.

O sistema regista pagamentos informados pelo centro; não efetua transferências bancárias. O WhatsApp automático continua adiado e a audiência privada do site foi preservada.
