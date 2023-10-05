# Método de versionamento 

O Versionamento Semântico fornece um sistema claro e consistente para gerenciar versões de software, facilitando a comunicação de mudanças e garantindo a compatibilidade com versões anteriores. As releases da RBB seguem o _semantic versioning_, cujo guia completo pode ser encontrado neste link (https://semver.org). 


## Regras de versionamento

**Declaração de API Pública**
* Software usando Versionamento Semântico DEVE declarar uma API pública. _A definição de API depende do caso, mas no geral, é uma biblioteca, aplicativo ou software que fornece funcionalidades para uso externo._

**Formato de versão**
* Um número de versão normal DEVE ter o formato de X.Y.Z, onde X, Y e Z são inteiros não negativos, e NÃO DEVE conter zeros à esquerda.
* Quando um software está na versão 0.x.x, ele geralmente está em desenvolvimento inicial ou está passando por testes iniciais. Isso significa que o software ainda não atingiu um estado estável ou uma API pública bem definida.
* X é a versão Major, Y é a versão Minor, e Z é a versão de Patch. 
* Versão Maior X (X.y.z | X > 0) DEVE ser incrementada se forem introduzidas mudanças incompatíveis na API pública. PODE incluir alterações a nível de versão Menor e de versão de Correção. Versão de Correção e Versão Menor DEVEM ser redefinidas para 0(zero) quando a versão Maior for incrementada.]
* Versão Menor Y (x.Y.z | x > 0) DEVE ser incrementada se uma funcionalidade nova e compatível for introduzida na API pública. DEVE ser incrementada se qualquer funcionalidade da API pública for definida como descontinuada. PODE ser incrementada se uma nova funcionalidade ou melhoria substancial for introduzida dentro do código privado. PODE incluir mudanças a nível de correção. A versão de Correção DEVE ser redefinida para 0(zero) quando a versão Menor for incrementada.
* Versão de Correção Z (x.y.Z | x > 0) DEVE ser incrementado apenas se mantiver compatibilidade e introduzir correção de bugs.
* No contexto do versionamento semântico, as "builds" são um campo opcional na versão que pode ser usado para incluir informações adicionais. Então, a estrutura de uma versão com build é **MAJOR.MINOR.PATCH+BuildMetadata**. Estão sendo usadas para marcar implementações intermediárias com a data de criação da release. Exemplo: _1.1.0+2023-02-30_.

* Cada elemento DEVE aumentar numericamente.
* Versão 1.0.0 define a API como pública. A maneira como o número de versão é incrementado após este lançamento é dependente da API pública e como ela muda.

**Imutabilidade das versões**
* Uma vez que um pacote versionado foi lançado (released), o conteúdo desta versão NÃO DEVE ser modificado. Qualquer modificação DEVE ser lançado como uma nova versão.

## Dinâmica

* A branch _main_ é a padrão. Ela deve ser protegida de novas alterações diretas, ou seja, qualquer nova funcionalidade deverá ser primeiro implantada em outra branch.
* Após a implementação e testes da nova funcionalidade, deverá ser feito um _pull request_.
* Releases após o _pull request_ são opcionais, porém desejáveis. Devem ser geradas a partir da branch _main_.
* Para o tratamento de incidentes, haverá a recuperação de uma release antiga e estável para outra branch, conserto da funcionalidade quebrada e enfim o _pull request_ para a main novamente, com a geração de uma nova release.
* Na criação de releases, deve-se ter em mente os recursos que serão usados por outros repositórios. As _Actions_ geram artefatos nas releases. A importação desses recursos se dá no yarn install.

 
