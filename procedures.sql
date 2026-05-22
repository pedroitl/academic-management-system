/*Stored Procedures (Procedimentos Armazenados)

sp_RegistrarMatricula (Transacional)
>> o Parâmetros: p_ID_Aluno, p_ID_Turma
o Regras:
>>> Verificar se o semestre está aberto para matrícula.  v
>>> Verificar se a turma tem vagas.    v
>>> Verificar pré-requisitos.     
>>> Verificar se o aluno já está matriculado na mesma disciplina.
>>> Inserir a matrícula com status 'Cursando' e confirmar transação.*/

DELIMITER $$
CREATE PROCEDURE sp_RegistrarMatricula (
    IN p_ID_Aluno INT,
    IN p_ID_Turma INT
)
BEGIN
    DECLARE v_id_semestre INT;
    DECLARE v_semestre_aberto CHAR(1);
    DECLARE v_max_vagas INT;
    DECLARE v_vagas_ocupadas INT;
    DECLARE v_id_disciplina INT;
    DECLARE v_qtd_requisitos_total INT;
    DECLARE v_qtd_requisitos_ok INT;
    DECLARE v_qtd_matriculas_mesma_disciplina INT;
    
    proc_end: BEGIN
    
    START TRANSACTION;

    SELECT t.id_semestre,
           t.id_disciplina,
           t.max_vagas,
           t.vagas_ocupadas
      INTO v_id_semestre,
           v_id_disciplina,
           v_max_vagas,
           v_vagas_ocupadas
      FROM turmas t
     WHERE t.id_turma = p_ID_Turma;

    SELECT s.aberto_matricula
      INTO v_semestre_aberto
      FROM semestres s
     WHERE s.id_semestre = v_id_semestre;

    IF TRIM(UPPER(v_semestre_aberto)) <> 'S' THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Semestre fechado';
	END IF;

    IF IFNULL(v_vagas_ocupadas,0) >= IFNULL(v_max_vagas,0) THEN
        SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Turma sem vagas';
	END IF;

    SELECT COUNT(*)
      INTO v_qtd_requisitos_total
      FROM pre_requisitos pr
     WHERE pr.id_disciplina_principal = v_id_disciplina;

    IF v_qtd_requisitos_total > 0 THEN
		
        SELECT COUNT(*)
			INTO v_qtd_requisitos_ok
			FROM turmas t 
            join matriculas m on t.id_turma=m.id_turma
            join disciplinas d on t.id_disciplina=d.id_disciplina
			JOIN pre_requisitos pr on d.id_disciplina = pr.id_disciplina_requisito
			AND m.id_aluno = p_ID_Aluno
			AND UPPER(m.status) = 'APROVADO'
         WHERE pr.id_disciplina_principal = v_id_disciplina;

        IF v_qtd_requisitos_ok < v_qtd_requisitos_total THEN
			
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Aluno não cursou as disciplinas pré-requisitos';
        END IF;
    END IF;
    
    SELECT COUNT(*)
      INTO v_qtd_matriculas_mesma_disciplina
      FROM matriculas m
      JOIN turmas t2
        ON t2.id_turma = m.id_turma
     WHERE m.id_aluno = p_ID_Aluno
       AND t2.id_disciplina = v_id_disciplina
       AND UPPER(m.status) = 'CURSANDO';

    IF v_qtd_matriculas_mesma_disciplina > 0 THEN
        SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Aluno já está cursando nessa turma.';
    END IF;

    INSERT INTO matriculas (
        id_turma,
        id_aluno,
        status,
        nota_final
    ) VALUES (
        p_ID_Turma,
        p_ID_Aluno,
        'Cursando',
        0.0
    );
    
/* esse ta duplicando as vagas pq na trigger tbm foi pedido que tivesse
um incremento de vagas, optamos por deixar nas trigger para evitar a duplicação.
    UPDATE turmas
       SET vagas_ocupadas = vagas_ocupadas + 1
     WHERE id_turma = p_ID_Turma;
*/
    COMMIT;
    END proc_end;
