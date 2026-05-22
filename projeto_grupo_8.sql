/*Arquivo em ordem de execução, mas é recomendado execução por lotes para sql não quebrar*/

drop database if exists academico;

create database academico;
use academico;

create table cursos(
	id_curso integer auto_increment,
    nome varchar(100),
    coordenador varchar (100),
    cargaHorariaTotal smallint,
    primary key (id_curso)
);
create table professores(
	id_professor integer auto_increment,
    nome varchar(200),
    titulacao varchar(100),
    email varchar(100),
	primary key(id_professor)
);
create table alunos(
   id_aluno integer auto_increment,
   nome varchar(200) not null,
   cpf char(14) not null,
   email varchar(100) not null,
   dataNascimento date not null,
   id_curso integer,
   primary key (id_aluno),
   foreign key (id_curso) references cursos(id_curso) ON DELETE RESTRICT
);
create table curriculos(
	id_curriculo smallint auto_increment,
    id_curso integer,
    anoInicio smallint,
    versao smallint,
    primary key(id_curriculo),
    foreign key (id_curso) references cursos(id_curso) ON DELETE RESTRICT
);
create table disciplinas(
	id_disciplina smallint auto_increment,
    nomeDisciplina varchar (100),
    cargaHoraria smallint,
    primary key (id_disciplina)
);
create table disciplinas_curriculo(
	id_disciplina smallint,
    id_curriculo smallint,
    periodoIdeal smallint,
    foreign key (id_disciplina) references disciplinas(id_disciplina)ON DELETE cascade,
    foreign key (id_curriculo) references curriculos(id_curriculo) ON DELETE cascade,
    primary key(id_disciplina, id_curriculo)
);
create table pre_requisitos(
	id_disciplina_principal smallint ,
	id_disciplina_requisito smallint,
	primary key(id_disciplina_requisito, id_disciplina_principal),
    foreign key (id_disciplina_principal) references disciplinas(id_disciplina)on delete cascade,
    foreign key (id_disciplina_requisito) references disciplinas(id_disciplina) on delete cascade
);
create table semestres(
	id_semestre smallint auto_increment,
    codigo_semestre integer,
    aberto_matricula char(1),
    primary key (id_semestre)
);

create table turmas(
	id_turma integer auto_increment,
    id_disciplina smallint,
    id_professor integer,
    id_semestre smallint,
    max_vagas smallint,
    vagas_ocupadas smallint default 0,
    primary key(id_turma),
    foreign key(id_disciplina) references disciplinas(id_disciplina) ON DELETE RESTRICT,
    foreign key (id_semestre) references semestres(id_semestre) ON DELETE RESTRICT, 
    foreign key (id_professor) references professores(id_professor) ON DELETE RESTRICT
);

create table matriculas(
	id_matricula integer auto_increment,
    id_turma integer,
    id_aluno integer,
    status char(10),
    nota_final decimal(4,2),
    primary key (id_matricula),
    foreign key(id_aluno) references alunos(id_aluno) ON DELETE RESTRICT,
    foreign key(id_turma) references turmas(id_turma) ON DELETE RESTRICT,
    check (status in ('CURSANDO','APROVADO','REPROVADO','TRANCADO'))
);

create table historicoAluno(
	id_historico integer auto_increment,
    id_aluno integer,
    id_disciplina smallint,
    notaFinal decimal(4,2),
    status char(10),
    dataConclusao date,
    primary key (id_historico),
    foreign key(id_aluno) references alunos(id_aluno) ON DELETE RESTRICT,
    foreign key(id_disciplina) references disciplinas(id_disciplina) ON DELETE RESTRICT
);

create table usuarios(
	id_usuario integer auto_increment,
    nome varchar(250),
    email varchar(250),
    tipoUsuario varchar(50),
    senhaHash varchar(100),
    primary key (id_usuario)
);

create table logsSistema(
	id_log integer auto_increment,
    usuario varchar(250),
    acao varchar (150),
    tabelaAfetada varchar(50),
    dataHora datetime,
    descricao varchar(500),
    primary key (id_log)
);
/*vw_BoletimAluno
Exibe o histórico completo de um aluno (nome, semestre, disciplina, professor,
nota e status).*/

create view vw_BoletimAluno as 
select h.id_aluno,h.id_disciplina,a.nome,s.codigo_semestre,d.nomeDisciplina, p.nome as "nome_professor", h.notaFinal, h.status
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
from turmas as t inner join semestres as s on t.id_semestre = s.id_semestre where s.aberto_matricula = "S" and t.vagas_ocupadas < t.max_vagas and s.codigo_semestre like CONCAT(YEAR(CURDATE()), '%');


/*vw_DesempenhoTurma
Mostra o nome da disciplina, professor, média das notas, número de aprovados e
reprovados por turma.*/

