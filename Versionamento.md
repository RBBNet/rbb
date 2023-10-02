# Método de versionamento 

As releases do Permissionamento seguem o _semantic versioning_, cujo guia completo pode ser encontrado neste link (https://semver.org). 

Por motivos de praticidade, esse arquivo contém um guia menor e resumido de versionamento, e como estamos utilizando ele.

## Regras de versionamento

* Software usando Versionamento Semântico DEVE declarar uma API pública. _Estamos considerando a API pública como sendo as ABIs dos contratos._ **Na verdade, no caso do repositório Permissionamento, a API são as ABI, mas isso é um caso específico. Acredito que é melhor explicitar aqui nesse .md que a definição de API depende do caso concreto e, lá no repositório Permissionamento e em todos aqueles que passarem a usar versionamento, além de apontar para esse .md, especificar qual é a API naquele caso específico. **
* Um número de versão normal DEVE ter o formato de X.Y.Z, onde X, Y, e Z são inteiros não negativos, e NÃO DEVE conter zeros à esquerda. X é a versão Maior, Y é a versão Menor, e Z é a versão de Correção. **Prefiro usar os termos em inglês, nesse caso: Major, Minor e Patch**
Cada elemento DEVE aumentar numericamente. _Pelo entendimento, a branch **migrations** ficou como 1.0.1, como um patch de correção, apesar de adicionar outras funcionalidades. Em tese, ela seria a 1.1.0._ **A versão não é da branch e, sim, de um release**
* Uma vez que um pacote versionado foi lançado(released), o conteúdo desta versão NÃO DEVE ser modificado. Qualquer modificação DEVE ser lançado como uma nova versão.
* Versão 1.0.0 define a API como pública. A maneira como o número de versão é incrementado após este lançamento é dependente da API pública e como ela muda. _A versão 1.0.0 é a usada na rede de Laboratório, com a release **v1.0.0+lab01-backend**._
* Versão de Correção Z (x.y.Z | x > 0) DEVE ser incrementado apenas se mantiver compatibilidade e introduzir correção de bugs.
* Versão Menor Y (x.Y.z | x > 0) DEVE ser incrementada se uma funcionalidade nova e compatível for introduzida na API pública. DEVE ser incrementada se qualquer funcionalidade da API pública for definida como descontinuada. PODE ser incrementada se uma nova funcionalidade ou melhoria substancial for introduzida dentro do código privado. PODE incluir mudanças a nível de correção. A versão de Correção DEVE ser redefinida para 0(zero) quando a versão Menor for incrementada.
* Versão Maior X (X.y.z | X > 0) DEVE ser incrementada se forem introduzidas mudanças incompatíveis na API pública. PODE incluir alterações a nível de versão Menor e de versão de Correção. Versão de Correção e Versão Menor DEVEM ser redefinidas para 0(zero) quando a versão Maior for incrementada.
* Por motivos de praticidade e melhora no entendimento, a build é nomeada a partir da data de lançamento da release. Exemplo: _v1.0.1+2023-09-28_. **Comentar, no repositório de Permissionamento, que iniciamos de forma diferente, mas padronizamos assim a partir dessa release***
