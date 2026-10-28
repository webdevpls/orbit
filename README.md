<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Ícone do Orbit">
</p>

<h1 align="center">Orbit</h1>

<p align="center">
  <strong>Seus apps em um anel de vidro, a um clique do scroll.</strong><br>
  Clique no botão do scroll do mouse e um anel de Liquid Glass aparece no cursor com até 8 apps,<br>
  sites, pastas, Atalhos ou ações do sistema. Nativo, leve e direto na barra de menus.
</p>

<p align="center"><sub>Desenvolvido por <strong>Vision Tech</strong></sub></p>

<p align="center"><strong>Português</strong> · <a href="README.en.md">English</a></p>

<p align="center">
  <a href="https://github.com/webdevpls/orbit/releases/latest"><img src="https://img.shields.io/github/v/release/webdevpls/orbit?label=download&color=8f75ff" alt="Última versão"></a>
  <img src="https://img.shields.io/badge/macOS-14.2%2B-black?logo=apple" alt="macOS 14.2+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/Apple%20silicon%20%2B%20Intel-universal-555" alt="Universal">
  <a href="LICENSE"><img src="https://img.shields.io/badge/licen%C3%A7a-GPL--3.0-green" alt="Licença GPL-3.0"></a>
</p>

<p align="center">
  <img src="docs/hero.png" alt="O anel do Orbit aberto com oito apps" width="720">
</p>

---

## Sumário

