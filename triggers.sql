/*trg_AtualizarContagemVagas
>> o AFTER INSERT em Matriculas.
>> o Incrementa VagasOcupadas na turma.*/

DELIMITER $
CREATE TRIGGER trg_AtualizarContagemVagas 
AFTER INSERT ON matriculas 
FOR EACH ROW 
BEGIN 
	UPDATE turmas
	SET vagas_ocupadas = vagas_ocupadas + 1 
    WHERE id_turma = NEW.id_turma;
END $
DELIMITER ;

/*trg_AuditoriaAluno
o AFTER UPDATE em Alunos.
o Caso o email seja alterado, registra em LogsSistema.*/

DELIMITER $
CREATE TRIGGER trg_AuditoriaAluno
AFTER UPDATE ON alunos
FOR EACH ROW
BEGIN
	IF OLD.email <> NEW.email THEN
		INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
		VALUES (NEW.nome,'Alteração de email','alunos',NOW(),'O email de um aluno foi alterado');
    END IF;
END $
DELIMITER ;

/*trg_LogOperacoesGerais
o AFTER INSERT, UPDATE, DELETE em tabelas principais.
o Registra ação em LogsSistema.*/


/*alunos*/
DELIMITER $
CREATE TRIGGER trg_LogInsertAlunos
AFTER INSERT ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Insert em Alunos','alunos',NOW(),'Houve uma inserção na tabela Alunos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateAlunos
AFTER UPDATE ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES (new.nome,'Update em Alunos','alunos',NOW(),'Houve uma atualização na tabela Alunos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteAlunos
AFTER DELETE ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Delete em Alunos','alunos',NOW(),'Houve uma exclusão na tabela Alunos');
END $
DELIMITER ;

/*turmas*/
DELIMITER $
CREATE TRIGGER trg_LogInsertTurmas
AFTER INSERT ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Insert em turmas','turmas',NOW(),'Houve uma inserção na tabela turmas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateTurmas
AFTER UPDATE ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Update em turmas','turmas',NOW(),'Houve uma atualização na tabela turmas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteTurmas
AFTER DELETE ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Delete em turmas','turmas',NOW(),'Houve uma exclusão na tabela turmas');
END $
DELIMITER ;

/*professores*/
DELIMITER $
CREATE TRIGGER trg_LogInsertProfessores
AFTER INSERT ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Insert em professores','professores',NOW(),'Houve uma inserção na tabela professores');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateProfessores
AFTER UPDATE ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES (NEW.nome,'Update em professores','professores',NOW(),'Houve uma atualização na tabela professores');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteProfessores
AFTER DELETE ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Delete em professores','professores',NOW(),'Houve uma exclusão na tabela professores');
END $
DELIMITER ;

/*cursos*/
DELIMITER $
CREATE TRIGGER trg_LogInsertCursos
AFTER INSERT ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Insert em cursos','cursos',NOW(),'Houve uma inserção na tabela cursos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateCursos
AFTER UPDATE ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Update em cursos','cursos',NOW(),'Houve uma atualização na tabela cursos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteCursos
AFTER DELETE ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Delete em cursos','cursos',NOW(),'Houve uma exclusão na tabela cursos');
END $
DELIMITER ;

/*disciplinas*/
DELIMITER $
CREATE TRIGGER trg_LogInsertDisciplinas
AFTER INSERT ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Insert em disciplinas','disciplinas',NOW(),'Houve uma inserção na tabela disciplinas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateDisciplinas
AFTER UPDATE ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Update em disciplinas','disciplinas',NOW(),'Houve uma atualização na tabela disciplinas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteDisciplinas
AFTER DELETE ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES ("Sistema",'Delete em disciplinas','disciplinas',NOW(),'Houve uma exclusão na tabela disciplinas');
END $
DELIMITER ;

/*trg_AtualizarHistoricoAutomaticamente
o AFTER UPDATE em Matriculas.
o Se o status mudar para 'Aprovado', insere no HistoricoAluno.*/

DELIMITER $
CREATE TRIGGER trg_AtualizarHistoricoAutomaticamente
AFTER UPDATE ON matriculas
FOR EACH ROW
BEGIN
	IF OLD.status <> NEW.status 
    AND NEW.status IN ('Aprovado') THEN
	INSERT INTO historicoAluno (id_aluno, id_disciplina, notaFinal, status, dataConclusao)
	VALUES (NEW.id_aluno, (SELECT id_disciplina FROM turmas WHERE id_turma = NEW.id_turma), NEW.nota_final, NEW.status, NOW());
    END IF;
END $
DELIMITER ;

/*trg_AtualizarStatusAutomaticamente
>> o AFTER UPDATE em Matriculas
>> o Se o aluno tiver 6 disciplinas com status 'Cursando', e tentar se
matricular em uma nova disciplina, o sistema deve impedir a matrícula e
registrar o evento em LogsSistema.
*/

DELIMITER $
CREATE TRIGGER trg_AtualizarStatusAutomaticamente
before insert ON matriculas
FOR EACH ROW
BEGIN
	DECLARE total_disciplinas INT;
    DECLARE aluno varchar(250);
    
    SELECT COUNT(*) INTO total_disciplinas
	FROM matriculas WHERE id_aluno = NEW.id_aluno AND status = 'Cursando';
    
    SELECT nome into aluno from alunos where id_aluno= NEW.id_aluno;
    
	IF total_disciplinas >= 6 THEN
		INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES (aluno,'ERROR','matriculas',NOW(),'Erro: Houve uma tentativa de cadastro de aluno em uma turma, porém o aluno referente já possui 6 disciplinas com status "cursando", o que não é aceito.');
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erro: Aluno já atingiu o limite de 6 turmas.';
    END IF;
END $
DELIMITER ;

/*Incremento para automatizar a inserção de dados em usuario 
---->by leh*/

DELIMITER $
CREATE TRIGGER trg_professor_usuario
AFTER INSERT ON professores
FOR EACH ROW
BEGIN
	INSERT INTO usuarios(nome,email, tipoUsuario,senhaHash)
    VALUES(NEW.nome,NEW.email,'PROFESSOR',SHA2('123456', 256));
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_aluno_usuario
AFTER INSERT ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO usuarios(nome,email,tipoUsuario,senhaHash)
    VALUES(NEW.nome,NEW.email,'ALUNO',SHA2('123456', 256));
END $
DELIMITER ;


DELIMITER $