create view vw_DesempenhoTurma as
select d.nomedisciplina,p.nome as "professor_disciplina",t.id_turma,avg(m.nota_final) as "medias_notas",
SUM(CASE WHEN m.status = 'Aprovado' THEN 1 ELSE 0 END) AS aprovados,
SUM(CASE WHEN m.status = 'Reprovado' THEN 1 ELSE 0 END) AS reprovados
from turmas as t inner join disciplinas as d on t.id_disciplina = d.id_disciplina inner join professores as p on t.id_professor = p.id_professor
inner join matriculas as m on m.id_turma = t.id_turma group by t.id_turma,d.nomedisciplina,p.nome;

/*vw_LogAuditoria
Exibe as 20 operações mais recentes da tabela LogsSistema.*/

create view vw_LogAuditoria as select * from logsSistema order by dataHora desc limit 20;

create view vw_Disciplinas_Curso as select  distinct dc.id_disciplina, c.id_curso from disciplinas_curriculo dc 
join curriculos c on dc.id_curriculo=c.id_curriculo;

/*trg_AtualizarContagemVagas
>> o AFTER INSERT em Matriculas.
>> o Incrementa VagasOcupadas na turma.*/

DELIMITER $
CREATE TRIGGER trg_AtualizarContagemVagas 
AFTER INSERT ON matriculas 
FOR EACH ROW 
BEGIN 
	UPDATE turmas SET vagas_ocupadas = vagas_ocupadas + 1 WHERE id_turma = NEW.id_turma;
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
		INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES (NEW.nome,'Alteração de email','alunos',NOW(),'O email de um aluno foi alterado');
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
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Insert em Alunos','alunos',NOW(),'Houve uma inserção na tabela Alunos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateAlunos
AFTER UPDATE ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES (new.nome,'Update em Alunos','alunos',NOW(),'Houve uma atualização na tabela Alunos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteAlunos
AFTER DELETE ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Delete em Alunos','alunos',NOW(),'Houve uma exclusão na tabela Alunos');
END $
DELIMITER ;

/*turmas*/
DELIMITER $
CREATE TRIGGER trg_LogInsertTurmas
AFTER INSERT ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Insert em turmas','turmas',NOW(),'Houve uma inserção na tabela turmas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateTurmas
AFTER UPDATE ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Update em turmas','turmas',NOW(),'Houve uma atualização na tabela turmas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteTurmas
AFTER DELETE ON turmas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Delete em turmas','turmas',NOW(),'Houve uma exclusão na tabela turmas');
END $
DELIMITER ;

/*professores*/
DELIMITER $
CREATE TRIGGER trg_LogInsertProfessores
AFTER INSERT ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Insert em professores','professores',NOW(),'Houve uma inserção na tabela professores');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateProfessores
AFTER UPDATE ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES (NEW.nome,'Update em professores','professores',NOW(),'Houve uma atualização na tabela professores');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteProfessores
AFTER DELETE ON professores
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Delete em professores','professores',NOW(),'Houve uma exclusão na tabela professores');
END $
DELIMITER ;

/*cursos*/
DELIMITER $
CREATE TRIGGER trg_LogInsertCursos
AFTER INSERT ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Insert em cursos','cursos',NOW(),'Houve uma inserção na tabela cursos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateCursos
AFTER UPDATE ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Update em cursos','cursos',NOW(),'Houve uma atualização na tabela cursos');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteCursos
AFTER DELETE ON cursos
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Delete em cursos','cursos',NOW(),'Houve uma exclusão na tabela cursos');
END $
DELIMITER ;

/*disciplinas*/
DELIMITER $
CREATE TRIGGER trg_LogInsertDisciplinas
AFTER INSERT ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Insert em disciplinas','disciplinas',NOW(),'Houve uma inserção na tabela disciplinas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogUpdateDisciplinas
AFTER UPDATE ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Update em disciplinas','disciplinas',NOW(),'Houve uma atualização na tabela disciplinas');
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_LogDeleteDisciplinas
AFTER DELETE ON disciplinas
FOR EACH ROW
BEGIN
	INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao) VALUES ("Sistema",'Delete em disciplinas','disciplinas',NOW(),'Houve uma exclusão na tabela disciplinas');
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
	IF OLD.status <> NEW.status AND NEW.status IN ('Aprovado') THEN
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
    
    SELECT COUNT(*) INTO total_disciplinas FROM matriculas WHERE id_aluno = NEW.id_aluno AND status = 'Cursando';
    
    SELECT nome into aluno from alunos where id_aluno= NEW.id_aluno;
    
	IF total_disciplinas >= 6 THEN
		INSERT INTO LogsSistema (usuario,acao, tabelaAfetada, dataHora, descricao)
	VALUES (aluno,'ERROR','matriculas',NOW(),'Erro: Houve uma tentativa de cadastro de aluno em uma turma, porém o aluno referente já possui 6 disciplinas com status "cursando", o que não é aceito.');
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Erro: Aluno já atingiu o limite de 6 turmas.';
    END IF;
