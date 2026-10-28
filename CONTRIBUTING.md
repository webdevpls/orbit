# Como contribuir com o Orbit

Obrigado por ajudar a melhorar o Orbit!

## Relatando bugs

[Abra uma issue](https://github.com/webdevpls/orbit/issues/new?template=bug_report.md) e inclua:

- A versão do macOS e o modelo do Mac (Apple silicon ou Intel)
- A marca e o modelo do mouse, e se algum app do fabricante (Logi Options+, Razer Synapse…) está aberto
- O que você fez, o que esperava e o que aconteceu

Logs ajudam. Rode o Orbit pelo Terminal e anexe o que aparecer:

```sh
pkill -x Orbit; /Applications/Orbit.app/Contents/MacOS/Orbit 2>&1 | tee ~/Desktop/orbit.log
```

## Sugerindo recursos

[Sugira um recurso](https://github.com/webdevpls/orbit/issues/new?template=feature_request.md).
Descreva primeiro o problema e depois a solução que você imagina.

## Pull requests

1. Faça um fork do repositório e crie uma branch a partir da `main`.
2. Compile com `./scripts/build-app.sh` e teste a mudança no app de verdade, com o mouse.
3. Siga o estilo dos arquivos ao redor: SwiftUI, views pequenas, comentários só onde o motivo não é óbvio.
4. O callback do event tap (`InputMonitor.handle`) roda em cada movimento do mouse: mantenha ele rápido e nunca bloqueie.
5. Textos novos da interface entram em inglês no código e com tradução em `Resources/pt-BR.lproj/Localizable.strings`.
6. Explique o que mudou e como você testou.

Ao contribuir, você concorda que a sua contribuição é licenciada sob a [GPL-3.0](LICENSE).