END $$
DELIMITER ;


/*sp_LancarNotas
>> o Parâmetros: p_ID_Matricula, p_NotaFinal
>> o Atualiza nota e define status: 'Aprovado' se nota ≥ 7, senão 'Reprovado'.*/

DELIMITER $$

CREATE PROCEDURE sp_LancarNotas(IN p_ID_Matricula int, IN p_NotaFinal decimal(4,2))
BEGIN
	DECLARE v_quantidade_matricula INT;
    DECLARE v_status varchar(20);
		select count(*) into v_quantidade_matricula
        from matriculas where id_matricula = p_ID_Matricula;
        if v_quantidade_matricula = 0 then
			signal  sqlstate '45000'
			set message_text = 'Nao ha matricula cadastrada com esse ID';
		else
			if p_NotaFinal >= 7 then
				set v_status = 'Aprovado';
            else 
				set v_status = 'Reprovado';
			end if;
        update matriculas
        set nota_final =  p_NotaFinal ,
			status = v_status
		where id_matricula = p_ID_Matricula;
        end if;
END $$
DELIMITER ;


/*sp_TrancarMatricula
>> o Parâmetros: p_ID_Matricula, p_Usuario
>> o Altera status para 'Trancado', decrementa vaga e registra log.*/

DELIMITER $$
create procedure sp_TrancarMatricula(in p_ID_Matricula int , in p_ID_Usuario int )
begin
	DECLARE v_quantidade_matricula INT;
    DECLARE v_id_turma int;
    declare usuario varchar(250);
    
		select count(*) into v_quantidade_matricula
        from matriculas where id_matricula = p_ID_Matricula;
        
        if v_quantidade_matricula > 0 then
            update matriculas
            set status = 'Trancado'
            where id_matricula = p_ID_Matricula;
            
            select id_turma
            into v_id_turma
            from matriculas
            where id_matricula = p_ID_Matricula; 
            
            update turmas
            set vagas_ocupadas = vagas_ocupadas - 1
            where id_turma = v_id_turma;
            
            select nome into usuario from alunos where id_aluno=p_ID_Usuario;
            insert into logssistema(usuario,acao,tabelaAfetada,dataHora)
            values(usuario,"trancar_matricula","matriculas",now());
        end if;
end $$

DELIMITER ;

/*sp_GerarHistoricoAluno
>> o Parâmetro: p_ID_Aluno
>> o Inserir no histórico todas as disciplinas aprovadas do aluno.*/
select count(*)
	from matriculas where id_aluno = 1;
DELIMITER $$
create procedure sp_GerarHistoricoAluno(in p_ID_Aluno int)
begin
    DECLARE v_quantidade_alunos int;
    DECLARE v_quantidade_alunos_matriculas int;
    
    select count(*) into v_quantidade_alunos_matriculas
	from matriculas where id_aluno = p_ID_Aluno;
    
    select count(*) into v_quantidade_alunos
	from historicoaluno where id_aluno = p_ID_Aluno;
    
    if v_quantidade_alunos < v_quantidade_alunos_matriculas then
		insert into historicoaluno(id_aluno,id_disciplina,notaFinal,status)
		select m.id_aluno,t.id_disciplina,m.nota_final,m.status
        from matriculas as m
        inner join turmas as t on m.id_turma = t.id_turma
        inner join disciplinas as d on t.id_disciplina = d.id_disciplina
        where m.status = "Aprovado"
        and m.id_aluno = p_ID_Aluno;        
	end if;
end $$
DELIMITER ;

/*sp_ReabrirPeriodoMatricula
>> o Reabre um semestre, definindo AbertoParaMatricula = TRUE.*/