END $
DELIMITER ;

/*Incremento para automatizar a inserção de dados em usuario */

DELIMITER $
CREATE TRIGGER trg_professor_usuario
AFTER INSERT ON professores
FOR EACH ROW
BEGIN
	INSERT INTO usuarios(nome,email, tipoUsuario,senhaHash) VALUES(NEW.nome,NEW.email,'PROFESSOR',SHA2('123456', 256));
END $
DELIMITER ;

DELIMITER $
CREATE TRIGGER trg_aluno_usuario
AFTER INSERT ON alunos
FOR EACH ROW
BEGIN
	INSERT INTO usuarios(nome,email,tipoUsuario,senhaHash) VALUES(NEW.nome,NEW.email,'ALUNO',SHA2('123456', 256));
END $
DELIMITER ;

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

INSERT INTO cursos(nome, coordenador, cargaHorariaTotal) VALUES 
('Sistemas de Informação', 'Ana Silva', 3000),
('Engenharia Civil', 'Fernanda Lima', 4000),
('Direito', 'Carlos Costa', 3800),
('Administração', 'Ricardo Souza', 3000),
('Psicologia', 'Maria Oliveira', 4000),
('Enfermagem', 'Pedro Santos', 4200);

INSERT INTO professores(nome, titulacao, email) VALUES 
('Pedro Souza 1', 'Especialista', 'prof1@email.com'),
('Amanda Pereira 2', 'Doutor', 'prof2@email.com'),
('Fernanda Costa 3', 'Doutor', 'prof3@email.com'),
('Ana Costa 4', 'Mestre', 'prof4@email.com'),
('Carlos Oliveira 5', 'Mestre', 'prof5@email.com'),
('Amanda Pereira 6', 'Especialista', 'prof6@email.com'),
('Pedro Oliveira 7', 'Mestre', 'prof7@email.com'),
('Fernanda Oliveira 8', 'Doutor', 'prof8@email.com'),
('Ricardo Lima 9', 'Especialista', 'prof9@email.com'),
('Amanda Ferreira 10', 'Especialista', 'prof10@email.com'),
('Pedro Rodrigues 11', 'Mestre', 'prof11@email.com'),
('Fernanda Pereira 12', 'Mestre', 'prof12@email.com'),
('Pedro Souza 13', 'Doutor', 'prof13@email.com'),
('Carlos Lima 14', 'Especialista', 'prof14@email.com'),
('Pedro Lima 15', 'Mestre', 'prof15@email.com'),
('Lucas Alves 16', 'Especialista', 'prof16@email.com'),
('Carlos Silva 17', 'Mestre', 'prof17@email.com'),
('Ricardo Oliveira 18', 'Mestre', 'prof18@email.com'),
('Carlos Alves 19', 'Mestre', 'prof19@email.com'),
('Lucas Souza 20', 'Especialista', 'prof20@email.com'),
('Lucas Lima 21', 'Doutor', 'prof21@email.com'),
('Ana Souza 22', 'Doutor', 'prof22@email.com'),
('Carlos Alves 23', 'Mestre', 'prof23@email.com'),
('Pedro Alves 24', 'Especialista', 'prof24@email.com'),
('Carlos Santos 25', 'Doutor', 'prof25@email.com'),
('Julia Alves 26', 'Doutor', 'prof26@email.com'),
('Fernanda Lima 27', 'Mestre', 'prof27@email.com'),
('Julia Souza 28', 'Doutor', 'prof28@email.com'),
('Amanda Ferreira 29', 'Doutor', 'prof29@email.com'),
('Lucas Souza 30', 'Doutor', 'prof30@email.com'),
('Maria Ferreira 31', 'Especialista', 'prof31@email.com'),
('João Silva 32', 'Especialista', 'prof32@email.com'),
('Maria Souza 33', 'Especialista', 'prof33@email.com'),
('Fernanda Santos 34', 'Mestre', 'prof34@email.com'),
('Pedro Alves 35', 'Doutor', 'prof35@email.com'),
('Pedro Oliveira 36', 'Especialista', 'prof36@email.com'),
('Maria Souza 37', 'Doutor', 'prof37@email.com'),
('Maria Santos 38', 'Mestre', 'prof38@email.com'),
('Carlos Silva 39', 'Doutor', 'prof39@email.com'),
('Ana Oliveira 40', 'Mestre', 'prof40@email.com'),
('Pedro Souza 41', 'Mestre', 'prof41@email.com'),
('Ricardo Oliveira 42', 'Doutor', 'prof42@email.com'),
('Amanda Oliveira 43', 'Especialista', 'prof43@email.com'),
('Amanda Pereira 44', 'Especialista', 'prof44@email.com');

