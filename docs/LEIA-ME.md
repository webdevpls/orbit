# Orbit — como instalar

**Português** · [English](#english)

## Instalação

### Opção 1: um comando (mais fácil)

Abra o **Terminal** (⌘ Espaço → "Terminal"), cole e aperte Enter:

```
curl -fsSL https://raw.githubusercontent.com/webdevpls/orbit/main/install.sh | bash
```

Pronto: o Orbit é instalado em Aplicativos e abre sozinho, sem aviso de segurança.

### Opção 2: DMG pelo Terminal (sem aviso)

```
curl -fL -o ~/Downloads/Orbit.dmg https://github.com/webdevpls/orbit/releases/latest/download/Orbit.dmg && open ~/Downloads/Orbit.dmg
```

Na janela que abrir, arraste o **Orbit** para **Applications**.

### Opção 3: DMG pelo navegador

1. Abra o **Orbit.dmg**. O macOS mostra *"não foi aberto"*: clique em **Concluído**.
2. Vá em **Ajustes do Sistema → Privacidade e Segurança**, role até a seção **Segurança** e clique em **Abrir Mesmo Assim** ao lado de *"Orbit.dmg" foi bloqueado*. Confirme com a sua senha.
3. Abra o DMG de novo e arraste o **Orbit** para **Applications** (Aplicativos).
4. Abra o Orbit. Se o aviso aparecer para o app, repita o passo 2.

O ícone aparece na **barra de menus**, no canto superior direito, e não no Dock.

Esse aviso aparece porque o Orbit ainda não é notarizado pela Apple (processo pago). O código é aberto e pode ser conferido no GitHub.

### Permissão de Acessibilidade

Clique no ícone do Orbit e em **Permitir**, e ligue o **Orbit** em **Ajustes do Sistema → Privacidade e Segurança → Acessibilidade**. Ela serve só para ver o clique do scroll e impedir que ele chegue ao app embaixo.

### Como usar

Segure o botão do scroll, aponte para um app e solte. Ou dê um clique rápido e escolha com outro clique. `⌥ Space` também abre o anel.

### Requisitos

macOS 14.2 ou mais recente · Apple silicon ou Intel

### Desinstalar

Feche o Orbit (Ajustes → Sair do Orbit) e apague ele da pasta Aplicativos.

Guia completo: https://github.com/webdevpls/orbit

---

## English

**Easiest:** paste this in Terminal: `curl -fsSL https://raw.githubusercontent.com/webdevpls/orbit/main/install.sh | bash`

**DMG without the prompt:** `curl -fL -o ~/Downloads/Orbit.dmg https://github.com/webdevpls/orbit/releases/latest/download/Orbit.dmg && open ~/Downloads/Orbit.dmg`

**DMG from the browser:** open **Orbit.dmg**. If macOS says it wasn't opened, click **Done**, go to **System Settings → Privacy & Security → Open Anyway**, then drag **Orbit** into **Applications**. Orbit lives in the **menu bar**.

Allow **Accessibility** when asked (System Settings → Privacy & Security → Accessibility). Then hold the scroll wheel, point and release, or press `⌥ Space`.

Requires macOS 14.2 or later · Apple silicon or Intel · Full guide: https://github.com/webdevpls/orbit/blob/main/README.en.md

Developed by **Vision Tech**