DELIMITER $$
create procedure sp_ReabrirPeriodoMatricula(in v_id_semestre int)
begin
	declare v_quantidade int;
    
	select count(*)
	into v_quantidade
	from semestres
	where id_semestre = v_id_semestre
	and UPPER(aberto_matricula) = "N";

	if  v_quantidade > 0 then
		update semestres
		set aberto_matricula = "S"
		where id_semestre = v_id_semestre;
	end if;
end $$
DELIMITER ;


/*Procedimentos de Retorno (OUT)
fn_CalcularCoeficienteRendimento(p_ID_Aluno)
Retorna a média das notas ponderada das disciplinas concluídas.*/

DELIMITER $$
create procedure fn_CalcularCoeficienteRendimento(in p_ID_Aluno int, out p_coeficiente decimal(10,2))
begin
    DECLARE v_numerador decimal(10,2);
    DECLARE v_denominador decimal(10,2);
    
    select sum(m.nota_final * d.cargaHoraria) ,sum(d.cargaHoraria) into v_numerador , v_denominador
	from matriculas as m
	inner join turmas as t on m.id_turma = t.id_turma
	inner join disciplinas as d on t.id_disciplina = d.id_disciplina
	where m.status = "Aprovado" and
		m.id_aluno = p_ID_Aluno;
        
	if v_denominador > 0 then
		set p_coeficiente = v_numerador / v_denominador;
	end if;
end $$
DELIMITER ;

set @coef := 0;

call fn_CalcularCoeficienteRendimento(1, @coef);

select @coef;

/*fn_ContarDisciplinasPendentes(p_ID_Aluno, p_ID_Curso)
Retorna quantas disciplinas do currículo o aluno ainda não cursou.*/

DELIMITER $$
create procedure fn_ContarDisciplinasPendentes( in p_ID_Aluno int , in p_ID_Curso int, out p_qtd_pendentes int)
begin
declare total int;
declare cursada int;
	select  count(*) into total from vw_Disciplinas_Curso where id_curso=p_ID_Curso;
	select count(*) into cursada from matriculas m join turmas t on t.id_turma=m.id_turma join vw_Disciplinas_Curso v 
on t.id_disciplina=v.id_disciplina where id_aluno=p_ID_Aluno and m.status='Aprovado' and v.id_curso=p_ID_Curso;
	set p_qtd_pendentes = total-cursada;
	
end $$
DELIMITER ;

/*fn_ListarDisciplinasAprovadas(p_ID_Aluno)
Retorna as disciplinas em que o aluno foi aprovado.*/

DELIMITER $$ 
create procedure fn_ListarDisciplinasAprovadas( in p_ID_Aluno int)
begin
    select distinct a.id_aluno, a.nome as "nome_aluno", ha.status,d.nomeDisciplina
	from matriculas as ha
    inner join turmas as t on t.id_turma=ha.id_turma
	inner join disciplinas d on t.id_disciplina = d.id_disciplina
	inner join alunos as a on ha.id_aluno = a.id_aluno
	where ha.status = "Aprovado"
    and a.id_aluno = p_ID_Aluno;
end $$
DELIMITER ;

CALL fn_ListarDisciplinasAprovadas(4);


/*fn_TotalHorasConcluidas(p_ID_Aluno)
Retorna a soma da carga horária das disciplinas já concluídas*/

DELIMITER $$
create procedure fn_totalhorasconcluidas(
    in  p_id_aluno int,
    out p_total_horas int
)
begin
    select
        sum(d.cargahoraria)
    into p_total_horas
    from matriculas as m
    inner join alunos as a on m.id_aluno = a.id_aluno
    inner join turmas t on m.id_turma=t.id_turma
    inner join disciplinas as d 
            on d.id_disciplina = t.id_disciplina
    where m.id_aluno = p_id_aluno
      and m.status   = 'Aprovado';
end $$
DELIMITER ;

set @horas := 0;

call fn_totalhorasconcluidas(7, @horas);

select @horas;