- [Recursos](#recursos)
- [Requisitos](#requisitos)
- [Instalação](#instalação)
- [Primeiro uso](#primeiro-uso)
- [Guia de uso](#guia-de-uso)
- [Privacidade](#privacidade)
- [Como funciona](#como-funciona)
- [Compilando o código](#compilando-o-código)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Problemas e perguntas frequentes](#problemas-e-perguntas-frequentes)
- [Próximos passos](#próximos-passos)
- [Como contribuir](#como-contribuir)
- [Licença e marca](#licença-e-marca)

## Recursos

| | |
| --- | --- |
| 🖱️ **Clique do scroll** | Abre o anel exatamente onde está o cursor. Também funciona com os botões voltar/avançar do mouse. |
| 🎯 **Segurar e soltar** | Segure o botão, aponte para um item e solte. Ou dê um clique rápido e escolha com outro clique. |
| 🪐 **Até 8 itens** | Apps, sites, arquivos e pastas, Atalhos do macOS e ações do sistema. |
| ⌨️ **Teclado também** | `⌥ Space` abre o anel no cursor. `1`–`8` abrem direto, setas e scroll navegam, `Esc` fecha. |
| ✨ **Liquid Glass** | Disco de vidro com luz colorida, brilho na cor do app selecionado e animações suaves. |
| 🛠️ **Editor visual** | Monte o anel pela barra de menus: clique num item para trocar, girar ou remover. |
| 🌐 **Português e inglês** | Segue o idioma do Mac ou o que você escolher nos Ajustes. |
| 🪶 **Leve** | Sem driver nem app auxiliar. Fica parado até você clicar. |

## Requisitos

- macOS **14.2 Sonoma** ou mais recente (visual Liquid Glass no macOS 26 Tahoe)
- Mac com Apple silicon ou Intel
- Um mouse com botão de scroll clicável (ou use o atalho de teclado)

## Instalação

### Opção 1: um comando (mais fácil)

Abra o **Terminal** (⌘ Espaço → "Terminal"), cole a linha abaixo e aperte Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/webdevpls/orbit/main/install.sh | bash
```

O script baixa a última versão, confere a soma SHA-256 e a assinatura, instala o Orbit em **Aplicativos** e abre o app, sem o aviso de segurança do macOS. Você pode [ver o que ele faz](install.sh) antes de rodar. Para atualizar, é só rodar de novo.

### Opção 2: instalador DMG

Para baixar e abrir o DMG **sem aviso de segurança**, cole no Terminal:

```sh
curl -fL -o ~/Downloads/Orbit.dmg https://github.com/webdevpls/orbit/releases/latest/download/Orbit.dmg && open ~/Downloads/Orbit.dmg
```

Na janela que abrir, arraste o **Orbit** para **Applications** (Aplicativos).

### Opção 3: DMG pelo navegador

Baixe o [**Orbit.dmg**](https://github.com/webdevpls/orbit/releases/latest/download/Orbit.dmg). Na primeira vez o macOS bloqueia, porque o app ainda não é notarizado pela Apple. Para liberar:

1. Abra o **Orbit.dmg**. Aparece o aviso *"Orbit.dmg" não foi aberto*. Clique em **Concluído** (não em "Mover para o Lixo").
2. Abra **Ajustes do Sistema → Privacidade e Segurança** e role até a seção **Segurança**.
3. Vai aparecer *"Orbit.dmg" foi bloqueado para proteger o seu Mac*. Clique em **Abrir Mesmo Assim** e confirme com a sua senha ou o Touch ID.
4. O DMG abre. Arraste o **Orbit** para a pasta **Aplicativos** (Applications).
5. Abra o Orbit. Se o mesmo aviso aparecer para o app, repita os passos 2 e 3.

> O botão **Abrir Mesmo Assim** só aparece por cerca de uma hora depois que você tenta abrir o arquivo. Se não estiver lá, abra o DMG de novo e volte aos Ajustes.

O ícone aparece na **barra de menus**, não no Dock.

> [!NOTE]
> **Por que aparece esse aviso?** O macOS bloqueia apps baixados da internet que não foram notarizados pela Apple, um processo pago (Apple Developer Program). O Orbit é open source: você pode ler todo o código aqui.

## Primeiro uso

O Orbit precisa da permissão de **Acessibilidade** para ver o clique do scroll e impedir que ele chegue ao app embaixo (senão o navegador abriria o link numa aba nova junto com o anel).

1. Clique no ícone do Orbit na barra de menus e depois em **Permitir**.
2. Em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**, ligue o **Orbit**.
3. O status no painel muda para **Ativo** em poucos segundos. Não precisa reabrir o app.

## Guia de uso

<img src="docs/screenshots/panel.png" width="320" align="right" alt="Painel do Orbit na barra de menus">

### Abrindo o anel

- **Segurar e soltar:** segure o botão do scroll, mova o mouse na direção do item e solte.
- **Clicar e escolher:** dê um clique rápido no scroll. O anel fica aberto: clique num item, ou fora do anel para fechar.
- **Teclado:** `⌥ Space` abre o anel no cursor.

Com o anel aberto:

| Tecla | Ação |
| --- | --- |
| `1` – `8` | Abre o item daquela posição (o 1 fica no topo, seguindo no sentido horário) |
| Setas, `Tab` ou scroll | Passa de item em item |
| `Return` ou `Space` | Abre o item selecionado |
| `Esc` ou clique direito | Fecha |

### Montando o anel

Clique no ícone do Orbit na barra de menus:

- Clique num **item do anel** para ver os detalhes. Dá para **testar**, **trocar**, **remover** ou **girar** ele de posição.
- Clique no **+** no centro para adicionar. Escolha entre **Apps**, **Sites**, **Arquivos**, **Atalhos** e **Sistema**.
- Sites mostram o ícone do próprio site, ou do app dele se estiver instalado. Apps e arquivos que foram apagados aparecem em cinza.

<br clear="right">

### Ações do sistema

Captura de Tela · Mission Control · Todos os Apps · Bloquear Tela · Desligar Tela · Emojis e Símbolos · Pasta Mesa.

### Ajustes

Clique na **engrenagem** no painel.

- **Botão do mouse:** clique do scroll, botão voltar, botão avançar ou desligado.
- **Atalho de teclado:** `⌥ Space`, `⌃⌥ Space`, `⌥⌘ O` ou desligado.
- **Clique rápido mantém aberto:** desligue se preferir que o anel sempre feche ao soltar o botão.
- **Tamanho do anel:** P, M ou G.
- **Idioma**, **Abrir ao iniciar sessão**, **Restaurar anel padrão** e **Sair**.

## Privacidade

- O Orbit usa a permissão de Acessibilidade **só** para ler os botões do mouse, a posição do cursor e as teclas de navegação **enquanto o anel está aberto**. Nada é gravado ou enviado.
- A única conexão de rede é para baixar o ícone dos sites que você coloca no anel: primeiro direto do próprio site (`/apple-touch-icon.png` ou `/favicon.ico`) e, se o site bloquear, pelo serviço de ícones do DuckDuckGo (que recebe só o domínio). Se você tiver o app do site instalado (ChatGPT, WhatsApp…), o Orbit usa o ícone do app e nem acessa a rede. O ícone fica em cache em `~/Library/Caches/Orbit`.
- Sem analytics, sem telemetria, sem checagem de atualização.
- O anel e os ajustes ficam só no seu Mac, em `~/Library/Preferences/io.github.orbit-ring.plist`.

## Como funciona

```
 Clique do scroll ──► CGEvent tap (Acessibilidade) ──► o clique é consumido
                              │
                              ▼
                 Painel flutuante no cursor ──► ângulo do cursor = item selecionado
                              │
                              ▼
               Soltar / clicar ──► NSWorkspace abre o app, site, arquivo ou Atalho
```

1. Um **CGEvent tap** observa os botões do mouse. Quando o botão escolhido é pressionado, o Orbit consome o evento e abre o anel num painel flutuante que não rouba o foco do app atual.
2. Enquanto o anel está aberto, o ângulo entre o centro e o cursor define o item selecionado. Perto do centro, nada é selecionado.
3. Ao soltar (ou clicar), o Orbit abre o item: apps e arquivos pelo `NSWorkspace`, Atalhos pelo `shortcuts run`, e ações do sistema pelos apps ou atalhos do macOS.
4. O atalho de teclado usa a API de hot keys do sistema, que não precisa de permissão extra.

## Compilando o código

**Requisitos:** Xcode 26 ou mais recente (Swift 6.2+). Sem outras dependências.

```sh
git clone https://github.com/webdevpls/orbit.git
cd orbit

# Opcional, uma vez: cria um certificado local de assinatura para o macOS
# lembrar da permissão de Acessibilidade entre builds.
./scripts/setup-signing.sh

# Gera o Orbit.app universal em ./build e o .dmg e o .zip em ./dist
./scripts/build-app.sh
open build/Orbit.app
```

| Comando | Descrição |
| --- | --- |
| `swift build` | Build rápido de debug para checar se compila |
| `./scripts/build-app.sh` | Build de release, pacote do app, assinatura, DMG e zip (`VERSION=1.2.3` define a versão) |
| `swift scripts/make-icon.swift` | Gera de novo o ícone do app |
| `Orbit --preview-ring` | Abre o anel no centro da tela (útil para ajustar o visual) |
| `Orbit --preview-panel` | Mostra o painel da barra de menus numa janela |

### Traduções

Os textos ficam em `Resources/<idioma>.lproj/Localizable.strings`. O texto em inglês é a chave. Para adicionar um idioma, copie `pt-BR.lproj`, traduza os valores e inclua o código em `CFBundleLocalizations` no `Info.plist` e em `AppLanguage.options`.

## Estrutura do projeto

```
Sources/Orbit
├── OrbitApp.swift             Entrada na barra de menus e serviços
├── Localization.swift         Idioma da interface
├── Model
│   ├── Action.swift           O que cada item faz (app, site, arquivo, Atalho, sistema)
│   ├── ActionRunner.swift     Executa as ações
│   ├── OrbitStore.swift       Itens do anel, ajustes, permissão, abrir ao iniciar
│   ├── Catalog.swift          Lista de apps instalados e Atalhos
│   └── IconProvider.swift     Ícones, favicons e a cor do brilho
├── Input
│   ├── InputMonitor.swift     CGEvent tap: botões, cursor, teclas e scroll
│   └── Hotkey.swift           Atalho de teclado global
├── Ring
│   ├── RingController.swift   Painel flutuante, geometria e seleção por ângulo
│   └── RingView.swift         O disco de vidro, a aurora e o brilho
└── Views
    ├── PanelView.swift        Painel da barra de menus e editor do anel
    ├── ActionPicker.swift     Escolha de apps, sites, arquivos, Atalhos e sistema
    ├── SettingsView.swift     Ajustes
    └── Components.swift       Botões, cartões de vidro, tema
Resources                      Info.plist, ícone, traduções
scripts                        Build, assinatura e ícone
```

## Problemas e perguntas frequentes

<details>
<summary><strong>Clico no scroll e nada acontece.</strong></summary>

Confira se o painel mostra **Ativo**. Se mostrar **Pausado**, ligue o Orbit em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**. Se ele já estiver ligado e mesmo assim não funcionar (acontece depois de atualizar), desligue e ligue de novo, ou remova com **–** e adicione outra vez.
</details>

<details>
<summary><strong>Meu mouse usa o clique do scroll para outra coisa.</strong></summary>

Se o app do fabricante (Logi Options+, por exemplo) também usa esse botão, desative a função lá, ou troque o Orbit para o botão voltar/avançar em **Ajustes → Botão do mouse**.
</details>

<details>
<summary><strong>Quero abrir links em nova aba com o clique do scroll.</strong></summary>

Enquanto o Orbit usa o clique do scroll, ele não chega ao navegador. Use ⌘ + clique para abrir em nova aba, ou troque o botão do Orbit nos Ajustes.
</details>

<details>
<summary><strong>O atalho de teclado não funciona.</strong></summary>

Outro app pode estar usando a mesma combinação (Raycast, Alfred, ChatGPT…). Escolha outra em **Ajustes → Atalho de teclado**.
</details>

<details>
<summary><strong>Funciona com trackpad?</strong></summary>

Sim, pelo atalho de teclado. Com o anel aberto, mova o cursor até o item e clique.
</details>

<details>
<summary><strong>Como desinstalo?</strong></summary>

Feche o Orbit (Ajustes → Sair do Orbit), apague ele da pasta Aplicativos e, se quiser, remova `~/Library/Preferences/io.github.orbit-ring.plist` e `~/Library/Caches/Orbit`.
</details>

## Próximos passos

- [ ] Anéis diferentes por app (um anel no Figma, outro no navegador)
- [ ] Atalhos de teclado personalizados como item do anel
- [ ] Pastas de itens (um item que abre um segundo anel)
- [ ] Gravar o seu próprio atalho de teclado para abrir o anel
- [ ] Homebrew (`brew install --cask orbit`)
- [ ] Builds notarizadas pela Apple
- [x] Português e inglês

Tem uma ideia? [Sugira um recurso](https://github.com/webdevpls/orbit/issues/new?template=feature_request.md).

## Como contribuir

Relatos de bug, ideias e pull requests são bem-vindos. Leia o [CONTRIBUTING.md](CONTRIBUTING.md) para começar.

## Segurança

Encontrou uma falha de segurança? Não abra uma issue pública: veja o [SECURITY.md](SECURITY.md). Cada release traz o `SHA256SUMS.txt`, e o instalador confere a soma e a assinatura do app antes de instalar.

## Licença e marca

O Orbit é software livre sob a **[Licença Pública Geral GNU v3.0](LICENSE)** (GPL-3.0). Você pode usar, estudar, compartilhar e modificar. Se distribuir uma versão modificada, ela também precisa ser lançada sob a GPL-3.0, com o código-fonte.

O **nome e o ícone do Orbit não fazem parte da GPL**. Forks e redistribuições precisam usar outro nome e outro ícone. Veja o [TRADEMARKS.md](TRADEMARKS.md).

<p align="center"><sub>Desenvolvido por <strong>Vision Tech</strong> · Copyright © 2026 Vision Tech</sub></p>
