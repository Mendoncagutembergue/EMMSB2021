# Simulação de enovelamento de proteínas e efeitos de solvente

IDEIAS INICIAIS -PRECISA ORGANIZAR E CHECAR ALGUMAS INFORMAÇÕES

## 1. Iniciando as simulações

Existem inputs prontos para simulação do peptídeo `(AAQAA)3` com água e TFE: `0%v/v` e `60%v/v` de TFE. O diretório onde os arquivos de input estão no diretória que será definido pela variável `XEMMSB_dir_MD`. Por exemplo:

```
XEMMSB_dir_MD=/home/leandro/Drive/Disciplinas/XEMMSB2021/Simulation/INPUTS/AAQAA_60vv
```
Redefina esta variável para instalar no diretório de sua preferência.

A simulação pode ser iniciado fazendo apenas:
```
./run-md.sh $XEMMSB_dir_MD
```
O script run-md.sh irá realizar todas as etapas da simulação para o sistema com `60%v/v` de TFE:

* [Minimização do sistema](#min)
* [Equilibração da temperatura e da pressão](#equi)
* [Produção - HREMD](#prod)



## 2. Descrição dos arquivos de input



```
# creating the box and the topology
julia input-tfe-100%.jl
cp topol_new.top topol.top
rm topol_new.top
packmol < box.inp

# Generation of the unprocessed topology
#echo 1 | gmx_mpi pdb2gmx -f system.pdb -o model1.gro -p topol.top -ff amber03w -ignh

# Minimization tpr file and processed topology creation
gmx_mpi grompp -f mim.mdp -c system.pdb -p topol.top -o minimization.tpr -pp processed.top -maxwarn 1
```


O arquivo `input-tfe-60.jl` cria um arquivo de input para o [Packmol](http://leandro.iqm.unicamp.br/m3g/packmol/home.shtml) que irá criar um caixa cúbica com seus lados medindo `56 Angstrons`, além de moléculas de água e TFE para que haja um solução de 60 %v/v de TFE. As quantidades de cada molécula podem ser verificadas no arquivo `box.inp`.

Para criar a caixa usando o packmol basta fazer:
```
packmol < box.inp
```

O output do comando acima será o arquivo `system.pdb`. Este pdb contém o sistema montado e pode ser visualizado por meio de softwares como o `vmd` e o `PyMOL`

-------------- aqui eu tenho que descrever todos os arquivos até a topologia
O arquivo system.pdb será, assim, um dos inputs para que as simulações sejam iniciadas. O próximo passo, portanto, será a construção do arquivo de topologia. No diretório `XEMMSB_dir_MD` há o arquivo `processed.top` que será o arquivo utilizado como topologia para as diferentes réplicas. Alguns pontos merecem atenção aqui.

Primeiramente, o arquivo de topologia deve contar os parâmetros para a água, a proteína e o tfe. 

[plumed](https://www.plumed.org/doc-v2.6/user-doc/html/hrex.html)



----------------------------------------

[gromacs_simulations](http://www.mdtutorials.com/gmx/lysozyme/01_pdb2gmx.html)

### <a name="min"></a>Minimização do sistema
Agora que os arquivos iniciais estão organizadas,podemos partir para a etapa de minimização. Precisamos criar um aquivo tpr para o gromacs. O arquivo Tpr é um binário usado para iniciar a simulação. O Tpr contém informações sobre a estrutura inicial da simulação, a topologia molecular e todos os parâmetros da simulação (como raios de corte, temperatura, pressão, número de passos, etc.).

O arquivo tpr da nossa minimização utilizará o arquivo topol.top. Como a atual etapa compreende a minimização, o arquivo mim.mdp (que possui todos os parâmetros para realizar um minimização) também deverá ser utilizado. Assim, para criar o arquivo tpr, usamos o comando:

```
gmx_mpi grompp -f mim.mdp -c system.pdb -p topol.top -o minimization.tpr -pp processed.top -maxwarn 1
```
Agora temos o arquivo minimization.tpr, para realizar a minimização usamos o comando:

```
gmx_mpi mdrun -s minimization.tpr -v -deffnm minimization

```
A minimização terá finalizado quando for printado no prompt:

![Alt Text](https://github.com/m3g/XEMMSB2021/blob/main/Simulation/figs/fim_minimizacao.png)

Agora, temos os seguintes arquivos:

* [minimization.gro]: Coordenadas do sistema minimizado. 
* [minimization.edr]: Arquivo binário da energia do sistema.
* [minimization.log]: Arquivo de texto ASCII do processo de minimização. 
* [minimization.trr]: Arquivo binário da trajetória (alta precisão).

Para a continuação da simulação, vamos utilizar o aquivo `minimization.gro`

### <a name="equi"></a>Equilibração da temperatura e da pressão

Como você deve ter notado, apenas uma minimização foi feita. Agora, faremos alterações no arquivo de topologia para realizar simulações de equilibração nos ensembles NVT e NPT.

Vamos, agora, utilizar arquivo processed.top gerado na criação do arquivo minimization.tpr. As simulações serão realizadas na temperatuda de 300 K e 1 bar. Sendo assim, é necessário abrir os arquivos nvt.mpr, npt.mdp e prod.mdp e alterar a variável REFT por 300. Vamos, agora, copiar todos os arquivos mdp para cada 4 pastas diferentes. Cada pasta representa um replicata que será simulada usando um hamiltoniano diferente (obs: o arquivo prod.mdp será usado na etapa final).

Assim, para copiar os arquivos fazemos:
```
echo {0..3} | xargs -n 1 cp nvt.mdp npt.mdp prod.mdp plumed.dat
```
O próximo passo, agora é escalonar a temperatura de acordo com os hamiltonianos.
Esse "escalonamento" consiste em multiplicar os parâmetros do campo força por um fator entre 0 e 1.

Aqui vamos usar 4 hamiltonianos: 1.0, 0.96, 0.93, 0.89 .


Nesta etapa, é importante selecionar os átomos que irão ser escalonados. Para isso, adicionamos um underline na frente dos átomos que queremos "aquecer". Na simulações tratadas neste curso, os átomos que serão escolonados são aqueles que compõem o poliptídeo.

Se você digitar `vi processed.top` e procurar pela proteína, encontrará o seguinte:
```
[ moleculetype ]
; Name            nrexcl
Protein_chain_X     3

[ atoms ]
;   nr       type  resnr residue  atom   cgnr     charge       mass  typeB    chargeB      massB
; residue   1 ALA rtp NALA q +1.0
     1         N3     1    ALA      N      1     0.1414      14.01
     2          H     1    ALA     H1      2     0.1997      1.008
     3          H     1    ALA     H2      3     0.1997      1.008
     4          H     1    ALA     H3      4     0.1997      1.008

```

O que precisa ser feito é adicionar _ na frente do nome de cada átomo, assim:


```

[ moleculetype ]
; Name            nrexcl
Protein_chain_X     3

[ atoms ]
;   nr       type  resnr residue  atom   cgnr     charge       mass  typeB    chargeB      massB
; residue   1 ALA rtp NALA q +1.0
     1         N3_     1    ALA      N      1     0.1414      14.01
     2          H_     1    ALA     H1      2     0.1997      1.008
     3          H_     1    ALA     H2      3     0.1997      1.008
     4          H_     1    ALA     H3      4     0.1997      1.008


```
Feito isso, devemos escalonar as topologias que serão usadas para as diferentes réplicas.

```
cd $XEMMSB_dir_MD/0
plumed partial_tempering 1.0 < processed.top > topol0.top
cd $XEMMSB_dir_MD/1
plumed partial_tempering 0.96 < processed.top > topol1.top
cd $XEMMSB_dir_MD/2
plumed partial_tempering 0.93 < processed.top > topol2.top
cd $XEMMSB_dir_MD/3
plumed partial_tempering 0.89 < processed.top > topol3.top
   
```

O método que está sendo utilizado consiste em uma simulação de dinâmica molecular com amostragem conformacional ampliada. Basicamente, os potências de interação intramolecular e proteína solvente são multiplicados por um fator chamado hamiltoniano, comumentemente representado pela letra grega &lambda; .Desta forma, a multiplicação dos potênciais pelo &lambda fará com que o sistema possua uma temperatura efetiva Ti. 
O fator de escalonamento &lambada; e as temperaturas efetivas Ti da i-ésima réplica são dados por: 

<img src="https://render.githubusercontent.com/render/math?math=\lambda_{i} =\frac{ T_{0}}{T_{i}}=exp(\frac{-i}{n-i} \ln(\frac{T_{max}}{T_{0}}))">

(ajustar latex)
onde &lambda;i é o faotr de escalonamento da i-ésima replicata, n é o número de replicatas, Ti é a temperatura efetiva, T0 é a temperatura inicial e Tmax é a temperatura máxima efetiva.


Temos, então, 4 simulações diferentes (uma simulação para cada réplica). Contudo, para as análises apenas a réplica de menor grau será utilizada (`&lambda; = 1`). No nosso método, a tentativa de trocas entre réplicas vizinhas ocorre a cada 400 passos da simulação (etapa de produção).


Feito o escalonamento das topologias e com todos os arquivos em seus respectivos diretórios, vamos criar o arquivo tpr que irá iniciar uma equilibração de 1 ns no ensemble NVT para cada replicata.

```
for i in 0 1 2 3; do
  gmx_mpi grompp -f $i/nvt$i.mdp -c minimization.gro  -p $i/topol$i.top -o $i/canonical.tpr -maxwarn 1
done

```
A flag -maxwarn serve para ignorar os avisos que o gromacs dá. Muitos desses avisos são coisas que não tem impacto nenhum na simulação. Entretanto, é recomendado rodar, na primeira vez, sem essa flag para observar o que o gromacs está reportando. ALguns dos avisos podem ser potencialmente danosos para sua simulação, como, por exemplo, um sistema que não está eletricamente neutro. Mais informações podem ser obtidas em [Errors](https://www.gromacs.org/Documentation_of_outdated_versions/Errors).

Agora que todos os arquivos tpr foram gerados, podemos iniciar a simulação da equilibração NVT fazendo:

```
mpirun -np 4 gmx_mpi mdrun -s canonical.tpr -v -deffnm canonical -multidir 0 1 2 3

```
A flag -np indica o número de processos que serão iniciados. Neste caso, cada processo terá uma réplica. O mpi fará a distribuição de processadores disponíveis para cada processo automaticamente.

#Colocar alguma coisa para as pessoas saberem se a simulação terminou

A etapa de equilibração NPT usa, essencialmente, os mesmos comandos, apenas alterando os inputs:

```
for i in 0 1 2 3; do
  gmx_mpi grompp -f $i/npt$i.mdp -c canonical.gro  -p $i/topol$i.top -o $i/isobaric.tpr -maxwarn 1
done


```
Após os arquivos `isobaric.tpr` serem criados (em cada pasta da réplica deve haver um arquivo `isobaric.tpr`), vamos usar o comando abaixo para realizar a equilibração da temperatura:


```
mpirun -np 4 gmx_mpi mdrun -s canonical.tpr -v -deffnm canonical -multidir 0 1 2 3
```


### <a name="prod"></a>Produção - HREMD

Agora, com a minimização e as equilibrações finalizadas, podemos então criar os arquivos tpr para as simulações de produção.

```
for i in 0 1 2 3; do
  gmx_mpi grompp -f $i/prod$i.mdp -p $i/topol$i.top -c $i/isobaric.gro  -o $i/production.tpr -maxwarn 1
done
```

Assim, a simulação será feita usando o comando:


```
 mpirun -np $rep gmx_mpi mdrun -plumed plumed.dat -s production.tpr -v -deffnm production -multidir 0 1 2 3  -replex 400 -hrex -dlb no
```

O comando acima possui alguns detalhes importantes que valhem a pena ser mencionados. Primeiramente





## 3. Verificação dos resultados

































































































































































































