/*trg_AtualizarContagemVagas
>> o AFTER INSERT em Matriculas.
>> o Incrementa VagasOcupadas na turma.*/


/*trg_AuditoriaAluno
o AFTER UPDATE em Alunos.
o Caso o email seja alterado, registra em LogsSistema.*/


/*trg_LogOperacoesGerais
o AFTER INSERT, UPDATE, DELETE em tabelas principais.
o Registra ação em LogsSistema.*/


/*trg_AtualizarHistoricoAutomaticamente
o AFTER UPDATE em Matriculas.
o Se o status mudar para 'Aprovado', insere no HistoricoAluno.*/

/*trg_AtualizarStatusAutomaticamente
>> o AFTER UPDATE em Matriculas
>> o Se o aluno tiver 6 disciplinas com status 'Cursando', e tentar se
matricular em uma nova disciplina, o sistema deve impedir a matrícula e
registrar o evento em LogsSistema.
*/

/*Valida CPF e salva no formato correto*/

DELIMITER $$

CREATE TRIGGER trg_valida_formata_cpf
BEFORE INSERT ON alunos
FOR EACH ROW
BEGIN
    SET NEW.cpf = REPLACE(REPLACE(NEW.cpf, '.', ''), '-', '');
    IF NEW.cpf NOT REGEXP '^[0-9]{11}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CPF inválido.';
    END IF;
    SET NEW.cpf = CONCAT(
        SUBSTRING(NEW.cpf,1,3), '.', 
        SUBSTRING(NEW.cpf,4,3), '.', 
        SUBSTRING(NEW.cpf,7,3), '-', 
        SUBSTRING(NEW.cpf,10,2)
    );
END$$
DELIMITER ;