INSERT INTO disciplinas(nomeDisciplina, cargaHoraria) VALUES
('Algoritmos e Lógica de Programação', 80),('Programação Orientada a Objetos', 80),('Banco de Dados', 80),
('Estrutura de Dados', 80),('Engenharia de Software', 60),
('Desenvolvimento Web', 80),('Sistemas Operacionais', 60),
('Redes de Computadores', 60),('Segurança da Informação', 60),
('Análise de Sistemas', 60),('Inteligência Artificial', 60),
('Computação em Nuvem', 60),('DevOps', 60),
('Gestão de Projetos de TI', 60),('Empreendedorismo Digital', 40),
('Cálculo I', 80),('Cálculo II', 80),
('Física Geral', 80),('Resistência dos Materiais', 80),
('Topografia', 60),('Desenho Técnico', 60),
('Materiais de Construção', 60),('Mecânica dos Solos', 80),
('Hidráulica', 60),('Estruturas de Concreto', 80),
('Estradas e Pavimentação', 60),('Saneamento Básico', 60),
('Gestão de Obras', 60),('Segurança do Trabalho', 40),('Projeto Estrutural', 80),
('Introdução ao Direito', 60),('Direito Constitucional', 80),('Direito Civil I', 80),
('Direito Penal I', 80),('Direito Administrativo', 60),
('Direito Tributário', 60),('Direito Trabalhista', 60),
('Direito Empresarial', 60),('Direito Processual Civil', 80),
('Direito Processual Penal', 80),('Direitos Humanos', 60),
('Ética Jurídica', 40),('Mediação e Arbitragem', 40),
('Direito Ambiental', 60),('Prática Jurídica', 80),
('Teoria Geral da Administração', 60),('Gestão de Pessoas', 60),
('Marketing', 60),('Administração Financeira', 80),
('Contabilidade Geral', 60),('Empreendedorismo', 60),
('Logística Empresarial', 60),('Planejamento Estratégico', 60),
('Economia', 60),('Gestão da Qualidade', 60),
('Comércio Exterior', 60),('Administração da Produção', 60),
('Pesquisa de Mercado', 40),('Ética Empresarial', 40),('Gestão de Projetos', 60),
('Introdução à Psicologia', 60),('Psicologia do Desenvolvimento', 80),
('Psicologia Social', 60),('Psicologia Cognitiva', 60),
('Psicanálise', 60),('Neuropsicologia', 60),
('Psicopatologia', 80),('Avaliação Psicológica', 60),('Psicologia Organizacional', 60),
('Psicologia Escolar', 60),('Ética Profissional', 40),
('Psicologia Clínica', 80),('Terapia Cognitivo-Comportamental', 60),
('Psicologia da Saúde', 60),('Estágio Supervisionado', 100),
('Anatomia Humana', 80),('Fisiologia Humana', 80),
('Microbiologia', 60),('Bioquímica', 60),
('Fundamentos de Enfermagem', 80),('Semiologia', 60),
('Farmacologia', 60),('Enfermagem em Saúde Coletiva', 60),
('Enfermagem Pediátrica', 60),('Enfermagem Obstétrica', 60),
('Enfermagem Cirúrgica', 80),('Urgência e Emergência', 80),
('UTI e Paciente Crítico', 80),('Ética em Enfermagem', 40),('Estágio Supervisionado em Enfermagem', 120);

INSERT INTO curriculos(id_curso, anoInicio, versao) VALUES
(1, 2023, 1),(1, 2025, 2),
(2, 2022, 1),(2, 2025, 2),
(3, 2021, 1),(3, 2024, 2),
(4, 2023, 1),(4, 2025, 2),
(5, 2022, 1),(5, 2025, 2),
(6, 2021, 1),(6, 2024, 2);

