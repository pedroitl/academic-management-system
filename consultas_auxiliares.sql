/*Verifica alunos que não estão matriculados em uma turma*/
		SELECT a.id_aluno FROM alunos a
		WHERE NOT EXISTS ( SELECT 1 FROM matriculas m JOIN turmas t ON m.id_turma = t.id_turma
			WHERE m.id_aluno = a.id_aluno AND t.id_turma = 90) order by a.id_aluno;
			
		/*Verifica turmas que estão com as vagas preenchidas*/
		SELECT t.id_turma, t.id_disciplina, t.max_vagas, t.vagas_ocupadas, s.codigo_semestre
		FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
		JOIN semestres s ON t.id_semestre = s.id_semestre
		WHERE t.vagas_ocupadas >= t.max_vagas;
        
        /*Verificar as turmas que um aluno y faz parte*/
        SELECT a.id_aluno, t.id_turma,  d.id_disciplina, m.status
		FROM matriculas m JOIN alunos a ON m.id_aluno = a.id_aluno
		JOIN turmas t ON m.id_turma = t.id_turma
		JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
		WHERE a.id_aluno = 1;	

	SELECT d.id_disciplina FROM cursos c JOIN curriculos cr ON cr.id_curso = c.id_curso
	JOIN disciplinas_curriculo dc ON dc.id_curriculo = cr.id_curriculo
	JOIN disciplinas d ON d.id_disciplina = dc.id_disciplina WHERE c.id_curso = 1;

	SELECT id_aluno FROM alunos WHERE id_curso = 1;
	select * from matriculas where id_aluno=1;


	/*Verificar se disciplina x que possue pre-requisitos e qual turmas tem disponiveis e o semestre está aberto*/
	SELECT t.id_turma, d1.id_disciplina AS disciplina,d2.id_disciplina AS pre_requisito, t.vagas_ocupadas
	FROM pre_requisitos p JOIN disciplinas d1 ON p.id_disciplina_principal = d1.id_disciplina
	JOIN disciplinas d2 ON p.id_disciplina_requisito = d2.id_disciplina
	JOIN turmas t ON t.id_disciplina = d1.id_disciplina 
    JOIN semestres s ON s.id_semestre=t.id_semestre ;
    
    SELECT 
    d.id_disciplina,
    d.nomeDisciplina,
    t.id_turma

FROM disciplinas d

LEFT JOIN turmas t
    ON t.id_disciplina = d.id_disciplina

;

        
	/*Verificar se uma disciplina x está vinculada a um aluno y*/

	SELECT a.id_aluno, t.id_turma,  d.id_disciplina, m.status
	FROM matriculas m JOIN alunos a ON m.id_aluno = a.id_aluno
	JOIN turmas t ON m.id_turma = t.id_turma
	JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
	WHERE a.id_aluno = 1 and t.id_disciplina=8;
    
    /*Verificar os alunos que não possuem matriculas em nenhuma turma*/
	SELECT a.id_aluno,a.id_curso FROM alunos a WHERE a.id_curso = 1
	AND NOT EXISTS (SELECT 1 FROM matriculas m WHERE m.id_aluno = a.id_aluno);   
    
    SELECT t.id_turma, t.id_disciplina, s.codigo_semestre
FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
JOIN semestres s ON t.id_semestre = s.id_semestre
WHERE s.aberto_matricula = 'N';

SELECT t.id_turma, t.id_disciplina, s.codigo_semestre
FROM turmas t JOIN disciplinas d ON t.id_disciplina = d.id_disciplina
JOIN semestres s ON t.id_semestre = s.id_semestre
WHERE s.aberto_matricula = 'S';

select * from semestres;

select count(DISTINCT d.id_disciplina) as disciplinas_pendentes from cursos c join curriculos cr 
on cr.id_curso= c.id_curso join disciplinas_curriculo dc on dc.id_curriculo=cr.id_curriculo
join disciplinas d on d.id_disciplina=dc.id_disciplina left join vw_BoletimAluno v  
on v.id_disciplina = d.id_disciplina and v.id_aluno = 2 where c.id_curso = 1
and v.id_aluno is null;

SELECT id_aluno,COUNT(*) AS quantidade_disciplinas_cursando
FROM matriculas WHERE UPPER(status) = 'CURSANDO' GROUP BY id_aluno;

select m.*, t.id_disciplina, d.nomeDisciplina from matriculas m join turmas t on m.id_turma=t.id_turma join disciplinas d on d.id_disciplina=t.id_disciplina where id_aluno=2;