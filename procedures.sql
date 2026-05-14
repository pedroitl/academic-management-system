/*Stored Procedures (Procedimentos Armazenados)

sp_RegistrarMatricula (Transacional)
>> o Parâmetros: p_ID_Aluno, p_ID_Turma
o Regras:
>>> Verificar se o semestre está aberto para matrícula.
>>> Verificar se a turma tem vagas.
>>> Verificar pré-requisitos.
>>> Verificar se o aluno já está matriculado na mesma disciplina.
>>> Inserir a matrícula com status 'Cursando' e confirmar transação.*/


/*sp_LancarNotas
>> o Parâmetros: p_ID_Matricula, p_NotaFinal
>> o Atualiza nota e define status: 'Aprovado' se nota ≥ 7, senão 'Reprovado'.*/

/*sp_TrancarMatricula
>> o Parâmetros: p_ID_Matricula, p_Usuario
>> o Altera status para 'Trancado', decrementa vaga e registra log.*/

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