INSERT INTO alunos(nome, cpf, email, dataNascimento, id_curso) VALUES 
('Amanda Oliveira Silva', '54514291824', 'amanda.silva@email.com', '2008-10-08', 1),
('Ana Beatriz Oliveira', '71398692504', 'ana.oliveira@email.com', '2001-03-03', 1),
('Amanda Alves Costa', '603.412.611-58', 'amanda.costa@email.com', '2005-06-28', 1),
('Carlos Oliveira Santos', '488.245.435-91', 'carlos.santos@email.com', '2004-06-08', 1),
('João Alves Costa', '321.970.821-17', 'joao.costa@email.com', '2007-07-04', 1),
('Amanda Silva Rodrigues', '711.614.301-24', 'amanda.rodrigues@email.com', '2004-08-21', 1),
('Carlos Rodrigues Alves', '95104532139', 'carlos.alves@email.com', '2005-12-13', 2),
('Ricardo Oliveira Santos', '41523416202', 'ricardo.santos@email.com', '2005-06-04', 2),
('Carlos Pereira Costa', '735.900.031-25', 'carlos.costa@email.com', '2003-06-29', 2),
('Carlos Lima Oliveira', '54757549753', 'carlos.oliveira@email.com', '2007-11-16', 2),
('Pedro Silva Souza', '32301221630', 'pedro.souza@email.com', '2002-06-12', 2),
('Lucas Henrique Silva', '568.978.495-52', 'lucas.silva@email.com', '2008-03-17', 3),
('Ricardo Lima Costa', '43184405889', 'ricardo.costa@email.com', '2002-10-19', 3),
('Maria Rodrigues Lima', '93701702528', 'maria.lima@email.com', '2004-12-01', 3),
('Pedro Costa Lima', '233.041.784-51', 'pedro.lima3@email.com', '2004-06-22', 3),
('Carlos Costa Oliveira', '29093347219', 'carlos.oliveira2@email.com', '2008-04-02', 3),
('Fernanda Souza Santos', '381.600.790-19', 'fernanda.santos@email.com', '2003-07-23', 4),
('Lucas Ferreira Souza', '790.843.795-11', 'lucas.souza@email.com', '2001-11-06', 4),
('Lucas Alves Ferreira', '657.047.832-70', 'lucas.ferreira2@email.com', '2003-04-28', 4),
('João Souza Lima', '433.451.997-37', 'joao.lima@email.com', '2001-01-05', 4),
('Julia Oliveira Lima', '90655217249', 'julia.lima@email.com', '2003-02-02', 4),
('Julia Pereira Costa', '154.227.436-65', 'julia.costa@email.com', '2007-04-26', 5),
('Carlos Ferreira Souza', '282.370.619-76', 'carlos.souza@email.com', '2004-01-01', 5),
('Ricardo Costa Ferreira', '37240255612', 'ricardo.ferreira@email.com', '2003-10-08', 5),
('Carlos Silva Pereira', '29408383107', 'carlos.pereira2@email.com', '2002-03-21', 5),
('Ricardo Costa Pereira', '29614207457', 'ricardo.pereira@email.com', '2008-10-03', 5),
('Carlos Eduardo Lima', '884.839.505-47', 'carlos.lima@email.com', '2001-11-09', 6),
('Carlos Santos Pereira', '797.402.720-91', 'carlos.pereira@email.com', '2006-05-28', 6),
('Pedro Costa Santos', '399.085.481-46', 'pedro.santos@email.com', '2002-10-06', 6),
('Carlos Alves Lima', '650.445.553-77', 'carlos.lima2@email.com', '2003-10-26', 6),
('João Pereira Costa', '22985519176', 'joao.costa2@email.com', '2008-10-18', 6),
('Pedro Souza Lima', '32970174227', 'pedro.lima@email.com', '2007-11-22', 1),
('Amanda Ferreira Lima', '936.131.184-16', 'amanda.lima@email.com', '2005-05-23', 1),
('Ricardo Costa Souza', '13878391786', 'ricardo.souza@email.com', '2004-12-24', 1),
('Ana Pereira Lima', '724.806.720-71', 'ana.lima@email.com', '2007-07-25', 1),
('Pedro Silva Souza', '32301221630', 'pedro.souza@email.com', '2002-06-12', 2),
('Pedro Costa Lima', '233.041.784-51', 'pedro.lima3@email.com', '2004-06-22', 3),
('Julia Oliveira Lima', '90655217249', 'julia.lima@email.com', '2003-02-02', 4),
('Julia Silva Rodrigues', '400.590.114-05', 'julia.rodrigues2@email.com', '2004-04-08', 5),
('Maria Silva Santos', '902.183.845-51', 'maria.santos@email.com', '2009-03-26', 6),
('Lucas Costa Ferreira', '616.485.704-18', 'lucas.ferreira@email.com', '2004-11-10', 1),
('Julia Alves Rodrigues', '17178987035', 'julia.rodrigues@email.com', '2005-08-11', 2),
('Ricardo Pereira Silva', '98571679825', 'ricardo.silva@email.com', '2004-06-18', 3),
('Ricardo Costa Lima', '60161480271', 'ricardo.lima@email.com', '2002-10-19', 4),
('Carlos Costa Rodrigues', '89451463601', 'carlos.rodrigues@email.com', '2002-08-23', 5),
('Pedro Pereira Lima', '333.427.146-73', 'pedro.lima2@email.com', '2002-05-04', 6),
('Pedro Santos Oliveira', '69411751360', 'pedro.oliveira@email.com', '2003-03-17', 1),
('Ricardo Lima Souza', '91138404665', 'ricardo.souza2@email.com', '2003-06-11', 2),
('Ricardo Santos Costa', '63537322336', 'ricardo.costa2@email.com', '2004-04-25', 3),
('Amanda Silva Costa', '98606424000', 'amanda.costa2@email.com', '2004-09-01', 4),
('Julia Ferreira Santos', '498.946.302-96', 'julia.santos@email.com', '2002-12-25', 5),
('Carlos Souza Pereira', '677.268.372-02', 'carlos.pereira3@email.com', '2002-02-04', 6);

