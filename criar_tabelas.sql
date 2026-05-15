drop database if exists academico;

create database academico;
use academico;

create table cursos(
	id_curso integer,
    nome varchar(100),
    coordenador varchar (100),
    cargaHorariaTotal smallint,
    primary key (id_curso)
);
create table professores(
	id_professor integer,
    nome varchar(200),
    titulacao varchar(100),
    email varchar(100),
	primary key(id_professor)
);
create table alunos(
   id_aluno integer,
   nome varchar(200),
   cpf char(13),
   email varchar(100),
   dataNascimento date,
   id_curso integer,
   primary key (id_aluno),
   foreign key (id_curso) references cursos(id_curso)
);
create table curriculos(
	id_curriculo smallint,
    id_curso integer,
    anoInicio smallint,
    versao smallint,
    primary key(id_curriculo),
    foreign key (id_curso) references cursos(id_curso)
);
create table disciplinas(
	id_disciplina smallint,
    nomeDisciplina varchar (100),
    cargaHoraria smallint,
    primary key (id_disciplina)
);
create table disciplinas_curriculo(
	id_disciplina smallint,
    id_curriculo smallint,
    periodoIdeal smallint,
    foreign key (id_disciplina) references disciplinas(id_disciplina),
    foreign key (id_curriculo) references curriculos(id_curriculo),
    primary key(id_disciplina, id_curriculo)
);
create table pre_requisitos(
	id_disciplina_principal smallint,
	id_disciplina_requisito smallint,
	primary key(id_disciplina_requisito, id_disciplina_principal),
    foreign key (id_disciplina_principal) references disciplinas(id_disciplina),
    foreign key (id_disciplina_requisito) references disciplinas(id_disciplina)
);
create table semestres(
	id_semestre smallint,
    codigo_semestre integer,
    aberto_matricula char(1),
    primary key (id_semestre)
);

create table turmas(
	id_turma integer,
    id_disciplina smallint,
    id_professor integer,
    id_semestre smallint,
    max_vagas smallint,
    vagas_ocupadas smallint default 0,
    primary key(id_turma),
    foreign key(id_disciplina) references disciplinas(id_disciplina),
    foreign key (id_semestre) references semestres(id_semestre),
    foreign key (id_professor) references professores(id_professor)
);

create table matriculas(
	id_matricula integer,
    id_turma integer,
    id_aluno integer,
    status char(10),
    nota_final decimal,
    primary key (id_matricula),
    foreign key(id_aluno) references alunos(id_aluno),
    foreign key(id_turma) references turmas(id_turma)
);

create table historicoAluno(
	id_historico smallint,
    id_aluno integer,
    id_disciplina smallint,
    notaFinal decimal,
    status char(10),
    dataConclusao date,
    primary key (id_historico),
    foreign key(id_aluno) references alunos(id_aluno),
    foreign key(id_disciplina) references disciplinas(id_disciplina)
);

create table usuarios(
	id_usuario integer,
    nome varchar(250),
    email varchar(250),
    tipoUsuario varchar(50),
    senhaHash varchar(100),
    primary key (id_usuario)
);

create table logsSistema(
	id_log integer,
    id_usuario integer,
    acao varchar (150),
    tabelaAfetada varchar(50),
    dataHora datetime,
    descricao varchar(500),
    primary key (id_log),
	foreign key (id_usuario) references usuarios(id_usuario)
);