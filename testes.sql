/*Testes Práticos
1. Matricular aluno com e sem pré-requisitos
o Testar matrícula em disciplina que exige pré-requisito ainda não cursado
(deve falhar).
o Testar matrícula em disciplina sem pré-requisitos (deve ser concluída
com sucesso).*/

/*Verifica disciplina que não estão matriculados em uma disciplina*/
SELECT t.id_turma, d1.id_disciplina AS disciplina,d2.id_disciplina AS pre_requisito
FROM pre_requisitos p JOIN disciplinas d1 ON p.id_disciplina_principal = d1.id_disciplina
JOIN disciplinas d2 ON p.id_disciplina_requisito = d2.id_disciplina
JOIN turmas t ON t.id_disciplina = d1.id_disciplina;

CALL sp_RegistrarMatricula(2, 90);




/*2. Simular falta de vaga e verificar rollback
o Tentar matricular um aluno quando a turma já está cheia (esperar
ROLLBACK e mensagem de erro).*/

/*Verifica alunos que não estão matriculados em uma turma*/
SELECT a.id_aluno FROM alunos a
WHERE NOT EXISTS ( SELECT 1 FROM matriculas m JOIN turmas t ON m.id_turma = t.id_turma
    WHERE m.id_aluno = a.id_aluno AND t.id_turma = 40) order by a.id_aluno;
    
/*Verifica turmas que estão com as vagas preenchidas*/
SELECT t.id_turma, t.id_disciplina, t.max_vagas, t.vagas_ocupadas, s.codigo_semestre
FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
JOIN semestres s ON t.id_semestre = s.id_semestre
WHERE t.vagas_ocupadas >= t.max_vagas;

CALL sp_RegistrarMatricula(5, 1);

select * from turmas where id_turma=1;

select * from matriculas where id_aluno=5;

call sp_TrancarMatricula(51,5);

select * from usuarios;
select * from logsSistema;
/*3. Trancar matrícula e conferir decremento de vaga
o Trancar uma matrícula ativa e confirmar se o campo VagasOcupadas da
turma foi decrementado corretamente.*/


/*4. Lançar notas e confirmar alteração automática de status
o Inserir notas e verificar se o status muda automaticamente para
'Aprovado' ou 'Reprovado'.*/

/*5. Gerar histórico de aluno e verificar consistência
o Executar sp_GerarHistoricoAluno e confirmar se apenas disciplinas
aprovadas foram registradas.*/

/*6. Consultar vw_DesempenhoTurma e validar médias
o Confirmar cálculo da média de notas, aprovados e reprovados por turma.*/

/*7. Executar funções de retorno (OUT)
o fn_CalcularCoeficienteRendimento → verificar o coeficiente de
desempenho de um aluno.
o fn_ContarDisciplinasPendentes → confirmar número correto de
disciplinas restantes.
o fn_ListarDisciplinasAprovadas → retornar disciplinas concluídas
com sucesso.
o fn_TotalHorasConcluidas → validar soma da carga horária das
disciplinas aprovadas.*/

/*8. Verificar logs de operações
o Após executar INSERT, UPDATE e DELETE em tabelas principais,
consultar vw_LogAuditoria e confirmar se os registros foram criados.*/

/*9. Testar limite de disciplinas cursando (Trigger
trg_AtualizarStatusAutomaticamente)
o Tentar matricular aluno já com 6 disciplinas cursando — o sistema deve
bloquear a matrícula e registrar tentativa em LogsSistema.*/

/*10. Reabrir período de matrícula
o Executar sp_ReabrirPeriodoMatricula e verificar se
AbertoParaMatricula do semestre foi alterado para TRUE.*/

/*11. Verificar integridade entre histórico e matrículas
o Após lançamentos de notas, confirmar que disciplinas aprovadas no
histórico correspondem às matrículas concluídas.*/

/*12. Testar exclusão e atualização em cascata (se aplicável)
o Excluir um curso e observar comportamento das FKs; verificar se há
restrições ou necessidade de ajustes.*/

/*13. Simular erro proposital para validar rollback
o Forçar uma falha dentro de sp_RegistrarMatricula (ex.: turma
inexistente) e confirmar que nenhuma alteração parcial ficou gravada.*/

SELECT t.id_turma, t.id_disciplina, s.codigo_semestre
FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
JOIN semestres s ON t.id_semestre = s.id_semestre
WHERE s.aberto_matricula = 'N';

SELECT t.id_turma, t.id_disciplina, s.codigo_semestre
FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
JOIN semestres s ON t.id_semestre = s.id_semestre
WHERE s.aberto_matricula = 'S';