INSERT INTO disciplinas_curriculo(id_disciplina, id_curriculo, periodoIdeal) VALUES
(1, 1, 1),(1, 2, 1),(16, 3, 1),(16, 4, 1),
(2, 1, 1),(2, 2, 1),(17, 3, 1),(17, 4, 1),
(3, 1, 2),(3, 2, 2),(18, 3, 2),(18, 4, 2),
(4, 1, 2),(4, 2, 2),(19, 3, 2),(19, 4, 2),
(5, 1, 3),(5, 2, 3),(20, 3, 3),(20, 4, 3),
(6, 1, 3),(6, 2, 3),(21, 3, 3),(21, 4, 3),
(7, 1, 4),(7, 2, 4),(22, 3, 4),(22, 4, 4),
(8, 1, 4),(8, 2, 4),(23, 3, 4),(23, 4, 4),
(9, 1, 5),(9, 2, 5),(24, 3, 5),(24, 4, 5),
(10, 1, 5),(10, 2, 5),(25, 3, 5),(25, 4, 5),
(11, 1, 6),(11, 2, 6),(26, 3, 6),(26, 4, 6),
(12, 1, 6),(12, 2, 6),(27, 3, 6),(27, 4, 6),
(13, 1, 7),(13, 2, 7),(28, 3, 7),(28, 4, 7),
(14, 1, 7),(14, 2, 7),(29, 3, 7),(29, 4, 7),
(15, 1, 8),(15, 2, 8),(30, 3, 8),(30, 4, 8),
(31, 5, 1),(31, 6, 1),(46, 7, 1),(46, 8, 1),
(32, 5, 1),(32, 6, 1),(47, 7, 1),(47, 8, 1),
(33, 5, 2),(33, 6, 2),(48, 7, 2),(48, 8, 2),
(34, 5, 2),(34, 6, 2),(49, 7, 2),(49, 8, 2),
(35, 5, 3),(35, 6, 3),(50, 7, 3),(50, 8, 3),
(36, 5, 3),(36, 6, 3),(51, 7, 3),(51, 8, 3),
(37, 5, 4),(37, 6, 4),(52, 7, 4),(52, 8, 4),
(38, 5, 4),(38, 6, 4),(53, 7, 4),(53, 8, 4),
(39, 5, 5),(39, 6, 5),(54, 7, 5),(54, 8, 5),
(40, 5, 5),(40, 6, 5),(55, 7, 5),(55, 8, 5),
(41, 5, 6),(41, 6, 6),(56, 7, 6),(56, 8, 6),
(42, 5, 6),(42, 6, 6),(57, 7, 6),(57, 8, 6),
(43, 5, 7),(43, 6, 7),(58, 7, 7),(58, 8, 7),
(44, 5, 7),(44, 6, 7),(59, 7, 7),(59, 8, 7),
(45, 5, 8),(45, 6, 8),(60, 7, 8),(60, 8, 8),
(61, 9, 1),(61, 10, 1),(76, 11, 1),(76, 12, 1),
(62, 9, 1),(62, 10, 1),(77, 11, 1),(77, 12, 1),
(63, 9, 2),(63, 10, 2),(78, 11, 2),(78, 12, 2),
(64, 9, 2),(64, 10, 2),(79, 11, 2),(79, 12, 2),
(65, 9, 3),(65, 10, 3),(80, 11, 3),(80, 12, 3),
(66, 9, 3),(66, 10, 3),(81, 11, 3),(81, 12, 3),
(67, 9, 4),(67, 10, 4),(82, 11, 4),(82, 12, 4),
(68, 9, 4),(68, 10, 4),(83, 11, 4),(83, 12, 4),
(69, 9, 5),(69, 10, 5),(84, 11, 5),(84, 12, 5),
(70, 9, 5),(70, 10, 5),(85, 11, 5),(85, 12, 5),
(71, 9, 6),(71, 10, 6),(86, 11, 6),(86, 12, 6),
(72, 9, 6),(72, 10, 6),(87, 11, 6),(87, 12, 6),
(73, 9, 7),(73, 10, 7),(88, 11, 7),(88, 12, 7),
(74, 9, 7),(74, 10, 7),(89, 11, 7),(89, 12, 7),
(75, 9, 8),(75, 10, 8),(90, 11, 8),(90, 12, 8);
INSERT INTO pre_requisitos(id_disciplina_principal, id_disciplina_requisito) VALUES
(2, 1),(25, 19),(39, 33),(60, 53),(77, 76), 
(4, 1),(26, 20),(40, 34),(62, 61),(78, 76), 
(5, 2),(27, 24),(45, 39),(63, 61),(79, 77), 
(6, 2),(28, 22),(47, 46),(64, 61),(80, 76),
(10, 5),(30, 25),(48, 46),(65, 61),(81, 80), 
(11, 4),(33, 31),(49, 50),(66, 64),(82, 79), 
(12, 8),(34, 31),(51, 46),(67, 65),(83, 80), 
(13, 7),(35, 32),(52, 46),(68, 67),(86, 81),
(14, 5),(36, 33),(53, 46),(72, 67),(87, 81),
(17, 16),(24, 17),(37, 33),(55, 46),(73, 72),(88, 87),
(19, 18),(22, 19),(38, 33),(56, 54),(75, 72),(90, 88); 


