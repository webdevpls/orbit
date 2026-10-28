# Orbit

Anel radial de apps para o macOS, na barra de menus. Clique no scroll do mouse e um anel de Liquid Glass
aparece no cursor com até 8 apps, sites, pastas, Atalhos ou ações do sistema.

## Como usar

- **Segurar e soltar:** segure o botão do scroll, aponte para um item e solte.
- **Clicar e escolher:** dê um clique rápido no scroll; o anel fica aberto. Clique num item (ou fora para fechar).
- **Teclado:** `⌥ Space` abre o anel no cursor. Com o anel aberto: `1`–`8` abrem direto, setas/scroll navegam,
  `Return` abre, `Esc` fecha.

Configure tudo pelo ícone na barra de menus: clique num item do anel para trocar, mover ou remover; o centro adiciona.
Em Ajustes dá para trocar o botão (scroll, voltar, avançar), o atalho de teclado e o tamanho do anel.

## Permissão

O Orbit precisa de **Acessibilidade** (Ajustes do Sistema → Privacidade e Segurança → Acessibilidade) para
ver o clique do scroll e impedir que ele chegue ao app embaixo.

## Build

```sh
./scripts/setup-signing.sh   # uma vez: certificado local para a permissão sobreviver aos rebuilds
./scripts/build-app.sh       # gera build/Orbit.app, dist/Orbit.zip e dist/Orbit.dmg
```

Requer macOS 14.2+. No macOS 26 usa Liquid Glass; antes disso, materiais translúcidos.

Debug: `build/Orbit.app/Contents/MacOS/Orbit --preview-ring` abre o anel no centro da tela.
