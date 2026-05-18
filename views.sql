/*vw_BoletimAluno
Exibe o histórico completo de um aluno (nome, semestre, disciplina, professor,
nota e status).*/

create view vw_BoletimAluno as
select a.nome,s.codigo_semestre,d.nomeDisciplina, p.nome as "nome_professor", h.notaFinal, h.status
from alunos as a
inner join semestres as s on s.id_semestre = a.id_aluno
inner join disciplinas as d on d.id_disciplina = a.id_aluno
inner join professores p on p.id_professor = a.id_aluno
inner join historicoaluno as h on h.id_historico = a.id_aluno;

select * from vw_BoletimAluno;

/*vw_TurmasDisponiveis
Lista as turmas abertas no semestre atual (AbertoParaMatricula = TRUE) que
ainda possuem vagas.*/

create view vw_TurmasDisponiveis as
select s.aberto_matricula,t.max_vagas,t.vagas_ocupadas,t.id_turma , (t.max_vagas - t.vagas_ocupadas) as "vagas_restantes"
from turmas as t
inner join semestres as s on t.id_semestre = s.id_semestre
where s.aberto_matricula = "S" and t.vagas_ocupadas < t.max_vagas;

/*vw_DesempenhoTurma
Mostra o nome da disciplina, professor, média das notas, número de aprovados e
reprovados por turma.*/

create view vw_DesempenhoTurma as
select d.nomedisciplina,p.nome as "professor_disciplina",t.id_turma,avg(m.nota_final) as "medias_notas",count(h.status) as "aprovados_reprovados"
from turmas as t
inner join disciplinas as d on t.id_disciplina = d.id_disciplina
inner join professores as p on t.id_professor = p.id_professor
inner join matriculas as m on m.id_turma = t.id_turma
inner join alunos as a on m.id_aluno = a.id_aluno
left join historicoaluno as h on h.id_aluno = a.id_aluno and h.id_disciplina = d.id_disciplina
group by d.nomedisciplina,p.nome,t.id_turma;


/*vw_LogAuditoria
Exibe as 20 operações mais recentes da tabela LogsSistema.*/

create view vw_LogAuditoria as
select * 
from logssistema
order by dataHora desc
limit 20;
select * from VIEW_logs_recentes;
