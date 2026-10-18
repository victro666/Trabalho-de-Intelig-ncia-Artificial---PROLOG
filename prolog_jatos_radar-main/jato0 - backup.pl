% Jato 0
:- module(jato0, [obter_controles/4]).

%% Explicacao:
% Informacao:
%   X: posição horizontal do jato
%   Y: posiçao vertical do jato
%   ANGLE: angulo de inclinacao do jato: 0 para virado para frente até PI*2 (~6.28)
%   SCORE: inteiro com a "vida" do jato. Em zero, ele perdeu
%   SPEED: velocidade do jato
% Adversarios:
%   vetor com a posicao de todos os adversarios, [ [X1,Y1], [X2,Y2], ... ]
% Misseis:
%   vetor com a posicao de todos os misseis, [ [X1,Y1], [X2,Y2], ... ]
% Controles:
%   FORWARD: 1 para acelerar e 0 para continuar a velocidade atual
%   REVERSE: 1 para desacelerar e 0 para continuar a velocidade atual
%   LEFT: 1 para ir pra esquerda e 0 para não ir
%   RIGHT: 1 para ir pra direita e 0 para não ir
%   BOOM: 1 para tentar disparar (BOOM). Obs.: ele só pode disparar uma bala a cada segundo
%   MSG: mensagem para DEBUG

%%% Faça seu codigo a partir daqui, sendo necessario sempre ter o predicado:
%%%% obter_controles([X,Y,ANGLE,SCORE,SPEED], ADVERSARIOS, MISSEIS, [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG]) :- ...

% ====================================================================
% REGRA 1: SOBREVIVÊNCIA MÁXIMA (FUGIR DE MÍSSEIS)
% ====================================================================
obter_controles(INFORMACAO, _, MISSEIS, CONTROLES) :-
    INFORMACAO = [X, Y, _ANGLE, _SCORE, _SPEED],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    tem_perigo_perto(X, Y, MISSEIS, 70),
    
    FORWARD is 1, REVERSE is 0, LEFT is 0, RIGHT is 1, BOOM is 0,
    MSG = "Perigo! Missil detectado, virando a DIREITA!",
    !.

% ====================================================================
% REGRA 2: EVITAR COLISÃO COM OUTROS CAÇAS
% ====================================================================
obter_controles(INFORMACAO, ADVERSARIOS, _, CONTROLES) :-
    INFORMACAO = [X, Y, _ANGLE, _SCORE, _SPEED],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    tem_perigo_perto(X, Y, ADVERSARIOS, 45),
    
    FORWARD is 1, REVERSE is 0, LEFT is 1, RIGHT is 0, BOOM is 0,
    MSG = "Inimigo muito perto! Virando a ESQUERDA!",
    !.

% ====================================================================
% REGRA 3: ATACAR INIMIGO MAIS PRÓXIMO
% ====================================================================
obter_controles(INFORMACAO, ADVERSARIOS, _, CONTROLES) :-
    INFORMACAO = [X, Y, ANGLE, _SCORE, _SPEED],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    ADVERSARIOS \= [],
    encontrar_alvo(X, Y, ADVERSARIOS, AlvoX, AlvoY, _Distancia),
    mirar(X, Y, ANGLE, AlvoX, AlvoY, FORWARD, LEFT, RIGHT, BOOM),
    
    REVERSE is 0, 
    MSG = "Cacando alvo mais proximo (Atirando sem parar)!",
    !.

% ====================================================================
% REGRA 4: RONDA CIRCULAR (COMPORTAMENTO PADRÃO)
% ====================================================================
obter_controles(_, _, _, CONTROLES) :-
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    FORWARD is 1, 
    REVERSE is 0, 
    LEFT is 0, 
    RIGHT is 1, % Mantém o botão direito pressionado para voar em círculos
    BOOM is 0,
    MSG = "Nenhum alvo. Ronda circular ativada.".


% ====================================================================
% PREDICADOS AUXILIARES
% ====================================================================

% --- VERIFICADOR DE PERIGOS ---
tem_perigo_perto(_, _, [], _) :- fail. 
tem_perigo_perto(X, Y, [[ObjX, ObjY] | _], RaioLimite) :-
    Distancia is sqrt((ObjX - X)^2 + (ObjY - Y)^2),
    Distancia < RaioLimite, !.
tem_perigo_perto(X, Y, [_ | RestoLista], RaioLimite) :-
    tem_perigo_perto(X, Y, RestoLista, RaioLimite).


% --- BUSCA DO ALVO MAIS PRÓXIMO ---
encontrar_alvo(X, Y, [[AX, AY]], AX, AY, Distancia) :-
    Distancia is sqrt((AX - X)^2 + (AY - Y)^2), !.
encontrar_alvo(X, Y, [[AX1, AY1] | RestoLista], MelhorX, MelhorY, MenorDist) :-
    encontrar_alvo(X, Y, RestoLista, AX2, AY2, Dist2),
    Dist1 is sqrt((AX1 - X)^2 + (AY1 - Y)^2),
    comparar(AX1, AY1, Dist1, AX2, AY2, Dist2, MelhorX, MelhorY, MenorDist).

comparar(X1, Y1, D1, _, _, D2, X1, Y1, D1) :- D1 < D2, !.
comparar(_, _, _, X2, Y2, D2, X2, Y2, D2).


% --- MATEMÁTICA PARA MIRAR ---
mirar(X, Y, _, AlvoX, AlvoY, 1, 0, 0, 1) :-
    X =:= AlvoX, Y =:= AlvoY, !.

mirar(X, Y, ANGLE, AlvoX, AlvoY, FORWARD, LEFT, RIGHT, BOOM) :-
    DeltaX is AlvoX - X,
    DeltaY is AlvoY - Y,
    AnguloMatematico is atan2(DeltaY, DeltaX), 
    AnguloJogo is AnguloMatematico + (pi / 2),
    ajustar_angulo(AnguloJogo, AnguloLimpo),
    Diferenca is AnguloLimpo - ANGLE,
    ajustar_diferenca(Diferenca, DiferencaFinal),
    decidir_teclas(DiferencaFinal, FORWARD, LEFT, RIGHT, BOOM).

ajustar_angulo(A, A_Normalizado) :- A < 0, !, A_Normalizado is A + (2 * pi).
ajustar_angulo(A, A_Normalizado) :- A >= (2 * pi), !, A_Normalizado is A - (2 * pi).
ajustar_angulo(A, A).

ajustar_diferenca(D, D_Ajustada) :- D < -pi, !, D_Ajustada is D + (2 * pi).
ajustar_diferenca(D, D_Ajustada) :- D > pi, !, D_Ajustada is D - (2 * pi).
ajustar_diferenca(D, D).


% --- DECISÃO FINAL DE TECLAS (ATAQUE) ---
% Ajuste de zigue-zague (margem de 0.40) e gatilho automático (BOOM = 1)
decidir_teclas(Diff, 1, 1, 0, 1) :- Diff < -0.40, !. % Vira a esquerda atirando
decidir_teclas(Diff, 1, 0, 1, 1) :- Diff > 0.40, !.  % Vira a direita atirando
decidir_teclas(_, 1, 0, 0, 1).                       % Alinhado, atira!

% Para evitar erros, o jato para:
obter_controles(_, _, _, [0,0,0,0,0,"nenhuma regra aplicada"]).

% Dica:
% Você pode transformar um vetor com qualquer coisa para string assim:
% term_string(VETOR, MSG).
% Assim, MSG passa a ser uma string do seu vetor
% Ex.:
% ?- term_string([1,2,"teste",oi], MSG.
% MSG = "[1,2,\"teste\",oi]".
