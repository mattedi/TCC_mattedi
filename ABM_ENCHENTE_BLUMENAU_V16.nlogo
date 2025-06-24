;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ABM de Enchentes em NetLogo
;; Simulação para enchentes em uma cidade com edifícios e habitantes
;; TCC - Mattedi - 2024
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

               ;Versão 15

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definição das breeds
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [habitantes habitante]
breed [edificios edificio]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definição das variáveis de cada patch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
patches-own [
  elevacao               ; altimetria (metro quadrado)
  agua-nivel             ; cota (metros quadrados)
  densidade-edilicia     ; DE
  densidade-demografica  ; DD
  centro
  V                      ; Vulnerabilidade
  D                      ; Desastre
  etapa                  ; Etapa da simulação
  derivada-x2  ; Derivada de segunda ordem em relação a x
  derivada-y2  ; Derivada de segunda ordem em relação a y
  ]

habitantes-own [ saude ]  ; Declara a variável 'saude' para os habitantes (grau de impacto)

edificios-own [
  integridade  ; Declara a variável 'integridade' para os edifícios (grau de impacto)
  tipo         ; Variável para o tipo de edifício
  resistencia  ; Resistência estrutural do edifício
]

globals [
  patches-inundados
  habitantes-afetados
  edificios-afetados
  condicao-enchente
  centros
  populacao-total
  lista-edificios
  permeabilidade
  tipos-edificios
  vulnerabilidade-total
  vulnerabilidade-media
  dano-total
  dano-medio
  densidade-demografica-media
  densidade-edilicia-media
  dano-medio-baixa-elevacao
  dano-medio-media-elevacao
  dano-medio-alta-elevacao
  dano-medio-residencial
  dano-medio-comercial
  dano-medio-industrial
  nivel-de-agua
  populacao-afetada
  dias-enchente
  kappa  ; Coeficiente de difusão
  delta  ; Taxa de dano
  epsilon  ; Taxa de recuperação
  dados-espaciais  ; Lista para armazenar os dados espaciais de cada tick
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                                              ;;ENTRADA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configuração do Ambiente (inicialização)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;SETUP
to setup
  ; Limpa o ambiente e inicializa a simulação
  clear-all  ;; Limpa todos os objetos, gráficos e reseta os ticks
  clear-output  ;; Limpa a saída para evitar acúmulo de mensagens anteriores

  ; Inicializa variáveis globais
  inicializar-variaveis-globais

  ; Configuração do terreno
  configurar-centros
  ask patches [
    setup-terreno
    set etapa "Configuração Inicial"
  ]

  ; Configuração de edifícios e habitantes
  distribuir-edificios  ;; Distribui edifícios com base nas regras definidas
  setup-habitantes      ;; Distribui habitantes conforme densidade demográfica

  ; Configurações finais e mensagem de inicialização
  print "Simulação de Enchentes em Blumenau iniciada."
  set dias-enchente 0
  set nivel-de-agua 0
  set populacao-afetada 0

  reset-ticks  ;; Reseta o contador de tempo
end

;INICIALIZAÇÃO DAS VARIAVEIS
to inicializar-variaveis-globais
  ; Define os pesos e parâmetros para o cálculo de vulnerabilidade
  set alfa 1.0  ;; Peso da densidade demográfica
  set beta 1.0  ;; Peso da densidade edilícia
  set gama 1.0  ;; Peso do nível da água
  set δ 1.0     ;; Taxa de dano
  set intensidade-chuva 5  ;; Intensidade da chuva

  ; Define as características iniciais dos edifícios
  set integridade-residencial 10  ;; Resistência inicial para edifícios residenciais
  set integridade-comercial 15   ;; Resistência inicial para edifícios comerciais
  set integridade-industrial 20  ;; Resistência inicial para edifícios industriais

  ; Parâmetros do solo
  set permeabilidade 0.2  ;; Permeabilidade do solo
end

;CONFIGURAÇÃO DOS CENTROS (Declividade)
to configurar-centros
  ; Seleciona patches aleatórios como centros da elevação do terreno
  set centros sort n-of 3 patches  ;; Escolhe 3 patches aleatórios
end

;SET OS EDIFICIOS
to distribuir-edificios
  ; Quantidade de edifícios de cada tipo para garantir a presença de todos
  let num-residencial max list 1 (num-edificios / 3)
  let num-comercial max list 1 (num-edificios / 3)
  let num-industrial max list 1 (num-edificios - num-residencial - num-comercial)

  ; Criando edifícios residenciais em patches com elevação entre 7.5 e 30
  create-edificios num-residencial [
    set tipo "residencial"
    set integridade integridade-residencial
    set resistencia 10  ; Resistência para edifícios residenciais
    set shape "house"
    set color red
    move-to one-of patches with [elevacao >= 7.5 and elevacao <= 25]
  ]

  ; Criando edifícios comerciais em patches com elevação entre 9 e 30
  create-edificios num-comercial [
    set tipo "comercial"
    set integridade integridade-comercial
     set resistencia 15  ; Resistência para edifícios comerciais
    set shape "building store"
    set color blue
    move-to one-of patches with [elevacao >= 9 and elevacao <= 30]
  ]

  ; Criando edifícios industriais em patches com elevação entre 10 e 30
  create-edificios num-industrial [
    set tipo "industrial"
    set integridade integridade-industrial
    set resistencia 20  ; Resistência para edifícios industriai
    set shape "factory"
    set color green
    move-to one-of patches with [elevacao >= 10 and elevacao <= 30]
  ]
   set delta 0.1  ; Taxa inicial de dano
   set kappa 0.1  ; Valor inicial para o coeficiente de difusão
   set epsilon 0.05  ; Taxa inicial de recuperação

  ; Verificação para confirmar a criação dos edifícios
  print (word "Edifícios criados: " count edificios)

end

;SETA OS HABIANTES
to setup-habitantes
  ; Distribui habitantes com base na densidade demográfica
  ask patches with [elevacao >= 7 and elevacao <= 20] [
    set densidade-demografica random 5
    if densidade-demografica > 0 [
      sprout-habitantes densidade-demografica [
        set size 1
        set shape "person student"
        set color yellow
        set saude 10
      ]
    ]
  ]
end

;SETA O TERRENO
to setup-terreno
  ; Configura o ambiente e as características de cada patch
  if member? self centros [
    set centro self  ]
  let centro1 item 0 centros
  let centro2 item 1 centros
  let centro3 item 2 centros
  let dist1 distance centro1
  let dist2 distance centro2
  let dist3 distance centro3
  set elevacao 30 - min (list dist1 dist2 dist3)
  if elevacao < 0 [ set elevacao 0 ]
  set agua-nivel 3
  set pcolor scale-color brown elevacao 30 0
  set V 0  ; Inicializa a vulnerabilidade
  set D 0  ; Inicializa o dano
end

;SETA CHUVA
to ativar-chuva
  ask patches [
    set agua-nivel agua-nivel + intensidade-chuva  ;; Usa o valor da caixa de entrada
  ]
end

;REGISTRA OS DADOS ESPACIAI
to registrar-dados-espaciais
  let tempo ticks
  let dados-atuais []

  ; Garante que dados-atuais será uma lista válida
  ask patches [
    set dados-atuais lput (list pxcor pycor D) dados-atuais
  ]

  ; Adiciona os dados atuais à lista de dados espaciais
  ifelse is-list? dados-espaciais [
    set dados-espaciais lput (list tempo dados-atuais) dados-espaciais
  ] [
    ; Inicializa dados-espaciais como uma lista se não estiver
    set dados-espaciais (list (list tempo dados-atuais))
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                                     ;;CONFIGURAÇÃO DA SIMULAÇÃO

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Definindo o nível de água para tipos de enchente
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to iniciar-enchente-pequeno-porte
  set condicao-enchente "Pequeno Porte"
  setar-nivel-agua 7.5 10.0
end

to iniciar-enchente-medio-porte
  set condicao-enchente "Médio Porte"
  setar-nivel-agua 10.3 13.0
end
to iniciar-enchente-grande-porte
  set condicao-enchente "Grande Porte"
  setar-nivel-agua 13.0 16.0
end
to setar-nivel-agua [min-level max-level]
  ask patches [
    if elevacao < max-level [
      set agua-nivel (random-float (max-level - min-level) + min-level)
      if agua-nivel > elevacao [
        set pcolor blue
      ]
    ]
  ]
end

to aumentar-nivel-agua
  ask patches [
    let aumento 0
    if condicao-enchente = "Pequeno Porte" [
      set aumento intensidade-chuva * (1 - permeabilidade) * (1 / (elevacao + 1))
    ]
    if condicao-enchente = "Médio Porte" [
      set aumento intensidade-chuva * (1 - permeabilidade) * (1 / (elevacao + 1)) * 1.5
    ]
    if condicao-enchente = "Grande Porte" [
      set aumento intensidade-chuva * (1 - permeabilidade) * (1 / (elevacao + 1)) * 2
    ]
    ; Influência da densidade edilícia e demográfica
    set aumento aumento * (1 + (densidade-edilicia + densidade-demografica) / 20)
    set agua-nivel agua-nivel + aumento
    if agua-nivel > elevacao [
      set pcolor blue
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Atualização da cor dos patches
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to atualizar-cores
  ask patches [
    if etapa = "Início da Enchente" [
      set pcolor blue - 2
    ]
    if etapa = "Calculando Vulnerabilidade" [
      set pcolor red - 2
    ]
    if etapa = "Calculando Danos" [
      set pcolor orange - 2
    ]
    if etapa = "Atualizando Visualização" [
      set pcolor green - 2
    ]
    if etapa = "Configuração Inicial" [
      set pcolor scale-color brown elevacao 30 0
    ]
    if etapa != "Início da Enchente" and etapa != "Calculando Vulnerabilidade"
    and etapa != "Calculando Danos" and etapa !=
    "Atualizando Visualização" and etapa != "Configuração Inicial" [
      set pcolor gray
    ]
  ]

  ; Atualiza a cor das tartarugas
  ask habitantes [
    if saude < 5 [
      set color red  ; Pessoas afetadas (saúde baixa) ficam vermelhas
    ]
    if saude >= 5 [
      set color magenta
    ]
  ]
  ask edificios [
    if integridade < 5 [
      set color orange ; Edifícios afetados (integridade baixa) ficam laranja
    ]
    if integridade >= 5 [
      set color yellow
    ]
  ]
end

to atualizar-contagem-afetados
  set patches-inundados count patches with [agua-nivel > elevacao]
  set habitantes-afetados count habitantes with [agua-nivel > elevacao]
  set edificios-afetados count edificios with [agua-nivel > elevacao]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculo das fórmulas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-vulnerability
  ask patches [
    set V alfa * densidade-demografica + beta * densidade-edilicia + gama * agua-nivel
  ]
end

to calculate-spatial-derivatives
  ask patches [
    ; Cálculo das derivadas de segunda ordem (diferenças finitas)
    let dx2 (sum [D] of neighbors4 - 4 * D)  ; Diferença finita no eixo x
    let dy2 (sum [D] of neighbors4 - 4 * D)  ; Diferença finita no eixo y

    ; Armazena o valor no patch
    set derivada-x2 dx2
    set derivada-y2 dy2
  ]
end

to calculate-damage
  ask patches with [agua-nivel > elevacao] [
    ; Calcula o termo de difusão espacial
    let diffusive-term kappa * (derivada-x2 + derivada-y2)
    set D D + (delta * V) - (epsilon * D) + diffusive-term

    ; Atualiza a saúde dos habitantes
    ask habitantes-here [
      set saude saude - (delta * V)
      if saude < 0 [ set saude 0 ]
    ]

    ; Atualiza a integridade dos edifícios
    ask edificios-here [
      set integridade integridade - (delta * V) / resistencia
      if integridade < 0 [ set integridade 0 ]
    ]
  ]
end

to calculate-vulnerability-and-damage
  ask patches [
    ; Suponhamos que a vulnerabilidade (V) é calculada como um exemplo simples:
    set V (alfa * densidade-demografica) + (beta * densidade-edilicia) + (gama * agua-nivel)

    ; Suponhamos que o dano (D) é diretamente proporcional à vulnerabilidade e ao nível da água:
    if agua-nivel > elevacao [
      set D (δ * V)  ; 'delta' aqui é uma taxa de dano que você precisa definir em outro lugar
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                                             ;;SAIDA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculos dos gráficos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to calculate-total-and-average-metrics
  let total_vulnerability sum [V] of patches
  let total_damage sum [D] of patches
  let average_vulnerability mean [V] of patches
  let average_damage mean [D] of patches
  ; Armazenando os valores globalmente para uso em gráficos ou outras análises
  set vulnerabilidade-total total_vulnerability
  set dano-total total_damage
  set vulnerabilidade-media average_vulnerability
  set dano-medio average_damage
end

to calcular-dano-medio-por-tipo
  ;; Calcula o dano médio para edifícios residenciais
  if any? edificios with [tipo = "residencial"] [
    set dano-medio-residencial mean [D] of edificios with [tipo = "residencial"]
  ]
  ;; Calcula o dano médio para edifícios comerciais
  if any? edificios with [tipo = "comercial"] [
    set dano-medio-comercial mean [D] of edificios with [tipo = "comercial"]
  ]
  ;; Calcula o dano médio para edifícios industriais
  if any? edificios with [tipo = "industrial"] [
    set dano-medio-industrial mean [D] of edificios with [tipo = "industrial"]
  ]
end

to calcular-densidades
  ;; Calcula a média da densidade demográfica
  set densidade-demografica-media mean [densidade-demografica] of patches
  ;; Calcula a média da densidade edilícia
  set densidade-edilicia-media mean [densidade-edilicia] of patches
end

to calcular-dano-medio-por-elevacao
  ;; Faixa de elevação baixa (exemplo: elevações entre 0 e 10)
  if any? patches with [elevacao >= 0 and elevacao < 10] [
    set dano-medio-baixa-elevacao mean [D] of patches with [elevacao >= 0 and elevacao < 10]
  ]
  ;; Faixa de elevação média (exemplo: elevações entre 10 e 20)
  if any? patches with [elevacao >= 10 and elevacao < 20] [
    set dano-medio-media-elevacao mean [D] of patches with [elevacao >= 10 and elevacao < 20]
  ]
  ;; Faixa de elevação alta (exemplo: elevações acima de 20)
  if any? patches with [elevacao >= 20] [
    set dano-medio-alta-elevacao mean [D] of patches with [elevacao >= 20]
  ]
end

to atualizar-grafico-dano-por-elevacao
  set-current-plot "Dano Médio por Elevação"
   set-current-plot-pen "Baixa Elevação"
  plotxy 5 dano-medio-baixa-elevacao
   set-current-plot-pen "Média Elevação"
  plotxy 15 dano-medio-media-elevacao
    set-current-plot-pen "Alta Elevação"
  plotxy 25 dano-medio-alta-elevacao
end

to atualizar-grafico-dano-medio
  set-current-plot "Dano Médio por Tipo de Edifício"
  set-current-plot-pen "Dano Residencial"
  plot dano-medio-residencial
  set-current-plot-pen "Dano Comercial"
  plot dano-medio-comercial
  set-current-plot-pen "Dano Industrial"
  plot dano-medio-industrial
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Atualização dos gráficos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to atualizar-graficos

  ;; Gráfico 1: Impactos nos Edifícios (Impactos Totais)
  let integridade-media-residencial mean [integridade] of edificios with [tipo = "residencial"]
  let integridade-media-comercial mean [integridade] of edificios with [tipo = "comercial"]
  let integridade-media-industrial mean [integridade] of edificios with [tipo = "industrial"]

  ;; Gráfico 4: Vulnerabilidade e Danos Totais por Tipo de Edifício
  let vulnerabilidade-total-residencial sum [V] of edificios with [tipo = "residencial"]
  let vulnerabilidade-total-comercial sum [V] of edificios with [tipo = "comercial"]
  let vulnerabilidade-total-industrial sum [V] of edificios with [tipo = "industrial"]

  let dano-total-residencial sum [D] of edificios with [tipo = "residencial"]
  let dano-total-comercial sum [D] of edificios with [tipo = "comercial"]
  let dano-total-industrial sum [D] of edificios with [tipo = "industrial"]

  calculate-total-and-average-metrics  ; Assegure-se de que este procedimento calcula as médias necessárias

  ;; Gráfico 2: Síntese dos Dados
  set-current-plot "Síntese dos dados"
  set-current-plot-pen "População Impactados"
  plot habitantes-afetados
  set-current-plot-pen "Edifícios Impactados"
  plot edificios-afetados
  set-current-plot-pen "Vulnerabilidade Máxima"
  plot max [V] of patches
  set-current-plot-pen "Dano Máximo"
  plot max [D] of patches

  ;;Grafico dano médio por elevação
  set-current-plot "Dano Médio por Elevação"
  ;; Plotando o dano médio para cada faixa de elevação
  set-current-plot-pen "Baixa Elevação"
  plotxy 5 dano-medio-baixa-elevacao  ;; Exemplo: usando o ponto 5 no eixo X para baixa elevação
  set-current-plot-pen "Média Elevação"
  plotxy 10 dano-medio-media-elevacao  ;; Exemplo: usando o ponto 15 no eixo X para média elevação
  set-current-plot-pen "Alta Elevação"
  plotxy 15 dano-medio-alta-elevacao  ;; Exemplo: usando o ponto 25 no eixo X para alta elevação

  ;;Gráfico  dano médio por tipo de edificio
  set-current-plot "Dano Médio por Tipo de Edifício"
  set-current-plot-pen "Dano Residencial"
  plot dano-medio-residencial
  set-current-plot-pen "Dano Comercial"
  plot dano-medio-comercial
  set-current-plot-pen "Dano Industrial"
  plot dano-medio-industrial

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plotagem dos gráficos espaciais
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to atualizar-grafico-impactos-espaciais
  ; Configura o gráfico atual
  set-current-plot "Progressão dos Impactos no Espaço"
  ;clear-plot

  ; Inicializa as variáveis para evitar erros
  let regiao1-dano 0
  let regiao2-dano 0
  let regiao3-dano 0
  let regiao4-dano 0
  let baixa-elevacao-dano 0
  let media-elevacao-dano 0
  let alta-elevacao-dano 0

  ; Calcula os danos por quadrante
  if any? patches with [pxcor < 0 and pycor < 0] [
    set regiao1-dano sum [D] of patches with [pxcor < 0 and pycor < 0]
  ]
  if any? patches with [pxcor >= 0 and pycor < 0] [
    set regiao2-dano sum [D] of patches with [pxcor >= 0 and pycor < 0]
  ]
  if any? patches with [pxcor < 0 and pycor >= 0] [
    set regiao3-dano sum [D] of patches with [pxcor < 0 and pycor >= 0]
  ]
  if any? patches with [pxcor >= 0 and pycor >= 0] [
    set regiao4-dano sum [D] of patches with [pxcor >= 0 and pycor >= 0]
  ]

  ; Calcula os danos por elevação
  if any? patches with [elevacao < 10] [
    set baixa-elevacao-dano sum [D] of patches with [elevacao < 10]
  ]
  if any? patches with [elevacao >= 10 and elevacao < 20] [
    set media-elevacao-dano sum [D] of patches with [elevacao >= 10 and elevacao < 20]
  ]
  if any? patches with [elevacao >= 20] [
    set alta-elevacao-dano sum [D] of patches with [elevacao >= 20]
  ]

  ; Plotando os valores para os quadrantes
  set-current-plot-pen "Quadrante 1"
  plot regiao1-dano
  set-current-plot-pen "Quadrante 2"
  plot regiao2-dano
  set-current-plot-pen "Quadrante 3"
  plot regiao3-dano
  set-current-plot-pen "Quadrante 4"
  plot regiao4-dano

  ; Plotando os valores para as elevações
  set-current-plot-pen "Baixa Elevação"
  plot baixa-elevacao-dano
  set-current-plot-pen "Média Elevação"
  plot media-elevacao-dano
  set-current-plot-pen "Alta Elevação"
  plot alta-elevacao-dano

  print (word "Dano no Quadrante 1: " regiao1-dano)
  print (word "Dano na Baixa Elevação: " baixa-elevacao-dano)

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Plotagem de Mapas de Calor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-vulnerability-heatmap
  ask patches with [agua-nivel > elevacao] [
    set pcolor scale-color red V 0 max [V] of patches
  ]
end
to update-damage-heatmap
  ask patches with [agua-nivel > elevacao] [
    set pcolor scale-color blue D 0 max [D] of patches
  ]
end
to exibir-etapa-nos-patches
  ask patches [
    set plabel etapa
    set plabel-color white ; Ajusta a cor do texto para melhor visibilidade
  ]
end

to update-heatmap-dano
  ask patches [
    set pcolor scale-color red D 0 max [D] of patches
  ]
end

to update-heatmap-dano-blue
  ask patches [
    set pcolor scale-color blue D 0 max [D] of patches
  ]
end

to update-heatmap-dano-red
  ask patches [
    set pcolor scale-color red D 0 max [D] of patches
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedimento principal da simulação = GO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  ; Verifica se é o primeiro tick e inicializa a simulação
  if ticks = 0 [
    ask patches [ set etapa "Início da Enchente" ]
  ]

  ; Atualiza o nível de água
  aumentar-nivel-agua

  ; Calcula vulnerabilidade e danos
  ask patches [ set etapa "Calculando Vulnerabilidade" ]
  calculate-vulnerability
  ask patches [ set etapa "Calculando Danos" ]
  calculate-damage

  ; Atualiza os gráficos principais e contagens
  atualizar-contagem-afetados
  atualizar-graficos

  ; Atualiza visualização de cores e mapas de calor
  ask patches [ set etapa "Atualizando Visualização" ]
  atualizar-cores
  update-vulnerability-heatmap
  update-damage-heatmap

  ; Verifica se atingiu o limite de dias da enchente
  if dias-enchente >= dias-enchente-meta [
    print "Simulação concluída: Atingiu o limite de dias de enchente."
    stop  ;; Para a simulação
  ]

  ; Atualiza métricas e gráficos adicionais
  calculate-vulnerability-and-damage
  calculate-total-and-average-metrics
  calculate-spatial-derivatives
  calcular-densidades
  calcular-dano-medio-por-elevacao
  atualizar-grafico-dano-por-elevacao
  calcular-dano-medio-por-tipo
  atualizar-grafico-dano-medio

  ; Simula a chuva e incrementa as variáveis globais
  ativar-chuva
  set nivel-de-agua nivel-de-agua + 1
  set populacao-afetada populacao-afetada + 5

  ; Registra dados espaciais para análise
  registrar-dados-espaciais

  ; Atualiza o gráfico de impactos espaciais
  atualizar-grafico-impactos-espaciais

  ; Saída de texto para monitoramento
  clear-output  ;; Limpa a saída antes de imprimir
  print (word "Tick atual: " ticks)
  print (word "Nível de Água: " nivel-de-agua)
  print (word "População Afetada: " populacao-afetada)
  print (word "Dano no Quadrante 1: " sum [D] of patches with [pxcor < 0 and pycor < 0])
  print (word "Dano na Baixa Elevação: " sum [D] of patches with [elevacao < 10])

  ; Incrementa o tempo da simulação
  set dias-enchente ticks / 24
  print (word "Dias de Enchente: " dias-enchente)

  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
509
10
1310
812
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-30
30
-30
30
0
0
1
ticks
30.0

BUTTON
39
117
136
150
   -SETUP-   
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
35
476
148
509
Pequeno Porte
iniciar-enchente-pequeno-porte
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
167
476
278
509
  Medio Porte  
iniciar-enchente-medio-porte
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
299
477
418
510
  Grande Porte  
iniciar-enchente-grande-porte
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
162
117
262
150
      -GO-      
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1422
307
1813
427
Dano Médio por Tipo de Edifício
Tempo
Dano Médio
0.0
10.0
0.0
100.0
false
true
"" ""
PENS
"Dano Residencial" 1.0 0 -13840069 true "" " plot dano-medio-residencial"
"Dano Comercial" 1.0 0 -2139308 true "" " plot dano-medio-comercial"
"Dano Industrial" 1.0 2 -16777216 true "" "plot dano-medio-industrial"

SLIDER
32
226
204
259
População
População
100000
500000
168790.0
1
1
NIL
HORIZONTAL

SLIDER
31
547
64
639
alfa
alfa
0
3
1.0
1
1
NIL
VERTICAL

SLIDER
78
548
111
640
beta
beta
0
3
1.0
1
1
NIL
VERTICAL

SLIDER
126
547
159
639
gama
gama
0
3
1.0
1
1
NIL
VERTICAL

SLIDER
173
548
206
640
δ
δ
0
3
1.0
1
1
NIL
VERTICAL

BUTTON
287
118
375
151
Go Rápido
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1427
756
1523
801
Celulas Afetadas
patches-inundados
17
1
11

MONITOR
1728
699
1846
744
População Impactada
habitantes-afetados
17
1
11

MONITOR
1729
755
1843
800
 Edifícios Impactados
edificios-afetados
2
1
11

MONITOR
1531
699
1616
744
  Máximo Vul 
max [V] of patches
2
1
11

MONITOR
1627
698
1709
743
    Média Vul 
mean [V] of patches
2
1
11

MONITOR
1530
756
1617
801
Máximo Dano
max [D] of patches
2
1
11

MONITOR
1627
757
1712
802
  Média Dano
mean [D] of patches
2
1
11

SLIDER
36
319
208
352
horas-impactadas
horas-impactadas
1
500
94.0
1
1
NIL
HORIZONTAL

TEXTBOX
46
82
259
120
1 Comandos de Controle
15
15.0
1

TEXTBOX
34
195
242
233
2 Configuração do Ambiente
15
15.0
1

TEXTBOX
38
443
277
481
3 Dimensionamento do Impacto
15
15.0
1

TEXTBOX
223
552
373
664
alfa = influência de DD em V\n(+DD/patch = +V)\nbeta = Influência de DE em V\n(+DE/patch = +V) \ngama = influência de E em V\n(+agua = +V) \nomega = intensidade de E\n(ESCALA: 1 a 4)
11
15.0
1

TEXTBOX
54
513
135
535
(7.30m - 10.0m)
9
15.0
1

TEXTBOX
184
513
278
531
(10.0m - 13.0m)
10
15.0
1

TEXTBOX
329
514
389
532
(<13.0m)
11
15.0
1

SLIDER
221
226
393
259
saude-inicial
saude-inicial
0
100
74.0
1
1
NIL
HORIZONTAL

SLIDER
220
268
253
420
integridade-residencial
integridade-residencial
0
100
11.0
1
1
NIL
VERTICAL

SLIDER
35
367
207
400
intensidade-chuva
intensidade-chuva
0
200
60.0
1
1
NIL
HORIZONTAL

PLOT
1421
54
1809
174
Síntese dos dados
Tempo
Valores
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"População Impactados" 1.0 0 -2674135 true "" "plot habitantes-afetados"
"Pachts Impactados" 1.0 0 -16777216 true "" "plot patches-inundados"
"Edifícios Impactados" 1.0 0 -13840069 true "" "plot edificios-afetados"
"Vulnerabilidade Máxima" 1.0 0 -13791810 true "" "plot max [V] of patches"
"Dano Máximo" 1.0 0 -987046 true "" "plot max [D] of patches"

SLIDER
33
273
205
306
num-edificios
num-edificios
17000
40000
24000.0
1000
1
NIL
HORIZONTAL

SLIDER
292
269
325
418
integridade-comercial
integridade-comercial
0
100
40.0
1
1
NIL
VERTICAL

SLIDER
360
270
393
419
integridade-industrial
integridade-industrial
0
100
70.0
1
1
NIL
VERTICAL

TEXTBOX
144
30
294
67
ENTRADAS
30
15.0
0

TEXTBOX
1563
10
1713
47
SAÍDAS
30
65.0
1

PLOT
1423
179
1811
299
Vulnerabilidade e Dano Médio
Tempo
Valores
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Vulnerabilidade Média" 1.0 0 -14454117 true "" "plot mean [V] of patches"
"Dano Médio" 1.0 0 -2674135 true "" "plot mean [D] of patches"

PLOT
1425
435
1815
555
Dano Médio Por Elevação
Dano Médio
Fiaxa de Elevação
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Baixa Elevação" 1.0 1 -16777216 true "" "plotxy 5 dano-medio-baixa-elevacao"
"Média Elevação" 1.0 1 -13840069 true "" "plotxy 10 dano-medio-media-elevacao "
"Alta Elevação" 1.0 0 -2674135 true "" "plotxy 15 dano-medio-alta-elevacao "

INPUTBOX
409
227
485
287
iniciar-chuva
140.0
1
0
Number

MONITOR
1427
698
1522
743
dias enchente
dias-enchente
2
1
11

INPUTBOX
408
296
482
356
dias-enchente-meta
1.0
1
0
Number

PLOT
1427
565
1814
685
Progressão dos Impactos no Espaço
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Quadrante 1" 1.0 0 -16777216 true "" "  plot regiao1-dano"
"Quadrante 2" 1.0 0 -13791810 true "" "  plot regiao2-dano"
"Quadrante 3" 1.0 1 -2674135 true "" "  plot regiao3-dano"
"Quadrante 4" 1.0 0 -13840069 true "" "  plot regiao4-dano"
"Baixa Elevação" 1.0 1 -7500403 true "" "plot baixa-elevacao-dano"
"Média Elevação" 1.0 1 -6459832 true "" "plot media-elevacao-dano"
"Alta Elevação" 1.0 1 -1184463 true "" "plot alta-elevacao-dano"

@#$#@#$#@
## WHAT IS IT?

The Urban Flood Impact Simulation Model

## HOW IT WORKS

The model operates with three agents (Demographic Density (inhabitants), Building Density (structures), and Flood) that communicate indirectly through the patches. 
The impact of floods can be formally modeled as follows:  
a) **Specification of Agents**: Demographic Density (DD), Building Density (BD), and Flood (F) (Table 2).  
b) **Local Interaction**: High DD and BD are more vulnerable to impacts because they affect the propagation of water, increasing the magnitude of the impact; vulnerability to impacts causes damage to both DD and BD.  
c) **Emergence**: Formation of scenarios B, C, and D, as summarized in Figure 8. From the local interaction among agents, the emergence of spatial damage patterns can be observed, such as more and less affected areas. This means that the flood (F) propagates according to elevation levels (topography) and building density (BD). In this context, vulnerability (V) increases with demographic density (DD), building density (BD), and flood level (F). Therefore, damage (D) increases with vulnerability (V), which tends to decrease over time.

**Formalization of Variables**:  
- **DD(x, y, t)**: Demographic density at position (x, y) at time t.  
- **BD(x, y, t)**: Building density at position (x, y) at time t.  
- **F(x, y, t)**: Flood level at position (x, y) at time t.  
- **V(x, y, t)**: Vulnerability to impacts at position (x, y) at time t.  
- **D(x, y, t)**: Damage at position (x, y) at time t.

**Parameter Definitions**:  
- **α**: Impact of DD on vulnerability.  
- **β**: Impact of BD on vulnerability.  
- **γ**: Impact of F on vulnerability.  
- **δ**: Impact of vulnerability on damage.  
- **ε**: Damage recovery rate.  
- **k**: Coefficient of spatial diffusion.  
- **t**: Temporal variable.  
- **∂**: Partial derivative.

The integration of these variables and parameters allows for the formalization of the ABM (Agent-Based Model) for flood impact in Blumenau in the following equations:  
1. **V(x, y, t) = α ⋅ DD(x, y, t) + β ⋅ BD(x, y, t) + γ ⋅ F(x, y, t)**  
2. **(∂D(x, y, t))/∂t = δ ⋅ V(x, y, t) - ε ⋅ D(x, y, t) + k ((∂²D(x, y, t))/∂x² + (∂²D(x, y, t))/∂y²))**

Equation (2) describes the rate of change of D at spatial position (x, y) over time t. It integrates both temporal and spatial variations.  
- The term **δ ⋅ V(x, y, t)** represents the increase in damage due to local vulnerability.  
- The term **ε ⋅ D(x, y, t)** models the reduction in damage due to recovery.  
- The term **k ((∂²D(x, y, t))/∂x² + (∂²D(x, y, t))/∂y²))** represents the spatial diffusion of damage.

Thus, the first equation models how local vulnerability is affected by DD, BD, and F. The second equation describes how damage evolves over time and space, integrating the effects of vulnerability, recovery, and spatial diffusion.

**Operational Terms**:  
An agent constitutes computational entities with properties or state variables. These state variables may include values such as position, velocity, age, wealth, flood levels, etc. A computational simulation, therefore, is a model that takes certain input values (computational entities), processes these inputs algorithmically (agent-based model), and produces outputs (scenarios). According to best simulation practices, agent-based models are more useful when there is a medium to large number (dozens to millions) of interacting agents and when agents are less homogeneous (two or more types of agents). Consequently, any modeling or simulation environment faces a trade-off: more detailed results and better-calibrated models depend on agent growth and heterogeneity; however, increasing the number and diversity of agents inevitably requires greater computational resources. This means that the more detailed a model is, the more modeling decisions must be processed.

## HOW TO USE IT

The inputs represent the initial variables and configurations necessary to run the simulation (**Model Configuration Parameters, Flood Type, Distribution of Buildings and Inhabitants**). The processing comprises a set of calculations and interactions that occur during the simulation loop (**Terrain Configuration [Patch], Vulnerability Distribution and Damage Calculation [Vulnerability Calculation, Damage Calculation], Interaction of Inhabitants, Monitoring by the Observer**). Finally, the outputs represent the results and data generated throughout and at the end of the simulation (**Count of Impacted Elements [flooded patches, affected buildings, affected inhabitants], Final State of the Inhabitants, Impact Visualization, Data for Further Analysis**).  

In summary, the simulation begins with the initial configurations of the environment and agents, performs calculations for vulnerability and damage based on the interactions of inhabitants with the environment, and outputs the quantity of affected buildings and inhabitants. An essential implementation that conditions the simulation pertains to the characterization of space. In Agent-Based Models (ABMs), space serves three main purposes: (1) it contains the agents; (2) it defines the spatial relationships between agents; and (3) it controls their movements. In this sense, the space can vary from abstract, represented by cells in a 2D space through a graphical interface, to geographically explicit, using either vector or raster data structures.  

For this implementation, the simulation is based on a **cell-based model**. In cell-based models, space is discretized into a grid of patches, each representing a unit of space, such as a square in a two-dimensional plane, as illustrated in **Figure 13**, which is subdivided into three regions: (i) input controls, (ii) simulation area, and (iii) output monitors. The procedure creates terrain with elevations based on three random centers through elevation. The elevation of each patch is calculated based on the distance from these centers, influencing its color. Additionally, the procedure initializes variables used later in the simulation to control the vulnerability and damage of the terrain.  

Although the configuration seems simple, it enables highly powerful simulation capabilities. Considering only the **default panel configuration** (with 13 panel controls) illustrated in **Figure 13**, more than six million possible combinations can be generated. Moreover, six controls are calibrated with continuous variables, allowing the construction of an infinite number of possible scenarios and, consequently, the testing of a large number of hypotheses. For **alpha, beta, gamma, and σ**, we defined four intensity levels (**1, 2, 3, 4**); for flood impacts, four levels (**Small, Medium, Large**) were set, with varying durations (**1, 3, 10 days**). For population (DD) and buildings (DE), five periods were defined (**census years of 1980, 1990, 2010, 2022, and the projection for 2030**). Furthermore, we included rainfall intensity, slope, health, and integrity. Based on this configuration, for each census year, three simulations were performed for floods of Small, Medium, and Large scale, considering the parameters **alpha, beta, gamma, and σ (1, 2, 3, 4)**, and for **1, 3, and 10 days impacted**, with calibration for rainfall intensity and slope, generating a virtually infinite range of possible relationships.


## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
4
Circle -7500403 true false 110 5 80
Polygon -7500403 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true false 127 79 172 94
Polygon -7500403 true false 195 90 240 150 225 180 165 105
Polygon -7500403 true false 105 90 60 150 75 180 135 105

person student
false
4
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true false 195 90 240 195 210 210 165 105
Circle -7500403 true false 110 5 80
Rectangle -7500403 true false 127 79 172 94
Polygon -7500403 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true false 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
