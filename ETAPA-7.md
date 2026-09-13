# Etapa 7 — Supabase

## Implementado

- Autenticação Supabase com acesso por email autorizado; sem seletor de perfis.
- Administrador inicial reservado a `waldob.manuel2007@gmail.com`.
- Gestão de acessos, suspensão, associação de alunos a fichas e de formadores a turmas.
- Links individuais de ativação/recuperação, gerados pelo Administrador. A geração não envia emails.
- Persistência das áreas de secretaria, formação e financeiro. O servidor verifica o perfil em cada operação.
- Controlo de versão ao guardar: alterações concorrentes são rejeitadas em vez de substituir os dados de outro utilizador.
- Pré-inscrição pública e inscrição no atendimento com três anexos obrigatórios, até 5 MB cada. Validação de formato também no servidor.
- Armazenamento privado dos anexos; visualização temporária apenas por Administrador/Secretaria.
- Inscrições entram pendentes; confirmação manual verifica os documentos guardados e atribui matrícula sequencial no servidor.
- Ficha existente preservada quando chega um novo pedido com o mesmo documento; dados enviados ficam disponíveis na análise.
- Histórico de operações, pagamentos preservados com estorno e certificados existentes imutáveis.
- Apenas o catálogo fornecido foi carregado. Alunos, inscrições e pagamentos de demonstração não foram importados.

## Organização técnica

`centro_state` guarda documentos JSON por área (`office`, `academic`, `finance`), cada um com versão. As tabelas têm RLS ativo e não oferecem políticas de leitura/escrita direta aos clientes. As funções RPC com `search_path` fixo verificam a identidade, confirmação e autorização no servidor. A leitura devolve apenas a projeção permitida para cada perfil. `centro_access`, `centro_audit` e o armazenamento privado completam a integração.

As migrações SQL foram aplicadas pela Management API, na ordem indicada nos nomes. Não reaplicar ficheiros já executados. O catálogo é carregado separadamente, apenas se estiver vazio. As Edge Functions usam credenciais do ambiente Supabase; nenhuma chave privilegiada deve ser incluída no navegador ou no Git.

Publicar `centro-inscricao` e `centro-acesso` com verificação JWT do gateway desativada. A primeira aceita candidaturas sem conta; a segunda verifica a sessão e o perfil de Administrador internamente antes de gerar qualquer link.

## Validação

- 37 testes das regras existentes passaram.
- Testes SQL transacionais: privilégios públicos, isolamento de aluno/formador, bloqueio de escrita pelo aluno, suspensão e conflito de versões.
- Percurso real na API: login, rejeição sem comprovativo, envio dos três ficheiros, gravação pendente, aprovação, matrícula e acesso do aluno. Conta, inscrição e anexos temporários removidos após verificação.
- Verificação TypeScript e compilação de produção. Sem inspeção visual de navegador nesta etapa.

## Limites atuais

- Sites permanece privado, preservando a audiência anterior. A abertura a candidatos externos depende da definição de acesso do site.
- SMTP não configurado: ativação/recuperação por link entregue pelo Administrador; emails automáticos não estão operacionais.
- PDFs e verificação pública de certificados continuam demonstrativos e sem validade oficial. Validação oficial e notificações pertencem às integrações seguintes.
- Os critérios iniciais de certificação (75% e 10/20) são valores de configuração a confirmar pelo centro antes de emitir documentos oficiais.
