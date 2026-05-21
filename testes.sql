/*Testes Práticos
1. Matricular aluno com e sem pré-requisitos
o Testar matrícula em disciplina que exige pré-requisito ainda não cursado
(deve falhar).
o Testar matrícula em disciplina sem pré-requisitos (deve ser concluída
com sucesso).*/

    
/*FALHA*/
select * from turmas where id_turma=92;
CALL sp_RegistrarMatricula(5, 92);

/*SUCESSO*/

select * from turmas where id_turma=109;
CALL sp_RegistrarMatricula(1, 109);


/*2. Simular falta de vaga e verificar rollback
o Tentar matricular um aluno quando a turma já está cheia (esperar
ROLLBACK e mensagem de erro).*/

/*FALHA*/
select * from turmas where id_turma=31;
CALL sp_RegistrarMatricula(47, 31);


/*3. Trancar matrícula e conferir decremento de vaga
o Trancar uma matrícula ativa e confirmar se o campo VagasOcupadas da
turma foi decrementado corretamente.*/

select * from matriculas where status ="Cursando" and id_aluno=28;
select * from turmas where id_turma=78;

call sp_TrancarMatricula(67,28);

/*4. Lançar notas e confirmar alteração automática de status
o Inserir notas e verificar se o status muda automaticamente para
'Aprovado' ou 'Reprovado'.*/

CALL sp_LancarNotas(5,6.2);

SELECT * FROM matriculas WHERE id_matricula = 5;

/*5. Gerar histórico de aluno e verificar consistência
o Executar sp_GerarHistoricoAluno e confirmar se apenas disciplinas
aprovadas foram registradas.*/

CALL sp_GerarHistoricoAluno(1);

SELECT * FROM historicoAluno h  WHERE h.id_aluno = 1;

/*6. Consultar vw_DesempenhoTurma e validar médias
o Confirmar cálculo da média de notas, aprovados e reprovados por turma.*/

SELECT * FROM vw_DesempenhoTurma;
select * from matriculas where id_turma=1;

/*7. Executar funções de retorno (OUT)
o fn_CalcularCoeficienteRendimento → verificar o coeficiente de
desempenho de um aluno.*/

select round(avg(nota_final),2) as coeficiente from matriculas where id_aluno=2 and upper(status)="APROVADO";

CALL fn_CalcularCoeficienteRendimento(2,@coeficiente);
SELECT @coeficiente;

/*o fn_ContarDisciplinasPendentes → confirmar número correto de
disciplinas restantes.*/


CALL fn_ContarDisciplinasPendentes(2,1,@disciplinas_pendentes);
SELECT @disciplinas_pendentes;

/*o fn_ListarDisciplinasAprovadas → retornar disciplinas concluídas
com sucesso.*/

CALL fn_ListarDisciplinasAprovadas(2);

/*o fn_TotalHorasConcluidas → validar soma da carga horária das
disciplinas aprovadas.*/
select m.*, d.cargaHoraria from matriculas m join turmas t on t.id_turma=m.id_aluno 
join disciplinas d on d.id_disciplina=t.id_disciplina where id_aluno=2 and m.status="Aprovado";

CALL fn_TotalHorasConcluidas(2,@horasTotais);
SELECT @horasTotais; 

/*8. Verificar logs de operações
o Após executar INSERT, UPDATE e DELETE em tabelas principais,
consultar vw_LogAuditoria e confirmar se os registros foram criados.*/
update alunos set email="teste@gmail.com" where id_aluno=7;
delete from alunos where id_aluno=50;
select * from vw_LogAuditoria;
/*9. Testar limite de disciplinas cursando (Trigger
trg_AtualizarStatusAutomaticamente)
o Tentar matricular aluno já com 6 disciplinas cursando — o sistema deve
bloquear a matrícula e registrar tentativa em LogsSistema.*/

/*Executar antes de validar*/
CALL sp_RegistrarMatricula(1, 111);
CALL sp_RegistrarMatricula(1, 110);
CALL sp_RegistrarMatricula(1, 92);

select count(*) as esta_cursando_em from matriculas where id_aluno=1 and upper(status)="CURSANDO";

CALL sp_RegistrarMatricula(1, 93);

/*10. Reabrir período de matrícula
o Executar sp_ReabrirPeriodoMatricula e verificar se
AbertoParaMatricula do semestre foi alterado para TRUE.*/

CALL sp_ReabrirPeriodoMatricula(3);
SELECT id_semestre, aberto_matricula FROM semestres WHERE id_semestre = 3;

/*11. Verificar integridade entre histórico e matrículas
o Após lançamentos de notas, confirmar que disciplinas aprovadas no
histórico correspondem às matrículas concluídas.*/



/*12. Testar exclusão e atualização em cascata (se aplicável)
o Excluir um curso e observar comportamento das FKs; verificar se há
restrições ou necessidade de ajustes.*/

/*13. Simular erro proposital para validar rollback
o Forçar uma falha dentro de sp_RegistrarMatricula (ex.: turma
inexistente) e confirmar que nenhuma alteração parcial ficou gravada.*/

select * from semestres where codigo_semestre=20251;