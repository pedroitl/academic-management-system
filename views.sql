/*vw_BoletimAluno
Exibe o histórico completo de um aluno (nome, semestre, disciplina, professor,
nota e status).*/

create view vw_BoletimAluno as 
select a.nome,s.codigo_semestre,d.nomeDisciplina, p.nome as "nome_professor", h.notaFinal, h.status
from historicoaluno as h inner join alunos a on h.id_aluno = a.id_aluno
inner join disciplinas d on h.id_disciplina = d.id_disciplina
inner join matriculas m on h.id_aluno=m.id_aluno
inner join turmas t on m.id_turma=t.id_turma and  t.id_disciplina = h.id_disciplina
inner join semestres as s on s.id_semestre = t.id_semestre
inner join professores p on p.id_professor = t.id_professor ;

/*vw_TurmasDisponiveis
Lista as turmas abertas no semestre atual (AbertoParaMatricula = TRUE) que
ainda possuem vagas.*/

create view vw_TurmasDisponiveis as
select t.id_turma,s.codigo_semestre,t.max_vagas,t.vagas_ocupadas, (t.max_vagas - t.vagas_ocupadas) as "vagas_restantes"
from turmas as t
inner join semestres as s on t.id_semestre = s.id_semestre
where s.aberto_matricula = "S" and t.vagas_ocupadas < t.max_vagas and s.codigo_semestre like CONCAT(YEAR(CURDATE()), '%');


/*vw_DesempenhoTurma
Mostra o nome da disciplina, professor, média das notas, número de aprovados e
reprovados por turma.*/

create view vw_DesempenhoTurma as
select d.nomedisciplina,p.nome as "professor_disciplina",t.id_turma,avg(h.notaFinal) as "medias_notas",
SUM(CASE WHEN h.status = 'Aprovado' THEN 1 ELSE 0 END) AS aprovados,
SUM(CASE WHEN h.status = 'Reprovado' THEN 1 ELSE 0 END) AS reprovados
from turmas as t inner join disciplinas as d on t.id_disciplina = d.id_disciplina
inner join professores as p on t.id_professor = p.id_professor
inner join matriculas as m on m.id_turma = t.id_turma
inner join historicoaluno as h on h.id_aluno = m.id_aluno and h.id_disciplina = d.id_disciplina
group by t.id_turma,d.nomedisciplina,p.nome;


/*vw_LogAuditoria
Exibe as 20 operações mais recentes da tabela LogsSistema.*/

create view vw_LogAuditoria as
select * 
from logsSistema
order by dataHora desc
limit 20;