INSERT INTO semestres(codigo_semestre, aberto_matricula) VALUES
(20231, 'N'),(20232, 'N'),(20241, 'N'),
(20242, 'N'),(20251, 'N'),(20252, 'S'),(20261, 'S');

INSERT INTO turmas (id_disciplina, id_professor, id_semestre, max_vagas, vagas_ocupadas) VALUES
(1, 1, 3, 40, 38),
(2, 2, 3, 40, 35),
(3, 3, 3, 35, 32),
(4, 4, 3, 35, 30),
(5, 5, 3, 30, 28),
(16, 11, 3, 50, 47),
(17, 12, 3, 45, 40),
(18, 13, 3, 45, 39),
(19, 14, 3, 40, 36),
(20, 15, 3, 40, 33),
(31, 21, 3, 60, 58),
(32, 22, 3, 60, 55),
(33, 23, 3, 55, 51),
(34, 24, 3, 55, 49),
(35, 25, 3, 50, 46),
(46, 31, 3, 45, 40),
(47, 32, 3, 45, 39),
(48, 33, 3, 40, 34),
(49, 34, 3, 40, 31),
(50, 35, 3, 35, 29),
(61, 41, 3, 40, 36),
(62, 42, 3, 40, 34),
(63, 43, 3, 35, 30),
(64, 44, 3, 35, 29),
(65, 1, 3, 35, 27),
(76, 7, 3, 50, 48),
(77, 8, 3, 50, 46),
(78, 9, 3, 45, 40),
(79, 10, 3, 45, 38),
(80, 11, 3, 40, 35),
(6, 6, 7, 40, 37),
(7, 7, 4, 35, 31),
(8, 8, 4, 35, 30),
(9, 9, 4, 30, 26),
(10, 10, 4, 30, 24),
(21, 16, 4, 35, 30),
(22, 17, 4, 35, 29),
(23, 18, 4, 40, 34),
(24, 19, 4, 35, 28),
(25, 20, 4, 35, 27),
(36, 26, 4, 50, 44),
(37, 27, 4, 50, 43),
(38, 28, 4, 45, 39),
(39, 29, 4, 45, 37),
(40, 30, 4, 45, 36),
(51, 36, 4, 35, 30),
(52, 37, 4, 35, 29),
(53, 38, 4, 35, 27),
(54, 39, 4, 35, 26),
(55, 40, 4, 35, 24),
(66, 2, 4, 30, 25),
(67, 3, 4, 30, 24),
(68, 4, 4, 30, 22),
(69, 5, 4, 30, 21),
(70, 6, 4, 30, 20),
(81, 12, 4, 40, 37),
(82, 13, 4, 40, 35),
(83, 14, 4, 35, 31),
(84, 15, 4, 35, 29),
(85, 16, 4, 35, 27),
(11, 1, 5, 30, 22),
(12, 2, 5, 30, 20),
(13, 3, 5, 30, 18),
(14, 4, 5, 30, 19),
(15, 5, 5, 25, 15),
(26, 11, 5, 35, 26),
(27, 12, 5, 35, 25),
(28, 13, 5, 35, 24),
(29, 14, 5, 30, 21),
(30, 15, 5, 30, 19),
(41, 21, 5, 40, 32),
(42, 22, 5, 35, 27),
(43, 23, 5, 35, 25),
(44, 24, 5, 35, 24),
(45, 25, 5, 30, 20),
(56, 31, 5, 35, 28),
(57, 32, 5, 35, 25),
(58, 33, 5, 30, 22),
(59, 34, 5, 30, 20),
(60, 35, 5, 30, 19),
(71, 41, 5, 30, 22),
(72, 42, 5, 30, 21),
(73, 43, 5, 30, 18),
(74, 44, 5, 30, 17),
(75, 1, 5, 25, 14),
(86, 7, 5, 35, 28),
(87, 8, 5, 35, 26),
(88, 9, 5, 35, 24),
(89, 10, 5, 30, 21),
(90, 11, 5, 25, 18),
(1, 1, 6, 40, 32),
(2, 2, 6, 40, 30),
(3, 3, 6, 35, 26),
(16, 11, 6, 50, 42),
(17, 12, 6, 45, 37),
(18, 13, 6, 45, 34),
(31, 21, 6, 60, 51),
(32, 22, 6, 60, 48),
(33, 23, 6, 55, 43),
(46, 31, 6, 45, 33),
(47, 32, 6, 45, 31),
(48, 33, 6, 40, 28),
(61, 41, 6, 40, 30),
(62, 42, 6, 40, 27),
(63, 43, 6, 35, 23),
(76, 7, 6, 50, 44),
(77, 8, 6, 50, 41),
(78, 9, 6, 45, 36),
(4, 4, 7, 35, 12),
(5, 5, 7, 30, 10),
(6, 6, 7, 40, 15),
(19, 14, 7, 40, 14),
(20, 15, 7, 40, 12),
(21, 16, 7, 35, 11),
(34, 24, 7, 55, 18),
(35, 25, 7, 50, 15),
(36, 26, 7, 50, 13),
(49, 34, 7, 40, 16),
(50, 35, 7, 35, 14),
(51, 36, 7, 35, 12),
(64, 44, 7, 35, 13),
(65, 1, 7, 35, 11),
(66, 2, 7, 30, 10),
(79, 10, 7, 45, 17),
(80, 11, 7, 40, 14),
(81, 12, 7, 40, 13);

