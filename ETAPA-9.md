# Etapa 9 — conclusão e certificados

## Funcionamento

O Administrador confirma os critérios em **Certificados → Definir critérios**. Os valores iniciais de 75% e 10/20 são exemplos e não autorizam emissões até essa confirmação. A Secretaria não pode alterar os critérios.

Na análise de conclusão, o servidor exige inscrição confirmada, turma associada ao curso com data de fim atingida, duração/carga horária preenchidas, presenças em todas as aulas registadas da turma e notas em todas as avaliações registadas. A frequência considera todas essas aulas; a média é a média aritmética das avaliações, sem arredondamento para decidir a aprovação. O responsável confirma explicitamente que a formação foi concluída.

A emissão regista a conclusão e cria um certificado com número sequencial, código QR aleatório e dados preservados. Repetir o pedido devolve o mesmo certificado. Alterações posteriores a notas, ficha ou critérios não modificam o documento emitido.

Administrador e Secretaria consultam os certificados. O aluno consulta apenas os seus em **Meus certificados**. O PDF contém matrícula, curso, período, duração, carga horária, frequência, média, critérios utilizados e espaço para assinatura/carimbo da Secretaria.

A verificação por QR distingue inscrição e certificado. A consulta pública não devolve nome, notas, identificação ou anexos. A privacidade do site foi preservada; o acesso externo à página continua dependente da autorização do proprietário.

## Dados e segurança

- Migração `202609130005_certificates.sql` aplicada; não reaplicar.
- Tabelas próprias de critérios e certificados com RLS e sem acesso direto pelos clientes.
- Critérios confirmados pelo Administrador; emissão apenas pela Secretaria/Administrador. Autorização também no servidor.
- Dados lidos e verificados no servidor durante a emissão, com bloqueios contra alterações concorrentes e chave única por inscrição.
- Histórico identifica o responsável pela confirmação dos critérios e pela emissão.
- Certificados de demonstração antigos não são convertidos automaticamente; os registos anteriores permanecem preservados na área financeira original.
- WhatsApp automático continua adiado a pedido do proprietário.

## Validação

- 41 testes locais passaram; verificação de tipos concluída.
- Testes transacionais no Supabase: critérios não confirmados, frequência/nota insuficientes, registos em falta, data de fim futura, confirmação manual, permissões, repetição de emissão, preservação do certificado, isolamento de alunos e privacidade do QR.
- PDFs fictícios com nomes normais e extensos: uma página, assinatura/carimbo visíveis e QR descodificado.
- Nenhum certificado de aluno real foi emitido nos testes; os dados de teste são revertidos na transação.
