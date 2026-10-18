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

% 1 REGRA DESVIAR DE MISSEIS - Se algum míssil entrar no raio de alcance, o jato vira imediatamente.
obter_controles(INFORMACAO, _ADVERSARIOS, MISSEIS, CONTROLES) :-
    INFORMACAO = [X, Y, _Ang, _Score, _Speed],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    existe_perigo(X, Y, MISSEIS, 65),
    
    FORWARD is 1,
    REVERSE is 0,
    LEFT is 0,
    RIGHT is 1, % manobra evasiva virando para a direita
    BOOM is 0,
    MSG = "Desviando de missil proximo",
    !.


% 2 REGRA PARA SAIR DO ALCANCE DE OUTROS JATOS - Se um jato inimigo estiver muito perto, muda a rota para sair do alcance dele
obter_controles(INFORMACAO, ADVERSARIOS, _MISSEIS, CONTROLES) :-
    INFORMACAO = [X, Y, _Ang, _Score, _Speed],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    % Raio menor que o dos mísseis (50px)
    existe_perigo(X, Y, ADVERSARIOS, 50),
    
    FORWARD is 1,
    REVERSE is 0,
    LEFT is 1,  % vira para a esquerda, para fazer um zigue-zague
    RIGHT is 0,
    BOOM is 1, % ataque defensivo
    MSG = "Evitando estar no raio de ataque do jato proximo",
    !.

% 3 REGRA DE ATAQUE PARA PERSEGUIR E ATIRAR NO JATO MAIS PRÓXIMO - Só acontece se as demais regras não forem acionadas, se o caminho estiver livre de mísseis e choques imediatos.
obter_controles(INFORMACAO, ADVERSARIOS, _MISSEIS, CONTROLES) :-
    INFORMACAO = [X, Y, AnguloAtual, _Score, _Speed],
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    
    % Verifica se ainda existem inimigos no radar
    ADVERSARIOS \= [],
    
    % Encontra as coordenadas do alvo mais perto
    menor_distancia(X, Y, ADVERSARIOS, AlvoX, AlvoY, _Dist),
    
    % Calcula diferenca angular e escolhe os comandos
    calcular_manobra(X, Y, AnguloAtual, AlvoX, AlvoY, FORWARD, LEFT, RIGHT, BOOM),
    
    REVERSE is 0,
    MSG = "Caçando e atacando o jato mais proximo",
    !.


% 4 REGRA PARA FICAR VOANDO EM CIRCULOS ATE ENCONTRAR ALGUM JATO PROXIMO - Ativada apenas se os jatos estiverem longe.
obter_controles(_INFO, _ADVERSARIOS, _MISSEIS, CONTROLES) :-
    CONTROLES = [FORWARD, REVERSE, LEFT, RIGHT, BOOM, MSG],
    FORWARD is 1,
    REVERSE is 0,
    LEFT is 0,
    RIGHT is 1, % voo em circulos para nao ficar parado
    BOOM is 0,
    MSG = "Patrulha: nenhum alvo restante".

% Para evitar erros, o jato para:
obter_controles(_, _, _, [0,0,0,0,0,"nenhuma regra aplicada"]).


% PREDICADOS AUXILIARES

% Caso base: lista vazia significa que nenhum perigo está no raio.
existe_perigo(_, _, [], _) :- fail.

% Passo recursivo 1: a cabeca da lista esta dentro do raio?
existe_perigo(X, Y, [[Mx, My] | _], Raio) :-
    Dist is sqrt((Mx - X)^2 + (My - Y)^2),
    Dist < Raio, !. % Encontrou um perigo, encerra a busca

% Passo recursivo 2: se a cabeca estava longe, continua testando a cauda.
existe_perigo(X, Y, [_ | Cauda], Raio) :-
    existe_perigo(X, Y, Cauda, Raio).


% BUSCA DO ALVO MAIS PRÓXIMO
% Caso base: lista com um unico adversario.
menor_distancia(X, Y, [[Ax, Ay]], Ax, Ay, Dist) :-
    Dist is sqrt((Ax - X)^2 + (Ay - Y)^2), !.

% Passo recursivo: divide a lista em cabeca e cauda, calcula a menor da cauda
% e depois compara quem tem menor distancia usando o predicado escolher_menor
menor_distancia(X, Y, [[Ax1, Ay1] | Cauda], MelhorX, MelhorY, MenorDist) :-
    menor_distancia(X, Y, Cauda, Ax2, Ay2, Dist2),
    Dist1 is sqrt((Ax1 - X)^2 + (Ay1 - Y)^2),
    escolher_menor(Ax1, Ay1, Dist1, Ax2, Ay2, Dist2, MelhorX, MelhorY, MenorDist).

% Se Dist1 for estritamente menor, unifica o primeiro alvo e corta.
escolher_menor(Ax1, Ay1, Dist1, _, _, Dist2, Ax1, Ay1, Dist1) :-
    Dist1 < Dist2, !.
% Caso contrario, unifica o segundo alvo.
escolher_menor(_, _, _, Ax2, Ay2, Dist2, Ax2, Ay2, Dist2).


% CÁLCULO DE MIRA E TRAJETÓRIA ---
% Caso particular: se o jato estiver exatamente nas mesmas coordenadas do alvo.
calcular_manobra(X, Y, _, AlvoX, AlvoY, 1, 0, 0, 1) :-
    X =:= AlvoX, Y =:= AlvoY, !.

calcular_manobra(X, Y, AnguloAtual, AlvoX, AlvoY, 1, LEFT, RIGHT, BOOM) :-
    Dx is AlvoX - X,
    Dy is AlvoY - Y,
    
    % atan2(Dy, Dx) devolve o angulo em relacao ao eixo horizontal
    AnguloMat is atan2(Dy, Dx),
    
   % (pi/2)
    AnguloJogo is AnguloMat + (pi / 2),
    
    ajustar_intervalo_2pi(AnguloJogo, AnguloNormalizado),
    
    Diff is AnguloNormalizado - AnguloAtual,
    ajustar_intervalo_pi(Diff, DeltaFinal),
    
    acionar_comandos(DeltaFinal, LEFT, RIGHT, BOOM).

% Mantém o ângulo dentro do círculo trigonométrico [0, 2*pi)
ajustar_intervalo_2pi(A, Res) :- A < 0, !, Res is A + (2 * pi).
ajustar_intervalo_2pi(A, Res) :- A >= (2 * pi), !, Res is A - (2 * pi).
ajustar_intervalo_2pi(A, A).

% Garante que a diferenca angular fique entre -pi e pi para pegar o caminho mais curto
ajustar_intervalo_pi(D, Res) :- D < -pi, !, Res is D + (2 * pi).
ajustar_intervalo_pi(D, Res) :- D > pi, !, Res is D - (2 * pi).
ajustar_intervalo_pi(D, D).

% --- SELEÇÃO DE TECLAS ---
% Margem de 0.35 radianos para estabilizar o voo e atirar continuamente
acionar_comandos(Delta, 1, 0, 1) :- Delta < -0.35, !. % Curva para a esquerda atirando
acionar_comandos(Delta, 0, 1, 1) :- Delta > 0.35, !.  % Curva para a direita atirando
acionar_comandos(_, 0, 0, 1).

% Dica:
% Você pode transformar um vetor com qualquer coisa para string assim:
% term_string(VETOR, MSG).
% Assim, MSG passa a ser uma string do seu vetor
% Ex.:
% ?- term_string([1,2,"teste",oi], MSG.
% MSG = "[1,2,\"teste\",oi]".