INSERT INTO matriculas(id_turma, id_aluno, status, nota_final) VALUES
(1, 1, 'Aprovado', 8.5),
(2, 1, 'Aprovado', 7.8),
(6, 1, 'Aprovado', 8.0),
(7, 1, 'Reprovado', 4.2),
(11, 1, 'Cursando', NULL),
(12, 1, 'Cursando', NULL),
(1, 2, 'Aprovado', 9.0),
(2, 2, 'Aprovado', 8.7),
(3, 2, 'Aprovado', 7.5),
(6, 2, 'Cursando', NULL),
(7, 2, 'Cursando', NULL),
(1, 3, 'Reprovado', 3.5),
(2, 3, 'Aprovado', 7.0),
(3, 3, 'Cursando', NULL),
(4, 3, 'Cursando', NULL),
(1, 4, 'Aprovado', 8.8),
(2, 4, 'Aprovado', 9.1),
(6, 4, 'Aprovado', 7.9),
(11, 4, 'Cursando', NULL),
(16, 7, 'Aprovado', 8.1),
(17, 7, 'Aprovado', 7.4),
(21, 7, 'Cursando', NULL),
(22, 7, 'Cursando', NULL),
(16, 8, 'Aprovado', 9.2),
(17, 8, 'Reprovado', 4.0),
(18, 8, 'Cursando', NULL),
(16, 9, 'Aprovado', 7.6),
(17, 9, 'Aprovado', 8.0),
(18, 9, 'Aprovado', 7.1),
(21, 9, 'Cursando', NULL),
(31, 12, 'Aprovado', 8.3),
(32, 12, 'Aprovado', 8.7),
(36, 12, 'Cursando', NULL),
(37, 12, 'Cursando', NULL),
(31, 13, 'Reprovado', 2.8),
(32, 13, 'Aprovado', 7.2),
(33, 13, 'Cursando', NULL),
(31, 14, 'Aprovado', 9.0),
(32, 14, 'Aprovado', 8.9),
(33, 14, 'Aprovado', 8.4),
(36, 14, 'Cursando', NULL),
(46, 17, 'Aprovado', 7.5),
(47, 17, 'Aprovado', 7.8),
(51, 17, 'Cursando', NULL),
(46, 18, 'Reprovado', 4.5),
(47, 18, 'Cursando', NULL),
(48, 18, 'Cursando', NULL),
(46, 19, 'Aprovado', 8.0),
(47, 19, 'Aprovado', 7.7),
(48, 19, 'Aprovado', 7.3),
(51, 19, 'Cursando', NULL),
(61, 22, 'Aprovado', 8.4),
(62, 22, 'Aprovado', 8.0),
(66, 22, 'Cursando', NULL),
(61, 23, 'Reprovado', 3.9),
(62, 23, 'Cursando', NULL),
(63, 23, 'Cursando', NULL),
(61, 24, 'Aprovado', 7.2),
(62, 24, 'Aprovado', 7.9),
(63, 24, 'Aprovado', 8.1),
(66, 24, 'Cursando', NULL),
(76, 27, 'Aprovado', 8.6),
(77, 27, 'Aprovado', 7.8),
(81, 27, 'Cursando', NULL),
(76, 28, 'Reprovado', 4.1),
(77, 28, 'Cursando', NULL),
(78, 28, 'Cursando', NULL),
(76, 29, 'Aprovado', 9.0),
(77, 29, 'Aprovado', 8.8),
(78, 29, 'Aprovado', 8.1),
(81, 29, 'Cursando', NULL);


