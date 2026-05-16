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

    IF v_semestre_aberto <> 'S' THEN
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    IF v_vagas_ocupadas >= v_max_vagas THEN
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    SELECT COUNT(*)
      INTO v_qtd_requisitos_total
      FROM pre_requisitos pr
     WHERE pr.id_disciplina_principal = v_id_disciplina;

    IF v_qtd_requisitos_total > 0 THEN
		
        
        SELECT COUNT(*)
			INTO v_qtd_requisitos_ok
			FROM pre_requisitos pr
			JOIN historicoAluno h
			ON h.id_disciplina = pr.id_disciplina_requisito
			AND h.id_aluno = p_ID_Aluno
			AND h.status = 'APROVADO'
         WHERE pr.id_disciplina_principal = v_id_disciplina;

        IF v_qtd_requisitos_ok < v_qtd_requisitos_total THEN
            ROLLBACK;
            LEAVE proc_end;
        END IF;
    END IF;
    
    SELECT COUNT(*)
      INTO v_qtd_matriculas_mesma_disciplina
      FROM matriculas m
      JOIN turmas t2
        ON t2.id_turma = m.id_turma
     WHERE m.id_aluno = p_ID_Aluno
       AND t2.id_disciplina = v_id_disciplina
       AND m.status = 'CURSANDO';

    IF v_qtd_matriculas_mesma_disciplina > 0 THEN
        ROLLBACK;
        LEAVE proc_end;
    END IF;

    INSERT INTO matriculas (
        id_turma,
        id_aluno,
        status,
        nota_final
    ) VALUES (
        p_ID_Turma,
        p_ID_Aluno,
        'CURSANDO',
        0.0
    );
    
    UPDATE turmas
       SET vagas_ocupadas = vagas_ocupadas + 1
     WHERE id_turma = p_ID_Turma;

    COMMIT;

    END proc_end;
END $$

DELIMITER ;


/*sp_LancarNotas
>> o Parâmetros: p_ID_Matricula, p_NotaFinal
>> o Atualiza nota e define status: 'Aprovado' se nota ≥ 7, senão 'Reprovado'.*/

DELIMITER $$

CREATE PROCEDURE sp_LancarNotas(IN p_ID_Matricula int, IN p_NotaFinal decimal(10,0))

BEGIN
	DECLARE v_quantidade_matricula INT;
    DECLARE v_status varchar(20);
    
		select count(*) into v_quantidade_matricula
        from matriculas where id_matricula = p_ID_Matricula;
        
        if v_quantidade_matricula = 0 then
			set v_status = v_status;
            
		else
        
			if p_NotaFinal >= 7 then
				set v_status = 'APROVADO';
			
            else 
				set v_status = 'REPROVADO';
                
			end if;
            
		
        update matriculas
        set nota_final =  p_NotaFinal ,
			status = v_status
		where id_matricula = p_ID_Matricula;
        
        end if;
    
	

END $$

DELIMITER ;

call sp_lancarNotas(3,8.0);

/*sp_TrancarMatricula
>> o Parâmetros: p_ID_Matricula, p_Usuario
>> o Altera status para 'Trancado', decrementa vaga e registra log.*/

DELIMITER $$

create procedure sp_TrancarMatricula(in p_ID_Matricula int , in p_ID_Usuario int )


begin

	DECLARE v_quantidade_matricula INT;
    DECLARE v_situacao varchar(20);
    DECLARE v_id_turma int;
    
		select count(*) into v_quantidade_matricula
        from matriculas where id_matricula = p_ID_Matricula;
        
        if v_quantidade_matricula = 0 then
			set v_situacao = v_situacao;
            
		else
			
            update matriculas
            set status = 'TRANCADO'
            where id_matricula = p_ID_Matricula;
            
            select id_turma
            into v_id_turma
            from matriculas
            where id_matricula = p_ID_Matricula; 
            
            update turmas
            set vagas_ocupadas = vagas_ocupadas - 1
            where id_turma = v_id_turma;
            
            insert into logssistema(id_usuario,acao,tabelaAfetada,dataHora)
            values(p_ID_Usuario,"trancar_matricula","matriculas",(now));
		
        end if;
        


end $$

DELIMITER ;


/*sp_GerarHistoricoAluno
>> o Parâmetro: p_ID_Aluno
>> o Insere no histórico todas as disciplinas aprovadas do aluno.*/

/*sp_ReabrirPeriodoMatricula
>> o Reabre um semestre, definindo AbertoParaMatricula = TRUE.*/

/*Procedimentos de Retorno (OUT)

fn_CalcularCoeficienteRendimento(p_ID_Aluno)
Retorna a média das notas ponderada das disciplinas concluídas.*/

/*fn_ContarDisciplinasPendentes(p_ID_Aluno, p_ID_Curso)
Retorna quantas disciplinas do currículo o aluno ainda não cursou.*/

/*fn_ListarDisciplinasAprovadas(p_ID_Aluno)
Retorna as disciplinas em que o aluno foi aprovado.*/


/*fn_TotalHorasConcluidas(p_ID_Aluno)
Retorna a soma da carga horária das disciplinas já concluídas*/